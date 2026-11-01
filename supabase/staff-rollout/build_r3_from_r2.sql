-- Reproducible build of the Step 2 r3 candidate (studio_api.handoff_to_riley_v1) from the stored r2 source.
-- r2: guard.controlled_change_sets dfd2b53e-a1a3-4db4-8638-7dad406a27fd, metadata.candidate_sql,
--     sha256 63389acf219e932c07ea95516fcb9898c2586e5706656f43857ecf034441f49f (18,175 bytes)
-- r3: guard.controlled_change_sets 8f2ad6b2-18c1-41c5-9b4d-a1f4d89d4e0d, metadata.candidate_sql,
--     sha256 fb652ba29c334fb15f61f4d58b250d4ac6645648a46297a01433a2e23f25aadf (20,926 bytes)
-- Each of the 11 search strings occurs exactly once in r2 (verified 2026-11-01).
-- Read-only: returns the r3 text and its sha256; compare with the registered candidate.
with r2 as (select metadata->>'candidate_sql' t from guard.controlled_change_sets
            where change_set_id = 'dfd2b53e-a1a3-4db4-8638-7dad406a27fd'),
r3 as (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace((select t from r2),$q$-- PROPOSAL ONLY - NOT INSTALLED. KPHD Studio virtual-staff rollout Step 2, revision 2.$q$,$q$-- PROPOSAL ONLY - NOT INSTALLED. KPHD Studio virtual-staff rollout Step 2, revision 3.
-- r3 replaces the installed r2 (change-set dfd2b53e-a1a3-4db4-8638-7dad406a27fd, sha256
--   63389acf219e932c07ea95516fcb9898c2586e5706656f43857ecf034441f49f, applied 2026-11-01 16:38 UTC).
-- r3 corrections (GPT source-bound review of r2, 2026-10-31 -> fix)
--  P1 cap race      : per-session advisory xact lock taken before the request-key lock in every mode
--                     (fixed order session -> request key; no cycle). Cap count and insert run under it,
--                     so concurrent distinct-key creates on one session cannot both pass the cap.
--  P2 side effects  : statement trigger runtime.work_queue scope_history_capture ->
--                     runtime.capture_scope_snapshots_v1 (SECURITY DEFINER) runs once per create AND per
--                     annotate. It scans every project-scoped queue row and appends a 'revised'
--                     scope_snapshot_v1 work_event for any row whose evaluated scope differs from its last
--                     snapshot (may touch unrelated project rows; handoff rows are studio-scoped and are
--                     never snapshotted). Cost O(project rows) per call. Result 'downstream' discloses it.
--  P2 validation    : executable tests incl. two-connection race R5, D4 snapshot count and P2b lock case in
--                     step2_handoff_to_riley_v1_r3_tests.sql; receipts recorded in change-set metadata.
--  Freshness        : expected_state_hash covers dot_*, the live handoff function, every work_queue
--                     trigger definition and trigger function, evaluate_work_scope_v1,
--                     enqueue_processor_http_v1 and memory.close_session_v2.
-- (r2 header follows, unchanged except where marked r3)$q$),$q$-- Unconfirmed: c_max_creates_per_session = 10 is a proposed bound, not a ruled value.$q$,$q$-- c_max_creates_per_session = 10 ruled by Kellie 2026-11-01 01:00 PT (r3).$q$),$q$trigger and has no downstream effect.$q$,$q$organizer trigger (scope_history_capture still runs; see r3 P2).$q$),$q$  perform pg_advisory_xact_lock(hashtextextended(v_key,0));$q$,$q$  -- r3 P1: serialize per session (lock order: session, then request key; every mode).
  perform pg_advisory_xact_lock(hashtextextended('claude-riley-handoff:session:' || p_session_id::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(v_key,0));$q$),$q$'downstream',case when p_mode='create' then 'jev_organizer_enqueue_and_wake_possible' else 'none' end);$q$,$q$'downstream',case when p_mode='create' then 'jev_organizer_enqueue_and_wake_possible;scope_snapshot_scan' else 'scope_snapshot_scan' end);$q$),$q$'contract','claude_riley_handoff_result/2'$q$,$q$'contract','claude_riley_handoff_result/3'$q$),$q$    -- AFTER INSERT trigger jev_organize_work enqueues organization and may wake the organizer (disclosed).$q$,$q$    -- AFTER INSERT trigger jev_organize_work enqueues organization and may wake the organizer (disclosed).
    -- r3: statement trigger scope_history_capture also runs (snapshot scan of project rows; disclosed).$q$),$q$    -- evidence-only change: jev_organize_work skips it (project/status/last_action/notes/blocker/project_id unchanged)$q$,$q$    -- evidence-only change: jev_organize_work skips it (project/status/last_action/notes/blocker/project_id unchanged)
    -- r3: scope_history_capture still runs once for this statement (snapshot scan; disclosed).$q$),$q$-- Acceptance tests: run in an isolated branch (not production), each test in its own transaction, rolled back.$q$,$q$-- Acceptance tests: executable form in step2_handoff_to_riley_v1_r3_tests.sql; every case runs in a
-- transaction that is rolled back (no committed rows, no organizer wake).$q$),$q$--  Contract
$q$,$q$--  r3 additions
--   R5 two connections, same session, distinct request keys: second create blocks on the session lock while
--      the first is open (lock_timeout -> 55P03); never two inserts past the cap
--   D4 create and annotate: count scope_snapshot_v1 events written in-transaction (disclosed; may be >0)
--   P2b annotate a Riley row claimed via studio_api.dot_claim_work_v1 (active_session) -> 40001
--  Contract
$q$),$q$-- Rollback: drop function studio_api.handoff_to_riley_v1(text,uuid,text,text,uuid,timestamptz,jsonb);$q$,$q$-- Rollback (r3): re-execute r2 candidate_sql from change-set dfd2b53e (sha256 63389acf...) to restore r2;
--   full removal: drop function studio_api.handoff_to_riley_v1(text,uuid,text,text,uuid,timestamptz,jsonb);$q$) as t)
select encode(sha256(convert_to(t,'UTF8')),'hex') as sha256, octet_length(t) as bytes,
       encode(sha256(convert_to(t,'UTF8')),'hex') = 'fb652ba29c334fb15f61f4d58b250d4ac6645648a46297a01433a2e23f25aadf' as matches_registered,
       t as candidate_sql
  from r3;
