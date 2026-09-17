# SCHEMATIC | Institutional Memory Layer — pgvector + Storage

**Status:** Draft v0.2 · Validated against the live Studio Home project on 2026-09-17 · Hardened · **Unratified**
**Supersedes:** Draft v0.1 (the "fits existing `core`/`restricted` schemas, no new schema, no new role" version).
**Governing documents:** SPEC | NOTION → SUPABASE MIGRATION — CLEAN SLATE V1.0 (D1–D10, ratified 2026-08-18) · `memory.policies.canonical_system_mesh_placement` (REUSE → EXTEND → LINK → PROJECT/VIEW → CREATE) · `memory.get_embedding_gate_v1()` (benchmark-before-ANN rule).

---

## 0 · Verdict

v0.1 is directionally right (pgvector in Postgres, one recall contract, Storage for drawing sets, Red Zone never embedded) and structurally wrong in four places that would each have failed on contact with the live project:

1. **A memory layer already exists.** Schema `memory` (21 tables) ships `memory.embeddings`, `memory.source_links` (with `rag_document_id` / `rag_chunk_id`), `memory.retrieval_runs`, `memory.retrieval_results`, `memory.retrieval_benchmarks`, `memory.maintenance_jobs`, and a ratified placement policy that forbids creating a parallel store. `core.embedding` and `core.embedding_queue` are the parallel store that policy forbids.
2. **A ratified gate blocks ruling F as written.** `memory.get_embedding_gate_v1()` returns `BENCHMARK_REQUIRED` and `ann_index_allowed = false` until ten governed benchmark queries exist and structured retrieval quality is measured. Provider, model, dimensions and the HNSW index cannot be ratified before that. Live: 0 active benchmarks, 0 retrieval runs, 0 embeddings.
3. **`fn_recall` cannot embed in-function via pg_net.** pg_net is asynchronous (returns a request id; the body lands later in `net._http_response`). A SQL function cannot wait for it. The synchronous `http` extension is installed, but the read-only agent roles cannot read Vault, and a `SECURITY DEFINER` wrapper would let any read-only session spend the provider budget and ship query text off-platform. The contract has to split.
4. **Storage RLS for `kphd_sync` / `kphd_agent` is a category error.** Those roles are `NOLOGIN` Postgres roles reached by `SET ROLE` from `postgres`; the Storage API authenticates JWT roles (`anon`, `authenticated`, `service_role`). Neither `kphd_*` role has `USAGE` on `storage`. Object access for the pipeline is `service_role` inside Edge Functions; for people it is `authenticated` + project membership; for agents it is metadata through a `core` view and signed URLs minted by an Edge Function.

Everything below is the corrected design. Nothing has been applied to the project.

---

## 1 · Validation findings

Evidence state: **Confirmed** = live pull 2026-09-17 unless marked otherwise.

