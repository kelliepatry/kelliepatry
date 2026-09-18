# WP-2 · Controlled Change Set — transition graph as data (R2)

> **Update 2026-09-18 — EXECUTED (by Codex, not by this change set).** Under GOV-20260917-04 Kellie authorized Codex to deploy an input-hardened version of this package as Controlled Change Set `d3b6d26b-0c3b-41b9-8ee2-5ae06acd11ab` (status applied, migration `20260917145546_lab_transition_graph_v1_input_hardened`, committed 2026-09-17 14:55 UTC). Live: `core.lab_transitions` with the same 31 rows, `core.evaluate_lab_transition_v1` with two added guards (`phase_and_status_required` for blank phase/status inputs; null `authority_kind` rejected), `guard.effect_policies` class `gated_transition`, grants and RLS as specified below. Codex's PR #1 (`codex/lab-transition-input-guards`) was merged into this branch. The change set `c9d7dec9…` described below was never authorized and is superseded; it lapsed at 2026-09-18 04:57 UTC. Independent re-run of the parity test against the **live** evaluator on 2026-09-18 03:42 UTC: 99,144 combinations, 0 mismatches, all 31 rules admitting. Instance 01 (`core.spec_work_items`, `transition_spec_work_item_v1`) unchanged.

**Original status at proposal (2026-09-17): PROPOSED, NOT APPLIED.** Ruling R2 (GOV-20260910-02) authorizes proposing this Controlled Change Set only. Execution requires a `core.decision_execution_authorizations` binding (action `controlled_change.execute`, target `controlled_change_set`, the id below) and a one-time commit token from Kellie (PRO-0138 §4–§6). Nothing in this package has been run against `core` or `guard`; the parity test ran on `pg_temp` objects only.

| Item | Value (Confirmed 2026-09-17) |
|---|---|
| Change set id | `c9d7dec9-4dc8-4d63-8539-2a571f12218d` (`guard.controlled_change_sets`) |
| Change set hash | `6ff00ba8363ee56848594435e07381eaf986f9ce6fd7efc5d9ee5cadd4641b01` |
| Impact class | structural (rank 40; human gate + commit token; executor `controlled_executor`) |
| Expected state hash | `core.database_structure_hash_v1()` at proposal time (pinned in the row). Any structural change before execution invalidates the set; re-propose from these files. |
| Expiry | 1440 min from proposal (function maximum). A lapsed proposal is re-proposed from the same files; the hashes below are the identity of the change. |
| Proposed by | `model:anthropic:claude`, session `e535acdb-1df2-4e33-b5bf-99a67829db00`, work `9b82ac79-58a0-4ba3-ad23-0cc82376077e` |
| Gate that opened this WP | loop e4e520db closed 2026-09-17 on Kellie's confirmation of GPT's 2026-09-10 review |

## Files

| File | SHA-256 | What it is |
|---|---|---|
| `migrations/20260917044900_lab_transition_graph_v1.sql` | `4df18511ebde70130c754bbdf3b709c1915f92f9e4392852f3e638120be62516` | Idempotent DDL: `core.lab_transitions`, lookup index, `core.evaluate_lab_transition_v1()` (read-only, SECURITY DEFINER with fixed search_path and explicit EXECUTE ACL), `guard.effect_policies` CHECK extended with `gated_transition` + that row (B5), grants and RLS policies. No DELETE grant anywhere. |
| `seed/lab_transitions_specification_operations.sql` | `69b69aec9ca7c4d0d31c2918bf3a5fd797b5a38612dafaa825206b2929734d32` | 31 rows for lab `specification_operations`, transcribed 1:1 from `core.transition_spec_work_item_v1`; upsert on `(lab_key, from_phase, to_phase)`. |
| `test/parity_test.sql` | `cc495a86c111a6c82de44cdf8ad2612e6915cc08bfdca3bd6a3d0c3dbb8d0488` | Self-contained parity proof on `pg_temp`: oracle = verbatim decision logic of the live function; candidate = the proposed evaluator over the seeded rows. |

Apply order when authorized: migration, then seed, both via `apply_migration` (never `execute_sql`), then re-run the parity test against `core` by swapping `pg_temp` for `core`/`guard` in the candidate.

## Table shape (brief §WP-2 columns, plus identity and audit fields)

