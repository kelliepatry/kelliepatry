# Staff rollout Step 2: Claude→Riley handoff route

`studio_api.handoff_to_riley_v1` on Studio Home Supabase (`qdgfcwdbzxxmhduhxcmj`).

| Rev | Change-set | Candidate sha256 | State |
| --- | --- | --- | --- |
| r2 | `dfd2b53e-a1a3-4db4-8638-7dad406a27fd` | `63389acf…f49f` | **Installed** 2026-11-01 16:38 UTC (GOV-20261101-RILEY-HANDOFF-INSTALL) |
| r3 | `8f2ad6b2-18c1-41c5-9b4d-a1f4d89d4e0d` | `fb652ba29c334fb15f61f4d58b250d4ac6645648a46297a01433a2e23f25aadf` | **Proposed**. Expires 2026-11-02 16:45 UTC. Awaiting Kellie's install approval for this exact hash. |

The r3 change-set hash is `d68f153262296c47e42fec31d1f75c9f6fb3af865ac172ef366cb4eae7164b3d`. Its expected state hash is `99390f828c23ca538c87ca66761490f3a363c91d5332697a7e9cc6fce26684cc`; the recipe is in `r3_state_hash.sql`.

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
