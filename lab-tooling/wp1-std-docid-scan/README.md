# WP-1 · STD- Doc ID workspace scan receipt

Brief: CLAUDE.md — STD | SPINE + STATE MACHINE WORK PATTERN, lab tooling v0.1 (WP-1, ruling R4 / GOV-20260910-04).
Session: `168bf88a-8430-4cfb-947c-1d45ba804af3` (memory.sessions, surface claude-code, continuation of 0e116ba9), bound to initiative `master-workflow-canonicalization` (binding 14e211aa-f8f3-442a-b6f4-03b1381c91de, explicit).
Scan run: 2026-09-11 (UTC), read-only. No serial minted. No Notion page created, moved, or archived by this scan.

Evidence labels: **Confirmed** = live pull this session; **Assumption** = labelled.

## Result (Confirmed)

| Item | Value |
|---|---|
| Workspace-wide max STD- serial observed | **STD-0006** |
| Registry (IDX \| Doc ID Registry) max for prefix STD | 6 (rows 1–6, all Status = Active) |
| Gaps in 1..6 | none |
| Collisions | **STD-0005** is carried by two pages: `STD-0005 \| STANDARD \| FINISH NOTES v2026.1 — KPHD MASTER` (registered) and `STD-0005 \| RUBRIC \| Lead Qualification Scoring` in AGT \| AGENT DEFINITIONS (not in the registry) |
| Unregistered STD- serials | STD-0005 (second bearer, above). No STD-0007 or higher found anywhere. |
| Correction to STD draft page | callout says "observed max STD-0005" → actual observed max is STD-0006 |

Next available serial by arithmetic is STD-0007. **Not issued** — issuance is Kellie's (execution-queue row filed; see below). Per §5 of the brief, Doc ID remains gated on the GPT/Codex review loop e4e520db (still open at scan time).

## Surfaces scanned

### A · Cross-checks (Confirmed)

| Surface | Method | Finding |
|---|---|---|
| IDX \| Doc ID Registry (`collection://d674594d-3e61-423a-9b37-63a33c79b4ef`) | SQL, `Prefix = 'STD'` | 6 rows: 0001 Content Strategy — KPHD · 0002 Project Page Naming Convention · 0003 Schema Definition & Controlled-Vocabulary Standard · 0004 MILLWORK & CARPENTRY NOTES · 0005 FINISH NOTES · 0006 Page Naming. Registry note on 0003/0005: prior collision resolved 2026-06-03. |
| Notion workspace title search `STD-` (title only, incl. archived) | notion-search | Serialled titles: STD-0001, 0002, 0003, 0004, 0005 (×2), 0006. Non-serial `STD \|` pages exist (Citation & Sourcing, Smart Architecture Principles, Built Context Registry, Supabase RLS floor, Layout Template Pipeline, Spec Property Schemas…) — no Doc ID, out of scope for max. `STD-SPEC-0001` and `HH.ALL.STD-001` are different namespaces, not STD- serials. |
| Notion search `STD-0007`, `STD-0008` | notion-search incl. archived | no bearer found |
| Supabase `mirror.pages` (13,100 rows) | regex `STD-\d{3,}` on title + properties | Same six serialled pages (STD-0001, 0002, 0003, 0005 RUBRIC, 0006 — 0004 not mirrored); five Marketing Knowledge pages match only because a text property references "STD-0001 AI Search spoke article priority list" (references, not Doc IDs). |

### B · IDX | Knowledge Database Registry — per-database scan

Registry data source: `collection://999c7bb3-7052-4c80-bab9-620f131746fd` (21 rows, all statuses).

Scan worker: read-only, SQL mode on every data source (one supplementary rows-mode formula filter on KNW | RESEARCH `note_id`). Finished 2026-09-11T21:21:12Z. BW.04 read as titles only; no figures read or recorded.