| # | v0.1 claim | Live fact (Confirmed) | Verdict | Correction carried into v0.2 |
|---|---|---|---|---|
| 1 | "Fits existing `core`/`restricted`, no new schema" | Schemas in use: `mirror`, `core` (200 tables), `restricted`, `memory` (21), `design` (19), `finance` (13), `runtime` (10), `research`, `integration`, `outbound`, `portal`, `web`, `guard`, `intake`, `telemetry`, `client_api`, `studio_auth`. | Stale premise | Design targets `memory` (embeddings, chunks, retrieval) and `core` (asset linkage). No new schema is still true. |
| 2 | New `core.embedding` table | `memory.embeddings` exists: `embedding_id, memory_version_id, embedding_provider, embedding_model, dimensions, embedding vector, is_current, created_at, archived_at`. 0 rows. Placement policy: REUSE → EXTEND → LINK → CREATE. | Violates placement policy | **EXTEND** `memory.embeddings` with a nullable `source_chunk_id`; add `memory.source_chunks` as the chunk store keyed to the existing `memory.source_links`. No `core.embedding`. |
| 3 | `vector(1536)` column + HNSW index | `memory.embeddings.embedding` is untyped `vector` (no dimension). HNSW requires a typed dimension. Gate says `ann_index_allowed = false`. | Blocked twice | Keep the column untyped so several models can coexist (schema already records provider/model/dimensions per row). Build the ANN index as a partial expression index `((embedding::vector(1536)) vector_cosine_ops) where dimensions = 1536 and is_current` **after** the gate flips. |
| 4 | `core.embedding_queue` on pgmq | `pgmq` 1.5.1 is available, **not installed**. pgmq queues live in schema `pgmq`, never in `core`. `pgmq.pop`/`pgmq.delete` delete rows, which collides with D7's posture. `memory.maintenance_jobs` already exists with `job_type, status, idempotency_key, attempt_count, claimed_at, worker_id, last_error_*`. | Reject pgmq | **REUSE** `memory.maintenance_jobs` with `job_type = 'embed_chunk'`. No new extension, no deletes, idempotency key built in. |
| 5 | pg_cron every 2 min → pg_net → Edge Fn | Existing convention is `runtime.enqueue_processor_http_v1(...)` (pg_net wrapper writing `runtime.processor_http_requests`) with `x-cron-secret` from Vault, plus `runtime.processor_registry` and the processor-ledger sweep. All 34 live jobs use it. | Align | Embed worker is scheduled through the same wrapper and registered in `runtime.processor_registry`; the cron body no-ops when no `queued` job exists so the 2-minute cadence costs nothing idle. |
| 6 | `fn_recall(q text …)` embeds via pg_net in-function | pg_net is async. `kphd_agent` and `kphd_sync` already hold EXECUTE on `net.http_post` (pre-existing exposure, noted). Vault is readable only by `postgres`. | Not implementable as written | Split contract (§5): `memory.recall_v1(p_query_text, p_query_embedding, …)` in SQL, plus Edge Function `memory-recall` that embeds the query and calls it. Keyword-only recall works today with no provider. |
| 7 | `kphd_agent: select-only` calls `fn_recall` | Recall must log to `memory.retrieval_runs` / `retrieval_results` (INSERT). Existing pattern: `SECURITY DEFINER`, pinned `search_path`, EXECUTE revoked from `public`, granted to named roles (`harden_rpc_execution_surface_v1`, `restrict_new_security_definer_execute_drift`). | Adjust | `memory.recall_v1` is `SECURITY DEFINER`, `search_path = ''`, EXECUTE granted to `kphd_agent` and the five persona forks only. |
| 8 | "Grants to both roles" | Eleven `kphd_*` roles exist. Agent persona forks (`kphd_agent_alex/cameron/minh/reese/riley`) receive grants individually, not through membership. `ALTER DEFAULT PRIVILEGES` covers `kphd_agent` SELECT on new `core`/`mirror` tables only, not `memory`. | Incomplete | Every new object grants `kphd_sync` (I/S/U) and all six agent roles (S) explicitly, in the same migration. |
| 9 | RLS not mentioned for new tables | Every `core`/`memory`/`mirror` table has RLS enabled; 12 tables already sit in the `rls_enabled_no_policy` advisor list. Policy naming convention: `<table>_context_read` (agents), `<table>_sync_insert/select/update` (sync). | Gap | RLS enabled + full policy set in the foundation migration. Never add to the no-policy list. |
| 10 | Sources: "decisions, meetings, protocols, specs" in `core` | `core.decisions` = 35 rows (immutable via `prevent_event_mutation`). Meetings and protocols are not `core` tables; they are `mirror.pages` (13,182 rows, 4,906 with bodies, ~30 M chars of `content_md`, p50 2.4 k chars, max 262 k). Specs = `core.project_specification_revisions` (103). | Wrong source map | Corpus v1 = `mirror.pages.content_md` (Canonical only) + `core.decisions` + `core.project_specification_revisions` + `memory.versions` (memory items). |
| 11 | Trigger on insert/update enqueues re-embed | Daily sync upserts every mirrored page (`synced_at` moves). An unconditional update trigger re-enqueues ~13 k rows per day. | Cost/noise | Trigger fires only `WHEN (old.content_md IS DISTINCT FROM new.content_md)`; chunk `content_hash` skips unchanged chunks on the worker side too. |
| 12 | Red Zone: "rows from `restricted.*` never land here" | Correct but insufficient. `mirror.pages` carries no restricted flag; `core.database_registry.restricted` is the flag (all 322 currently `false`), and it keys on the registry **row** page id, not the Notion database id. The join is `regexp_replace(data_source_url, '^collection://', '')::uuid = mirror.pages.notion_db_id`, guarded for malformed URLs (stored verbatim, e.g. `'1135'`) and duplicate registry rows (`bool_or(restricted)`). | Gap | Enqueue trigger and worker both refuse pages whose registry rows are restricted, missing, or malformed (fail closed). `restricted.*` tables get no trigger and no chunk store in v1. |
| 13 | New `core.document_asset` | Overlaps `core.deliverables` (sheet: `register_code`, `register_serial`, `phase_definition_id`, `project_id`) + `core.deliverable_versions` (revision: `version_label`, `source_uri`, `content_fingerprint`, `source_id`) + `core.source_artifacts` (6,274 rows; `source_system`, `source_uri`, `content_fingerprint`) + `core.media_assets` (`original_bucket`, `original_object_path`, `sha256`) + `design.layout_manifests`/`layout_manifest_output_bindings` (already bind LayOut output to `deliverable_version_id`). | Violates placement policy | **LINK**: a Storage object becomes a `core.source_artifacts` row (`source_system = 'supabase_storage'`) referenced by `core.deliverable_versions.source_id`. Revision chain = versions of one deliverable; add nullable `supersedes_deliverable_version_id` only if ordering by `created_at` proves insufficient. |
| 14 | Phase as free text `SD/DD/CD/Permit` | `core.phase_definitions` (162 rows, `phase_code`) is the vocabulary (D6: lookups, never enums). `design.layout_manifests.phase_code` already uses it. | Align | Path segment and metadata use `phase_code` from `core.phase_definitions`. |
| 15 | Bucket `evidence` | Buckets: `project-media-originals`, `project-media-derivatives`, `studio-artifacts-backup`, `studio-portal-capture`. One object exists in total. "Evidence" already names `core.*_evidence_links` and `studio_bridge_evidence`. | Naming collision | Bucket `project-deliverables` (private), naming aligned with `project-media-*`. |
| 16 | Edge Fn runs `pdftotext` | Deno Edge runtime has no system binaries. `core.qnap_file_versions` already models `parse_status`, `text_excerpt`, `search_document` for NAS files (pipeline built, 0 rows). | Not implementable as written | Text extraction in-function with a pure-JS PDF parser on per-sheet PDFs (size-capped), or via the QNAP source bridge for full sets. Extraction output lands in `memory.source_chunks`, never in a new column. |
| 17 | Key in Supabase Vault | Vault (extension, schema owned by `supabase_admin`, 8 secrets today) serves DB-side callers. The embedding call happens in the Edge Function, which reads Edge Function secrets (env), not Vault. | Misplaced | Provider key = Edge Function secret. Vault holds only what pg_cron needs (`meeting_cron_secret`, `studio_project_url`, already present). |
| 18 | Backfill in 120-row batches | 120 is the Notion pagination constant. Provider batching is bounded by tokens per request and rate limits, not rows. | Wrong unit | Batches of ≤ 64 chunks, ≤ 8,000 tokens per chunk, retry with backoff on 429 (existing `harness_explicit_429_retry_v1` pattern). Parity = current chunks with a current embedding vs. chunks expected from `content_hash`. |
| 19 | Sequence names `wave3_*` | Spec waves are Notion-migration waves; Wave 3 = Reference Library. Migration naming in the project is feature-scoped (`memory_*`, `create_memory_*`). | Rename | `memory_semantic_layer_v1_<step>`. |
| 20 | Provider: OpenAI `text-embedding-3-small` | `memory.policies.allowed_providers = {openai, anthropic, internal}` on every active policy. Edge runtime ships `Supabase.ai.Session('gte-small')` (384-dim, in-platform, 512-token window). | Both admissible | Ruling reframed (§8): benchmark both against the ten governed queries, ratify one as `is_current`, keep the other available. |

