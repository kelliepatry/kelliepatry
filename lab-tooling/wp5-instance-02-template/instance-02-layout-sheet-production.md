# Instance 02 · LayOut sheet production — STD §7 template fill (for ruling)

**Status: PROPOSAL FOR RULING. No schema, no rows, no function. Fills STD §7's ten items and nothing else.**
Prepared 2026-09-18 by Claude Code, session `d57d2e0d-ba91-4cf3-98d6-30204610f1e0`, work `9b82ac79-58a0-4ba3-ad23-0cc82376077e`. Governing pattern: STD | SPINE + STATE MACHINE WORK PATTERN (`3d7732ea-2011-8190-b368-f4f26607be68`), rulings R1–R5, R3 (shared receipts backbone, phased).

Sources (Confirmed, live 2026-09-18 unless marked): WORKSPACE | SketchUp + LayOut Integration Lab (`3c7732ea-2011-810d-891f-e50965cd0b73`) sections "STD evaluation — SketchUp and LayOut as separate interacting workflows" (2026-09-10), "Initialization complete — Workflow B — LayOut", and "PHASE 2 · B | PH2-LO-001 — LayOut workflow" (2026-09-10); PRE-PROTOCOL | LAYOUT TEMPLATE PIPELINE (PRO-0053, Draft); runtime activation card `layout-drawing-set-operator v0.1-runtime-1` (SHA-256 `cd8c4345…`); `design` schema as deployed (tables `layout_manifests`, `layout_manifest_recipe_bindings`, `layout_sheet_recipes`, `layout_recipe_zones`, `capability_runs`, `capability_runtime_evidence`, `layout_manifest_output_bindings`, `layout_manifest_release_bindings`; views `v_layout_manifest_readiness`, `v_layout_manifest_traceability`, `v_layout_manifest_release_readiness`, `v_layout_recipe_readiness`).

The lab has already ruled (2026-09-10) that SketchUp and LayOut are two spines joined by a typed handoff, not one workflow. This template fills the **LayOut** spine only. The SketchUp spine (`sketchup_model_revision_work`) and the handoff contract `SU-LO-HANDOFF-v0.1` are out of scope here and are referenced, not redefined.

---

## 1 · Lab name / initiative slug

- `lab_key`: **`layout_sheet_production`**
- Initiative: `master-workflow-canonicalization` (subordinate lab, same PRO-0143 register entry as this project; no new initiative under the six-program cap).
- Research home (existing): `research.studies.study_key = layout-ai-capability-study`.
- Workflow identity in the lab record: `layout`.

## 2 · Spine row type — existing table, or the gap it proves

**Candidate named by the lab and the brief:** `layout_sheet_revision_work`, sheet-revision grain. No such table exists (Confirmed).

**Nearest existing table:** `design.layout_manifests` — one row per drawing manifest (a bounded sheet set for one project, phase_code, package_type, issue_type), FK to `core.sketchup_models` via `source_model_id`, `status` ∈ draft · resolved · blocked · ready · executed · verified · superseded, `release_required`, joined to `design.capability_runs` by `run_id`. Sheets inside a manifest are `design.layout_manifest_recipe_bindings` rows (`sheet_id` text, recipe, required, sequence). Live: 2 synthetic manifests (one verified, one superseded), 0 recipe bindings, 9 recipes all `geometry_status = unresolved`.

**Gap this proves (STD §3.3, §3.6, §3.9, §3.12):**
- `layout_manifests.status` mixes phase and status in one field (draft/ready/executed/verified are phases; blocked is a status; superseded is a terminal marker). STD rule 3 requires separate fields.
- No `state_version`, no `idempotency_key`, no skill pinning columns on the manifest row.
- Sheet and viewport identity is not relational (lab gap `PH2-LO-GAP-002`); `sheet_id` is free text on the binding row.
- No append-only transition receipt for the manifest itself; evidence lives in `design.capability_runtime_evidence` keyed by run, not by manifest transition.

**Options for ruling (Q1):**
- (a) **Reuse** `design.layout_manifests` as the Instance 02 spine at manifest grain, with sheets as type-profiled bindings. Requires a later CCS adding `phase`, `state_version`, `idempotency_key`, skill pinning, and a transition function reading `core.lab_transitions`; `status` keeps its operational meaning. Sheet-revision semantics are carried by supersession of the manifest plus `layout_manifest_output_bindings`.
- (b) **Create** `design.layout_sheet_revisions` at true sheet-revision grain (one row per sheet per revision), manifests becoming groupings.

