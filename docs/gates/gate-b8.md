# Gate G8 (hardening / handoff): verification report

**Date:** 2026-11-07 · **Scope:** the whole backend (B0–B8) as it exists in the working tree · **Baseline for diff hygiene:** `HEAD` = `7ab5d3b` (CP1 commit). No `gate-*` tags exist.

> **Independence disclosure.** This verification was run by the same Claude session that wrote B4–B8. It is **not** the independent fresh-session `V` the process asks for. It follows `v-verify.md` strictly (source, tests, fixtures, migrations and docs untouched; real commands only; adversarial probes; NOT VERIFIED where something cannot be run), and every claim below was reproduced with fresh commands, but it does not replace a run by a verifier who did not write the code.

## 1. Summary
The running application and the test suite behave as specified in everything that could be executed here: clean build green (214 unit + 157 integration, 0 failed, 0 skipped), 26 of 27 live probes PASS, the one FAIL is an ordering difference already recorded as Decision A11. The gate itself is **not met**: the G8 row requires "CI green", "staging deploy reachable over HTTPS" and "smoke script green", and the smoke script does not exist, CI has never run, there is no staging, nothing is committed or tagged, and the human checks are pending.

**Verdict: NO-GO for tagging `gate-b8`** (minimal fixes in section 6). No functional defect was found in the code under test.

## 2. Checks (command | evidence | result)

