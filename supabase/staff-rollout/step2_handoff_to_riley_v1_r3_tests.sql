-- Executable acceptance tests for studio_api.handoff_to_riley_v1 r3 (KPHD Studio virtual-staff rollout Step 2).
-- Candidate source: guard.controlled_change_sets where metadata->>'candidate_key' = 'staff-rollout-step2-r3'.
--
-- Safety: every part ends in RAISE, so its whole transaction rolls back: no committed rows, no committed
-- pg_net request, no organizer wake. r3 is installed into pg_temp for the test, so the live
-- studio_api.handoff_to_riley_v1 is never replaced. Results come back in the error text "TESTRESULTS ...".
--
-- Settings (same call, before the DO block):
--   select set_config('kphd.test_session',        '<active governed v3 anthropic session id>', false);
--   select set_config('kphd.test_closed_session', '<completed session id of the same actor>', false);
--
-- Part A: single connection.  Part B: R5 race, run B1 and B2 at the same time on two connections.

---------------------------------------------------------------------------------------------------------
-- PART A
---------------------------------------------------------------------------------------------------------
do $t$
declare
  S  constant uuid := current_setting('kphd.test_session')::uuid;
  SC constant uuid := current_setting('kphd.test_closed_session')::uuid;
  A  constant text := 'model:anthropic:claude';
  ok constant jsonb := '{"title":"TEST r3 rolled back","outcome_required":"x","acceptance_test":"x"}';
  v_sql text; res text := ''; fails text := ''; st text; got text;
  r1 jsonb; r2 jsonb; t uuid; w runtime.work_queue%rowtype; w2 runtime.work_queue%rowtype;
  q0 bigint; q1 bigint; i0 bigint; i1 bigint; s0 bigint; s1 bigint; ii int; ts timestamptz; bh text;