| # | Database | Data source | Title prop | Doc-ID prop | Rows | STD- hits | Tokens |
|---|---|---|---|---|---|---|---|
| 1 | AGT \| AGENT DEFINITIONS | `collection://311732ea-2011-81fe-aeda-000bc9e22949` | Title | none | 197 | 1 | STD-0005 (RUBRIC \| Lead Qualification Scoring) |
| 2 | BW.04 \| PROFORMA BASELINE | `collection://a53066bb-30a1-4002-9139-03f897dfa836` | Line Item | none | 15 | 0 | — |
| 3 | CIT \| CODE CITATIONS | `collection://6ef55997-413a-49a2-aec3-ecf77afcc00c` | Citation | none | 1 | 0 | — |
| 4 | CLIENT INTELLIGENCE | `collection://340732ea-2011-8111-a115-000b69a8321c` | Client Name | none | 9 | 0 | — |
| 5 | HUB \| DESIGN STATEMENTS | `collection://2f2732ea-2011-8151-b549-000b7845b6e2` | Title | none | 4 | 0 | — |
| 6 | HUB \| HUBS INDEX | `collection://2f3732ea-2011-818a-a079-000ba8a3a9fe` | Title | none | 16 | 0 | — |
| 7 | HUB \| INTELLIGENCE SYSTEM KNOWLEDGE | `collection://a04ffbc2-4b18-4445-89d3-a11a382bae0f` | Title | none | 35 | 0 | — |
| 8 | INTEL \| INTEL FINDINGS | `collection://fad085f3-684a-4eca-8d9d-aa7f05ef172a` | Finding | none | 4 | 0 | — |
| 9 | INTEL \| PEOPLE INTELLIGENCE | `collection://9107b3b9-04d6-4c1a-92a0-95bb221a7ee2` | Name | none | 1 | 0 | — |
| 10 | INTEL \| PROJECT INTELLIGENCE BRIEFS | `collection://7f29c063-657f-4b1f-a1fe-8096b4542dec` | Project Intelligence Brief | none | 2 | 0 | — |
| 11 | KNW \| AHJ & PERMITTING REFERENCE | `collection://e1e44f57-76cd-465c-8b8b-37c12ca8ae7e` | Title | Doc ID (text) | 4 | 0 | — |
| 12 | KNW \| CASE STUDIES & PROJECT KNOWLEDGE | `collection://1dd26a52-0a0c-4377-a5f8-e444a94ec2d0` | Case Study Title | none | 11 | 0 | — |
| 13 | KNW \| DESIGN PHILOSOPHY & LEADERSHIP | `collection://8673186a-4919-496f-b916-b9c2b2670f19` | Title | none | 19 | 0 | — |
| 14 | KNW \| MARKETING & CONTENT | `collection://d2d49a98-a1cd-4357-bb4b-b8adcae59277` | Content Title | none | 5 | 0 | — |
| 15 | KNW \| RESEARCH | `collection://4d84afd1-6d35-4265-997f-821a6b0e2130` | Title | note_id (formula) | 148 | 0 | — |
| 16 | PRO \| Protocols & SOPs | `collection://1c78e9f0-1c91-4c45-82c8-ccc2a07a91ce` | Title | Doc ID (text) | 163 | 0 | — |
| 17 | RESPONSES \| QUESTIONNAIRE INSTANCES | `collection://001268b1-b1a4-4912-baae-f48163fd6e5e` | Name | none | 0 | 0 | — |
| 18 | STD \| KPHD Standards | `collection://54b2750a-3038-4f49-87b8-5bd69c5d3d01` | Title | Standard Code (text) | 3 | 2 | STD-0004, STD-0005 (+ STD-SPEC-0001, other namespace) |
| 19 | Templates | `collection://2f2732ea-2011-8185-9e83-000bd328e1e3` | Title | none | 226 | 0 | — |
| 20 | TRACKER \| EMOTIONAL MILESTONES | `collection://cc11504a-dd5a-4d0b-87e7-0a38d3ec68e7` | Entry | none | 0 | 0 | — |
| 21 | WATCH \| Platform & API Updates | `collection://8e91c647-6862-482e-8ca8-310bda3ffb70` | Title | none | 20 | 0 | — |
| 22 | SKL \| Skills Library (not in registry; carries Doc IDs) | `collection://7ee7f407-89f6-4e18-abb9-91e275eaf6ab` | Skill Name | Doc ID (text) | 96 | 0 | — |
| 23 | IDX \| Doc ID Registry (not in registry) | `collection://d674594d-3e61-423a-9b37-63a33c79b4ef` | Title | Doc ID (formula) + Prefix/Number | 366 | 6 | STD-0001..0006 |

STD \| KPHD Standards, full row dump (3 rows): STD-0004 MILLWORK & CARPENTRY NOTES (Standard Code STD-0004, Status New Standard) · STD-0005 FINISH NOTES (STD-0005, New Standard) · STD \| SPEC PROPERTY SCHEMAS — PER-CLASS REQUIRED SETS & QA GATE (Standard Code STD-SPEC-0001, Active).

Observation (fact, no adjudication): registry rows STD-0001, 0002, 0003 and 0006 point to pages that live outside the 21 registry-listed databases (Marketing Knowledge; ADO \| Architecture Doc \| Knowledge ×2; db/ Database Migration Queue). They are reachable by workspace title search, which is why the cross-checks in §A are load-bearing for the max.

## Filing

- Execution-queue row: two rows in TRACKER | KELLIE EXECUTION QUEUE — `3d8732ea-2011-818f-b775-fb066b59d894` (Issue STD- Doc ID; Status Blocked on loop e4e520db) and `3d8732ea-2011-815f-8205-ce38370b1990` (Rule STD-0005 collision; one question, one recommendation)
- STD page change-log entry: callout corrected to "observed max STD-0006" and a `2026-09-11 · WP-1 STD- scan (R4)` line appended to the change log on page `3d7732ea-2011-8190-b368-f4f26607be68` (Claude draft; no ratified page edited)
- Checkpoint: `memory.close_session_v2` on session `168bf88a-8430-4cfb-947c-1d45ba804af3` (request key close-20260911-std-lab-tooling-01) with current_state, next_actions by owner, blockers, unresolved questions, and a GPT-readable handoff. WP-2 through WP-5 not started: open loop e4e520db (GPT/Codex Instance 01 review) was still open at close.