| # | Check | Command / how | Evidence | Result |
|:--|:--|:--|:--|:--|
| 1 | Clean build | `cd backend && ./mvnw clean verify` (JDK 21.0.12.1) | `Tests run: 214, Failures: 0, Errors: 0, Skipped: 0` (unit) · `Tests run: 157, Failures: 0, Errors: 0, Skipped: 0` (integration) · `BUILD SUCCESS`. No `<skipped>` in any surefire/failsafe XML. | **PASS** |
| 2 | Start-up refusal without a profile | `java -jar target/qesma-backend-0.0.1-SNAPSHOT.jar` | `IllegalStateException: No Spring profile is active. … There is deliberately no default profile.` | **PASS** |
| 3 | Stack starts, health, Flyway | `docker compose up -d db` (healthy); `java -jar … --spring.profiles.active=local,fake-auth --server.port=18080` | `/actuator/health` → `{"status":"UP","groups":["liveness","readiness"]}`, readiness `UP`, liveness `UP`; `flyway_schema_history`: versions 1–8 all `success=true`. (Port 8080 on this machine is held by another process, PID 7980; I did not touch it.) | **PASS** |
| 4 | Spec 10.1: vectors V1–V8 automated | failsafe/surefire XML | `FixtureTest` 9/9; via API: `BalancesSettlementsIT` 17/17 (V1, V2), `ExpensesIT` 19/19 (V3, V4), `ItemizedExpensesIT` 21/21 (V5–V8); `EnginePropertyTest` 3/3 | **PASS** |
| 5 | Spec 10.2: every endpoint and error code covered | `ApiContractCoverageIT` | 1/1 pass: all 24 operations answered 2xx, all 14 error codes produced on real responses | **PASS** |
| 6 | Spec 10.3: real Android device flow | — | No device, no mobile app | **NOT VERIFIED** (human) |
| 7 | Spec 10.4: edit/delete update balances, revisions remain | `ExpenseEditDeleteIT` 13/13, `Cp2LedgerInvariantIT` 6/6, live probe (check 15–16) | pass | **PASS** |
| 8 | Spec 10.5: retry never duplicates | live probe + `ExpenseIdempotencyIT` 10/10 | below (G4) | **PASS** |
| 9 | G4 live: V1 nets/transfers | `node vprobe.js http://localhost:18080` (HTTP only, scratchpad script, not in the repo) | nets `10000,-8000,-2000`; transfers `A>M 8000, S>M 2000` | **PASS** |
| 10 | G4 live: V3 | same | owed `3334,3333,3333` | **PASS** |
| 11 | G4 live: V4 nets and transfers | same | nets `17500,7500,-12500,-12500` correct; transfers `Z>X 12500, W>Y 7500, W>X 5000` while the spec text lists `Z>X, W>X, W>Y` | **FAIL as literally written / PASS against A11**: same three transfers and amounts, different order; Decision A11 (B3) documents that applying 7.7 literally gives this order, and `fixtures/engine/V4-…json` (unchanged vs `HEAD`) follows it. The spec text and the rule disagree; A11 was decided by the agent, not confirmed by you. |
| 12 | G4: same key twice → one row; 20 parallel same-key requests → one row | live probe + SQL `count(*)` | rows=1, `Idempotency-Replayed: true`; 20 parallel → rows=1, all 201 | **PASS** |
| 13 | G4: list query count bounded | `ExpenseListQueryCountIT` 5/5 | one vs fifty items → same statement count (test, not live) | **PASS** |
| 14 | G5: V5–V8 via API, preview == create, preview persists nothing | live probe | totals 56179/49280/50160/44000, owed exactly as spec; `preview.members == create.shares`; row counts of 6 tables identical before/after 5 previews | **PASS** |
| 15 | G6: stale `If-Match` → 409, nothing changes; ETag | live probe | 409 `VERSION_CONFLICT`; expense still total 4000, version 2; `ETag: "1"` on GET | **PASS** |
| 16 | G6: two parallel PUTs → one 200 and one 409; revisions; deleted absent | live probe + SQL | statuses `{200,409}`; revisions `CREATE,UPDATE,UPDATE,DELETE` (4 rows in SQL); list empty, GET 404, balances 0 | **PASS** (note: the gate text says "create+update+delete → 3 revisions"; with two successful updates there are 4, one per change, as designed) |
| 17 | G7: V2 via API | live probe | nets `2000,0,-2000`, one transfer of 2000 | **PASS** |
| 18 | G7: randomized scenario keeps Σnet=0, transfers zero all nets | `Cp2LedgerInvariantIT`, `BalancesSettlementsIT` (in the clean build) | 6/6 and 17/17 pass | **PASS** (test, not live) |
| 19 | G7: EXPLAIN notes; max dataset within bound | `docs/perf-notes.md` exists; `BalancesPerformanceIT` output in this build | `PERF balances(15 members, 500 expenses, 200 settlements) = 26 ms, JPA statements = 2`; p95 of 8 typical requests ≤ 56 ms (in-process, excludes network); bound 2000 ms / p95 500 ms | **PASS** |
| 20 | G8: table-driven IDOR over every group-scoped route | `IdorMatrixIT` 1/1 in the build, **plus** live: every operation of the live `/v3/api-docs` containing `{gid}` called with a second user's token | 17 routes: all `404 NOT_FOUND`, body identical to a nonexistent group's (ignoring `instance`/`requestId`); anonymous `401`; owner's snapshot (members, expenses, settlements, group version) unchanged `2,1,1,1 → 2,1,1,1` | **PASS** |
| 21 | G8: `docs/openapi.json` valid and matches spec 8.2 | `openapitools/openapi-generator-cli:v7.8.0 validate`; canonical compare with live `/v3/api-docs`; `OpenApiExportIT` 3/3 | "No validation issues detected."; committed == live: true; 24 operations, OpenAPI 3.0.1 | **PASS** |
| 22 | G8: restore drill | `bash scripts/test-restore.sh` | exit 0: live-database restore refused, corrupt dump refused, restored schema/rows/balances identical (`PASS: backup and restore reproduce …`) | **PASS** (script drill; "do the restore yourself once" is yours) |
| 23 | G3 greps | `grep -RnE "\b(float\|double\|Float\|Double)\b" …/engine`; `grep "org.springframework\|jakarta.persistence" …/engine` | both return nothing; also nothing in all of `src/main/java` (incl. `BigDecimal`) | **PASS** |
| 24 | G1: two simultaneous first logins → one user | 10 parallel `POST /auth/google`, one subject, SQL count | `1` | **PASS** |
| 25 | G1: reuse of a rotated refresh token revokes the family | live probe | reuse → 401; the newer token → 401 | **PASS** |
| 26 | G1: no token in the run log | grep of the app's log | JWT pattern `eyJ…`: 0; `Bearer …`: 0; `fake:` login string: 0 | **PASS** |
| 27 | G2: 16 parallel member creates | live, SQL | 16 members, 16 distinct `sort_order`, 1..16; unique index `ux_members_group_name (group_id, lower(display_name))` exists | **PASS** |
| 28 | **G4–G8: smoke script green** | `ls scripts/` | `scripts/smoke.sh` **does not exist** (prompt `X` was never run). The live probe above was written by me, outside the repo. | **FAIL** (required artifact missing) |
| 29 | G8: CI green | — | The workflow has never run on GitHub (nothing pushed/committed); the new jobs (`openapi-valid`, `restore-test`, `dependency-scan` with Trivy) have never executed | **NOT VERIFIED** |
| 30 | G8: staging deploy over HTTPS; smoke against staging; phone check | — | No staging. Local production stack with `DOMAIN=localhost` (Caddy internal CA) was run earlier in this session; not repeated here and not Let's Encrypt | **NOT VERIFIED** |
| 31 | Dependency scan | Trivy via Docker | The vulnerability database download failed/timed out; no scan result exists | **NOT VERIFIED** |
| 32 | Human checks: 3 real receipts, dogfood outing, restore yourself, phone | — | Not provided | **NOT VERIFIED** (human) |

