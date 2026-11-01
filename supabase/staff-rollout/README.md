# Staff rollout Step 2: Claude→Riley handoff route

`studio_api.handoff_to_riley_v1` on Studio Home Supabase (`qdgfcwdbzxxmhduhxcmj`).

| Rev | Change-set | Candidate sha256 | State |
| --- | --- | --- | --- |
| r2 | `dfd2b53e-a1a3-4db4-8638-7dad406a27fd` | `63389acf…f49f` | Installed 2026-11-01 16:38 UTC (GOV-20261101-RILEY-HANDOFF-INSTALL); replaced by r4 at 19:11 UTC. |
| r3 | `8f2ad6b2-18c1-41c5-9b4d-a1f4d89d4e0d` | `fb652ba29c334fb15f61f4d58b250d4ac6645648a46297a01433a2e23f25aadf` | Proposed, superseded. GPT review `c6f833ff`: changes_required. |
| r4 | `e165a340-e0ff-42eb-9a33-65a23665eef0` | `cb47a08e0fa4eb714673dd42a28bdd46f5ead2e1f0fa42ec99cab464245447ad` | **Installed** 2026-11-01 19:11 UTC by a separate Claude Code session (thread `5e0c94ab`) on Kellie's exact-hash approval, GOV-20261101-RILEY-HANDOFF-R4-INSTALL (migration `wave_staff_step2_handoff_to_riley_v1_r4`). GPT review `b8dd7797` (after install): **accept_with_findings**. |

The r3 change-set hash is `d68f153262296c47e42fec31d1f75c9f6fb3af865ac172ef366cb4eae7164b3d`. Its expected state hash is `99390f828c23ca538c87ca66761490f3a363c91d5332697a7e9cc6fce26684cc`; the recipe is in `r3_state_hash.sql`.

## Route check: PASSED (2026-11-01 19:56 UTC)

- **Route check 2 `02074ec9-2c10-47e1-a20b-e65d15a53b10`** (research_evidence) went through every step:
  - created 19:53:57 via the installed r4 `handoff_to_riley_v1`;
  - listed by `dot_next_work_v1`;
  - claimed (`dot_claim`, actor chatgpt_dot) and completed (`dot_progress` complete) at 19:56:17;
  - final state `complete / completed / completed`, no longer listed.

  Kellie ran the claim and complete in the SQL editor on Riley's behalf, through Dot's own functions. The organizer requests and assessments fired as disclosed.
- **Route check 1 `1cae1c73`** could not be completed. It was classed `internal_working_state`, and `core.project_delivery_action_policies` sets that class to `prepare_only`, so Dot's complete returns `42501 must go to review`. It was then released at 19:51, which cleared `assigned_agt`. It was then suppressed at Kellie's direction ("you decide"): `waiting / suppressed`, evidence kept, work_event `06e99204`, and it is no longer in Riley's queue.
- **Design note:** `handoff_to_riley_v1` defaults `action_class` to `internal_working_state`, so default handoffs can only go to review. Work Riley should close herself must be handed off as `research_evidence` or `prepare_candidate`.

## GPT review of r4 (b8dd7797, accept_with_findings)

No production-function defect found. Open items:

- **R4-D1 (test harness): closed.** B2 and C2 now reject any version other than r3/r4, and the new Part V asserts the pair from their verbatim outputs: the same version, the contender observed the holder's pid, r4 both `NOERR`, r3 exactly one `40P01`. On the recorded runs, r4 is PASS and the r3 control is PASS; a deliberately broken pair FAILs on both checks.
- **R4-R1:** concurrency outcomes that need a committed winner remain **NOT TESTED** (GPT: keep that status; do not run committed production fixtures). The verbatim B2/C2 driver outputs are now stored in Supabase checkpoint `2c08eabf-9073-44d6-b7cb-b1f355dbd38d`.
- **R4-R2: documented contract.** Supported usage of `studio_api.handoff_to_riley_v1`:
  - one handoff call per transaction, optionally followed by `studio_api.end_work_v1` on the same session;
  - the caller must not already hold a `runtime.work_queue` row lock or the session row FOR UPDATE;
  - batched calls are unsupported. If one is ever needed, sort by (session_id, request_key, task_id) and retry the whole transaction on `40P01`.
- **R4-I1:** state hash v2 is a bounded manifest; its exclusion classes are listed in `r4_state_hash.sql`. The live hash after install is `706ac035102b5e24025bcb82f0df51316b7555e2b52dec4d3d7d1141219d4de3`.
- **R4-I2:** both test-file identities are kept (registration `dae14a5c…`, as run `723c64e3…`).

