# Claude Code notes for this repo

## Supabase (Studio Home, `qdgfcwdbzxxmhduhxcmj`)

Standing authorization `GOV-20261109-A9-STANDING-SQL-AUTHORIZATION` (ruled 2026-11-09): run SQL on Studio Home (`execute_sql`, `apply_migration`, read-only Supabase tools) without asking Kellie to approve or "proceed" first.

Still binding:
- Never delete (D7): no DELETE, TRUNCATE, or DROP of populated tables, and no DELETE grants.
- `vault` schema is reserved.
- DDL only through `apply_migration`, idempotent, snake_case wave-prefixed names. Data changes are idempotent upserts.
- Safety gate (GOV-20261106-SAFETY-GATE-READS-CODE): routine changes use the controlled change path. Code touching money, access or owner rights, deletion, outside sends, the approval machinery or a stored read of a person needs Kellie's exact authorization.
- Widening access (agent-role grants, RLS loosening, restricted-schema locks) needs its own named ruling.

Full operating rules: the `kphd-supabase` skill. The governing record is in Supabase `core.governance_decisions`.
