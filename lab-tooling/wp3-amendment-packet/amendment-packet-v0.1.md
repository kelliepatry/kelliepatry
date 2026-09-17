# Amendment packet v0.1 — PRO-0140 (A1, A4, A6) · PRO-0138 (B1, B3, B5)

**Status: PROPOSAL ONLY. No ratified page has been edited.** Each item below requires separate Kellie ratification (PRO-0138 §14; PRO-0140 §14). Accepted for drafting by ruling R5 (GOV-20260910-05). Held until the transition table exists (R2 CCS executed): A2, A3, A5, B2, B4.

Sources (Confirmed, live pulls 2026-09-17): PRO-0140 page `3cd732ea-2011-8151-8c64-d5f4f627218c` (Published, ratified 2026-08-31); PRO-0138 page `3ca732ea-2011-81a5-a2ed-cffd56b1508f` (Published, V1.0 ratified 2026-08-28); STD | Spine + State Machine Work Pattern v0.1 `3d7732ea-2011-8190-b368-f4f26607be68` (Draft, R1–R5 ruled, §6 corrected 2026-09-17); GPT packet-prep comments on the STD page dated 2026-09-10 (comment ids `3d7732ea-2011-8151-9ff9-001d2a32add2` for A-items, `3d7732ea-2011-81d2-951d-001d6f4e6294` for B-items). Proposed wording follows GPT's draft where given and is marked where extended.

Prepared by Claude Code, session `e535acdb-1df2-4e33-b5bf-99a67829db00`, work `9b82ac79-58a0-4ba3-ad23-0cc82376077e`. Branch `claude/std-lab-tooling-vas4i6`.

---

## A1 · PRO-0140 §1 — definition of *worker*

**Section.** §1 · Architecture rule — responsibility before identity, item 6.

**Current wording (verbatim).**
> 6. No new queue, cron, database, or runtime worker is created merely because an internship has been named.

**Proposed wording.** Keep item 6 unchanged and add item 6a immediately after it:
> 6a. *Worker* means a bounded transition role against one spine row; it is not a persona, runtime agent, inbox, or standing employee identity. Creating or naming a lab, internship, or responsibility does not create a new runtime worker object. Where this protocol says "runtime worker" it means a standing process or persona, never a transition role.

**Rationale.** STD §1 defines a worker as "a role on a transition, not an identity; it needs no persona, inbox, or agent registration to exist," and STD §3.15 forbids creating a queue, cron, database, or persona because a lab has been named. Without 6a, item 6's phrase "runtime worker" reads as a prohibition on the word the standard depends on. GPT wording adopted; last sentence added to close the ambiguity in both directions.

---

## A4 · PRO-0140 §7 — machine-readable work receipt

**Section.** §7 · Work receipt.

**Current wording (verbatim).**
> Every internship execution ends in an evidence-bearing receipt:
> 1. Responsibility. 2. Business result expected. 3. Work performed. 4. Source evidence. 5. Output produced. 6. Exceptions / uncertainty. 7. Authority used and authority still required. 8. Acceptance evidence for reviewer. 9. Next owner. 10. Status: Ready for Review | Blocked | Escalated | No Action.
> "Complete" may be used only when completion has an externally defined acceptance condition and that condition is met.

**Proposed wording.** Keep the ten items and the "Complete" sentence. Append:
> **Machine form.** For work carried on a lab spine (STD | Spine + State Machine), the receipt is satisfied by the spine row, its transition event, and its run binding taken together; no parallel prose receipt is required. Field mapping:
>
> | §7 item | Machine field |
> |---|---|
> | 1 Responsibility | spine row identity (`work_item_key` / `lab_key`) + the transition rule applied |
> | 2 Business result expected | spine `objective` |
> | 3 Work performed | event `from_phase → to_phase`, `from_status → to_status`, `reason` |
> | 4 Source evidence | event `evidence` (JSON object bound to canonical identities) |
> | 5 Output produced | run binding `output_hash` (input side: `input_hash`) |
> | 6 Exceptions / uncertainty | `to_status` ∈ waiting_human · waiting_evidence · blocked, with `reason` |
> | 7 Authority used / still required | event `authority_kind`; the next rule's `allowed_authority_kinds` and `is_human_gate` |
> | 8 Acceptance evidence | `evidence` satisfying the rule's `exit_evidence_schema` |
> | 9 Next owner | next rule's `allowed_authority_kinds`; spine `assigned_to` |
> | 10 Status | spine `phase` + `status` (never one field) |
>
> Correlation/idempotency key: spine `idempotency_key`. State version: event `state_version`. A receipt missing any mapped field is incomplete, not "Complete".

**Rationale.** STD §1 (Receipt) and §3.5 ("no transition without a receipt; no receipt without evidence"). GPT correction 3 (2026-09-10) established that in Instance 01 the receipt fields are split across `core.spec_work_item_events`, the spine row, and `core.spec_worker_run_bindings`; the mapping above reflects that split rather than pretending one event row carries everything. GPT wording adopted; table added so reviewers can inspect the mapping without reading the schema.

---

## A6 · PRO-0140 §12 — spine reference pattern

**Section.** §12 · Infrastructure placement.

**Current wording (verbatim).**
> Do not create six new databases or separate work queues. Before implementation, map the internship fields onto existing Studio Home structures for:
> - agent/capability registry and manifest bindings;
> - `runtime.work_queue` / execution packets;
> - authorization / decision receipts;
> - `runtime.work_events` and evidence;
> - telemetry / performance measures;
> - governance records and Notion review surfaces.
> Only a proven structural gap may justify new schema.