## 3. Adversarial probes (live, against the running app)
| Probe | Result |
|:--|:--|
| Another user's token on every group-scoped route | 17/17 → 404, identical to nonexistent; owner data unchanged |
| Same `Idempotency-Key`, different body | 422 `IDEMPOTENCY_KEY_REUSED` |
| Stale ETag on PUT | 409 `VERSION_CONFLICT`, state unchanged |
| Total 0 / negative / `9223372036854775807` / 10^12 + 1 | 422 each (never 500) |
| Total beyond `long` (`99999999999999999999`) | 400 (unparseable number) |
| Exactly 10^12 | 201 accepted |
| Oversized body, 70 KB declared and chunked | 413 both |
| Duplicate member ids in payers | 422 `VALIDATION_ERROR` |
| Unknown member id | 422 `MEMBER_NOT_IN_GROUP` |
| Malformed JSON | 400 problem+json, no stack trace (note: its `type` is `about:blank`, unlike the app's own `https://qesma.app/problems/…` URIs) |
| Missing token / tampered signature | 401 / 401 |
| Expired token (forged with the committed dev secret; control with future `exp` accepted) | 401 |
| 10 logins in a burst from one IP | the limiter answered 429 on the following calls (observed while preparing check 27) |

## 4. Diff hygiene (against `HEAD` = `7ab5d3b`)
- **Fixtures / expected values:** `git diff HEAD -- fixtures` empty. **Migrations V1–V4:** byte-identical; V5–V8 are new.
- **Dependencies:** `git diff HEAD -- backend/pom.xml` empty (no new Maven dependency since CP1). New CI tooling (Trivy, Dependabot, openapi-generator image) is recorded in ADR-003/004.
- **Existing tests modified (4 files):** `AbstractApiIT` (+helpers, one javadoc line removed), `GroupsMembersIT` (member name shortened to fit the 40-character rule), `GroupApiSliceTest` (placeholder zeros replaced by real totals/`lastExpenseAt` because the totals became real in B4; added a PATCH-returns-full-body assertion), `LayeringTest` (two tests added). **No assertion was weakened or removed**; two zero-assertions were replaced by the correct non-zero values.
- **Disabled tests / `assumeTrue` / TODO / FIXME:** none. **Catch-all `catch (Exception|Throwable|RuntimeException)`:** none in `src/main`; the one `@ExceptionHandler(Exception.class)` in `GlobalExceptionHandler` is the logged catch-all that answers a generic 500.
- **Money types:** no `float`, `double` or `BigDecimal` anywhere in `src/main/java`.
- **Scope:** 25 tracked files modified and ~90 files untracked. Outside strict B8 scope but deliberate: CP1/CP2/acceptance documents, `.github/*`, deploy files, `scripts/*`, a one-line change to `CLAUDE.md` and `backend/AGENTS.md` (run command now `local,fake-auth`).
- **Everything from B4 onward is uncommitted.** A leftover `backups/` folder (git-ignored) exists in the repository root from a local compose run.
- Git status before and after this verification differs only by this file.

## 5. Other findings
- **V4 order (see check 11):** spec text vs rule; needs your confirmation of A11.
- Framework-generated errors (malformed JSON) use `type: about:blank`, inconsistent with the app's problem type URIs (cosmetic).
- Unchecked here because nothing could be run: Let's Encrypt issuance, behaviour behind a real reverse proxy on a VPS, CI, the Android app.

## 6. Minimal fixes required before `gate-b8` can be tagged
1. **Commit** B4–B8 in reviewable commits and tag the earlier gates you want to honour (or accept a single `gate-b8`).
2. **Create and run `scripts/smoke.sh`** (prompt `X`); the gate lists it for G4–G8.
3. **Push and get CI green**, including the first run of the new jobs (Trivy findings, if any, to be triaged).
4. **Staging:** deploy with `docker-compose.prod.yml` on a real host and DNS name, run the smoke script against it, open it from your phone over HTTPS.
5. **Your human checks:** do a restore yourself once, enter the three real receipts (settles A1 and confirms the engine against real data), dogfood one real outing, run the flow on a device.
6. **Decide A11** (V4 transfer order: keep the rule's order and fix the spec text, or change the rule).
7. **Repeat this `V` in a fresh session** by a verifier who did not write the code.

**Final verdict: NO-GO for tagging; functional state: no defects found in what could be executed.**
