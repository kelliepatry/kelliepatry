-- ============================================================================
-- PARITY TEST — lab_transition_graph_v1 (runs entirely on pg_temp objects; touches no canonical row,
-- creates nothing in core/guard; safe to execute on production as a read-only proof).
-- Oracle    : verbatim decision logic of core.transition_spec_work_item_v1 (see pg_temp.oracle_*).
-- Candidate : the proposed evaluator, byte-identical to the migration except schema names -> pg_temp.
-- Space     : every valid from-state of spec_work_items (phase/status consistent with
--             spec_work_items_terminal_state_check) x every to-phase x every to-status x 3 authority kinds
--             x evidence {} / non-empty x authorization bound / not x archived / not.
-- Pass      : 0 mismatches on (allowed, reason_code); every seeded rule admits >= 1 combination.
-- ============================================================================
create table if not exists pg_temp.lab_transitions (
  transition_id uuid primary key default gen_random_uuid(),
  lab_key text not null,
  from_phase text not null,
  to_phase text not null,
  allowed_authority_kinds text[] not null,
  entry_condition jsonb not null default '{}'::jsonb,
  exit_evidence_schema jsonb not null default '{}'::jsonb,
  is_human_gate boolean not null default false,
  active boolean not null default true,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lab_transitions_lab_key_check check (lab_key ~ '^[a-z][a-z0-9_]{2,63}$'),
  constraint lab_transitions_phase_check check (nullif(btrim(from_phase),'') is not null and nullif(btrim(to_phase),'') is not null),
  constraint lab_transitions_authority_check check (cardinality(allowed_authority_kinds) > 0 and allowed_authority_kinds <@ array['human','worker','system']::text[]),
  constraint lab_transitions_entry_condition_check check (jsonb_typeof(entry_condition) = 'object'),
  constraint lab_transitions_exit_evidence_check check (jsonb_typeof(exit_evidence_schema) = 'object'),
  constraint lab_transitions_gate_authority_check check ((not is_human_gate) or allowed_authority_kinds = array['human']::text[]),
  constraint lab_transitions_gate_not_self_loop_check check ((not is_human_gate) or from_phase <> to_phase),
  constraint lab_transitions_uniq unique (lab_key, from_phase, to_phase)
);

create temp table if not exists effect_policies (like guard.effect_policies including defaults);
insert into pg_temp.effect_policies select * from guard.effect_policies
  where not exists (select 1 from pg_temp.effect_policies);
insert into pg_temp.effect_policies
  (impact_class, severity_rank, human_gate_required, commit_token_required, agent_execution_allowed,
   schema_change_allowed, physical_delete_allowed, max_rows, max_objects, executor_class, description)
select * from (values ('gated_transition', 25, true, false, false, false, false, 1, 1, 'controlled_executor',
   'Entry into a human-only lab spine phase (STD | Spine + State Machine, B5). Worker and system authority may never execute it, whatever the prompt says; the executor is a human transition carrying a bound authorization. Not a packet class: spine-only effect, one row, no commit token.')) as v(a,b,c,d,e,f,g,h,i,j,k)
where not exists (select 1 from pg_temp.effect_policies where impact_class='gated_transition');