Pre-existing items surfaced, not this design's to fix but relevant: `kphd_agent` holds EXECUTE on `net.http_post`/`http_get`; `core.source_capture_fingerprints` has RLS disabled; 12 tables have RLS without policies; 33 unindexed FKs; 491 unused indexes. Recommend a separate hygiene ticket.

---

## 2 · Hardened architecture

```
                    ┌──────────────── enqueue side ────────────────┐
Notion ── notion-sync ──▶ mirror.pages ──(content_md changed AND registry.restricted = false)──┐
core.decisions (insert) ──────────────────────────────────────────────────────────────────────┤
core.project_specification_revisions (insert) ────────────────────────────────────────────────┤
memory.versions (insert) ─────────────────────────────────────────────────────────────────────┤
                                                                                              ▼
                                                        memory.source_links (existing; one per source row)
                                                                                              │
                                                        memory.source_chunks (NEW; chunk_ix, content, content_hash, tsvector)
                                                                                              │
                                                        memory.maintenance_jobs (existing; job_type = 'embed_chunk')
                                                                                              │
             pg_cron */2 ──▶ runtime.enqueue_processor_http_v1 ──▶ Edge Fn: memory-embed ──▶ memory.embeddings (existing; + source_chunk_id)
             (no-op when queue empty)                              (service_role · Edge secret)   provider/model/dims per row · is_current

Drawing sets:
LayOut / PDF export ──▶ bucket project-deliverables ──▶ storage.objects INSERT trigger ──▶ core.source_artifacts (supabase_storage)
      path {project_code}/{phase_code}/{register_code}-{serial}/r{rev}/{file}     └──▶ core.deliverable_versions.source_id (LINK)
                                                                                    └──▶ memory.source_links → chunks (text extracted)

Query side:
Claude / GPT / Riley ──▶ memory.recall_v1(p_query_text, p_query_embedding, p_project_id, p_phase_code, p_k)
   (SET ROLE kphd_agent*)     ├─ keyword leg: tsvector on source_chunks + memory.items.search_vector   (works today)
                              ├─ semantic leg: cosine over memory.embeddings where is_current           (after gate)
                              └─ writes memory.retrieval_runs / retrieval_results (SECURITY DEFINER, pinned search_path)
HTTP callers ──▶ Edge Fn: memory-recall  (embeds query, then calls memory.recall_v1)
```