begin
  select metadata->>'candidate_sql' into v_sql from guard.controlled_change_sets
   where metadata->>'candidate_key' = 'staff-rollout-step2-r3'
     and encode(sha256(convert_to(metadata->>'candidate_sql','UTF8')),'hex') = metadata->>'candidate_sha256'
   order by proposed_at desc limit 1;
  if v_sql is null then raise exception 'r3 candidate not found or sha mismatch'; end if;
  execute replace(v_sql, 'studio_api.handoff_to_riley_v1', 'pg_temp.handoff_to_riley_v1');

  -- expected-error cases: each in its own subtransaction; record 'name:expected/got'
  for st, got in
    select * from (values ('A1null','22023'),('A1empty','22023'),('A1blank','22023'),('A2','42501'),
      ('A3null','22023'),('A3unknown','42501'),('A6closed','42501'),('M1null','22023'),('M1other','22023'),('M2','22023'),
      ('S1','42501'),('S2deliver','42501'),('S2system','42501'),('S3cap_domain','42501'),('S3scope_type','42501'),
      ('S3capability','42501'),('S3scope_review','42501'),('S3work_index','42501'),('S3target_type','42501'),
      ('S5assignee','42501'),('S5action_class','42501'),('S5scope_ruling','42501'),('P1','42501'),('P2closed','42501')) v
  loop
    declare e text := 'NOERR';
    begin
      begin
        case st
          when 'A1null'   then perform pg_temp.handoff_to_riley_v1(null,S,'t-a','create',null,null,ok);
          when 'A1empty'  then perform pg_temp.handoff_to_riley_v1('',S,'t-a','create',null,null,ok);
          when 'A1blank'  then perform pg_temp.handoff_to_riley_v1('  ',S,'t-a','create',null,null,ok);
          when 'A2'       then perform pg_temp.handoff_to_riley_v1('model:openai:gpt',S,'t-a2','create',null,null,ok);
          when 'A3null'   then perform pg_temp.handoff_to_riley_v1(A,null,'t-a3','create',null,null,ok);
          when 'A3unknown' then perform pg_temp.handoff_to_riley_v1(A,gen_random_uuid(),'t-a3u','create',null,null,ok);
          when 'A6closed' then perform pg_temp.handoff_to_riley_v1(A,SC,'t-a6','create',null,null,ok);
          when 'M1null'   then perform pg_temp.handoff_to_riley_v1(A,S,'t-m1',null,null,null,ok);
          when 'M1other'  then perform pg_temp.handoff_to_riley_v1(A,S,'t-m1o','other',null,null,ok);
          when 'M2'       then perform pg_temp.handoff_to_riley_v1(A,S,'t-m2','create','0113f8d5-ff9b-41b6-b91e-d389ce02b366',null,ok);
          when 'S1'       then perform pg_temp.handoff_to_riley_v1(A,S,'t-s1','create',null,null,
                                 ok||jsonb_build_object('project_id',(select project_id from runtime.work_queue where project_id is not null limit 1)));
          when 'S2deliver' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s2d','create',null,null,ok||'{"pipeline_family":"DELIVER"}');
          when 'S2system' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s2s','create',null,null,ok||'{"pipeline_family":"SYSTEM"}');
          when 'S3cap_domain' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s3a','create',null,null,ok||'{"capability_domain":"x"}');
          when 'S3scope_type' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s3b','create',null,null,ok||'{"scope_type":"project"}');
          when 'S3capability' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s3c','create',null,null,ok||'{"capability":"x"}');
          when 'S3scope_review' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s3d','create',null,null,ok||'{"action_key":"scope.review"}');
          when 'S3work_index' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s3e','create',null,null,ok||'{"action_key":"work_index.prepare"}');
          when 'S3target_type' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s3f','create',null,null,ok||'{"target_type":"work_scope_review"}');
          when 'S5assignee' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s5a','create',null,null,ok||'{"assignee":"kellie"}');
          when 'S5action_class' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s5b','create',null,null,ok||'{"action_class":"client_visible_output"}');
          when 'S5scope_ruling' then perform pg_temp.handoff_to_riley_v1(A,S,'t-s5c','create',null,null,ok||'{"scope_ruling":"x"}');
          when 'P1' then
            select updated_at into ts from runtime.work_queue where task_id='0113f8d5-ff9b-41b6-b91e-d389ce02b366';
            perform pg_temp.handoff_to_riley_v1(A,S,'t-p1','annotate','0113f8d5-ff9b-41b6-b91e-d389ce02b366',ts,'{"note":"x"}');
          when 'P2closed' then
            select task_id, updated_at into t, ts from runtime.work_queue
             where assigned_agt in ('chatgpt_dot','kphd_agent_riley') and archived_at is null and session_lock::text <> 'active_session'
               and (status::text not in ('active','blocked','waiting') or operational_status in ('completed','suppressed','failed'))
             order by updated_at limit 1;
            perform pg_temp.handoff_to_riley_v1(A,S,'t-p2c','annotate',t,ts,'{"note":"x"}');
        end case;
      exception when others then e := sqlstate;
      end;
      res := res || st || ':' || e || ' ';
      if e <> got then fails := fails || st || '(want ' || got || ' got ' || e || ') '; end if;
    end;
  end loop;

  -- success path (stays in this transaction; rolled back at the end)
  select count(*) into q0 from net.http_request_queue;
  select count(*) into s0 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1';
  r1 := pg_temp.handoff_to_riley_v1(A,S,'t-y1','create',null,null,ok);
  t := (r1->>'task_id')::uuid;
  select count(*) into q1 from net.http_request_queue;
  select count(*) into s1 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1';
  select count(*) into i0 from intake.items where source_record_id = t::text;
  select * into w from runtime.work_queue where task_id = t;
  -- S4
  if not (w.scope_type='studio' and w.project_id is null and w.pipeline_family='SYSTEM' and w.capability_domain='agent_orchestration'
          and w.action_key='claude.riley_handoff' and w.capability is null and w.target_type is null
          and w.operational_status='detected' and w.assigned_agt='chatgpt_dot') then fails := fails || 'S4 '; end if;
  -- D1 / D4(create) / contract
  res := res || 'D1:intake=' || i0 || ',http=' || (q1-q0) || ' D4create:snapshots=' || (s1-s0) || ' ';
  if i0 <> 1 or (q1-q0) > 1 then fails := fails || 'D1 '; end if;
  if r1->>'contract' <> 'claude_riley_handoff_result/3' or r1->>'downstream' <> 'jev_organizer_enqueue_and_wake_possible;scope_snapshot_scan'
    then fails := fails || 'contract '; end if;
  -- Y1
  r2 := pg_temp.handoff_to_riley_v1(A,S,'t-y1','create',null,null,ok);
  if not ((r1-'replayed') = (r2-'replayed') and (r2->>'replayed')::boolean) then fails := fails || 'Y1 '; end if;
  -- Y2 (replay through a completed session of the same actor: replayed, no writes)
  r2 := pg_temp.handoff_to_riley_v1(A,SC,'t-y1','create',null,null,ok);
  if not ((r1-'replayed') = (r2-'replayed') and (r2->>'replayed')::boolean) then fails := fails || 'Y2 '; end if;
  -- Y3
  begin perform pg_temp.handoff_to_riley_v1(A,S,'t-y1','create',null,null,ok||'{"note":"diff"}'); st := 'NOERR';
  exception when others then st := sqlstate; end;
  res := res || 'Y3payload:' || st || ' '; if st <> '22023' then fails := fails || 'Y3payload '; end if;
  begin perform pg_temp.handoff_to_riley_v1('model:openai:gpt',S,'t-y1','create',null,null,ok); st := 'NOERR';
  exception when others then st := sqlstate; end;
  res := res || 'Y3actor:' || st || ' '; if st <> '42501' then fails := fails || 'Y3actor '; end if;
  -- P2stale
  begin perform pg_temp.handoff_to_riley_v1(A,S,'t-p2s','annotate',t,w.updated_at - interval '1 second','{"note":"x"}'); st := 'NOERR';
  exception when others then st := sqlstate; end;
  res := res || 'P2stale:' || st || ' '; if st <> '40001' then fails := fails || 'P2stale '; end if;
  -- D2 / D4(annotate) / P3: annotate success
  select count(*) into q0 from net.http_request_queue;
  select count(*) into s0 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1';
  r2 := pg_temp.handoff_to_riley_v1(A,S,'t-p3','annotate',t,w.updated_at,'{"note":"annotate test"}');
  select count(*) into q1 from net.http_request_queue;
  select count(*) into s1 from runtime.work_events where detail->>'contract' = 'scope_snapshot_v1';
  select count(*) into i1 from intake.items where source_record_id = t::text;
  select * into w2 from runtime.work_queue where task_id = t;
  res := res || 'D2:intake_delta=' || (i1-i0) || ',http=' || (q1-q0) || ' D4annotate:snapshots=' || (s1-s0) || ' ';
  if (i1-i0) <> 0 or (q1-q0) <> 0 then fails := fails || 'D2 '; end if;
  if r2->>'downstream' <> 'scope_snapshot_scan' then fails := fails || 'D2contract '; end if;
  if (to_jsonb(w) - array['evidence','updated_at']) is distinct from (to_jsonb(w2) - array['evidence','updated_at'])
     or jsonb_array_length(w2.evidence) <> jsonb_array_length(w.evidence) + 1 then fails := fails || 'P3 '; end if;
  -- P2b: claim through the real Dot API (sets active_session), then annotate -> 40001
  bh := runtime.evaluate_work_scope_v1(t)->>'basis_hash';
  perform studio_api.dot_claim_work_v1(t, w2.updated_at, bh);
  select * into w2 from runtime.work_queue where task_id = t;
  begin perform pg_temp.handoff_to_riley_v1(A,S,'t-p2b','annotate',t,w2.updated_at,'{"note":"x"}'); st := 'NOERR';
  exception when others then st := sqlstate; end;
  res := res || 'P2b:lock=' || w2.session_lock::text || ',' || st || ' ';
  if w2.session_lock::text <> 'active_session' or st <> '40001' then fails := fails || 'P2b '; end if;
  -- D3 + Y4: fill to the cap of 10, 11th refused, replay still served
  for ii in 2..10 loop perform pg_temp.handoff_to_riley_v1(A,S,'t-d3-'||ii,'create',null,null,ok); end loop;
  begin perform pg_temp.handoff_to_riley_v1(A,S,'t-d3-11','create',null,null,ok); st := 'NOERR';
  exception when others then st := sqlstate; end;
  res := res || 'D3:' || st || ' '; if st <> '54000' then fails := fails || 'D3 '; end if;
  r2 := pg_temp.handoff_to_riley_v1(A,S,'t-y1','create',null,null,ok);
  if not (r2->>'replayed')::boolean then fails := fails || 'Y4 '; end if;

  raise exception using errcode='P0001', message =
    'TESTRESULTS(rolled back) ' || case when fails = '' then 'PASS' else 'FAIL: ' || fails end || ' | ' || res;
