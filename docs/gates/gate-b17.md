# Gate B17 — conflict contract + account deletion (independent verification)

Verifier: fresh session, read-only on source/tests/fixtures/migrations/docs (only this file created).
Baseline for diff hygiene: `f19649c` (previous commit before B17). B17 commits: `e9aa9e3` (part A), `7c12c33` (part B).
Date: 2026-11-16.

**Gate source note.** `docs/PHASE1_VALIDATION_GATES.md` has gate rows G0–G8 only; there is no B17 row. The milestone argument given to `/v-verify` was `/flv-verify` (another command, not a milestone); the owner confirmed B17 is the target. The checks below are therefore **derived from the B17 prompt and `docs/PHASE2_SPEC.md` section 9**, not from a gate table. Say so when reading the verdict.

## Summary

| | |
|---|---|
| Clean build | `./mvnw clean verify` green: 301 unit + 379 integration tests, 0 failed, 0 skipped |
| Stack | App started on port **18080** (port 8080 is held by a foreign process, PID 7980, left untouched); health UP; V19 applied on top of a 4-day-old local database |
| B17 behaviour | Every derived check PASS on the live stack, except items marked NOT VERIFIED |
| Verdict | **GO WITH FIXES** (no blocking defect found; two policy/cost findings and three coverage gaps below) |

## Evidence

| # | Check | Command / method | Evidence | Result |
|---|---|---|---|---|
| 1 | Clean build, no skipped tests | `cd backend && ./mvnw clean verify` | `Tests run: 301, Failures: 0, Errors: 0, Skipped: 0` (unit) then `Tests run: 379, Failures: 0, Errors: 0, Skipped: 0` (IT); `BUILD SUCCESS`; no `Skipped: [1-9]` line anywhere | PASS |
| 2 | Stack starts, health | `docker compose up -d db`; `mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth -Dspring-boot.run.arguments=--server.port=18080`; `curl :18080/actuator/health` | `{"status":"UP","groups":["liveness","readiness"]}` | PASS |
| 3 | V19 migrates an existing DB | `psql: flyway_schema_history`, `information_schema`, `pg_constraint` | `19 account deletion true`; column `deleted_at` exists; `ck_users_deleted_anonymised` exists | PASS |
| 4 | Stale `PUT` expense returns latest | live: edit to v2, then `PUT If-Match "1"`; compare with `GET` | `409 VERSION_CONFLICT currentVersion=2 current==GET? YES`, `Content-Type: application/problem+json` | PASS |
| 5 | Stale `DELETE` expense returns latest | live: `DELETE If-Match "1"` | `409 currentVersion=2 current.id==eid? YES` | PASS |
| 6 | Stale group `PATCH` returns `GroupDto` | live: `PATCH If-Match "99"` | `409 currentVersion=1 current==GET group? YES` | PASS |
| 7 | Conflict leaks nothing | live: stranger stale PUT; plain member stale DELETE of another's expense; plain member stale group PATCH | stranger `404`, no `current`/`currentVersion`; member `403 FORBIDDEN`, no `current`; member PATCH `403`, no `current` | PASS |
| 8 | OpenAPI models the conflict | `jq` on `docs/openapi.json` | `VersionConflictProblem` referenced only from `PATCH /groups/{gid}`, `PUT` and `DELETE /groups/{gid}/expenses/{eid}` 409; generic `Problem` still used elsewhere; no dangling `$ref` (`[]`) | PASS |
| 9 | Committed OpenAPI equals the running app | `curl :18080/v3/api-docs` vs `docs/openapi.json`, `jq -S` | `live ops=54 committed ops=54`, `IDENTICAL`; `deleteMe` responses `204,400,401,409,413,422,500` | PASS |
| 10 | `DELETE /me` bad confirm | `{"confirm":"nope"}` | `422`, nothing changed | PASS |
| 11 | Balances and ledger identical after deleting a member's account | live: group with 3 members, 2 expenses (one paid by the deleting user); snapshot `GET balances`, `GET expenses`, ledger row count; delete Dina; re-read | `balances identical YES`, `expenses identical YES`, ledger rows `66 → 66`; Dina's member `{"displayName":"Dina","hasAccount":false,"role":"MEMBER"}` | PASS (expenses only, see gap 1) |
| 12 | Purge per table | `psql` after deletion | users row `Deleted user\|deleted:…\|email=NULL\|deleted=true`; refresh_tokens, payment_handles, notifications, notification_prefs, idempotency_keys, join_requests, members linked to the user: all `0` (before: refresh 1, idempotency 2, notifications 2) | PASS |
| 13 | Sessions end | old access token on `GET /me`, `POST /groups`, `PATCH /me`, handles, notifications, `DELETE /me`; old refresh token | all `401`; refresh `401`; repeat `DELETE /me` `401` | PASS |
| 14 | Old Google subject free | sign in again with the same subject | new user id differs: YES, new display name | PASS |
| 15 | Owner must transfer | owner of a group with history + another member calls `DELETE /me` | `409 OWNER_MUST_TRANSFER`, `groups=[{"id":"<gid>","name":"GateB17"}]`; account intact (`GET /me` 200); a second owned empty group still exists (rollback proven, count `1`) | PASS |
| 16 | Sole-member empty group removed | live: group + invite, delete account | before `group=1 invites=1`; `204`; after `group=0 invites=0 members=0` | PASS |
| 17 | Password account | no password / wrong password / correct password / old login / re-register | `422` / `422` (failed_attempts=1) / `204` / `401` / re-register same username new id differs: YES; `user_passwords` rows `0` | PASS |
| 18 | Parallel deletes | 6 concurrent `DELETE /me`, one account | `1×204, 5×401` | PASS |
| 19 | No identifier in logs | grep the app log for each email, username, display names, passwords | `0` occurrences each; `account.deleted` lines present; `"level":"ERROR"` lines `0`; 5xx `0` | PASS |
| 20 | Settlement invariance live | not run in the live scenario | covered only by `AccountDeletionIT` (settlement created and compared) | NOT VERIFIED live |
| 21 | Refresh racing deletion | no dedicated test and not run live | `rotate` takes the user row `FOR SHARE` first by design; sign-in-vs-delete races are tested (`AccountDeletionIT`), refresh-vs-delete is not | NOT VERIFIED |