Red Zone: no trigger on `restricted.*`; no chunk store for restricted content in v1. If restricted recall is ever wanted it is a separate `restricted.source_chunks` / `restricted.embeddings` pair with no agent grants, ratified per Wave 4 rules. Not designed here.

---

## 3 · Objects (EXTEND / LINK; no parallel store)

### `memory.source_chunks` (new, in the existing memory domain)
- `source_chunk_id uuid pk` · `source_link_id uuid → memory.source_links` · `chunk_ix int`
- `content text` · `content_hash text` (sha256 of normalized content) · `token_estimate int`
- `search_vector tsvector generated` · `metadata jsonb` (project_id, phase_code, notion_db_id, source_edited_at)
- `is_current boolean default true` · `created_at` · `archived_at` (soft-delete only, D7)
- unique `(source_link_id, chunk_ix) where is_current` · GIN on `search_vector` · index on `content_hash`

### `memory.embeddings` (existing; extend)
- add `source_chunk_id uuid null → memory.source_chunks`
- add check: exactly one of `memory_version_id`, `source_chunk_id` is not null
- add `content_hash text` (copied from the chunk at embed time; re-embed only when it changes)
- unique `(source_chunk_id, embedding_model) where is_current and source_chunk_id is not null`
- **no ANN index in the foundation migration** (gate)

### `memory.maintenance_jobs` (existing; reuse)
- `job_type = 'embed_chunk'`, `idempotency_key = source_chunk_id || ':' || content_hash`, `metadata = {source_chunk_id, model}`
- states: `queued → claimed → done | failed` via existing columns; failures retry with `attempt_count`, never deleted

