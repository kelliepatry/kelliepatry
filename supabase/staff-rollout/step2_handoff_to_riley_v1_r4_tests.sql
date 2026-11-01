-- Executable acceptance tests for studio_api.handoff_to_riley_v1 r4 (KPHD Studio virtual-staff rollout Step 2).
-- Answers GPT review c6f833ff (R3-D2, R3-R1, R3-R2, R3-I1). Governing: GOV-MASTER-20261101.
--
-- PIN: every part loads the candidate only from the exact change-set id AND sha256 given in the settings below,
-- and raises 'PIN FAIL' otherwise. Nothing is selected by key or by "latest".
-- SAFETY: every part ends in RAISE, so its whole transaction rolls back (no committed rows, no committed pg_net
-- request, no organizer wake). The candidate is installed into pg_temp; the live studio_api function is untouched.
-- Fixture writes (memory.actor_access, memory.actors, memory.spaces, memory.sessions, a stale scope_snapshot_v1
-- work_event) happen only inside subtransactions that are always rolled back by pg_temp.try().
-- FAIL CLOSED: each part compares every result with its expected SQLSTATE and ends 'PASS' or 'FAIL: <cases>'.
-- Part B contenders raise FAIL if they never observe their holder.
--
-- Settings (same call, before each part):
--   select set_config('kphd.cs_id',  '<r4 change_set_id>', false),  set_config('kphd.cs_sha', '<r4 candidate sha256>', false),
--          set_config('kphd.ctl_id', '<r3 change_set_id>', false),  set_config('kphd.ctl_sha','<r3 candidate sha256>', false),
--          set_config('kphd.test_session',  '<active governed v3 anthropic session id>', false),
--          set_config('kphd.test_session2', '<second active governed v3 anthropic session id>', false),
--          set_config('kphd.test_closed_session', '<completed session id of the same actor>', false);
-- Parts: SETUP (in every call) | A (one connection) | ISO (one connection) | B1/C1, B2/C2 (two connections each).

---------------------------------------------------------------------------------------------------------
-- SETUP: run at the top of every part's call (pg_temp objects live for the connection only).
---------------------------------------------------------------------------------------------------------
create or replace function pg_temp.load(p_id text, p_sha text, p_as text) returns void language plpgsql as $f$
declare v_sql text;
begin
  select metadata->>'candidate_sql' into v_sql from guard.controlled_change_sets
   where change_set_id = p_id::uuid
     and encode(sha256(convert_to(metadata->>'candidate_sql','UTF8')),'hex') = p_sha;
  if v_sql is null then raise exception 'PIN FAIL: no candidate at change_set_id % with sha256 %', p_id, p_sha; end if;
  execute replace(v_sql, 'studio_api.handoff_to_riley_v1', 'pg_temp.' || p_as);
end $f$;
-- try(): runs p_sql in a subtransaction that is ALWAYS rolled back; returns 'NOERR' or the SQLSTATE.
create or replace function pg_temp.try(p_sql text) returns text language plpgsql as $f$
begin
  execute p_sql;
  raise exception using errcode = 'P0099';
exception when others then
  return case when sqlstate = 'P0099' then 'NOERR' else sqlstate end;
end $f$;
create or replace function pg_temp.ok() returns jsonb language sql as
  $f$ select '{"title":"TEST r4 rolled back","outcome_required":"x","acceptance_test":"x"}'::jsonb $f$;
create or replace function pg_temp.s()  returns uuid language sql as $f$ select current_setting('kphd.test_session')::uuid $f$;
create or replace function pg_temp.s2() returns uuid language sql as $f$ select current_setting('kphd.test_session2')::uuid $f$;
create or replace function pg_temp.sc() returns uuid language sql as $f$ select current_setting('kphd.test_closed_session')::uuid $f$;
-- holder/contender helpers for Part B
create or replace function pg_temp.adv_held_by_other(p_key text) returns int language sql as $f$
  select pid from pg_locks
   where locktype = 'advisory' and granted and objsubid = 1 and pid <> pg_backend_pid()
     and classid = ((hashtextextended(p_key,0) >> 32) & 4294967295)::bigint::oid
     and objid  = (hashtextextended(p_key,0) & 4294967295)::bigint::oid
   limit 1 $f$;