## Adversarial probes (live, stack on :18080)

| Probe | Result |
|---|---|
| Another user's token on 19 existing group-scoped routes (GET/PATCH/DELETE group; POST members; GET/POST expenses; GET/PUT/DELETE expense; revisions; balances; settlements GET/POST; invites GET/POST; activity; leave; transfer-ownership; notification-prefs) | all `404 NOT_FOUND`. (`GET /groups/{gid}/members` returned `405`: the route does not exist, not an authorization gap.) |
| Same `Idempotency-Key`, same body | `201` replay |
| Same `Idempotency-Key`, different body | `422` problem type `idempotency-key-reused` |
| Stale ETag | `409` (checks 4–6) |
| Amount `0`, `-5`, `9223372036854775807` | `422 VALIDATION_ERROR` each |
| Amount `9223372036854775808` (overflow) | `400 VALIDATION_ERROR`, not 500 |
| Duplicate payer ids | `422 "Duplicate payer"` |
| Unknown member id | `422 member-not-in-group` |
| Malformed JSON | `400` |
| 300 012-byte body | `413 VALIDATION_ERROR` |
| No token / garbage token | `401` both |
| Deleted account's token on 7 `/me`-class routes | all `401` |

A first probe pass was discarded: the shell had no UUID generator, so every create returned `422 Idempotency-Key required` and the scenario was empty (its "204 for the owner" and "balances identical" results were meaningless). It was fixed and the whole scenario rerun; only the rerun is reported. Two further probe-harness bugs (a malformed `tr`, then a Windows `/tmp` path) made the first oversized-body attempts invalid; the 413 above is from the third, verified attempt.

## Diff hygiene (`f19649c..7c12c33`, excluding `mobile/`)