### `core.source_artifacts` + `core.deliverable_versions` (existing; link)
- Storage object row: `source_system = 'supabase_storage'`, `source_kind = 'deliverable_pdf'`, `source_key = bucket/object_path`, `source_uri = storage://…`, `content_fingerprint = sha256`, `metadata = {bytes, mime, sheet, rev, source_app}`
- `core.deliverable_versions.source_id` points at it; `version_label = 'r{rev}'`
- No `core.document_asset`. No DELETE; superseded revisions remain as older versions of the same deliverable.

### `core.v_deliverable_assets` (new view, PROJECT step)
- Read-only join of deliverables × versions × source_artifacts for agent consumption; grants SELECT to the six agent roles. Agents never touch `storage.*`.

---

## 4 · Storage

- Bucket `project-deliverables`, private, `file_size_limit` 100 MB, allowed MIME `application/pdf`, `application/zip` (LayOut `.layout` bundles), `image/svg+xml`.
- Path: `{project_code}/{phase_code}/{register_code}-{register_serial}/r{rev}/{filename}` · `project_code` from `core.projects`, `phase_code` from `core.phase_definitions`.
- Trigger on `storage.objects` INSERT (bucket filter) → `runtime.enqueue_processor_http_v1` → Edge Fn `deliverable-ingest`: parse path, upsert `core.source_artifacts`, link/create `core.deliverable_versions`, extract text (per-sheet PDFs ≤ 20 MB in-function; larger sets routed to the QNAP source bridge), write `memory.source_links` + `memory.source_chunks`, enqueue `embed_chunk` jobs.
- RLS on `storage.objects` for this bucket: `service_role` full (Edge Functions); `authenticated` SELECT where `core.portal_project_members` (existing portal membership) matches the first path segment's project; no `anon`. `kphd_*` roles: none (they read `core.v_deliverable_assets`).
- Uploads for the pilot go through the existing `studio-artifact-backup-once` / portal provisioning pattern or the Dashboard; the ingest trigger is the only write path into `core`.

---

## 5 · Recall contract

```sql
memory.recall_v1(
  p_query_text      text,
  p_query_embedding vector default null,   -- null ⇒ keyword-only
  p_project_id      uuid default null,
  p_phase_code      text default null,
  p_k               int  default 8,
  p_session_id      uuid default null
) returns table (
  rank int, final_score numeric, semantic_score numeric, keyword_score numeric,
  chunk text, source_system text, source_record_type text, source_record_id text,
  notion_page_id uuid, source_uri text, project_id uuid, phase_code text, source_chunk_id uuid
)
```
- `SECURITY DEFINER`, `SET search_path = ''`, EXECUTE revoked from `public`, granted to `kphd_agent` and the five persona forks. Logs one `memory.retrieval_runs` row and its `retrieval_results`.
- Hybrid rank: reciprocal-rank fusion of the keyword leg and, when an embedding is supplied and the gate is `EVALUATION_READY`, the semantic leg. Authority weighting reuses `memory.items.authority_level` for memory-item hits.
- Edge Fn `memory-recall` (`x-cron-secret`-style header auth, `service_role` inside) embeds `p_query_text` with the ratified model and calls the same function. One SQL contract, two entry points.
- Restricted content is structurally absent, so no per-query redaction is needed in v1.

---

## 6 · Security posture

- **Grants:** `kphd_sync` I/S/U on `memory.source_chunks`; six agent roles SELECT; nobody DELETE (D7). `memory.embeddings` writes come only from the Edge worker (`service_role`) through `memory.upsert_chunk_embedding_v1`, `SECURITY DEFINER`, EXECUTE granted to `service_role` only.
- **RLS:** enabled on `memory.source_chunks` with `source_chunks_context_read` (six agent roles), `source_chunks_sync_insert/select/update` (`kphd_sync`), `source_chunks_service_all` (`service_role`).
- **Red Zone, fail closed:** enqueue trigger and worker both require a registry match with `restricted = false`; unmatched, malformed, or duplicated-and-any-restricted rows are skipped and counted in `mirror.parity_log`.
- **Secrets:** provider key as Edge Function secret only. Vault untouched except reuse of `meeting_cron_secret` / `studio_project_url` for the cron→function hop.
- **Egress:** only `memory-embed` and `memory-recall` call the provider. No SQL path reaches the provider. Recommend revoking `net.http_post` from `kphd_agent` in the hygiene ticket; this design does not depend on it.
- **Immutability:** `core.decisions` and `core.source_artifacts` already carry `prevent_event_mutation`; the design only inserts.