insert into pg_temp.lab_transitions (lab_key, from_phase, to_phase, allowed_authority_kinds, entry_condition, exit_evidence_schema, is_human_gate, notes)
select v.lab_key, v.from_phase, v.to_phase, v.allowed_authority_kinds, v.entry_condition, v.exit_evidence_schema, v.is_human_gate, v.notes
from (values
  ('specification_operations','intake','intake',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','evidence','evidence',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','reconciliation','reconciliation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','draft_revision','draft_revision',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','review_preparation','review_preparation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','change_preparation','change_preparation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','controlled_commit','controlled_commit',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','output_check','output_check',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'same-phase update: status/binding/receipt only (transition_spec_work_item_v1: p_to_phase = v_item.phase)'),
  ('specification_operations','intake','evidence',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (intake -> evidence)'),
  ('specification_operations','evidence','reconciliation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (evidence -> reconciliation)'),
  ('specification_operations','reconciliation','evidence',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (reconciliation -> evidence)'),
  ('specification_operations','reconciliation','draft_revision',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (reconciliation -> draft_revision)'),
  ('specification_operations','draft_revision','evidence',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (draft_revision -> evidence)'),
  ('specification_operations','draft_revision','reconciliation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (draft_revision -> reconciliation)'),
  ('specification_operations','draft_revision','review_preparation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (draft_revision -> review_preparation)'),
  ('specification_operations','review_preparation','evidence',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (review_preparation -> evidence)'),
  ('specification_operations','review_preparation','draft_revision',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (review_preparation -> draft_revision)'),
  ('specification_operations','review_preparation','change_preparation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (review_preparation -> change_preparation)'),
  ('specification_operations','change_preparation','review_preparation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (change_preparation -> review_preparation)'),
  ('specification_operations','output_check','review_preparation',array['human','worker','system']::text[],'{}'::jsonb,'{}'::jsonb,false,'mainline/back-edge per transition_spec_work_item_v1 (output_check -> review_preparation)'),
  ('specification_operations','review_preparation','controlled_commit',array['human']::text[],'{"effect_class":"gated_transition","requires_authorization_binding":true}'::jsonb,'{}'::jsonb,true,'HUMAN GATE: authority_kind must be human AND an authorization binding (approved approval or authorizing decision, same project) must exist'),
  ('specification_operations','change_preparation','controlled_commit',array['human']::text[],'{"effect_class":"gated_transition","requires_authorization_binding":true}'::jsonb,'{}'::jsonb,true,'HUMAN GATE: authority_kind must be human AND an authorization binding (approved approval or authorizing decision, same project) must exist'),
  ('specification_operations','controlled_commit','output_check',array['human','worker','system']::text[],'{}'::jsonb,'{"required":true}'::jsonb,false,'leaving controlled_commit requires commit evidence (evidence <> {})'),
  ('specification_operations','output_check','closed',array['human','worker','system']::text[],'{"completion_allowed":true,"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"]}'::jsonb,'{"required_when_to_status_in":["completed"]}'::jsonb,false,'terminal edge: completion only from output_check; completion requires output-check evidence; refuse/cancel also admitted here'),
  ('specification_operations','intake','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)'),
  ('specification_operations','evidence','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)'),
  ('specification_operations','reconciliation','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)'),
  ('specification_operations','draft_revision','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)'),
  ('specification_operations','review_preparation','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)'),
  ('specification_operations','change_preparation','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)'),
  ('specification_operations','controlled_commit','closed',array['human','worker','system']::text[],'{"completion_status":"completed","terminal":true,"terminal_statuses":["completed","refused","cancelled"],"to_status_in":["refused","cancelled"]}'::jsonb,'{}'::jsonb,false,'refusal/cancellation to closed from any non-terminal phase (edge admitted only for to_status refused|cancelled)')
) as v(lab_key, from_phase, to_phase, allowed_authority_kinds, entry_condition, exit_evidence_schema, is_human_gate, notes)
on conflict (lab_key, from_phase, to_phase) do nothing;

create or replace function pg_temp.evaluate_lab_transition_v1(
  p_lab_key text,
  p_from_phase text,
  p_from_status text,
  p_to_phase text,
  p_to_status text,
  p_authority_kind text default 'worker',
  p_evidence jsonb default '{}'::jsonb,
  p_authorization_bound boolean default false,
  p_archived boolean default false
) returns jsonb
language plpgsql
stable
security invoker
set search_path to 'pg_catalog'
as $function$
-- Pure, read-only evaluator over the transition table. Reproduces the decision order of
-- core.transition_spec_work_item_v1 (input validation -> row state -> edge admission ->
-- terminal invariants -> authority/gate -> exit evidence). It never mutates anything;
-- the lab's transition function calls it and then performs the write + receipt.
declare
  v_rule pg_temp.lab_transitions%rowtype;
  v_terminal_phase text;
  v_terminal_statuses text[];
  v_completion_status text;
  v_terminal_phase_count integer;
  v_status_set_count integer;
  v_policy_agent_allowed boolean;
  v_evidence_required boolean := false;
begin
  if nullif(btrim(coalesce(p_lab_key,'')),'') is null then
    return jsonb_build_object('allowed',false,'reason_code','lab_key_required');
  end if;
  if p_authority_kind not in ('human','worker','system') then
    return jsonb_build_object('allowed',false,'reason_code','invalid_authority_kind');
  end if;
  if p_evidence is null or jsonb_typeof(p_evidence) <> 'object' then
    return jsonb_build_object('allowed',false,'reason_code','invalid_evidence');
  end if;

  -- Lab terminal constants are data on the terminal rows; they must agree or the graph is unusable.
  select count(distinct t.to_phase), min(t.to_phase), count(distinct t.entry_condition->'terminal_statuses'),
         min(t.entry_condition->>'completion_status')
    into v_terminal_phase_count, v_terminal_phase, v_status_set_count, v_completion_status
    from pg_temp.lab_transitions t
   where t.lab_key = p_lab_key and t.active
     and coalesce((t.entry_condition->>'terminal')::boolean,false);
  if v_terminal_phase_count <> 1 or v_status_set_count <> 1 then
    return jsonb_build_object('allowed',false,'reason_code','inconsistent_graph');
  end if;
  select array_agg(distinct s) into v_terminal_statuses
    from pg_temp.lab_transitions t
         cross join lateral jsonb_array_elements_text(t.entry_condition->'terminal_statuses') s
   where t.lab_key = p_lab_key and t.active
     and coalesce((t.entry_condition->>'terminal')::boolean,false);

  -- Row state (mirrors: archived -> terminal)
  if coalesce(p_archived,false) then
    return jsonb_build_object('allowed',false,'reason_code','archived');
  end if;
  if p_from_status = any(v_terminal_statuses) then
    return jsonb_build_object('allowed',false,'reason_code','terminal_item');
  end if;

  -- Edge admission: the row must exist and, when it carries to_status_in, admit this to_status.
  select * into v_rule
    from pg_temp.lab_transitions t
   where t.lab_key = p_lab_key and t.active
     and t.from_phase = p_from_phase and t.to_phase = p_to_phase
     and (t.entry_condition->'to_status_in' is null or (t.entry_condition->'to_status_in') ? p_to_status)
   limit 1;
  if not found then
    return jsonb_build_object('allowed',false,'reason_code','invalid_phase_transition');
  end if;

  -- Terminal invariants
  if p_to_phase = v_terminal_phase and p_to_status = v_completion_status
     and not coalesce((v_rule.entry_condition->>'completion_allowed')::boolean,false) then
    return jsonb_build_object('allowed',false,'reason_code','completion_not_allowed_from_phase','rule_id',v_rule.transition_id);
  end if;
  if p_to_phase = v_terminal_phase and not (p_to_status = any(v_terminal_statuses)) then
    return jsonb_build_object('allowed',false,'reason_code','terminal_phase_requires_terminal_status','rule_id',v_rule.transition_id);
  end if;
  if p_to_phase <> v_terminal_phase and p_to_status = any(v_terminal_statuses) then
    return jsonb_build_object('allowed',false,'reason_code','terminal_status_requires_terminal_phase','rule_id',v_rule.transition_id);
  end if;

  -- Authority and human gate (gate is data in two places: the row and guard.effect_policies)
  if not (p_authority_kind = any(v_rule.allowed_authority_kinds)) then
    return jsonb_build_object('allowed',false,
      'reason_code', case when v_rule.is_human_gate then 'gate_requires_human' else 'authority_kind_not_allowed' end,
      'rule_id',v_rule.transition_id);
  end if;
  if v_rule.is_human_gate then
    select ep.agent_execution_allowed into v_policy_agent_allowed
      from pg_temp.effect_policies ep
     where ep.impact_class = coalesce(v_rule.entry_condition->>'effect_class','gated_transition');
    if v_policy_agent_allowed is distinct from false then
      -- fail closed: the gate's effect policy is missing or would let an agent execute it
      return jsonb_build_object('allowed',false,'reason_code','gate_policy_missing_or_open','rule_id',v_rule.transition_id);
    end if;
    if coalesce((v_rule.entry_condition->>'requires_authorization_binding')::boolean,false)
       and not coalesce(p_authorization_bound,false) then
      return jsonb_build_object('allowed',false,'reason_code','gate_requires_authorization','rule_id',v_rule.transition_id);
    end if;
  end if;

  -- Exit evidence
  v_evidence_required := coalesce((v_rule.exit_evidence_schema->>'required')::boolean,false)
                      or coalesce((v_rule.exit_evidence_schema->'required_when_to_status_in') ? p_to_status,false);
  if v_evidence_required and p_evidence = '{}'::jsonb then
    return jsonb_build_object('allowed',false,
      'reason_code', case when p_to_phase = v_terminal_phase then 'completion_evidence_required' else 'exit_evidence_required' end,
      'rule_id',v_rule.transition_id);
  end if;

  return jsonb_build_object('allowed',true,'reason_code','allowed','rule_id',v_rule.transition_id,'is_human_gate',v_rule.is_human_gate);
end
$function$;

create or replace function pg_temp.oracle_transition_spec_work_item_v1(
  p_from_phase text, p_from_status text, p_to_phase text, p_to_status text,
  p_authority_kind text, p_evidence jsonb, p_authorized boolean, p_archived boolean
) returns text language plpgsql as $f$
-- ORACLE: the decision logic of core.transition_spec_work_item_v1 (pg_get_functiondef, 2026-09-17),
-- with the row read replaced by parameters, the authorization EXISTS replaced by p_authorized,
-- and the UPDATE/INSERT removed. Every RAISE message is preserved verbatim.
declare
  v_item record;
  v_allowed boolean := false;
  v_authorized boolean := false;
begin
  if p_authority_kind not in ('human','worker','system') then
    raise exception 'Invalid authority kind %',p_authority_kind;
  end if;
  if p_evidence is null or jsonb_typeof(p_evidence)<>'object' then
    raise exception 'evidence must be a JSON object';
  end if;
  select p_from_phase as phase, p_from_status as status,
         case when p_archived then now() end as archived_at into v_item;
  if v_item.archived_at is not null then raise exception 'Work item % is archived','x'; end if;
  if v_item.status in ('completed','refused','cancelled') then
    raise exception 'Terminal work item % cannot transition; create a successor item','x';
  end if;

  if p_to_phase=v_item.phase then
    v_allowed := true;
  elsif p_to_phase='closed' and p_to_status in ('refused','cancelled') then
    v_allowed := true;
  elsif v_item.phase='intake' and p_to_phase='evidence' then
    v_allowed := true;
  elsif v_item.phase='evidence' and p_to_phase='reconciliation' then
    v_allowed := true;
  elsif v_item.phase='reconciliation' and p_to_phase in ('evidence','draft_revision') then
    v_allowed := true;
  elsif v_item.phase='draft_revision' and p_to_phase in ('evidence','reconciliation','review_preparation') then
    v_allowed := true;
  elsif v_item.phase='review_preparation' and p_to_phase in ('evidence','draft_revision','change_preparation','controlled_commit') then
    v_allowed := true;
  elsif v_item.phase='change_preparation' and p_to_phase in ('review_preparation','controlled_commit') then
    v_allowed := true;
  elsif v_item.phase='controlled_commit' and p_to_phase='output_check' then
    v_allowed := true;
  elsif v_item.phase='output_check' and p_to_phase in ('review_preparation','closed') then
    v_allowed := true;
  end if;

  if not v_allowed then
    raise exception 'Invalid phase transition % -> %',v_item.phase,p_to_phase;
  end if;

  if p_to_phase='closed' and p_to_status='completed' and v_item.phase<>'output_check' then
    raise exception 'Completion requires output_check as the current phase';
  end if;
  if p_to_phase='closed' and p_to_status not in ('completed','refused','cancelled') then
    raise exception 'Closed phase requires a terminal status';
  end if;
  if p_to_phase<>'closed' and p_to_status in ('completed','refused','cancelled') then
    raise exception 'Terminal status requires the closed phase';
  end if;

  if p_to_phase='controlled_commit' and v_item.phase<>'controlled_commit' then
    if p_authority_kind<>'human' then
      raise exception 'Only a durable human authorization may enter controlled_commit';
    end if;
    v_authorized := p_authorized;
    if not v_authorized then
      raise exception 'controlled_commit requires a bound approved approval or authorizing decision';
    end if;
  end if;

  if v_item.phase='controlled_commit' and p_to_phase='output_check' and p_evidence='{}'::jsonb then
    raise exception 'Leaving controlled_commit requires commit evidence';
  end if;
  if p_to_phase='closed' and p_to_status='completed' and p_evidence='{}'::jsonb then
    raise exception 'Completion requires output-check evidence';
  end if;
  return 'allowed';
exception when others then
  return case
    when sqlerrm like 'Invalid authority kind%' then 'invalid_authority_kind'
    when sqlerrm like 'evidence must be a JSON object%' then 'invalid_evidence'
    when sqlerrm like 'Work item % is archived' then 'archived'
    when sqlerrm like 'Terminal work item%' then 'terminal_item'
    when sqlerrm like 'Invalid phase transition%' then 'invalid_phase_transition'
    when sqlerrm = 'Completion requires output_check as the current phase' then 'completion_not_allowed_from_phase'
    when sqlerrm = 'Closed phase requires a terminal status' then 'terminal_phase_requires_terminal_status'
    when sqlerrm = 'Terminal status requires the closed phase' then 'terminal_status_requires_terminal_phase'
    when sqlerrm = 'Only a durable human authorization may enter controlled_commit' then 'gate_requires_human'
    when sqlerrm = 'controlled_commit requires a bound approved approval or authorizing decision' then 'gate_requires_authorization'
    when sqlerrm = 'Leaving controlled_commit requires commit evidence' then 'exit_evidence_required'
    when sqlerrm = 'Completion requires output-check evidence' then 'completion_evidence_required'
    else 'UNMAPPED: ' || sqlerrm end;
end
$f$;

create temp table if not exists parity_results as
with phases as (select unnest(array['intake','evidence','reconciliation','draft_revision','review_preparation','change_preparation','controlled_commit','output_check','closed']) as p),
     statuses as (select unnest(array['open','queued','running','waiting_human','waiting_evidence','blocked','completed','refused','cancelled']) as s),
     from_states as (
       select fp.p as from_phase, fs.s as from_status
       from phases fp cross join statuses fs
       where (fp.p = 'closed') = (fs.s in ('completed','refused','cancelled'))   -- spec_work_items_terminal_state_check
     ),
     dims as (
       select f.from_phase, f.from_status, tp.p as to_phase, ts.s as to_status, ak.a as authority_kind, ev.e as evidence, au.b as authorized, ar.b as archived
       from from_states f
       cross join phases tp cross join statuses ts
       cross join (select unnest(array['human','worker','system']) as a) ak
       cross join (select unnest(array['{}'::jsonb, '{"commit_receipt":"x"}'::jsonb]) as e) ev
       cross join (select unnest(array[false,true]) as b) au
       cross join (select unnest(array[false,true]) as b) ar
     )
select d.*,
       pg_temp.oracle_transition_spec_work_item_v1(d.from_phase,d.from_status,d.to_phase,d.to_status,d.authority_kind,d.evidence,d.authorized,d.archived) as oracle_code,
       pg_temp.evaluate_lab_transition_v1('specification_operations',d.from_phase,d.from_status,d.to_phase,d.to_status,d.authority_kind,d.evidence,d.authorized,d.archived) as candidate
from dims d;

select 'combinations' as metric, count(*)::text as value from parity_results
union all select 'mismatches', count(*)::text from parity_results where oracle_code <> (candidate->>'reason_code') or (oracle_code='allowed') <> (candidate->>'allowed')::boolean
union all select 'allowed_both', count(*)::text from parity_results where oracle_code='allowed' and (candidate->>'allowed')::boolean
union all select 'seeded_rules', count(*)::text from pg_temp.lab_transitions
union all select 'rules_admitting_at_least_one', count(distinct candidate->>'rule_id')::text from parity_results where (candidate->>'allowed')::boolean
union all select 'rules_never_admitting', string_agg(t.from_phase||'->'||t.to_phase, ', ') from pg_temp.lab_transitions t where not exists (select 1 from parity_results r where (r.candidate->>'allowed')::boolean and (r.candidate->>'rule_id')::uuid = t.transition_id)
union all select 'reason:'||oracle_code, count(*)::text from parity_results group by oracle_code
union all select 'unmapped_oracle_messages', count(*)::text from parity_results where oracle_code like 'UNMAPPED%'
union all select 'candidate_rule_ids_are_seeded', bool_and((candidate->>'rule_id') is null or (candidate->>'rule_id')::uuid in (select transition_id from pg_temp.lab_transitions))::text from parity_results
order by 1;
