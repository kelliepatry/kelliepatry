-- Expected-state hash recipe for change-set "Step 2 r3" (studio_api.handoff_to_riley_v1).
-- Covers: studio_api.dot_*, the live handoff function, every non-internal trigger on runtime.work_queue
-- and its function, runtime.evaluate_work_scope_v1, runtime.enqueue_processor_http_v1, memory.close_session_v2.
select encode(sha256(convert_to(
  (select string_agg(p.oid::regprocedure::text || ':' || encode(sha256(convert_to(pg_get_functiondef(p.oid),'UTF8')),'hex'), '|' order by p.oid::regprocedure::text)
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where (n.nspname = 'studio_api' and (p.proname like 'dot\_%' or p.proname = 'handoff_to_riley_v1'))
       or (n.nspname = 'runtime' and p.proname in ('evaluate_work_scope_v1','enqueue_processor_http_v1'))
       or (n.nspname = 'memory' and p.proname = 'close_session_v2')
       or p.oid in (select t.tgfoid from pg_trigger t where t.tgrelid = 'runtime.work_queue'::regclass and not t.tgisinternal))
  || '|triggers:' ||
  (select string_agg(t.tgname || '=' || t.tgenabled::text || ':' || pg_get_triggerdef(t.oid), '|' order by t.tgname)
     from pg_trigger t where t.tgrelid = 'runtime.work_queue'::regclass and not t.tgisinternal),
  'UTF8')), 'hex') as state_hash;