---

## 7 · Sequence (gate-first)

| Step | Migration / action | Acceptance |
|---|---|---|
| 0 | **Benchmark seed.** Insert ≥ 10 governed queries into `memory.retrieval_benchmarks` with `expected_memory_ids` (Kellie supplies or confirms the questions). Run keyword-only `recall_v1` and record baseline precision@k in `retrieval_runs`. | `memory.get_embedding_gate_v1().status = 'EVALUATION_READY'` |
| 1 | `memory_semantic_layer_v1_foundations` — `source_chunks`, `embeddings` extension, `upsert_chunk_embedding_v1`, `recall_v1` (keyword leg live), RLS + grants, enqueue triggers, processor registration. | Advisors clean for new objects; keyword recall returns ranked chunks for the benchmark set. |
| 2 | Chunk backfill (session-side `execute_sql`, idempotent on `content_hash`): Canonical `mirror.pages` bodies, `core.decisions`, `core.project_specification_revisions`, `memory.versions`. | Parity: chunks per source table vs. eligible source rows; restricted-skip count reported. |
| 3 | Deploy `memory-embed`; embed the benchmark corpus with **both** candidate models; record `retrieval_runs` per model. | Precision@8 per model, cost per 1 k chunks, latency. Ruling F decided on evidence. |
| 4 | Ratify provider (§8). `memory_semantic_layer_v1_ann_index` — partial HNSW on the ratified dimension; flip `ann_index_allowed` in the gate function; full embed backfill. | Embedding parity = current chunks with a current embedding of the ratified model. |
| 5 | `memory_semantic_layer_v1_deliverables` — bucket, Storage trigger, `deliverable-ingest`, `core.v_deliverable_assets`, storage RLS. | One real sheet round-trips: upload → artifact → version → chunks → recall hit. |
| 6 | Drawing backfill for the three active projects (pilot). | Every current sheet has a `deliverable_version` with a Storage-backed `source_id`. |
| 7 | Close-out: advisors (security + performance) → spec stamp on the migration spec page → execution-queue sweep. | Standard wave close-out. |

Steps 0 and 3 are the ones v0.1 lacked; everything else is v0.1 re-homed onto existing objects.

---

## 8 · Ruling F — embedding provider (reframed)

v0.1 asked "OpenAI `text-embedding-3-small`, key in Vault: yes/no?". The live gate makes a bare yes/no non-compliant. The ruling is now two-part:

**F1 (rule now):** Authorise the benchmark set (Step 0) and the two-model bake-off (Step 3). Candidates: `openai/text-embedding-3-small` (1536-dim, 8 k-token window, external call, low cost) and `internal/gte-small` via `Supabase.ai` in the Edge runtime (384-dim, 512-token window, no egress, no cost). Both are already in `memory.policies.allowed_providers`. F1 must also state the **egress clause**: nearly every project memory space is `sensitivity = 'confidential'`, so choosing the external model means confidential (never restricted) project text is sent to the provider under its API data-use terms. Ruling that explicitly, once, is what makes the later per-row `embedding_provider` value defensible.

**F2 (rule after Step 3):** Ratify one model as `is_current` for `source_chunks` embeddings on the evidence. Recommendation going in: `text-embedding-3-small`, because Notion page bodies (p50 2.4 k chars, long tail to 262 k) chunk better under the 8 k window, and one model serves Claude and GPT sessions identically. `gte-small` stays available as the no-egress fallback if the egress clause is declined for confidential spaces, in which case confidential spaces embed in-platform and only `internal` spaces use the external model.

Key placement under either outcome: Edge Function secret. Not Vault.

---

## 9 · Draft DDL — `memory_semantic_layer_v1_foundations` (idempotent; NOT applied)