**Proposed wording.** Insert a bullet after the `runtime.work_queue` bullet:
> - lab spine rows and their transition graph — reference pattern `core.spec_work_items` with `core.spec_work_item_events` (STD | Spine + State Machine, Instance 01); an internship or worker binds to one spine row and one named transition, not to a generic surface. Once the R2 change set is executed, allowed transitions are rows in `core.lab_transitions`.

**Rationale.** STD §2 (canonical pattern), §3.8 (exact-target binding), §6 (Instance 01 as the accepted reference), R1 (spine = domain grain; `runtime.work_queue` = execution grain). §12 currently lists the packet grain but not the domain grain, so an internship charter has no named place to bind its "one recurring job" to a unit of work. GPT wording adopted; the `core.lab_transitions` clause added and conditioned on R2 execution.

---

## B1 · PRO-0138 §1 — the gated spine phase *is* the human gate

**Section.** §1 · Governing execution sequence.

**Current wording (verbatim).**
> **Observe → prepare → classify effect → bind exact target → human gate when required → issue one-time authorization → execute through the permitted executor → verify readback → record evidence.**
> An LLM never receives authority merely because it was asked to complete a task. Execution authority must resolve from the system of record at execution time.

**Proposed wording.** Keep both paragraphs. Append:
> For work carried on a lab spine (STD | Spine + State Machine), entry into a gated spine phase is the human gate. The sequence is satisfied by the lab's transition table when the gated transition requires human authority and bound authorization evidence, and the transition function enforces it. A worker cannot enter a gated phase regardless of prompt, claim, or apparent approval in conversation.

**Rationale.** STD §3.13 ("human gates are explicit, few, and enforced in the transition function") and the corrected §6 Human-gate row (entry to `controlled_commit` requires `authority_kind = human` **and** a bound approved approval or authorizing decision). Binds the prose sequence to phase data so the gate is auditable as rows rather than as narrative. GPT wording adopted; "or apparent approval in conversation" added to align with §5's rule that a conversational "yes" is not authorization.

---

## B3 · PRO-0138 (new) — protocol-level idempotency

**Section.** New §4a, placed between §4 · Controlled Change Set and §5 · Step-up execution authorization (no existing text is altered).

**Current wording.** None. Idempotency exists today only at the object level: `runtime.work_queue.idempotency_key` and `core.spec_work_items.idempotency_key` (Confirmed); `guard.controlled_change_sets.change_set_hash` serves the same purpose for change sets.

**Proposed wording.**
> ## §4a · Idempotency
> Every Routine or Bounded effect carries a stable idempotency/correlation key supplied by the proposer and recorded on the receipt. Identical replay (same key, same canonical payload) returns the original receipt and performs no new effect. Conflicting replay (same key, different payload) fails closed. Keys are scoped to the exact target (for spine work: project + spine row). Controlled Change Sets satisfy this rule through `change_set_hash`.

**Rationale.** STD §3.7 ("identical replay returns the original receipt, conflicting replay is rejected"). AGT-0199 implements this per object; elevating it to protocol level makes it a requirement for every future lab and packet family rather than a per-build choice. GPT wording adopted; scoping sentence and the change-set clause added so the rule has one home for all three existing key types.

---

## B5 · PRO-0138 §2 — worker-forbidden phases as effect policy data

**Section.** §2 · Effect classes (table) and §11 · Supabase implementation (live control objects).

**Current wording (verbatim, §2 table rows).**
> Routine · Bounded · Bulk · Structural · Destructive · Catastrophic (six classes; "Impact is determined by the database/control layer, not by the model's self-description of risk.")

**Proposed wording.** Add one row to the §2 table between Bounded and Bulk:
> | Gated transition | Entry into a human-only lab spine phase (one row, spine-only effect) | Never — worker/system authority is refused by the transition function | Required: human authority **and** bound authorization evidence; no commit token |

Append to §2 after the table:
> Gated transitions are not a packet class. They exist so that a worker-forbidden phase is policy data (`guard.effect_policies`, class `gated_transition`, `agent_execution_allowed = false`) and graph data (`core.lab_transitions.is_human_gate`), never prose. A worker may not enter such a phase even if a prompt says proceed.

Add to the §11 live-object list once the R2 change set is executed: `guard.effect_policies` row `gated_transition`; `core.lab_transitions`; `core.evaluate_lab_transition_v1()`.

**Rationale.** STD §3.13 and R2 (GOV-20260910-02: the graph becomes data). Today the gate is enforced only inside `core.transition_spec_work_item_v1`; expressing it as an effect policy makes the same rule readable by every lab's evaluator and by audits. Mechanically this requires replacing the six-value CHECK on `guard.effect_policies.impact_class` — a classification change under §14, hence this packet. `core.classify_execution_effect_v1` resolves a class by rule and only then reads the policy row by name, so the added row cannot change how any existing operation classifies (verified 2026-09-17). Proposed row values: severity_rank 25, human_gate_required true, commit_token_required false, agent_execution_allowed false, schema_change_allowed false, physical_delete_allowed false, max_rows 1, max_objects 1, executor_class `controlled_executor`. Migration: `lab-tooling/wp2-transition-graph/migrations/20260917044900_lab_transition_graph_v1.sql`.

---

## Held (R5) — not drafted

A2 (§3 charter item 3 → name spine table + exact transition rows), A3 (§5 I2 → named rows in the transition table), A5 (§9 checkpoints fire on spine boundaries), B2 (§2 classify spine-only transitions as Routine, external-effect transitions by their packets), B4 (§13 v3 packet-claim dependency for multi-lab work). Each depends on `core.lab_transitions` existing; drafting resumes after the R2 CCS is executed.

## Ratification

One execution-queue row filed: "Ratify amendment packet v0.1". Recommendation: ratify A1, A6, B1, B3 as written; ratify A4 and B5 with the CCS (they describe objects the CCS creates). Nothing in this file edits a ratified page.
