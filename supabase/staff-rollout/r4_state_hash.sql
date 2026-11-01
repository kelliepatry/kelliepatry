-- Expected-state hash recipe v2 for change-set "Step 2 r4" (studio_api.handoff_to_riley_v1).
-- Answers GPT review c6f833ff finding R3-D1 (incomplete dependency binding).
--
-- Function manifest = call closure, computed live, starting from:
--   * studio_api.handoff_to_riley_v1 (the live installed version) and every studio_api.dot_* function;
--   * every non-internal trigger function on runtime.work_queue, runtime.work_events and intake.items.
-- A function joins the closure when an included function's source mentions it schema-qualified
-- (all of these functions use search_path ''), across the schemas runtime, jev_runtime, intake, memory, core,
-- studio_api, guard and outbound. Matching is textual, so a mention in a comment also includes a function
-- (over-inclusion only; it never omits a qualified call).
-- Each function contributes: identity, owner, ACL, SECURITY DEFINER flag, volatility, proconfig (search_path etc.)
-- and sha256 of pg_get_functiondef.
-- Also bound: every non-internal trigger definition (with enabled flag) on the three tables, and every row of
-- jev_runtime.contracts (contract, family, criteria, status), which holds the organizer contract criteria.
-- Not bound (stated): vault secret values, runtime.processor_registry rows, table/column DDL, RLS policies.
with recursive
schemas as (
  select oid from pg_namespace
   where nspname in ('runtime','jev_runtime','intake','memory','core','studio_api','guard','outbound')),
candidates as (
  select p.oid, n.nspname, p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where p.pronamespace in (select oid from schemas) and p.prokind in ('f','p')),
seeds as (
  select p.oid from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'studio_api' and (p.proname = 'handoff_to_riley_v1' or p.proname like 'dot\_%')
  union
  select t.tgfoid from pg_trigger t
   where not t.tgisinternal
     and t.tgrelid in ('runtime.work_queue'::regclass, 'runtime.work_events'::regclass, 'intake.items'::regclass)),
closure(oid) as (
  select oid from seeds
  union
  select c.oid from closure f join candidates c
    on pg_get_functiondef(f.oid) ~* ('\m' || c.nspname || '\.' || c.proname || '\M')),
fn as (
  select p.oid::regprocedure::text as ident,
         p.oid::regprocedure::text
         || '|owner=' || pg_get_userbyid(p.proowner)
         || '|acl=' || coalesce(p.proacl::text, 'default')
         || '|secdef=' || p.prosecdef::text
         || '|vol=' || p.provolatile::text
         || '|cfg=' || coalesce(p.proconfig::text, '')
         || '|def=' || encode(sha256(convert_to(pg_get_functiondef(p.oid), 'UTF8')), 'hex') as line
    from pg_proc p where p.oid in (select oid from closure)),
trg as (
  select t.tgrelid::regclass::text || '.' || t.tgname || '=' || t.tgenabled::text || ':' || pg_get_triggerdef(t.oid) as line
    from pg_trigger t
   where not t.tgisinternal
     and t.tgrelid in ('runtime.work_queue'::regclass, 'runtime.work_events'::regclass, 'intake.items'::regclass)),
ctr as (
  select c.contract || '|' || coalesce(c.family, '') || '|' || coalesce(c.criteria::text, '') || '|' || coalesce(c.status, '') as line
    from jev_runtime.contracts c)
select encode(sha256(convert_to(
         'functions:' || (select string_agg(line, E'\n' order by ident) from fn)
         || E'\ntriggers:' || (select string_agg(line, E'\n' order by line) from trg)
         || E'\ncontracts:' || coalesce((select string_agg(line, E'\n' order by line) from ctr), ''),
       'UTF8')), 'hex') as state_hash,
       (select count(*) from fn) as functions_bound,
       (select count(*) from trg) as triggers_bound,
       (select count(*) from ctr) as contracts_bound,
       (select string_agg(ident, ', ' order by ident) from fn) as function_manifest;