`lab_key · from_phase · to_phase · allowed_authority_kinds[] · entry_condition (jsonb) · exit_evidence_schema (jsonb) · is_human_gate · active` + `transition_id`, `notes`, `created_at`, `updated_at`. Unique on `(lab_key, from_phase, to_phase)`. CHECKs: authority kinds ⊆ {human, worker, system}; a gate row allows only `human` and is never a self-loop.

`entry_condition` keys: `terminal` (marks the lab's terminal phase), `terminal_statuses[]`, `completion_status`, `completion_allowed`, `to_status_in[]` (edge admission), `requires_authorization_binding`, `effect_class`. `exit_evidence_schema` keys: `required`, `required_when_to_status_in[]`. Everything the live function hard-codes as constants (terminal phase, terminal statuses, completion status) is data on the terminal rows; the evaluator refuses an inconsistent graph.

## Seeded graph (lab `specification_operations`, 31 rows)

- 8 same-phase rows (status/binding/receipt updates), one per non-terminal phase.
- 12 mainline and back-edges: intake→evidence; evidence→reconciliation; reconciliation→evidence|draft_revision; draft_revision→evidence|reconciliation|review_preparation; review_preparation→evidence|draft_revision|change_preparation; change_preparation→review_preparation; output_check→review_preparation.
- 2 human-gate entries into controlled_commit (from review_preparation and change_preparation): `allowed_authority_kinds = {human}`, `requires_authorization_binding`, `effect_class = gated_transition`.
- 1 commit exit controlled_commit→output_check with `exit_evidence_schema.required = true`.
- 1 terminal edge output_check→closed: `completion_allowed`, evidence required when `to_status = completed`.
- 7 refuse/cancel edges P→closed for the other non-terminal phases, admitted only for `to_status ∈ {refused, cancelled}`.

## Parity test result (run live 2026-09-17, temp objects only)

| Metric | Value |
|---|---|
| Combinations evaluated | 99,144 (51 valid from-states × 9 to-phases × 9 to-statuses × 3 authority kinds × evidence ∅/non-empty × authorization bound/not × archived/not) |
| Mismatches (allowed or reason code) | **0** |
| Allowed by both | 10,188 |
| Seeded rules | 31; rules admitting ≥ 1 combination: 31; rules never admitting: none |
| Unmapped oracle messages | 0 |
| Rejections by reason | archived 49,572 · invalid_phase_transition 30,096 · terminal_status_requires_terminal_phase 4,968 · terminal_item 2,916 · gate_requires_human 576 · terminal_phase_requires_terminal_status 432 · exit_evidence_required 216 · gate_requires_authorization 144 · completion_evidence_required 36 |

Finding surfaced by the test: the live function's branch "Completion requires output_check as the current phase" is unreachable (edge admission already blocks `completed` from every phase but output_check). The table reproduces that behavior exactly; the branch is kept in the evaluator as `completion_not_allowed_from_phase` so a future lab that admits completion from several phases still fails closed.

## B5 effect policy (also in the migration)

`guard.effect_policies` is keyed by `impact_class` and CHECK-limited to six classes, so the worker-forbidden-phase policy cannot be a row without replacing that constraint. The migration replaces `effect_policies_class_chk` to add `gated_transition` (rank 25: human gate required, no commit token, agent execution not allowed, one row, executor `controlled_executor`). `core.classify_execution_effect_v1` resolves a class by rule and only then reads the policy row by name, so the added class cannot change how any existing operation classifies (verified against its definition). The evaluator fails closed if the gate's policy row is missing or would allow agent execution. Ratification of the classification change is amendment B5 (WP-3 packet).

## Out of scope, on purpose

- No change to `core.spec_work_items`, `core.spec_work_item_events`, or `core.transition_spec_work_item_v1`. Cutting the live function over to `core.evaluate_lab_transition_v1` is a separate ruling; this CCS makes the cutover a one-line change with a parity test already in hand.
- No lab registry table, no queue, no cron, no persona (brief §4, STD §3.15). `lab_key` is a text key validated by CHECK.
- Instance 02 rows are not seeded (WP-5 fills STD §7 only).

## Filing

- CCS record: `guard.controlled_change_sets` `c9d7dec9-4dc8-4d63-8539-2a571f12218d` (event `proposed` in `guard.controlled_change_events`).
- Execution-queue row: "Authorize CCS lab_transition_graph_v1" (Kellie: authorization binding + commit token).
- Checkpoint: see PLAN | SPINE + STATE MACHINE LAB TOOLING v0.1 §7 and `memory.checkpoints` on session `e535acdb`.
