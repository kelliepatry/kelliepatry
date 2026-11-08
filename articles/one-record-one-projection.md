[← Back to “How we work with AI”](https://kelliepatry.com/notes/how-we-work-with-ai) · [Field Notes](https://kelliepatry.com/notes) · [Home](https://kelliepatry.com/)

---

# One record, one projection

### Moving the studio's registered databases into Supabase, and leaving Notion as documentation

**KPHD Studio, Los Angeles · 8 November 2026 · working draft v0.1 · build owner: Claude, by Kellie's direction · decision key GOV-20261108-NOTION-PROJECTION-ONLY**

> **Recorded.** GOV-20261108-NOTION-PROJECTION-ONLY was recorded in core.governance_decisions through core.record_governance_decision_v1 on 8 November 2026. Receipt b3278148-43cf-4fd5-b80e-68bda6ddd111. The approved package hash is the sha256 of this file at commit 9aef9391 (e024199d2d3936255a04dc5276a15b0a07e6d2d0aa3e6c162d06dc346bd8f048). This note and anything after it are outside that hash; a change to sections 1 to 9 is a new version and a new receipt.

> **The ruling.** Kellie, 8 November 2026: "I believe the databases should fully migrate into supabase with a stable schema system now - and notion remains documentation only - with stable matching schema." Then, on the recommendation below: "Branch the build as needed - approved as recommended - you now own this." This paper is the build. It replaces one clause of the master governance decision, names the Supabase home of every active registered database, and sets the order in which the write direction flips.

**Read with:** [Binding the three maps](./binding-the-three-maps.md) (the eight read classes this plan is built on) · [How an artist sees](./how-an-artist-sees.md) · [The anatomy](./anatomy-of-a-small-business-that-survives-ai.md)

---

## 1. What the ruling changes

The master governance decision, GOV-MASTER-20261101, clause M1, reads: "Supabase (Studio Home) is the authority for governance, protocols and standards; Notion holds a read-only projection of these and stays read/write for all other content."

This decision replaces the second half of that sentence. From now:

- **Supabase is the authority for every structured record**, not only governance, protocols and standards. A record is anything with fields: a project, a task, a decision, a contact, an image, an invoice, a code.
- **Notion keeps two roles.** Prose, which a person writes and the system sweeps in: notes, briefs, meeting records, working pages. Projection, which the system generates from Supabase and nobody edits: one page template per read class, carrying the spine fields, regenerated on change, drift caught by fingerprint.
- **Notion loses one role.** Human-edited structured databases end. Each active registered database is matched or backfilled into its Supabase home, projected back, verified, then archived by Status. Nothing is deleted.
- **Human structured input enters through governed functions or swept prose.** The session close already works this way. Meeting action items reaching the work queue is the proof case for swept prose, and it gates the Task class.

The earlier direction, GOV-20261031-NOTION-RETRIEVAL-LAYER, said Supabase becomes the single retrieval layer and Notion content is mirrored in full. It is already retired into the master. This decision completes it by removing the write side too.

---

## 2. What is already true

Live reads, 8 November 2026.

| Fact | Evidence |
| --- | --- |
| Supabase already governs the core record | 221 tables in core, 21 in memory, 12 in runtime, 13 in finance, 20 in design, 8 in mirror, 2 in intake. Projects 66, deliverables 566, decisions 147, work queue 295, meeting snapshots 886, phase definitions 162. |
| The registry is already synced one way, with a migration order | core.database_registry: 323 rows, 234 Active, synced from Notion daily. Wave 1 = active workflow (86), wave 2 = passive logging (49), wave 3 = reference (87), wave 9 = retired (74). |
| Notion is already mirrored page by page | mirror.pages holds 14,220 pages from 186 Notion databases. Those databases match 202 registry rows. The capture layer for prose exists. |
| Projection already runs for four record types | Scheduled processors: database-registry-sync, deliverable-notion-sync, deliverable-notion-parity, phase-id-notion-parity, initiative-tracker-notion-sync, notion-parity-daily. The projection pattern exists; it has to be generalised to one template per class. |
| Intake exists | intake.items holds 8,343 rows with source, fingerprint, project resolution, triage and routing state. Swept prose has a landing table. |
| The money tables exist and are empty | finance.invoices 0 rows, finance.payment_events 0 rows. Nine Business and Log databases hold money. Their backfill is an M4a gate, item by item. |
| The meeting sweep is in shadow | Lifecycle shadow since August; last success 3 November; zero work rows created per run; retry backlog 153; source identity unverified on about 1,800 drops. Owner: Track W (GPT). |
| The measured image read has never touched project photographs | 64 palette records, all from study images; zero from core.media_assets. |

So the migration is not a build from nothing. Capture exists (mirror), structured homes exist (core and the other schemas), projection exists for four types, intake exists. What is missing is the promotion from mirrored page to structured row for each database, the generalised projection, and the end of structured editing in Notion.

---

## 3. The stable schema

The schema is the eight read classes from the binding, each as a record shape, each row carrying the four spine fields.

| Class | Record shape | Primary Supabase homes | Projection template |
| --- | --- | --- | --- |
| Spine | registry row | core.database_registry, knowledge_registry, capability_registry, classification_systems, memory.actors, runtime.processor_registry | Registry card |
| Record | project component | core.projects, deliverables, project_work_items, change_orders, sketchup_models, specifications, phase_definitions | Record card |
| Link | typed relation | core.decisions, decision_links, link_graph_*, memory.events, reviewed_change_sets | Link card |
| Reference | versioned document | core.source_artifacts (document kinds), agent_skill_versions, external_authority_records, classification_terms | Document page |
| Seeing | image record | core.media_assets, source_artifacts (image and palette kinds), visual_clusters, arena_channels, design.* | Image card |
| Business | party or opportunity | core.parties, commercial_opportunities, offer_tiers, content_opportunities, finance.* | Party card |
| Task | work item | runtime.work_queue, intake.items, outbound.meeting_snapshots, event_occurrences | Task card |
| Log | event | core.agent_run_log, audit_log, observation_events, telemetry.run_log | none; logs are not projected |

Spine fields on every projected row: id, state, one-line summary, supersedes. The projection is generated, read-only, and carries the fingerprint of the Supabase rows it was built from. A projection whose fingerprint no longer matches is regenerated, never edited.

Prose pages are the exception. They are written by a person in Notion, captured by mirror.pages, and swept into intake.items, where triage turns them into tasks, decisions or notes in their homes. Six registered databases become prose: the meeting database, project notes, office notes, the brandstorm sprint, and the two discussion databases.

---

## 4. The target map

Every active registered database has one action and one home. The rule that assigns them is in section 9; the full map is Appendix B.

| Action | Meaning | Count |
| --- | --- | --- |
| match | The Supabase home already holds the same records. Reconcile mirrored pages to rows, project, archive. | 151 |
| backfill | The home exists but the rows are not there yet. Load from mirror.pages, verify, project, archive. | 21 |
| document | The database is really a set of documents. Each becomes a versioned source artifact with an id, projected as a page. | 24 |
| prose | Human-written. Stays in Notion as the write surface, swept through mirror and intake. | 6 |
| retire | Supabase already holds the machine record. The Notion copy is archived; nothing is migrated. | 32 |

| Class | match | backfill | document | prose | retire | total |
| --- | --- | --- | --- | --- | --- | --- |
| Spine | 27 | 0 | 2 | 0 | 1 | 30 |
| Record | 23 | 4 | 0 | 0 | 1 | 28 |
| Link | 14 | 2 | 0 | 2 | 0 | 18 |
| Reference | 38 | 1 | 15 | 1 | 4 | 59 |
| Seeing | 7 | 6 | 2 | 0 | 1 | 16 |
| Business | 24 | 2 | 5 | 0 | 0 | 31 |
| Task | 13 | 0 | 0 | 3 | 1 | 17 |
| Log | 5 | 6 | 0 | 0 | 24 | 35 |

Duplicates resolve at the match. The two Active rows of the Database Registry, the five decision stores, the two Phase Handoffs, the two Office Wikis, the two Case Studies, the two Sub Phases, the two Discussions, the two Submittals and the three email trackers each land in one home. No separate merge ruling is needed; the match is the merge.

---

## 5. Gates that stay closed until opened

- **M4a, money.** Nine databases hold invoices, payments, expenses, budgets or fees. Their backfill into finance.* is pre-approved item by item, never as a batch. They are listed in Appendix B under backfill with "(Red Zone)".
- **M4c, deletion.** No Notion database or page is deleted. Archive by Status, after projection and fingerprint verification.
- **M4e, master amendment.** This decision replaces M1 text, so it is recorded through core.record_governance_decision_v1 with a receipt, naming the text it replaces, binding the sha256 of this document as the approved package.
- **Ownership, M5.** The meeting pipeline (Track W) belongs to GPT. This plan names its proof as a dependency and does not touch it. The Task class flip waits on that proof.
- **One writer per record.** During a database's flip it is frozen read-only in Notion. A person who needs to change it changes the Supabase row through a governed function, or writes prose.

---

## 6. Sequence

| Step | What | Done when | Owner |
| --- | --- | --- | --- |
| 0 | Record the ruling with a receipt. Hash this document. | Receipt id exists for GOV-20261108-NOTION-PROJECTION-ONLY. | Claude |
| 1 | Intake proof: one real meeting's action items become work-queue rows with owners, through the sweep, not by hand. | At least one meeting since 3 November yields rows in runtime.work_queue with owner set and source traceable to the meeting page. | Track W (GPT) proves; Claude consumes |
| 2 | Record flip, five pilots: Master Projects, Documents, Plan Drops, Model Tracker, Written Specifications. Freeze, match mirrored pages to rows, project, verify fingerprint, archive. | Five databases archived in Notion; five projections live; zero drift over five business days. | Claude |
| 3 | Rest of Record and Spine. Then Link. | Classes fully flipped; projection template per class live. | Claude |
| 4 | Task flip, after step 1. Meeting Database, Project Notes, Office Notes, Brandstorm, Discussions stay as prose. Checklists, work blocks, queues, email, calendar flip to their homes. | No human-edited task database remains. | Claude |
| 5 | Seeing and Business flip. Finance databases only after each M4a approval. | Image read row three walked on one project. Parties and opportunities reconciled. | Claude; Kellie on M4a |
| 6 | Reference to documents, Log to retire, in bulk. | 24 document pages carry ids; 32 log databases archived. | Claude |
| 7 | Replace routing: Model Context Map search routing and the read-path table point at projections and homes; the binding paper and this plan become history. | Routing cites no human-edited Notion database. | Claude |

**Done when, for the whole.** No Active registered database accepts human structured edits. Every class has a projection template. Fingerprint drift is zero for two consecutive weeks. Kellie's own writes land only in prose pages or governed functions.

**Stop conditions.** A flip that needs a new column on an authority table stops and asks (M4e). A flip that would lose rows not present in its home stops; the home is backfilled first. Any money row stops at M4a.

---

## 7. Where Kellie types, after the flip

| She wants to | She does | It lands in |
| --- | --- | --- |
| Make a note, write up a meeting, think on a page | Writes a Notion page in Office Notes, Project Notes or the meeting database | mirror.pages, then intake.items, then its home |
| Give a ruling or approve something | Says it in chat or on the page; the worker records it | core.governance_decisions with a receipt, or the work item |
| Add a task or assign work | Writes it as an action item in prose, or asks the worker | runtime.work_queue through intake or end_work_v1 |
| Add an image | Drops it in the image intake | core.media_ingest_runs, then media_assets |
| Change a project fact | Asks the worker, who changes the row | core.projects and its projection |
| Touch money | Approves the specific item (M4a) | finance.* through its governed path |
| Read anything | Opens the projection page | Generated from Supabase, never edited |

---

## 8. What this does not do

No new database, tracker or register. No column on an authority table without M4e. No deletion. No flip of the meeting sweep from shadow to live by this owner. No migration of money without M4a. No rename of a live database before its flip; the read-names in the binding apply at projection time, when the projection template names the class, not the old database.

---

## 9. The assignment rule

Actions and homes were assigned to the clean registered name by ordered pattern rules, first match wins, then checked by hand. The rules live in the repository alongside this paper and can be re-run when the registry changes. Any owner can override a row in Appendix B by changing the action or home; the override is recorded on the row.

---

## Appendix B · Target map for all 234 active registered databases

### Match (151)

| Class | Registered name | Supabase home |
| --- | --- | --- |
| Business | BIZ \| AI-Augmented Service Offerings | core.commercial_opportunities + offer_tiers + contract_versions |
| Business | BIZ \| Audience Research | core.parties + party_profiles + commercial_opportunities |
| Business | BIZ \| Brand Messaging | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Client Engagement | core.parties + party_profiles + commercial_opportunities |
| Business | BIZ \| Client Pain Points | core.parties + party_profiles + commercial_opportunities |
| Business | BIZ \| Client Profiles | core.parties + party_profiles + commercial_opportunities |
| Business | BIZ \| Content Briefs | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Content Ideas | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Content Pipeline | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| LinkedIn Contacts | core.parties + party_contact_methods + party_role_bindings |
| Business | BIZ \| Marketing + Sales Ops | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Marketing Operations | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Master Contacts | core.parties + party_contact_methods + party_role_bindings |
| Business | BIZ \| Messaging — Campaigns | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Offer Groups | core.commercial_opportunities + offer_tiers + contract_versions |
| Business | BIZ \| Pre-Client Qualification | core.parties + party_profiles + commercial_opportunities |
| Business | BIZ \| Proposal Workflow | core.commercial_opportunities + offer_tiers + contract_versions |
| Business | BIZ \| Proposals | core.commercial_opportunities + offer_tiers + contract_versions |
| Business | BIZ \| Questionnaire | core.feasibility_client_briefs + restricted.pages (responses) |
| Business | BIZ \| Real Estate Brokers | core.parties + party_contact_methods + party_role_bindings |
| Business | BIZ \| Reconnaissance — Dream Client Tracker | core.parties + party_profiles + commercial_opportunities |
| Business | BIZ \| Sales + Proposals | core.commercial_opportunities + offer_tiers + contract_versions |
| Business | BIZ \| Social Media Writing | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Business | BIZ \| Unified CRM | core.parties + party_profiles + commercial_opportunities |
| Link | DOC \| Decision Memos | core.decisions + decision_links + governance_decisions |
| Link | DOC \| KB Knowledge Change Proposals | core.reviewed_change_sets + guard.controlled_change_sets |
| Link | DOC \| Project Learnings | memory.items (class learning) + evidence_links |
| Link | INT \| Decision Log | core.decisions + decision_links + governance_decisions |
| Link | INT \| Decision Quality Tracker | core.decisions + decision_links + governance_decisions |
| Link | INT \| Handoff Registry | runtime.work_context_bindings + memory.events |
| Link | INT \| Project Lessons | memory.items (class learning) + evidence_links |
| Link | PRJ \| Decision Log | core.decisions + decision_links + governance_decisions |
| Link | PRJ \| Design Decision Tracker | core.decisions + decision_links + governance_decisions |
| Link | PRJ \| Phase Handoffs | runtime.work_context_bindings + memory.events |
| Link | Publish Decision Log — kphd-model-publishes | core.decisions + decision_links + governance_decisions |
| Link | SYS \| Phase Handoffs | runtime.work_context_bindings + memory.events |
| Link | SYS \| Relation Map | core.link_graph_* (kphd-link-graph) |
| Link | SYS \| Soft Flags Database | core.agent_failure_events |
| Log | BIZ \| Marketing Analytics | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Log | BIZ \| Newsletter Subscribers | core.content_opportunities + content_publications + telemetry.content_signal_events |
| Log | OPS \| Time Tracker | core.time_entries (+ classification_terms for codes) |
| Log | PRJ \| Plan Drop History | core.deliverables + deliverable_versions (registers DWG, PKG, RPT) |
| Log | SYS \| Database Audit Tracker | core.database_registry |
| Record | DOC \| Documents | core.deliverables + deliverable_versions (registers DWG, PKG, RPT) |
| Record | OPS \| Model Tracker | core.sketchup_models + project_model_of_record (register SKP) |
| Record | PRJ \| AI Workflow Stages | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Automation Engine | core.work_definitions |
| Record | PRJ \| Change Order Log | core.change_orders (register CO) |
| Record | PRJ \| Construction Milestone Tracker | core.project_work_items |
| Record | PRJ \| Design Workflow Projects | core.projects (+ project_phase_clusters) |
| Record | PRJ \| Drawing Documentation Intelligence | core.deliverables + design.layout_manifests + design.sheet_revisions |
| Record | PRJ \| Location Discovery + Code Search | core.permit_cases + regulatory_assessments + parcels/premises |
| Record | PRJ \| Master Projects | core.projects (+ project_phase_clusters) |
| Record | PRJ \| Master Workflow | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Milestones/codes | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Phase Templates | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Plan Drops | core.deliverables + deliverable_versions (registers DWG, PKG, RPT) |
| Record | PRJ \| Production Database | core.projects (+ project_phase_clusters) |
| Record | PRJ \| RFI Tracker | core.deliverables (register RFI → BUILD.02.02) |
| Record | PRJ \| Sub Phase | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Sub-Category, Phase | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Submittal Log | core.deliverables (register SUB → BUILD.02.03) |
| Record | PRJ \| Submittals & Deliverables | core.deliverables (register SUB → BUILD.02.03) |
| Record | PRJ \| Work Orders | core.project_work_items |
| Record | PRJ \| Workflow + Process | core.phase_definitions + legacy_phase_crosswalk |
| Record | PRJ \| Written Specifications | core.specifications + specification_classifications |
| Reference | DOC \| AI Agent Architecture | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Accounts + Procedures | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Agent Definitions | memory.actors + runtime.agents + core.agent_skill_versions |
| Reference | DOC \| Architecture Docs | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Office Wiki | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Office Wiki & Operations Manual | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| PM Playbooks | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Pattern Library | memory.items (class learning) + evidence_links |
| Reference | DOC \| Permit Knowledge | core.external_authority_records + regulatory_assessments |
| Reference | DOC \| Policies | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Prompt Engineering | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Question Bank | core.feasibility_client_briefs + restricted.pages (responses) |
| Reference | DOC \| Research + Protocols | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Studio Procedures | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Technical Guides | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | DOC \| Vendor Catalog | core.parties + party_contact_methods + party_role_bindings |
| Reference | LIB \| Codes - Building | core.external_authority_records + regulatory_assessments |
| Reference | LIB \| Codes - Technical | core.external_authority_records + regulatory_assessments |
| Reference | LIB \| Deliverable Taxonomy | core.phase_deliverable_expectations + deliverable_binding_rules |
| Reference | LIB \| Deliverables by Phase | core.phase_deliverable_expectations + deliverable_binding_rules |
| Reference | LIB \| Deliverables by Sub Phase | core.phase_deliverable_expectations + deliverable_binding_rules |
| Reference | LIB \| Design Phase Template | core.phase_definitions + legacy_phase_crosswalk |
| Reference | LIB \| Milestone Definitions | core.phase_definitions + legacy_phase_crosswalk |
| Reference | LIB \| Phase Code Master | core.phase_definitions + legacy_phase_crosswalk |
| Reference | LIB \| Process Types | core.phase_definitions + legacy_phase_crosswalk |
| Reference | LIB \| Project Category | core.classification_systems + classification_terms |
| Reference | LIB \| Project Classification | core.classification_systems + classification_terms |
| Reference | LIB \| Service Offering Codes | core.commercial_opportunities + offer_tiers + contract_versions |
| Reference | LIB \| SketchUp Standardization | core.classification_systems (tag taxonomy) + sketchup_component_definitions |
| Reference | LIB \| Specifications by type | core.specifications + specification_classifications |
| Reference | LIB \| Sub Phase | core.phase_definitions + legacy_phase_crosswalk |
| Reference | LIB \| Sub-Category Phase [OLD] | core.phase_definitions + legacy_phase_crosswalk |
| Reference | LIB \| Task Sub-List [Codes] | core.classification_systems + classification_terms |
| Reference | LIB \| Vendor Directory | core.parties + party_contact_methods + party_role_bindings |
| Reference | OPS \| C-Suite Virtual Staff Profiles | memory.actors + runtime.agents + core.agent_skill_versions |
| Reference | OPS \| COE Operations | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | OPS \| Office Process + Workflow | core.agent_skill_versions + source_artifacts (protocol projection already in force) |
| Reference | OPS \| Time Tracking Codes | core.time_entries (+ classification_terms for codes) |
| Seeing | Cultural Reference Library | core.visual_clusters + arena_channels + source_artifacts (study kinds) |
| Seeing | IMG \| Image Reference System | core.media_assets (+ media_rights_records) |
| Seeing | INT \| Design Movements Radar | core.visual_clusters + arena_channels + source_artifacts (study kinds) |
| Seeing | OPS \| INTAKE Image Intake (Router-Routed) | core.media_ingest_runs + intake.items |
| Seeing | RUN \| Figma Population Outcomes | design.template_registry + design.population_runs |
| Seeing | SPARKS \| Zeitgeist & Ways of Seeing | core.visual_clusters + arena_channels + source_artifacts (study kinds) |
| Seeing | SYS \| Figma Template Registry | design.template_registry + design.population_runs |
| Spine | DOC \| Hubs | core.knowledge_registry |
| Spine | DOC \| Tag Registry — Active Hashtags | core.classification_systems + classification_terms |
| Spine | OPS \| Virtual Staff Registry | memory.actors + runtime.agents + core.agent_skill_versions |
| Spine | PRJ \| Project Deliverables Registry | core.phase_deliverable_expectations + deliverable_binding_rules |
| Spine | SYS \| AI Agents + Scheduler | runtime.processor_registry + cron.job + core.work_definitions |
| Spine | SYS \| Agent Cheat Sheets | memory.actors + runtime.agents + core.agent_skill_versions |
| Spine | SYS \| Category Registry | core.classification_systems + classification_terms |
| Spine | SYS \| Custom Agents (SoT) | memory.actors + runtime.agents + core.agent_skill_versions |
| Spine | SYS \| Database Migration Queue | core.database_registry |
| Spine | SYS \| Database Registry | core.database_registry |
| Spine | SYS \| Database Registry (second Active row) | core.database_registry |
| Spine | SYS \| Failure Class Library | core.agent_failure_subjects + agent_failure_events |
| Spine | SYS \| Hub Governance | core.knowledge_registry |
| Spine | SYS \| Hub Registry | core.knowledge_registry |
| Spine | SYS \| Orchestration Ops | runtime.processor_registry + cron.job + core.work_definitions |
| Spine | SYS \| Orchestration Pipeline | runtime.processor_registry + cron.job + core.work_definitions |
| Spine | SYS \| Page Migration | runtime.work_queue (class system) |
| Spine | SYS \| Pipeline Steps | runtime.processor_registry + cron.job + core.work_definitions |
| Spine | SYS \| Retroactive Scan Tracker | runtime.work_queue (class system) |
| Spine | SYS \| Staff & Virtual Employee Registry | memory.actors + runtime.agents + core.agent_skill_versions |
| Spine | SYS \| Staff Persona Registry | memory.actors + runtime.agents + core.agent_skill_versions |
| Spine | SYS \| System Build Queue | runtime.work_queue (class system) |
| Spine | SYS \| System Notes, Skills and Operational Notes | core.agent_skill_versions |
| Spine | SYS \| Testing & QA Tracker | runtime.work_queue (class system) |
| Spine | Skills Index (DB) | core.agent_skill_versions |
| Spine | TRACKER \| Studies + Outcomes | core.observation_pilots + research.studies |
| Spine | TRACKER \| Tracked Projects + Programs | core.initiatives (+ initiative_projects) |
| Task | BIZ \| Discovery Questions — Client Intake | core.feasibility_client_briefs + restricted.pages (responses) |
| Task | INT \| AI Issues & Action Items Tracker | runtime.work_queue + intake.items |
| Task | OPS \| Email Inbox | core.gmail_attention_candidates + outbound.email_delivery_jobs |
| Task | OPS \| Email Log | core.gmail_attention_candidates + outbound.email_delivery_jobs |
| Task | OPS \| INTAKE Triage Queue | runtime.work_queue + intake.items |
| Task | OPS \| Intake Queue | runtime.work_queue + intake.items |
| Task | OPS \| Output Tracker | outbound.email_delivery_jobs + core.content_publications |
| Task | STUDIO \| Email Action Tracker | core.gmail_attention_candidates + outbound.email_delivery_jobs |
| Task | SYS \| Agent Routing Queue | runtime.work_queue + intake.items |
| Task | TSK \| EVENT CALENDAR | outbound.event_occurrences |
| Task | TSK \| Executive Action Items | runtime.work_queue + intake.items |
| Task | TSK \| WORK \| ACTIVE CHECKLISTS | runtime.work_queue + intake.items |
| Task | TSK \| Work Blocks | runtime.work_queue + intake.items |

### Backfill (21)

| Class | Registered name | Supabase home |
| --- | --- | --- |
| Business | BIZ \| Invoices | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Business | BIZ \| Revenue Intelligence | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Link | PRJ \| Project Risk Flags | core.decision_impacts + obligations (class risk) |
| Link | PRJ \| Risk & Exception Register | core.decision_impacts + obligations (class risk) |
| Log | BIZ \| Cost Tracking & Budget Monitor | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Log | BIZ \| Payments Received | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Log | Client Outcomes Tracker | core.observation_events (class outcome) |
| Log | OPS \| Client Statement Log | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Log | OPS \| Expense Tracking | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Log | PRJ \| FF&E Budget | finance.project_budget_impacts + core.phase_economics_snapshots |
| Record | OPS \| Billing Setup | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Record | OPS \| Billing Threshold Table | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Record | OPS \| Reimbursable Expenses | finance.invoices / payment_events / ar_cases / project_budget_impacts (Red Zone) |
| Record | PRJ \| GC Budget Tracker | finance.project_budget_impacts + core.phase_economics_snapshots |
| Reference | OPS \| Budget Reference Library | finance.project_budget_impacts reference set |
| Seeing | DOC \| Design Reference Library | core.source_artifacts (design_reference, studio_material_reference) + visual_clusters |
| Seeing | DOC \| Design Visuals | core.source_artifacts (design_reference, studio_material_reference) + visual_clusters |
| Seeing | DOC \| Material Studies | core.source_artifacts (design_reference, studio_material_reference) + visual_clusters |
| Seeing | DOC \| Pinterest Board Registry | core.source_artifacts (pinterest_import_manifest) + arena_channels |
| Seeing | DOC \| Project Images | core.media_assets + media_asset_variants |
| Seeing | OPS \| Asset Library | core.media_assets + media_asset_variants |

### Document (24)

| Class | Registered name | Supabase home |
| --- | --- | --- |
| Business | BIZ \| Market Intelligence | core.source_artifacts (strategy_document) → projected page |
| Business | BIZ \| Marketing Content | core.source_artifacts (strategy_document) → projected page |
| Business | BIZ \| Mise en Place | core.source_artifacts (strategy_document) → projected page |
| Business | BIZ \| Sales Playbooks & Strategy | core.source_artifacts (strategy_document) → projected page |
| Business | BIZ \| Strategy + Positioning | core.source_artifacts (strategy_document) → projected page |
| Reference | DOC \| Case Library | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Case Studies | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Case Studies & Project Knowledge | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Contract Templates | core.source_artifacts (template_catalog_capture) → projected page |
| Reference | DOC \| Core Curriculum | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Design Position | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Design Statements | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Executive Knowledge Base | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Hospitality Design Training Framework | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Philosophy + Leadership | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Production Design Training Framework | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Reflection & Feedback | core.source_artifacts (case_study, study_text) → projected page |
| Reference | DOC \| Three-Lens Library | core.source_artifacts (case_study, study_text) → projected page |
| Reference | LIB \| Deliverable Templates | core.source_artifacts (template_catalog_capture) → projected page |
| Reference | LIB \| Project Workflow Templates | core.source_artifacts (template_catalog_capture) → projected page |
| Seeing | DOC \| 3D & Visualization Tools | core.source_artifacts (document) → projected page |
| Seeing | DOC \| Render & Visualization Systems | core.source_artifacts (document) → projected page |
| Spine | SYS \| Framework Design | core.source_artifacts (document) → projected page |
| Spine | SYS \| SYSTEM Templates | core.source_artifacts (document) → projected page |

### Prose (6)

| Class | Registered name | Supabase home |
| --- | --- | --- |
| Link | PRJ \| Discussions, Projects | mirror.pages → outbound.meeting_snapshots / memory.items |
| Link | PRJ \| Project Discussions | mirror.pages → outbound.meeting_snapshots / memory.items |
| Reference | OPS \| Office Notes | mirror.pages → memory.items / intake.items (register NOTE) |
| Task | PRJ \| Project Notes | mirror.pages → memory.items / intake.items (register NOTE) |
| Task | TSK \| Brandstorm Sprint | mirror.pages → memory.items / intake.items (register NOTE) |
| Task | TSK \| Meeting Database | mirror.pages → outbound.meeting_snapshots (register MTG) |

### Retire (32)

| Class | Registered name | Supabase home |
| --- | --- | --- |
| Log | AHJ Queue Tracker | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | AI Experiments Log | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | Error Tracking | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| AHJ Performance Database | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Agent Performance | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Agent Performance Analytics | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Agent Performance Baseline | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Anomaly Log Database | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Error Log | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Error Patterns | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Flexibility Patterns | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Health Metrics Database | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| KPI Metrics | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| PULSEy Weekly Intelligence Reports | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | INT \| Stall Detection Monitor | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | OPS \| Client Data Incidents | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | OPS \| OpenClaw File Registry | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | OPS \| OpenClaw Run Log | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | OPS \| Virtual Staff Comms | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | SYS \| AI Chat Log (Main Agent) | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | SYS \| Agent Audit Trail | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | SYS \| Citation Index | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | SYS \| Security Audit Log | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Log | SYS \| System Performance Metrics | core.agent_run_log / agent_failure_events / audit_log / observation_events / telemetry.run_log / qnap_* / permit_cases |
| Record | OPS \| Occupancy | no live use found; archive, re-create in finance if needed |
| Reference | INT \| Agent Behaviors | core.agent_evaluation_* + runtime.v_work_health_v1 hold the live form |
| Reference | INT \| Project Knowledge Base | core.agent_evaluation_* + runtime.v_work_health_v1 hold the live form |
| Reference | INT \| Validation Scenarios | core.agent_evaluation_* + runtime.v_work_health_v1 hold the live form |
| Reference | OPS \| Friday Systems Review (Widgets) | core.agent_evaluation_* + runtime.v_work_health_v1 hold the live form |
| Seeing | SYS \| Creative OS Database | runtime.work_queue + core.work_definitions already hold the flow |
| Spine | SYS \| Master Workflow + Database Connections + Virtual Staff | core.database_registry + runtime.processor_registry supersede it |
| Task | OPS \| Daily Briefing Log | runtime.v_processor_run_outcomes_v2 + digest receipts |

---

## Sources

Live reads 8 November 2026: core.governance_decisions (GOV-MASTER-20261101 M1 to M9; GOV-20261031-NOTION-RETRIEVAL-LAYER, retired), core.record_governance_decision_v1 signature, core.database_registry, mirror.pages joined to the registry by data source id, intake.items, finance.invoices and payment_events, outbound.processor_state and meeting_sweep_runs, runtime.processor_registry, cron.job, information_schema for every schema named. Notion: PLAN | BUILD PHASE 2 — RETRIEVAL LANE; BRIEF | LLM READ PATH + RECORD SPINE; SYSTEM | MODEL CONTEXT MAP. Kellie's direction, Claude Code session, 8 November 2026.

---

*Working draft. The ruling in section 1 is recorded in Supabase with this document's hash as the approved package. Sections 4 and 6 are the build; Appendix B is generated by rule and checked by hand. Comments and corrections: open an issue on this repository.*

---

[← Back to “How we work with AI”](https://kelliepatry.com/notes/how-we-work-with-ai) · [Field Notes](https://kelliepatry.com/notes) · [Home](https://kelliepatry.com/)