create or replace function pg_temp.wait_for(p_key text, p_secs int) returns int language plpgsql as $f$
declare v int; i int;
begin
  for i in 1..(p_secs*4) loop
    v := pg_temp.adv_held_by_other(p_key);
    if v is not null then return v; end if;
    perform pg_sleep(0.25);
  end loop;
  return null;
end $f$;

---------------------------------------------------------------------------------------------------------
-- PART A (single connection; expected SQLSTATE per case)
---------------------------------------------------------------------------------------------------------
do $a$
declare
  A constant text := 'model:anthropic:claude';
  res text := ''; fails text := ''; c record; got text;
  r1 jsonb; r2 jsonb; t uuid; w runtime.work_queue%rowtype; w2 runtime.work_queue%rowtype;
  q0 bigint; q1 bigint; i0 bigint; i1 bigint; s0 bigint; s1 bigint; ii int; bh text; st text;
  v_actor uuid; v_space uuid; v_proj_task uuid; v_proj uuid;
begin
  perform pg_temp.load(current_setting('kphd.cs_id'), current_setting('kphd.cs_sha'), 'h');
  select actor_id, space_id into v_actor, v_space from memory.sessions where session_id = pg_temp.s();

  for c in select * from (values
    ('A1null',   '22023', $q$select pg_temp.h(null,pg_temp.s(),'t-a','create',null,null,pg_temp.ok())$q$),
    ('A1empty',  '22023', $q$select pg_temp.h('',pg_temp.s(),'t-a','create',null,null,pg_temp.ok())$q$),
    ('A1blank',  '22023', $q$select pg_temp.h('  ',pg_temp.s(),'t-a','create',null,null,pg_temp.ok())$q$),
    ('A2',       '42501', $q$select pg_temp.h('model:openai:gpt',pg_temp.s(),'t-a2','create',null,null,pg_temp.ok())$q$),
    ('A3null',   '22023', $q$select pg_temp.h('model:anthropic:claude',null,'t-a3','create',null,null,pg_temp.ok())$q$),
    ('A3unknown','42501', $q$select pg_temp.h('model:anthropic:claude',gen_random_uuid(),'t-a3u','create',null,null,pg_temp.ok())$q$),
    ('A4revoked','42501', format($q$update memory.actor_access set revoked_at = now() where actor_id=%L and space_id=%L;
                                    select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a4a','create',null,null,pg_temp.ok())$q$, v_actor, v_space)),
    ('A4expired','42501', format($q$update memory.actor_access set valid_until = now() - interval '1 minute' where actor_id=%L and space_id=%L;
                                    select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a4b','create',null,null,pg_temp.ok())$q$, v_actor, v_space)),
    ('A4no_propose','42501', format($q$update memory.actor_access set can_propose = false where actor_id=%L and space_id=%L;
                                    select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a4c','create',null,null,pg_temp.ok())$q$, v_actor, v_space)),
    ('A4space_archived','42501', format($q$update memory.spaces set archived_at = now() where space_id=%L;
                                    select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a4d','create',null,null,pg_temp.ok())$q$, v_space)),
    ('A5paused', '42501', $q$update memory.actors set status = 'paused' where actor_key = 'model:anthropic:claude';
                              select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a5p','create',null,null,pg_temp.ok())$q$),
    ('A5retired','42501', $q$update memory.actors set status = 'retired' where actor_key = 'model:anthropic:claude';
                              select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a5r','create',null,null,pg_temp.ok())$q$),
    ('A6completed','42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.sc(),'t-a6','create',null,null,pg_temp.ok())$q$),
    ('A6legacy', '42501', $q$update memory.sessions set episode_request_key = null where session_id = pg_temp.s();
                             select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a6l','create',null,null,pg_temp.ok())$q$),
    -- a v3 session cannot have a null thread (memory_sessions_episode_fields); test the legacy no-thread shape
    ('A6legacy_no_thread','42501', $q$update memory.sessions set episode_request_key = null, external_thread_id = null where session_id = pg_temp.s();
                             select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a6t','create',null,null,pg_temp.ok())$q$),
    ('A6provider','42501', $q$update memory.sessions set provider = 'openai' where session_id = pg_temp.s();
                             select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a6p','create',null,null,pg_temp.ok())$q$),
    ('A6over72h','42501', $q$update memory.sessions set started_at = now() - interval '73 hours' where session_id = pg_temp.s();
                             select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-a6o','create',null,null,pg_temp.ok())$q$),
    ('M1null',   '22023', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-m1',null,null,null,pg_temp.ok())$q$),
    ('M1other',  '22023', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-m1o','other',null,null,pg_temp.ok())$q$),
    ('M2',       '22023', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-m2','create','0113f8d5-ff9b-41b6-b91e-d389ce02b366',null,pg_temp.ok())$q$),
    ('S1',       '42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s1','create',null,null,
                             pg_temp.ok()||jsonb_build_object('project_id',(select project_id from runtime.work_queue where project_id is not null limit 1)))$q$),
    ('S2deliver','42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s2d','create',null,null,pg_temp.ok()||'{"pipeline_family":"DELIVER"}')$q$),
    ('S2system', '42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s2s','create',null,null,pg_temp.ok()||'{"pipeline_family":"SYSTEM"}')$q$),
    ('S3cap_domain','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s3a','create',null,null,pg_temp.ok()||'{"capability_domain":"x"}')$q$),
    ('S3scope_type','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s3b','create',null,null,pg_temp.ok()||'{"scope_type":"project"}')$q$),
    ('S3capability','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s3c','create',null,null,pg_temp.ok()||'{"capability":"x"}')$q$),
    ('S3scope_review','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s3d','create',null,null,pg_temp.ok()||'{"action_key":"scope.review"}')$q$),
    ('S3work_index','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s3e','create',null,null,pg_temp.ok()||'{"action_key":"work_index.prepare"}')$q$),
    ('S3target_type','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s3f','create',null,null,pg_temp.ok()||'{"target_type":"work_scope_review"}')$q$),
    ('S5assignee','42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s5a','create',null,null,pg_temp.ok()||'{"assignee":"kellie"}')$q$),
    ('S5action_class','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s5b','create',null,null,pg_temp.ok()||'{"action_class":"client_visible_output"}')$q$),
    ('S5scope_ruling','42501',$q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-s5c','create',null,null,pg_temp.ok()||'{"scope_ruling":"x"}')$q$),
    ('P1',       '42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-p1','annotate','0113f8d5-ff9b-41b6-b91e-d389ce02b366',
                             (select updated_at from runtime.work_queue where task_id='0113f8d5-ff9b-41b6-b91e-d389ce02b366'),'{"note":"x"}')$q$),
    ('P2closed', '42501', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-p2c','annotate',x.task_id,x.updated_at,'{"note":"x"}')
                             from (select task_id, updated_at from runtime.work_queue
                                    where assigned_agt in ('chatgpt_dot','kphd_agent_riley') and archived_at is null
                                      and session_lock::text <> 'active_session'
                                      and (status::text not in ('active','blocked','waiting') or operational_status in ('completed','suppressed','failed'))
                                    order by updated_at limit 1) x$q$)
  ) v(name, expected, sql)
  loop
    got := pg_temp.try(c.sql);
    res := res || c.name || ':' || got || ' ';
    if got is distinct from c.expected then fails := fails || c.name || '(want ' || c.expected || ' got ' || got || ') '; end if;
  end loop;

  -- success path: stays in this transaction until the final RAISE
  select count(*) into q0 from net.http_request_queue;
  select count(*) into s0 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1';
  r1 := pg_temp.h(A,pg_temp.s(),'t-y1','create',null,null,pg_temp.ok());
  t := (r1->>'task_id')::uuid;
  select count(*) into q1 from net.http_request_queue;
  select count(*) into s1 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1';
  select count(*) into i0 from intake.items where source_record_id = t::text;
  select * into w from runtime.work_queue where task_id = t;
  if not (w.scope_type='studio' and w.project_id is null and w.pipeline_family='SYSTEM' and w.capability_domain='agent_orchestration'
          and w.action_key='claude.riley_handoff' and w.capability is null and w.target_type is null
          and w.operational_status='detected' and w.assigned_agt='chatgpt_dot') then fails := fails || 'S4 '; end if;
  res := res || 'D1:intake=' || i0 || ',http=' || (q1-q0) || ' D4create:snapshots=' || (s1-s0) || ' ';
  if i0 <> 1 or (q1-q0) > 1 then fails := fails || 'D1 '; end if;
  if r1->>'downstream' <> 'jev_organizer_enqueue_and_wake_possible;scope_snapshot_scan' then fails := fails || 'contract '; end if;
  -- Y1 / Y2 / Y3
  r2 := pg_temp.h(A,pg_temp.s(),'t-y1','create',null,null,pg_temp.ok());
  if not ((r1-'replayed') = (r2-'replayed') and (r2->>'replayed')::boolean) then fails := fails || 'Y1 '; end if;
  r2 := pg_temp.h(A,pg_temp.sc(),'t-y1','create',null,null,pg_temp.ok());
  if not ((r1-'replayed') = (r2-'replayed') and (r2->>'replayed')::boolean) then fails := fails || 'Y2 '; end if;
  got := pg_temp.try($q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-y1','create',null,null,pg_temp.ok()||'{"note":"diff"}')$q$);
  res := res || 'Y3payload:' || got || ' '; if got <> '22023' then fails := fails || 'Y3payload '; end if;
  got := pg_temp.try($q$select pg_temp.h('model:openai:gpt',pg_temp.s(),'t-y1','create',null,null,pg_temp.ok())$q$);
  res := res || 'Y3actor:' || got || ' '; if got <> '42501' then fails := fails || 'Y3actor '; end if;
  -- P2stale
  got := pg_temp.try(format($q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-p2s','annotate',%L,%L::timestamptz - interval '1 second','{"note":"x"}')$q$, t, w.updated_at));
  res := res || 'P2stale:' || got || ' '; if got <> '40001' then fails := fails || 'P2stale '; end if;
  -- D2 / P3: evidence-only annotate
  select count(*) into q0 from net.http_request_queue;
  r2 := pg_temp.h(A,pg_temp.s(),'t-p3','annotate',t,w.updated_at,'{"note":"annotate test"}');
  select count(*) into q1 from net.http_request_queue;
  select count(*) into i1 from intake.items where source_record_id = t::text;
  select * into w2 from runtime.work_queue where task_id = t;
  res := res || 'D2:intake_delta=' || (i1-i0) || ',http=' || (q1-q0) || ' ';
  if (i1-i0) <> 0 or (q1-q0) <> 0 then fails := fails || 'D2 '; end if;
  if (to_jsonb(w) - array['evidence','updated_at']) is distinct from (to_jsonb(w2) - array['evidence','updated_at'])
     or jsonb_array_length(w2.evidence) <> jsonb_array_length(w.evidence) + 1 then fails := fails || 'P3 '; end if;
  -- D4+ positive scope snapshot: a stale snapshot fixture on one project row makes the handoff's own statement
  -- trigger write a corrective scope_snapshot_v1 event (create and annotate each checked).
  select task_id, project_id into v_proj_task, v_proj from runtime.work_queue where project_id is not null and archived_at is null limit 1;
  insert into runtime.work_events(task_id,project_id,event_type,actor_type,actor_ref,authority_class,idempotency_key,detail,occurred_at)
  values (v_proj_task, v_proj, 'revised', 'function', 'scope-gate-v1', 'assist', 'r4-test-stale-snapshot:' || gen_random_uuid(),
          jsonb_build_object('contract','scope_snapshot_v1','scope',jsonb_build_object('fixture','stale-r4-test')), clock_timestamp());
  select count(*) into s0 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1' and task_id = v_proj_task;
  perform pg_temp.h(A,pg_temp.s(),'t-d4c','create',null,null,pg_temp.ok());
  select count(*) into s1 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1' and task_id = v_proj_task;
  res := res || 'D4+create:fixture_row_snapshots=' || (s1-s0) || ' ';
  if (s1-s0) < 1 then fails := fails || 'D4+create '; end if;
  insert into runtime.work_events(task_id,project_id,event_type,actor_type,actor_ref,authority_class,idempotency_key,detail,occurred_at)
  values (v_proj_task, v_proj, 'revised', 'function', 'scope-gate-v1', 'assist', 'r4-test-stale-snapshot:' || gen_random_uuid(),
          jsonb_build_object('contract','scope_snapshot_v1','scope',jsonb_build_object('fixture','stale-r4-test-2')), clock_timestamp());
  select count(*) into s0 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1' and task_id = v_proj_task;
  select * into w2 from runtime.work_queue where task_id = t;
  perform pg_temp.h(A,pg_temp.s(),'t-d4a','annotate',t,w2.updated_at,'{"note":"d4 annotate"}');
  select count(*) into s1 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1' and task_id = v_proj_task;
  res := res || 'D4+annotate:fixture_row_snapshots=' || (s1-s0) || ' ';
  if (s1-s0) < 1 then fails := fails || 'D4+annotate '; end if;
  -- P2b: real Dot claim sets active_session; annotate then refused
  select * into w2 from runtime.work_queue where task_id = t;
  bh := runtime.evaluate_work_scope_v1(t)->>'basis_hash';
  perform studio_api.dot_claim_work_v1(t, w2.updated_at, bh);
  select * into w2 from runtime.work_queue where task_id = t;
  got := pg_temp.try(format($q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-p2b','annotate',%L,%L,'{"note":"x"}')$q$, t, w2.updated_at));
  res := res || 'P2b:lock=' || w2.session_lock::text || ',' || got || ' ';
  if w2.session_lock::text <> 'active_session' or got <> '40001' then fails := fails || 'P2b '; end if;
  -- D3 + Y4: this transaction already holds 2 creates (t-y1, t-d4c); fill to 10, 11th refused, replay served
  for ii in 3..10 loop perform pg_temp.h(A,pg_temp.s(),'t-d3-'||ii,'create',null,null,pg_temp.ok()); end loop;
  got := pg_temp.try($q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-d3-11','create',null,null,pg_temp.ok())$q$);
  res := res || 'D3:' || got || ' '; if got <> '54000' then fails := fails || 'D3 '; end if;
  r2 := pg_temp.h(A,pg_temp.s(),'t-y1','create',null,null,pg_temp.ok());
  if not (r2->>'replayed')::boolean then fails := fails || 'Y4 '; end if;

  raise exception using errcode='P0001', message = 'TESTRESULTS(rolled back) PART A '
    || current_setting('kphd.cs_id') || '/' || left(current_setting('kphd.cs_sha'),12) || ' '
    || case when fails = '' then 'PASS' else 'FAIL: ' || fails end || ' | ' || res;
end
$a$;

---------------------------------------------------------------------------------------------------------
-- PART ISO (single connection): the call must start with this SET so the whole transaction is REPEATABLE READ.
---------------------------------------------------------------------------------------------------------
-- set transaction isolation level repeatable read;
do $iso$
declare got text;
begin
  if current_setting('transaction_isolation') <> 'repeatable read' then
    raise exception 'TESTRESULTS(rolled back) PART ISO FAIL: fixture isolation is %', current_setting('transaction_isolation');
  end if;
  perform pg_temp.load(current_setting('kphd.cs_id'), current_setting('kphd.cs_sha'), 'h');
  got := pg_temp.try($q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'t-iso','create',null,null,pg_temp.ok())$q$);
  raise exception using errcode='P0001', message = 'TESTRESULTS(rolled back) PART ISO '
    || case when got = '25000' then 'PASS' else 'FAIL' end || ' | repeatable_read_create:' || got;
end
$iso$;

---------------------------------------------------------------------------------------------------------
-- PART B1 (holder, connection 1): signals phase 'r4test:B1', takes session S's lock with a create, takes the
-- route-check work row lock with an annotate, holds both for 25 s, rolls back.
---------------------------------------------------------------------------------------------------------
do $b1$
declare t0 timestamptz := clock_timestamp(); r jsonb; a jsonb;
begin
  perform pg_temp.load(current_setting('kphd.cs_id'), current_setting('kphd.cs_sha'), 'h');
  r := pg_temp.h('model:anthropic:claude', pg_temp.s(), 'b1-hold', 'create', null, null, pg_temp.ok());
  a := pg_temp.h('model:anthropic:claude', pg_temp.s(), 'b1-annot', 'annotate', '1cae1c73-fda6-408b-9bf5-3bbaf5e79672',
         (select updated_at from runtime.work_queue where task_id='1cae1c73-fda6-408b-9bf5-3bbaf5e79672'), '{"note":"r4 test hold"}');
  perform pg_advisory_xact_lock(hashtextextended('r4test:B1', 0));   -- phase signal, taken last
  perform pg_sleep(25);
  raise exception using errcode='P0001', message = format('TESTRESULTS(rolled back) PART B1 pid=%s held %s..%s',
    pg_backend_pid(), t0, clock_timestamp());
end
$b1$;

---------------------------------------------------------------------------------------------------------
-- PART C1 (contender, connection 2): waits for 'r4test:B1', then each probe with lock_timeout 2 s.
---------------------------------------------------------------------------------------------------------
do $c1$
declare holder int; res text := ''; fails text := ''; c record; got text;
begin
  perform pg_temp.load(current_setting('kphd.cs_id'), current_setting('kphd.cs_sha'), 'h');
  holder := pg_temp.wait_for('r4test:B1', 40);
  if holder is null then raise exception 'TESTRESULTS(rolled back) PART C1 FAIL: holder never observed'; end if;
  perform set_config('lock_timeout', '2s', true);
  for c in select * from (values
    ('R5_distinct_key_same_session', '55P03', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'c1-distinct','create',null,null,pg_temp.ok())$q$),
    ('R4_same_key_same_session',     '55P03', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'b1-hold','create',null,null,pg_temp.ok())$q$),
    ('R1_close_while_handoff_open',  '55P03', $q$select studio_api.end_work_v1('model:anthropic:claude',pg_temp.s(),'r4-test-close-c1',
                                                   jsonb_build_object('summary','r4 test close probe (rolled back)'))$q$),
    ('R3_competing_annotate_other_session','55P03', $q$select pg_temp.h('model:anthropic:claude',pg_temp.s2(),'c1-annot','annotate',
                                                   '1cae1c73-fda6-408b-9bf5-3bbaf5e79672',
                                                   (select updated_at from runtime.work_queue where task_id='1cae1c73-fda6-408b-9bf5-3bbaf5e79672'),'{"note":"x"}')$q$),
    ('control_installed_r2_distinct_key','NOERR', $q$select studio_api.handoff_to_riley_v1('model:anthropic:claude',pg_temp.s(),'c1-r2-control','create',null,null,pg_temp.ok())$q$)
  ) v(name, expected, sql)
  loop
    got := pg_temp.try(c.sql);
    res := res || c.name || ':' || got || ' ';
    if got is distinct from c.expected then fails := fails || c.name || '(want ' || c.expected || ' got ' || got || ') '; end if;
  end loop;
  -- still inside the holder window?
  if pg_temp.adv_held_by_other('r4test:B1') is null then fails := fails || 'holder_window_closed_before_end '; end if;
  raise exception using errcode='P0001', message = format('TESTRESULTS(rolled back) PART C1 pid=%s holder=%s %s | %s',
    pg_backend_pid(), holder, case when fails = '' then 'PASS' else 'FAIL: ' || fails end, res);
end
$c1$;

---------------------------------------------------------------------------------------------------------
-- PART B2 (holder, connection 1) and PART C2 (contender, connection 2): R3-R1 handoff-then-close composition.
-- kphd.b2_version = 'r4' (pinned r4) or 'r3' (pinned r3 control, kphd.ctl_id / kphd.ctl_sha).
-- Holder: phase lock, create on S (session lock + session row SHARE), wait 6 s so the contender queues, then
-- end_work_v1 (memory.close_session_v2, session row FOR UPDATE) in the same transaction; records its SQLSTATE.
-- Contender: same version, create on S with lock_timeout 30 s; records its SQLSTATE.
-- Expected r4: holder close NOERR, contender NOERR (after holder rollback), no 40P01 anywhere.
-- Expected r3: 40P01 in exactly one of the two.
---------------------------------------------------------------------------------------------------------
do $b2$
declare v text := current_setting('kphd.b2_version'); close_state text; t0 timestamptz := clock_timestamp(); t1 timestamptz;
begin
  if v is null or v not in ('r3','r4') then raise exception 'TESTRESULTS(rolled back) PART B2 FAIL: kphd.b2_version must be r3 or r4, got %', v; end if;
  if v = 'r4' then perform pg_temp.load(current_setting('kphd.cs_id'), current_setting('kphd.cs_sha'), 'h');
  else perform pg_temp.load(current_setting('kphd.ctl_id'), current_setting('kphd.ctl_sha'), 'h'); end if;
  perform pg_advisory_xact_lock(hashtextextended('r4test:B2:' || v, 0));
  perform pg_temp.h('model:anthropic:claude', pg_temp.s(), 'b2-hold-' || v, 'create', null, null, pg_temp.ok());
  perform pg_sleep(6);
  t1 := clock_timestamp();
  begin
    perform studio_api.end_work_v1('model:anthropic:claude', pg_temp.s(), 'r4-test-close-b2-' || v,
                                   jsonb_build_object('summary','r4 test close in holder (rolled back)'));
    close_state := 'NOERR';
  exception when others then close_state := sqlstate;
  end;
  perform pg_sleep(2);
  raise exception using errcode='P0001', message = format('TESTRESULTS(rolled back) PART B2 version=%s pid=%s close_in_holder=%s close_started=%s end=%s',
    v, pg_backend_pid(), close_state, t1, clock_timestamp());
end
$b2$;

do $c2$
declare v text := current_setting('kphd.b2_version'); holder int; got text; t0 timestamptz; verdict text;
begin
  if v is null or v not in ('r3','r4') then raise exception 'TESTRESULTS(rolled back) PART C2 FAIL: kphd.b2_version must be r3 or r4, got %', v; end if;
  if v = 'r4' then perform pg_temp.load(current_setting('kphd.cs_id'), current_setting('kphd.cs_sha'), 'h');
  else perform pg_temp.load(current_setting('kphd.ctl_id'), current_setting('kphd.ctl_sha'), 'h'); end if;
  holder := pg_temp.wait_for('r4test:B2:' || v, 40);
  if holder is null then raise exception 'TESTRESULTS(rolled back) PART C2 FAIL: holder never observed'; end if;
  perform set_config('lock_timeout', '30s', true);
  t0 := clock_timestamp();
  got := pg_temp.try($q$select pg_temp.h('model:anthropic:claude',pg_temp.s(),'c2-wait','create',null,null,pg_temp.ok())$q$);
  verdict := case
    when v = 'r4' and got = 'NOERR' then 'PASS (contender completed; check holder close_in_holder=NOERR)'
    when v = 'r3' and got = '40P01' then 'PASS-CONTROL (deadlock reproduced on r3, contender was victim)'
    when v = 'r3' and got = 'NOERR' then 'CHECK (contender ok on r3; holder must show 40P01)'
    else 'FAIL' end;
  raise exception using errcode='P0001', message = format('TESTRESULTS(rolled back) PART C2 version=%s pid=%s holder=%s contender=%s waited=%s %s',
    v, pg_backend_pid(), holder, got, clock_timestamp() - t0, verdict);
end
$c2$;

---------------------------------------------------------------------------------------------------------
-- PART V (verifier, any connection; read-only). Answers GPT review b8dd7797 finding R4-D1: B2 and C2 run on
-- separate connections and cannot see each other's results, so the pair is asserted here from their verbatim
-- outputs. Set, in the same call:
--   kphd.b2_version = 'r3' | 'r4'
--   kphd.b2_out     = the holder's full TESTRESULTS text (PART B2 ...)
--   kphd.c2_out     = the contender's full TESTRESULTS text (PART C2 ...)
-- PASS requires: both texts are for the same version; the contender observed exactly the holder's pid; and
--   r4: holder close NOERR and contender NOERR (no 40P01 anywhere)
--   r3: exactly one of the two is 40P01 (the deadlock control reproduced)
---------------------------------------------------------------------------------------------------------
do $v$
declare
  v  text := current_setting('kphd.b2_version');
  b  text := current_setting('kphd.b2_out');
  c  text := current_setting('kphd.c2_out');
  b_ver text := substring(b from 'PART B2 version=(r[34])');
  c_ver text := substring(c from 'PART C2 version=(r[34])');
  b_pid text := substring(b from 'PART B2 version=r[34] pid=([0-9]+)');
  c_holder text := substring(c from ' holder=([0-9]+)');
  b_close text := substring(b from 'close_in_holder=([0-9A-Z]+)');
  c_state text := substring(c from ' contender=([0-9A-Z]+)');
  fails text := '';
begin
  if v is null or v not in ('r3','r4') then fails := fails || 'bad_version '; end if;
  if b_ver is distinct from v or c_ver is distinct from v then fails := fails || 'version_mismatch(' || coalesce(b_ver,'?') || '/' || coalesce(c_ver,'?') || ') '; end if;
  if b_pid is null or c_holder is distinct from b_pid then fails := fails || 'holder_pid_mismatch(' || coalesce(b_pid,'?') || '/' || coalesce(c_holder,'?') || ') '; end if;
  if b_close is null or c_state is null then fails := fails || 'unparsed_result '; end if;
  if v = 'r4' and not (b_close = 'NOERR' and c_state = 'NOERR') then fails := fails || 'r4_expected_both_NOERR '; end if;
  if v = 'r3' and not ((b_close = '40P01') <> (c_state = '40P01')) then fails := fails || 'r3_expected_exactly_one_40P01 '; end if;
  raise exception using errcode='P0001', message = format('TESTRESULTS PART V version=%s holder_pid=%s holder_close=%s contender=%s %s',
    v, b_pid, b_close, c_state, case when fails = '' then 'PASS' else 'FAIL: ' || fails end);
end
$v$;