**Recommendation:** (a). Placement order is REUSE → EXTEND → LINK → CREATE; the manifest table already carries the project/source-model guards (`design.validate_layout_manifest_v1`), readiness, traceability, and release bindings. Move to (b) only if a real project run shows sheets in one manifest needing independent phases, which the two synthetic rows cannot show.

## 3 · Ordered phases (8)

`queued → recipe_bound → composed → structural_checked → native_checked → visual_review → accepted → closed`

Exactly the lab's Workflow B lifecycle (2026-09-10). Terminal phase `closed`; terminal statuses `completed · refused · cancelled` (aligned with Instance 01 so `core.evaluate_lab_transition_v1` reads them as data). Supersession is a successor row, never a phase.

Mapping of the existing `layout_manifests.status` vocabulary onto phase + status, for the later CCS (not applied):

| existing status | phase | status |
|---|---|---|
| draft | queued or recipe_bound | open |
| resolved | recipe_bound | open |
| blocked | (unchanged phase) | blocked |
| ready | composed | open |
| executed | native_checked | open |
| verified | accepted | open |
| superseded | closed | completed (successor row exists) |

## 4 · Transition table

Shaped for `core.lab_transitions` with `lab_key = 'layout_sheet_production'`. Unapplied. Entry conditions and exit evidence are transcribed from the lab's PH2-LO-001 phase table.

| from → to | allowed authority | entry condition | exit evidence schema | gate |
|---|---|---|---|---|
| each non-terminal phase → itself | human, worker, system | same-phase update (status, binding, receipt) | — | no |
| queued → recipe_bound | human, worker, system | exact deliverable/scope/format; logical template family/version or existing drawing set; requested result | recipe id + version, applicable standard, sheet type profile, resolved zones/scale/render policy; SketchUp handoff id for model-required sheets | no |
| recipe_bound → composed | human, worker, system | recipe geometry `READY` (`design.v_layout_recipe_readiness`); handoff valid for model-required sheets | working derivative hash; target page/layer/entity/viewport locator; bounded before/after receipt; source and manifest bindings | no |
| composed → structural_checked | human, worker, system | composed receipt present | page count/order; shared/layer visibility; reference freshness; attributes/bindings; bounds/zones; no unrelated structural change | no |
| structural_checked → native_checked | human, worker, system | structural pass | native open/save/close/reopen persistence; native file hash; required reference/render readback | no |
| native_checked → visual_review | human, worker, system | native pass | native PDF/screenshot/render; scene/composition/scale/crop correct; typography/line hierarchy; no clipping; warnings reviewed | no |
| visual_review → accepted | **human only** | `requires_authorization_binding = true`; `effect_class = gated_transition` | human ruling + exact native file/hash + structural, native, visual evidence | **yes (G1)** |
| accepted → closed | human, worker, system | `terminal`, `completion_allowed`; to_status ∈ completed | disposition and continuation recorded; `required_when_to_status_in: [completed]` | no |
| structural_checked → composed · native_checked → composed · visual_review → composed | human, worker, system | failed check; back-edge for rework | rework receipt naming the failed check | no |
| any non-terminal → closed | human, worker, system | `terminal`, `to_status_in: [refused, cancelled]` | refusal or cancellation reason | no |

Row count: 8 self-loops + 7 mainline + 3 back-edges + 7 refuse/cancel = 25. Same key vocabulary as Instance 01 (`terminal`, `terminal_statuses`, `completion_status`, `completion_allowed`, `to_status_in`, `requires_authorization_binding`, `effect_class`, `required`, `required_when_to_status_in`) so the deployed evaluator needs no change.

## 5 · Human gates (≤ 2)

- **G1 · visual_review → accepted.** A technical API pass never enters `accepted`; entry requires human authority and a bound authorization (the lab: "human ruling + exact native file/hash"). Encoded as the gate row above.
- **G2 · production issue / release.** Not a spine phase. Release is an external-effect packet (`design.layout_manifest_release_bindings`, `v_layout_manifest_release_readiness.release_signal`) gated by a human under PRO-0138; an accepted manifest stays `accepted` until a release packet closes it. Keeping release out of the spine keeps the gate count at two and matches the lab's rule "acceptance does not equal external issue/release".

## 6 · Type profiles

Profiles (from the lab): `non_model_sheet` · `model_required_sheet` · `text_schedule_heavy` · `viewport_heavy`. Dimensions that differ (three):

