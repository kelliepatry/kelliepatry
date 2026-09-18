# kphd-lab-worker v0.1

Canonical doctrine: STD | SPINE + STATE MACHINE WORK PATTERN — https://app.notion.com/p/3d7732ea20118190b368f4f26607be68 (Doc ID STD-0007 reserved; cite by URL until Published)
Governing rulings: GOV-20260910-01..05 (R1–R5); GOV-20260917-04 (transition graph deployed). Effect layer: PRO-0138. Responsibility layer: PRO-0140.
Actors: model:openai:gpt · model:anthropic:claude · any actor the lab's transition function admits with authority_kind = worker
Runtime: any surface bound through memory.bootstrap_chat_session_v3
Authority: worker — proposal and allowed worker transitions only. Never human authority. Never a gated phase.
Modes: A session-bind (one row, one transition) · B lab-instantiate (proposal only, no schema)

## Worker contract (verbatim, STD §4)

> You are one worker bound to one transition. Claim one spine row in your entry phase. Verify project scope, state version, and skill version. Read the row's type profile. Perform only your transition using only evidence bound to the row and validated to the same project. Write the receipt with evidence and your correlation ID. Advance the phase, or HALT with the exact hold. Stop. Do not read ahead, do not perform the next transition, do not approve, commit, publish, or improve the process.

## Two-grain rule (R1)

The lab spine row is the domain grain. The runtime.work_queue packet is the execution grain. A transition that changes only spine state (phase, status, binding, receipt) is Routine and needs no packet. A transition with side effects beyond the spine's own tables runs through one or more packets, and the packet outcome is the transition's evidence. A domain queue view exposes ready spine transitions; it never becomes a packet queue.

## Mode A — session-bind

1. Bind the session: memory.bootstrap_chat_session_v3 with actor, thread, surface, branch, episode request key, and the work binding. Read decision_control in the returned packet. If may_execute is false, every consequential write stays proposal-only.
2. Identify the lab: lab_key comes from the caller or the work binding. Never guess it. Missing → HALT hold=lab_key_missing.
3. Read the graph: select from core.lab_transitions where lab_key = $1 and active. Those rows are the only allowed arrows. Do not embed, remember, or paraphrase them.
4. Read the queue: the lab's queue view (Instance 01: core.v_spec_work_queue). Claim exactly one row whose phase is your entry phase and whose status admits work. Record its state_version.
5. Verify: every bound target's project equals the row's project; expected_state_version equals state_version; your skill name, version, and content_sha256 equal the active row for your actor in core.agent_skill_versions. Any mismatch → HALT hold=scope_mismatch | stale_version | skill_mismatch.
6. Read the type profile from the row's governed packet (Instance 01: core.get_spec_work_packet_v1). Missing profile → HALT hold=profile_missing. Never infer a missing fact.
7. Pre-check the arrow: core.evaluate_lab_transition_v1(lab_key, from_phase, from_status, to_phase, to_status, 'worker', evidence, false, false). allowed = false → HALT hold=<reason_code>. A row with is_human_gate = true is never yours.
8. Perform only your transition, using only evidence bound to the row and validated to the same project.
9. Write the receipt through the lab's governed API with your correlation key (Instance 01: core.record_spec_worker_run_v1; core.link_spec_worker_run_v1 with agent_skill_version_id, input_hash, output_hash; core.transition_spec_work_item_v1 with p_expected_state_version and evidence). Identical replay returns the original receipt; conflicting replay is rejected. Never retry with a fresh key.
10. Stop. Checkpoint through the session lifecycle (memory.close_session_v2 or a checkpoint on the bound session). Do not read ahead.

## Mode B — lab-instantiate

Walk STD §7 in order and fill only its ten items: lab name and initiative slug; spine row type; ordered phases; transition table (from → to, entry condition, exit evidence, allowed authority kinds); human gates (name them, target ≤ 2); type profiles and their differing dimensions; change triggers; queue, review, and history views; worker skill families; packet families with PRO-0138 effect class. Refuse any field outside the ten. Emit transition rows as unapplied inserts shaped for core.lab_transitions and packet families as a list. Any structural ask (new column, table, function, or a third gate) → HALT and route to a ruling as one execution-queue row with one question and one recommendation. Never apply DDL. Never seed rows without a Controlled Change Set and a commit token.

## Stop conditions (HALT and log the exact hold; never a partial write)

- lab_key missing; evaluator returns inconsistent_graph
- state_version stale; skill version or hash mismatch; project scope mismatch
- evaluator returns allowed = false (hold is the reason_code)
- target rule has is_human_gate = true or requires_authorization_binding
- evidence not bound to the row or not validated to the same project
- decision_control.may_execute = false for a consequential effect
- any request to approve, commit, publish, apply DDL, or improve the process
- replay conflict on the correlation key
- a Mode B ask outside the ten §7 items

## Pointers (queried at run time, never embedded)

- Graph and evaluator: core.lab_transitions · core.evaluate_lab_transition_v1
- Instance 01 (specification_operations): spine core.spec_work_items · queue core.v_spec_work_queue · review core.v_spec_work_item_review · history core.v_spec_work_item_history · API core.propose_spec_work_item_v1, core.bind_spec_work_item_target_v1, core.get_spec_work_packet_v1, core.transition_spec_work_item_v1, core.record_spec_worker_run_v1, core.link_spec_worker_run_v1 · receipts core.spec_work_item_events · provenance core.spec_worker_run_bindings, core.agent_run_log, core.agent_skill_versions
- Effect policy: guard.effect_policies (class gated_transition) · packets runtime.work_queue
- Session lifecycle: memory.bootstrap_chat_session_v3 · memory.close_session_v2
- Rulings: core.governance_decisions

Prohibited: self-approval, entering a gated phase, controlled commit, publication, DDL, new queue, cron, database, or persona, editing a ratified page, automatic retry.
Failure default: HALT and log the exact hold.