## What r4 fixes (GPT review c6f833ff of r3)

- **R3-R1 deadlock.** The per-session lock now comes before the session-row lock. The handoff-then-close composition that deadlocked on r3 (reproduced: `40P01`) completes on r4.
- **R3-R2 isolation.** Callers must run at READ COMMITTED. A REPEATABLE READ caller gets `25000`.
- **R3-D1 freshness.** State hash v2 (`r4_state_hash.sql`) binds the live call closure (33 functions, with owner, ACL, security mode, volatility and settings), 11 trigger definitions on work_queue, work_events and intake.items, and the 6 organizer contract rows. Value at registration: `0c630e75ba9a2f5ab0f16b5f2311ccb05ebd0a93e1720694585183ae864774a1`.
- **R3-D2 / R3-I1 tests.** `step2_handoff_to_riley_v1_r4_tests.sql` is pinned to the change-set ID and SHA, fails closed, and adds the auth variants, a positive snapshot write, the isolation refusal and the two-connection close/annotate/same-key/deadlock cases. Receipts are in Supabase checkpoint `0d80f88b-d421-4698-b43d-8d5a9af3ff88`.

### r4 test receipts (2026-11-01, production, every transaction rolled back)

- **Part A: PASS** (pinned e165a340/cb47a08e). First run failed two fixtures on table check constraints (`23514`); fixed (A5 uses `paused`/`retired`; a v3 session cannot have a null thread, so A6 tests legacy-no-thread) and re-run.
- **ISO: PASS.** REPEATABLE READ → `25000`.
- **B1/C1: PASS.** Holder pid 1124779, 18:58:07–18:58:32 UTC. Distinct-key create, same-key create, session close and a competing annotate from a second session all `55P03`. Installed r2 let a second create through.
- **B2/C2 r3 control:** deadlock reproduced, holder close `40P01`.
- **B2/C2 r4: PASS.** Holder close `NOERR`, contender completed after 3.9 s.
- **Not tested:** the committed 9→10 boundary with a contender resuming after the holder commits, and outcomes that need a committed winner. A Supabase branch was tried and failed to replay migrations (33 of 635), so it was deleted.
- The change-set metadata records the pre-run test-file hash (`dae14a5c…`). The file as run is `723c64e3727b0178db66a5dadf60e9b7b1edcde873e93362df36669ced2d2c53`; the only difference is the two fixture fixes.

## What r3 fixes (GPT source-bound review of r2)

- **P1 cap race.** r3 takes a per-session advisory transaction lock before the request-key lock, in every mode. Concurrent creates on one session now serialize, so two of them can't both pass the 10-create cap.
- **P2 side effects.** The `scope_history_capture` statement trigger runs on every create and annotate. It scans all project-scoped queue rows and can append `scope_snapshot_v1` events. r3 discloses this in the header and in the result's `downstream` field, and tests it (D4).
- **P2 validation.** The acceptance tests are now executable SQL (`step2_handoff_to_riley_v1_r3_tests.sql`).
- **Freshness.** The expected state hash now covers the trigger, auth and dependency functions, not just `dot_*`.

## Test receipts (2026-11-01, production, every transaction rolled back)

- **Part A: PASS.** A1×3, A2, A3×2, A6, M1×2, M2, S1, S2×2, S3×6, S4, S5×3, P1, P2 closed/stale, **P2b active_session → 40001**, P3, Y1–Y4, D1 (1 intake, 1 http), D2 (0/0), D3 54000, D4 (0 snapshots on create and on annotate).
- **Part B (R5), two backends.** The holder (pid 1114954) held the session lock from 16:47:35 to 16:48:20 UTC. The contender (pid 1114955) ran at 16:47:37:
  - installed r2: second create **succeeded**, so the race was real.
  - r3: **55P03**, blocked by the session lock.
- Residue after all runs: 0 test rows. Only the real route-check item `1cae1c73` remains.

## Files

- `build_r3_from_r2.sql`: read-only. Rebuilds the r3 text from the stored r2 source using 11 exact single-occurrence replacements, and checks the result against the registered SHA.
- `step2_handoff_to_riley_v1_r3_tests.sql`: Part A (one connection) and Part B1/B2 (two concurrent connections).
- `r3_state_hash.sql`: the expected-state hash recipe.

Rollback for r3: re-execute the r2 `candidate_sql` from change-set dfd2b53e. Rows are retained (D7).