| dimension | non_model_sheet | model_required_sheet | text_schedule_heavy | viewport_heavy |
|---|---|---|---|---|
| SketchUp handoff required at recipe_bound | no | yes (`SU-LO-HANDOFF-v0.1`) | no | yes |
| extra exit evidence at structural/native check | — | source freshness, reference readback | overflow evidence | scene, bounds, scale, render evidence |
| recipe family (from `design.layout_sheet_recipes`) | COVER_STANDARD, SCHEDULE_PRIMARY, DETAIL_GRID | PLAN_PRIMARY, PLAN_WITH_NOTES, RCP_PRIMARY, SECTION_PRIMARY | SCHEDULE_PRIMARY, PLAN_WITH_NOTES | FOUR_ELEVATIONS, TWO_ELEVATIONS, PLAN_PRIMARY, RCP_PRIMARY |

Profiles are read from the recipe row (`layout_sheet_recipes.metadata`, `qa_contract`, `render_policy`), never embedded in a worker.

## 7 · Change triggers (successor row)

- Recipe id or version changes for a bound sheet.
- Template or working-file identity changes.
- SketchUp handoff successor: source revision, fingerprint, or scene Page PID / state hash changes (`stale_source` HALT; never auto-update an accepted sheet).
- Any edit to an accepted manifest.
- Reissue: the released manifest is superseded by the successor (`layout_manifests.status = superseded` today).
- Terminal rows never transition (STD §3.12).

## 8 · Queue / review / history views

Existing (reuse): `design.v_layout_manifest_readiness` (readiness precedence BLOCKED_AUTHORITY → BLOCKED_TEMPLATE → BLOCKED_RUNTIME → BLOCKED_COMPILER → READY_FOR_SUPERVISED_EXECUTION), `design.v_layout_manifest_traceability` (deliverable version binding, stale bindings), `design.v_layout_manifest_release_readiness` (release signal), `design.v_layout_recipe_readiness`.

Needed once the spine has phase + status (part of the later CCS, not this document): `design.v_layout_work_queue` (rows by phase and status, claim-ready), `design.v_layout_manifest_review`, `design.v_layout_manifest_history`. History reads the shared receipts backbone per R3 (digital-thread provenance layer), not a new per-lab events table.

## 9 · Worker skills (one per transition family, pinned by hash)

- `kphd-lab-worker` v0.1 (generic Mode A; SHA-256 `0d761326aedce40c32b3e8ff0633c16e700aaa38448c0a0da7fd3bd6ae3e8fc5`; release path under ruling).
- `layout-drawing-set-operator` v0.1-runtime-1 (existing, `core.agent_skill_versions` ids 31/32, SHA-256 `cd8c4345d5c43b9dfc5cc6c27772c0d4e0808713a1e98aab7e61646d3240e226`) as the domain skill for the compose and check families: PLAN and GUIDED EXECUTION modes only; SUPERVISED COMPILER stays fail-closed until `v_layout_manifest_readiness` returns READY.
- Transition families: compose (recipe_bound → composed), check (composed → structural_checked → native_checked), review-prep (native_checked → visual_review), accept (G1, human, no worker skill).

## 10 · Packet families (PRO-0138 effect class per family)

| family | effect class | carrier | notes |
|---|---|---|---|
| manifest resolve / recipe bind | Routine | `design.capability_runs` mode plan | spine-only state plus manifest_json |
| viewport placement / sheet composition | Bounded | `design.capability_runs` mode guided or supervised; workstation-native `Layout::Document` | one derivative file, bounded entities; refuses locked or off-page targets |
| native save / reopen probe | Bounded | `design.capability_runtime_evidence` type runtime_acceptance | file hash evidence |
| PDF / PNG proof export | Bounded | `design.artifact_outputs` with `capability_run_id` | output fingerprint |
| visual QA capture | Routine | `design.capability_runtime_evidence` | screenshot/render evidence |
| source update / relink | Bounded | explicit packet with its own receipt | wrong-file relink refuses; stale source halts |
| release / issue | Bounded with external side effect + human gate (G2) | `design.layout_manifest_release_bindings` | never from a worker |

---

## Rulings surfaced (filed as separate execution-queue rows)

- **Q1 · Spine row type for Instance 02.** Reuse `design.layout_manifests` at manifest grain with a phase/status split added by a later CCS, or create a sheet-revision table. Recommendation: reuse.
- **Q2 · Release as packet, not phase.** Keep production issue/release outside the spine as a human-gated Bounded packet, so the lab has two gates. Recommendation: yes.

No row is inserted, no table changed, no function created by this document. Instance 02 rows for `core.lab_transitions` are drafted only after Q1 is ruled.
