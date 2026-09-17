-- ============================================================================
-- PROPOSAL ONLY — DO NOT APPLY WITHOUT A core.decision_execution_authorizations BINDING
-- AND KELLIE'S COMMIT TOKEN (PRO-0138 §4–§6). Ruling R2 = GOV-20260910-02 authorizes
-- proposing this Controlled Change Set, not executing it.
--
-- Migration: lab_transition_graph_v1
-- Purpose  : transition graph as data (STD | Spine + State Machine §3.2, §3.13, R2).
--            One row per allowed phase arrow per lab; a pure evaluator that reproduces
--            core.transition_spec_work_item_v1's decision order from those rows; and the
--            B5 effect-policy class that makes the human gate policy data.
-- Effect   : STRUCTURAL (core.classify_execution_effect_v1 dry run 2026-09-17).
-- Idempotent: create if not exists / create or replace / drop constraint if exists / guarded inserts.
-- Does NOT touch core.spec_work_items, core.spec_work_item_events, or transition_spec_work_item_v1.
-- Cutover of the live function to the table is a separate ruling (kept out of this CCS on purpose).
-- ============================================================================

create table if not exists core.lab_transitions (
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

comment on table core.lab_transitions is
  'Transition graph as data, one row per allowed phase arrow per lab (STD | Spine + State Machine, R2). entry_condition keys: terminal, terminal_statuses[], completion_status, completion_allowed, to_status_in[], requires_authorization_binding, effect_class. exit_evidence_schema keys: required, required_when_to_status_in[].';

create index if not exists lab_transitions_lookup_idx
  on core.lab_transitions (lab_key, from_phase, to_phase) where active;

-- ---------------------------------------------------------------------------
-- B5: worker-forbidden phases as an effect policy (guard.effect_policies).
-- The table is keyed by impact_class and CHECK-limited to six classes; adding
-- 'gated_transition' requires replacing that constraint. core.classify_execution_effect_v1
-- resolves the class by rule and only then reads the policy row by name, so the
-- added row cannot change how any existing operation classifies (verified 2026-09-17).
-- PRO-0138 §14: classification changes require Kellie ratification — that is the B5 packet.
-- ---------------------------------------------------------------------------
alter table guard.effect_policies drop constraint if exists effect_policies_class_chk;
alter table guard.effect_policies add constraint effect_policies_class_chk
  check (impact_class = any (array['routine','bounded','gated_transition','bulk','structural','destructive','catastrophic']::text[]));

insert into guard.effect_policies
  (impact_class, severity_rank, human_gate_required, commit_token_required, agent_execution_allowed,
   schema_change_allowed, physical_delete_allowed, max_rows, max_objects, executor_class, description)
select * from (values
  ('gated_transition', 25, true, false, false, false, false, 1, 1, 'controlled_executor',
   'Entry into a human-only lab spine phase (STD | Spine + State Machine, B5). Worker and system authority may never execute it, whatever the prompt says; the executor is a human transition carrying a bound authorization. Not a packet class: spine-only effect, one row, no commit token.')
) as v(impact_class, severity_rank, human_gate_required, commit_token_required, agent_execution_allowed,
       schema_change_allowed, physical_delete_allowed, max_rows, max_objects, executor_class, description)
where not exists (select 1 from guard.effect_policies ep where ep.impact_class = v.impact_class);

-- ---------------------------------------------------------------------------
-- Evaluator (read-only). SECURITY DEFINER because guard.effect_policies carries a
-- deny-all RLS marker and kphd_agent has no guard USAGE (PRO-0138 §12); the function
-- is the only read path, has a fixed search_path, schema-qualified references, and an
-- explicit EXECUTE ACL (PRO-0138 §9).
-- ---------------------------------------------------------------------------
create or replace function core.evaluate_lab_transition_v1(
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
security definer
set search_path to 'pg_catalog'
as $function$
-- Pure, read-only evaluator over the transition table. Reproduces the decision order of
-- core.transition_spec_work_item_v1 (input validation -> row state -> edge admission ->
-- terminal invariants -> authority/gate -> exit evidence). It never mutates anything;
-- the lab's transition function calls it and then performs the write + receipt.
declare
  v_rule core.lab_transitions%rowtype;
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
    from core.lab_transitions t
   where t.lab_key = p_lab_key and t.active
     and coalesce((t.entry_condition->>'terminal')::boolean,false);
  if v_terminal_phase_count <> 1 or v_status_set_count <> 1 then
    return jsonb_build_object('allowed',false,'reason_code','inconsistent_graph');
  end if;
  select array_agg(distinct s) into v_terminal_statuses
    from core.lab_transitions t
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
    from core.lab_transitions t
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
      from guard.effect_policies ep
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

revoke all on function core.evaluate_lab_transition_v1(text,text,text,text,text,text,jsonb,boolean,boolean) from public;
grant execute on function core.evaluate_lab_transition_v1(text,text,text,text,text,text,jsonb,boolean,boolean) to kphd_agent, kphd_sync;

-- ---------------------------------------------------------------------------
-- Grants and RLS (D7: no DELETE anywhere; pattern mirrors core.initiative_sessions)
-- ---------------------------------------------------------------------------
alter table core.lab_transitions enable row level security;
grant select on core.lab_transitions to kphd_agent;
grant select, insert, update on core.lab_transitions to kphd_sync;
drop policy if exists lab_transitions_agent_read on core.lab_transitions;
create policy lab_transitions_agent_read on core.lab_transitions for select to kphd_agent using (true);
drop policy if exists lab_transitions_sync_all on core.lab_transitions;
create policy lab_transitions_sync_all on core.lab_transitions for all to kphd_sync using (true) with check (true);