- **Dependencies:** `pom.xml` untouched. None added.
- **Fixtures / expected money values:** no file under `fixtures/` changed.
- **New TODO/FIXME, `@Disabled`, assumptions, catch-all handlers:** none added (grep of the added lines).
- **Existing tests modified (all loosened by exactly one statement or given a new mock):**
  - `ExpenseListQueryCountIT`: `EXPECTED_STATEMENTS` 7→8, group detail ≤4→≤5, revisions ≤3→≤4, group list ≤2→≤3, settlements ≤4→≤5.
  - `RoleQueryCountIT` ≤2→≤3; `SettlementQueryCountIT` ≤4→≤5; `BalancesPerformanceIT` ≤3→≤4.
  - `SecurityChainTest`, `ExpenseApiSliceTest`, `GroupApiSliceTest`, `SettlementApiSliceTest`: added `@MockitoBean UserService` / `AccountDeletionService`; `GroupApiSliceTest.staleVersionIs409VersionConflict` now stubs `groups.get` and asserts the new fields.
  - `ApiContractCoverageIT`: +6 lines (the `DELETE /me` calls). `ExpenseEditDeleteIT`, `GroupsMembersIT`: additive assertions/tests.
  - The loosened bounds are the visible cost of finding F1; they are explained in the test comments, but they are still weakened guards.
- **Outside the milestone's stated scope:** `GroupService.delete` now removes invites and join requests (fixes a real FK failure, recorded as A118; arguably in scope since account deletion needs the same path); `docs/mobile-client.md` and `backend/README.md` edits (scope-appropriate).
- **Not part of B17 but present in the working tree:** a large set of uncommitted `mobile/` changes (regenerated `qesma_api`, new FL screens, goldens). They are not in the B17 commits and were not reviewed here.

## Findings

| # | Severity | Finding |
|---|---|---|
| F1 | Medium | The deleted-account check is one extra primary-key `SELECT` on **every** authenticated request (JWT validator, `UserService.isDeleted`), uncached. It is a deliberate trade for immediate token rejection, but it is a per-request cost on the whole API and it is why six statement-count/performance bounds were raised. No benchmark of the extra latency was run here. |
| F2 | Medium | Policy gap: a sole Owner of a group **with history** and no other active member can never delete their account (`OWNER_MUST_TRANSFER`) until they add someone else to the group. That follows the recommended rule in the prompt, but Google Play's account-deletion requirement and PDPL expect a way out. The spec lists lawyer review as open (A120) but does not list this dead end explicitly. |
| F3 | Low | Coverage: no test or live run of a **refresh racing the deletion** (check 21), and the live balance-invariance check used expenses only, not settlements (check 20; settlements are covered by `AccountDeletionIT` only). |
| F4 | Low | `DELETE /me` has no rate limit beyond the password lockout (documented in A115); Google accounts have no brake at all. Acceptable because it needs a valid token and `confirm`, but note it. |
| F5 | Info | Port 8080 was occupied by a foreign process, so the stack was verified on 18080; `README` instructions assume 8080. |

## Required fixes (minimal)

1. **F2:** record the "sole owner with history has no way out" case as an explicit open item in the spec (A120), or decide an escape (for example allow it by making the group ownerless-but-readable, or by deleting the account's membership role only). Decision needed before release; no code change is required to ship B17 itself.
2. **F3:** add one refresh-vs-delete race test and one live/IT settlement case in the balance-invariance check, or record them as accepted gaps.
3. **F1:** either record measured latency/statement cost in the Decision Log (A115 already states the probe) or add a short-TTL cache; if left as is, say so explicitly.

## Verdict

**GO WITH FIXES.** All derived checks that were run passed against the real stack, the build is clean with no skipped tests, and no authorization, idempotency or money defect was found. The listed items are a policy decision (F2), two coverage gaps (F3) and a documented performance cost (F1); none blocks merging B17.

## Human check (done by me): ✔/✘ + notes

_To be filled by the owner._ Suggested 5 minutes: delete a throwaway account in the app/emulator while a second member watches the balances; confirm the remaining member sees the same totals and the deleted person's name as an unconnected member.