Review copy. Apply only via `apply_migration` after F1 is ruled and Step 0 passes. Grants are spelled out per role because `ALTER DEFAULT PRIVILEGES` does not cover `memory`.

```sql
-- 1. chunk store -----------------------------------------------------------
create table if not exists memory.source_chunks (
  source_chunk_id uuid primary key default gen_random_uuid(),
  source_link_id  uuid not null references memory.source_links(source_link_id),
  chunk_ix        integer not null,
  content         text not null,
  content_hash    text not null,
  token_estimate  integer,
  metadata        jsonb not null default '{}'::jsonb,
  search_vector   tsvector generated always as (to_tsvector('simple', coalesce(content,''))) stored,
  is_current      boolean not null default true,
  created_at      timestamptz not null default now(),
  archived_at     timestamptz
);
create unique index if not exists source_chunks_current_uq
  on memory.source_chunks (source_link_id, chunk_ix) where is_current;
create index if not exists source_chunks_search_idx on memory.source_chunks using gin (search_vector);
create index if not exists source_chunks_hash_idx   on memory.source_chunks (content_hash);
create index if not exists source_chunks_meta_project_idx
  on memory.source_chunks ((metadata->>'project_id'), (metadata->>'phase_code'));

-- 2. extend embeddings (no ANN index here; see gate) -----------------------
alter table memory.embeddings add column if not exists source_chunk_id uuid references memory.source_chunks(source_chunk_id);
alter table memory.embeddings add column if not exists content_hash text;
do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'embeddings_one_subject_ck') then
    alter table memory.embeddings add constraint embeddings_one_subject_ck
      check (num_nonnulls(memory_version_id, source_chunk_id) = 1);
  end if;
end $$;
create unique index if not exists embeddings_chunk_model_current_uq
  on memory.embeddings (source_chunk_id, embedding_model) where is_current and source_chunk_id is not null;
create index if not exists embeddings_source_chunk_idx on memory.embeddings (source_chunk_id);

-- 3. RLS ---------------------------------------------------------------------
alter table memory.source_chunks enable row level security;
drop policy if exists source_chunks_context_read on memory.source_chunks;
create policy source_chunks_context_read on memory.source_chunks for select
  to kphd_agent, kphd_agent_alex, kphd_agent_cameron, kphd_agent_minh, kphd_agent_reese, kphd_agent_riley
  using (archived_at is null);
drop policy if exists source_chunks_sync_select on memory.source_chunks;
create policy source_chunks_sync_select on memory.source_chunks for select to kphd_sync using (true);
drop policy if exists source_chunks_sync_insert on memory.source_chunks;
create policy source_chunks_sync_insert on memory.source_chunks for insert to kphd_sync with check (true);
drop policy if exists source_chunks_sync_update on memory.source_chunks;
create policy source_chunks_sync_update on memory.source_chunks for update to kphd_sync using (true) with check (true);
drop policy if exists source_chunks_service_all on memory.source_chunks;
create policy source_chunks_service_all on memory.source_chunks for all to service_role using (true) with check (true);

-- 4. grants (no DELETE anywhere — D7) ---------------------------------------
grant usage on schema memory to kphd_sync, kphd_agent, kphd_agent_alex, kphd_agent_cameron, kphd_agent_minh, kphd_agent_reese, kphd_agent_riley;
grant select, insert, update on memory.source_chunks to kphd_sync;
grant select on memory.source_chunks
  to kphd_agent, kphd_agent_alex, kphd_agent_cameron, kphd_agent_minh, kphd_agent_reese, kphd_agent_riley;

-- 5. Red Zone eligibility (fail closed) --------------------------------------
create or replace function memory.page_is_embeddable_v1(p_notion_db_id uuid)
returns boolean language sql stable set search_path = '' as $$
  select coalesce(
    (select not bool_or(r.restricted)
       from core.database_registry r
      where r.data_source_url ~ '^collection://[0-9a-f-]{36}$'
        and regexp_replace(r.data_source_url, '^collection://', '')::uuid = p_notion_db_id),
    false);   -- no registry match ⇒ not embeddable
$$;
revoke execute on function memory.page_is_embeddable_v1(uuid) from public;

-- 6. enqueue: mirror.pages body change --------------------------------------
create or replace function memory.enqueue_page_chunking_v1()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_link uuid;
begin
  if new.archived_at is not null or coalesce(length(new.content_md),0) = 0 then return new; end if;
  if not memory.page_is_embeddable_v1(new.notion_db_id) then return new; end if;
  insert into memory.source_links (space_id, source_system, source_record_type, source_record_id, notion_page_id, source_hash, source_timestamp)
  values ((select space_id from memory.spaces where scope_type = 'studio' limit 1),
          'notion', 'page', new.notion_page_id::text, new.notion_page_id, md5(new.content_md), new.notion_edited_at)
  on conflict do nothing;
  insert into memory.maintenance_jobs (job_type, status, idempotency_key, metadata)
  values ('chunk_source', 'queued', 'chunk:notion:' || new.notion_page_id || ':' || md5(new.content_md),
          jsonb_build_object('source_system','notion','notion_page_id',new.notion_page_id))
  on conflict (idempotency_key) do nothing;
  return new;
end $$;
drop trigger if exists trg_mirror_pages_enqueue_chunking on mirror.pages;
create trigger trg_mirror_pages_enqueue_chunking
  after insert or update of content_md on mirror.pages
  for each row when (old.content_md is distinct from new.content_md)
  execute function memory.enqueue_page_chunking_v1();
-- (equivalent AFTER INSERT triggers on core.decisions, core.project_specification_revisions, memory.versions;
--  none on restricted.*)

-- 7. recall (keyword leg live now; semantic leg activates when an embedding is passed
--    and the gate reports EVALUATION_READY) --------------------------------
--    body omitted from the review copy; contract in §5. SECURITY DEFINER, search_path '',
--    revoke from public, grant execute to the six agent roles.

-- 8. processor registration -----------------------------------------------
insert into runtime.processor_registry (processor_key, lane, cron_job_name, capability, execution_mode, status, authority_class, notes)
values ('memory-embed', 'memory', 'memory-embed-sweep', 'embed_chunk', 'http', 'planned', 'system',
        'Drains memory.maintenance_jobs job_type=embed_chunk via Edge Fn memory-embed')
on conflict (processor_key) do nothing;
```

