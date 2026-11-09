---
name: kphd-supabase
description: Operating rules for Kellie's KPHD Supabase project (Studio Home, qdgfcwdbzxxmhduhxcmj, ca-central-1, Pro plan) — the target of the Notion → Supabase clean-slate migration (SPEC V1.0, D1–D10). ALWAYS use this skill before any Supabase operation in this workspace — DDL, migrations, SQL execution, registry ingest, role/grant changes, advisors, parity checks, or wave work. Also use when Kellie says "run the migration", "next batch", "ingest", "parity check", "advisors", "stamp the spec", or references mirror/core/restricted schemas, kphd_sync, or kphd_agent. Defines guardrails that MUST NOT be violated (no DELETE grants, no vault schema, idempotent DDL only).
---

# KPHD Supabase Operating Rules

Target: Supabase project **Studio Home** (`qdgfcwdbzxxmhduhxcmj`, ca-central-1, Pro plan). Governing document: SPEC | NOTION → SUPABASE MIGRATION — CLEAN SLATE, V1.0, decisions D1–D10 (Notion page `3c1732ea-2011-814f-8ed7-cb49b78facae`).

## Standing SQL authorization — A9

Per `GOV-20261109-A9-STANDING-SQL-AUTHORIZATION` (spec amendment A9, ruled 2026-11-09), Claude Code and Claude may run SQL on Studio Home (`execute_sql`, `apply_migration` and the read-only tools) without asking for per-session or per-statement approval. Do not ask Kellie to "proceed" before routine SQL. The guardrails below still apply. So does GOV-20261106-SAFETY-GATE-READS-CODE: routine changes go through the controlled change path. Code that touches money, access or owner rights, deletion, outside sends, the approval machinery or a stored read of a person still needs Kellie's exact authorization. Widening access needs its own named ruling.

## Hard guardrails — never violate

1. **No DELETE, ever.** Per decision D7, no role is granted DELETE. Never grant DELETE, never issue DELETE statements against registries, never work around this with TRUNCATE or DROP on populated tables. Deletions happen only by explicit ratified spec amendment.
2. **`vault` schema is reserved.** Owned by supabase_admin for the Vault secrets extension (`vault.secrets`). Never create, alter, or reference `vault` as a project schema. The restricted/Red Zone layer lives in `restricted`.
3. **All DDL goes through `apply_migration`**, never `execute_sql`. Migration names are snake_case, prefixed by wave (e.g. `wave0_foundations`, `wave0_fix_audit_fn`).
4. **All DDL must be idempotent.** Use `create schema if not exists`, `create table if not exists`, `create index if not exists`, and `drop trigger if exists` before recreating triggers. Re-running unguarded DDL fails on duplicate objects.
5. **DML/data operations go through `execute_sql`** and must be idempotent upserts — never blind inserts into registries.

## Schemas and roles

- Schemas: `mirror` (Notion mirrors), `core` (registries, agent logs), `restricted` (Red Zone).
- `kphd_sync`: select/insert/update on mirror and core registries; insert on `core.audit_log`. No DELETE.
- `kphd_agent`: select-only. (Fork `kphd_agent_riley` governs the Riley Chen persona boundary — see riley-chen skill.)
- New objects in these schemas require grants re-issued to both roles in the same migration.

## Registry ingest pattern

Source: Notion database registry, collection `c7d9804d-de6d-4662-9151-ab006b422f55`.

- Notion SQL paginates at ~100 rows regardless of LIMIT. Reliable pattern: `ORDER BY u LIMIT 120 OFFSET N`, advance by batch, stop when `has_more` is false.
- Cast Notion page IDs as `'32hexstring'::uuid`.
- Upsert form: `insert ... on conflict (notion_page_id) do update set name = excluded.name, ..., synced_at = now()`.
- Malformed `data_source_url` values (e.g. bare `'1135'`, `'https://www.notion.so/792'`) are stored **verbatim** — no transformation, no cleanup.
- After each batch, report rows affected and running total against the source count.

## Audit trigger pattern

Direct `record` → jsonb casting fails. Use a declared `rec jsonb` variable:

```sql
rec := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
```

## Standard wave close-out sequence

When a wave's ingest completes, run in order:

1. **Parity check** — row counts source vs target per registry; report any delta before proceeding.
2. **Advisors** — run both security and performance advisors (`get_advisors`); surface all findings, fix or explicitly defer each.
3. **Spec stamp** — append a build-log entry to the spec page in Notion (what ran, migrations applied, counts, date).
4. **Execution queue sweep** — any step only Kellie can do goes on the queue (`https://app.notion.com/p/9f8f4efe`) per the kphd-execution-queue skill.

## Reporting style

Action first, executive register. Lead with what was executed and the counts. Links at the bottom. No narration of tool mechanics.