end
$t$;

---------------------------------------------------------------------------------------------------------
-- PART B1 (holder): takes the per-session lock via a create, holds it for 45 s, then rolls back.
---------------------------------------------------------------------------------------------------------
do $b1$
declare v_sql text; r jsonb; t0 timestamptz := clock_timestamp();
begin
  select metadata->>'candidate_sql' into v_sql from guard.controlled_change_sets
   where metadata->>'candidate_key' = 'staff-rollout-step2-r3' order by proposed_at desc limit 1;
  execute replace(v_sql, 'studio_api.handoff_to_riley_v1', 'pg_temp.handoff_to_riley_v1');
  r := pg_temp.handoff_to_riley_v1('model:anthropic:claude', current_setting('kphd.test_session')::uuid, 'r5-holder', 'create', null, null,
         '{"title":"TEST r5 holder","outcome_required":"x","acceptance_test":"x"}');
  perform pg_sleep(45);
  raise exception using errcode='P0001', message = format('TESTRESULTS(rolled back) R5-B1 pid=%s locked_at=%s released_at=%s created=%s',
    pg_backend_pid(), t0, clock_timestamp(), r->>'task_id');
end
$b1$;

---------------------------------------------------------------------------------------------------------
-- PART B2 (contender): another connection. Polls pg_locks (up to 30 s) until a different backend holds the
-- r3 session advisory lock for the test session, then:
--   control: installed studio_api version (r2, no session lock) -> expected to proceed (shows the race)
--   r3     : pg_temp r3 with lock_timeout 2 s -> expected 55P03 (blocked by B1's session lock)
-- holder_pid_seen=NONE means the two parts did not overlap and the run is inconclusive.
---------------------------------------------------------------------------------------------------------
do $b2$
declare v_sql text; c text := 'NOERR'; e text := 'NOERR'; t0 timestamptz; t1 timestamptz; seen_pid int; ii int;
  S uuid := current_setting('kphd.test_session')::uuid;
  k bigint := hashtextextended('claude-riley-handoff:session:' || current_setting('kphd.test_session'), 0);
  ok jsonb := '{"title":"TEST r5 contender","outcome_required":"x","acceptance_test":"x"}';
begin
  for ii in 1..60 loop
    select pid into seen_pid from pg_locks
     where locktype='advisory' and granted and objsubid=1 and pid <> pg_backend_pid()
       and classid = ((k >> 32) & 4294967295)::bigint::oid and objid = (k & 4294967295)::bigint::oid limit 1;
    exit when seen_pid is not null;
    perform pg_sleep(0.5);
  end loop;
  select metadata->>'candidate_sql' into v_sql from guard.controlled_change_sets
   where metadata->>'candidate_key' = 'staff-rollout-step2-r3' order by proposed_at desc limit 1;
  execute replace(v_sql, 'studio_api.handoff_to_riley_v1', 'pg_temp.handoff_to_riley_v1');
  perform set_config('lock_timeout', '2s', true);
  t0 := clock_timestamp();
  begin perform studio_api.handoff_to_riley_v1('model:anthropic:claude', S, 'r5-control', 'create', null, null, ok);
  exception when others then c := sqlstate; end;
  t1 := clock_timestamp();
  begin perform pg_temp.handoff_to_riley_v1('model:anthropic:claude', S, 'r5-contender', 'create', null, null, ok);
  exception when others then e := sqlstate; end;
  raise exception using errcode='P0001', message = format(
    'TESTRESULTS(rolled back) R5-B2 pid=%s holder_pid_seen=%s control_installed_r2=%s at=%s r3=%s at=%s end=%s',
    pg_backend_pid(), coalesce(seen_pid::text,'NONE'), c, t0, e, t1, clock_timestamp());
end
$b2$;