`memory.maintenance_jobs` needs a unique index on `idempotency_key` if one does not already exist; verify before applying (`\d memory.maintenance_jobs`).

The ANN index, for the later migration, on the assumption the ruling lands on 1536 dimensions:

```sql
create index if not exists embeddings_hnsw_1536_cos
  on memory.embeddings using hnsw ((embedding::vector(1536)) vector_cosine_ops)
  where is_current and dimensions = 1536;
```

---

## 10 · Open items and assumptions

- **Confirmed:** `memory.maintenance_jobs.idempotency_key` is unique-indexed (`maintenance_jobs_idempotency_key_key`); the `on conflict (idempotency_key)` clause in §9 is valid.
- **Confirmed:** `memory.spaces` holds one `studio` space and one `project` space per active project. Source links hang on the project space when the source row resolves to a `project_id`, otherwise on the studio space. Nearly every project space carries `sensitivity = 'confidential'`; this is the basis for the egress clause in F1.
- **Confirmed:** portal membership table is `public.portal_project_memberships`; storage RLS for the deliverables bucket joins it.
- **Confirmed:** 310 of 322 registry rows carry a well-formed `collection://<uuid>` data-source URL; the other 12 fail closed under `memory.page_is_embeddable_v1` and must be listed in the Step 2 parity report.
- **Kellie rulings required (queued on the execution tracker):** F1 now (benchmark set, bake-off, egress clause); F2 after the bake-off; the ten benchmark questions for Step 0.
- **Hygiene ticket (separate):** revoke `net.http_post` from agent roles; RLS policies for the 12 policy-less tables; `core.source_capture_fingerprints` RLS.
- This file lives in a public profile repository. It deliberately carries no project reference, no client names, no secrets, and no fee-adjacent content. Keep it that way or move it to the private docs surface before adding operational detail.
