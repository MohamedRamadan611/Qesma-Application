# Gate B14 — Payment handles — 2026-11-13

**Scope:** the uncommitted B14 working tree on `main` (HEAD `941913a`). B13 and the `mobile/` changes are also uncommitted in the same tree, so B14 is not isolated by a commit. There are no `gate-*` tags, so diff hygiene is against `HEAD` and is restricted to the files B14 added or edited.
**Gate definition used:** `docs/PHASE1_VALIDATION_GATES.md` is Phase 1 only and has no B14 row. I used `.claude/commands/b14-payment-handles.md` ("Tests" and "Constraints"), PHASE2_SPEC §7, §10, §11 and Decision Log A90–A94.

> **Independence disclosure.** This verification ran in the same Claude conversation that wrote B14. It is not a fresh session. Every result below comes from a command run in this session, but the verifier shares the author's blind spots. The milestone argument was given as `/flv-verify` (the Flutter verify command); the owner confirmed B14 when asked.

## 1. Summary
The suite is green with no skipped tests, the live probes behaved as specified, and the running app's OpenAPI document is identical to `docs/openapi.json`. The visibility rule held on every probe I tried: only the payer of a transfer and Owner/Admin got the receiver's handles, and the values appeared nowhere else and in no log line. One requirement of the B14 prompt was not met literally: the "B10 matrix extended" item (finding F1). There are no defects in the behaviour itself.

**Verdict: GO WITH FIXES** (one minimal, non-blocking fix, F1).

Evidence caveat: my first two probe-script runs were invalid because of harness problems (no `uuidgen`, so nobody joined the group; Git Bash mangled raw Arabic bytes in the curl argument). The results below come from the third, complete run. A fourth run was needed for a clean stranger column because the auth rate limiter (1 minute window) had blocked the stranger's login. Those two probe issues are not application defects, and I isolated the Arabic one by hand (row 7).

## 2. Checks

| # | Check | Command | Evidence | Result |
|:--|:--|:--|:--|:--|
| 1 | Clean build | `cd backend && ./mvnw clean verify` | `Tests run: 299, Failures: 0, Errors: 0, Skipped: 0` (unit); `Tests run: 306, Failures: 0, Errors: 0, Skipped: 0` (integration); `BUILD SUCCESS`, `Total time: 09:12 min`. `grep -rn "@Disabled\|@Ignore" backend/src/test` = 0 hits. | **PASS** |
| 2 | Stack starts, health | `docker compose` db already `Up 35 hours (healthy)`; `./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth -Dspring-boot.run.arguments=--server.port=18090` (8080 is held by PID 7980, not touched) | `curl localhost:18090/actuator/health` → `{"status":"UP","groups":["liveness","readiness"]}`. Flyway log: `Migrating schema "public" to version "16 - payment handles"` … `now at version v16`; `flyway_schema_history` shows 16 / `payment handles` / `t`. | **PASS** |
| 3 | B14 classes ran and passed | failsafe/surefire report | `PaymentHandleRulesTest` 65, `PaymentHandlesIT` 7, `PaymentHandleVisibilityIT` 9, `PaymentHandleExposureIT` 2, `PaymentHandleLogsIT` 1, `PaymentHandleQueryCountIT` 3; all 0 failures, 0 skipped | **PASS** |
| 4 | Set / normalise / get | live `PUT /me/payment-handles` `{"instapay":"ZZReceiver@ZZBank","wallet":"<Arabic-Indic digits with dash and space>"}`, then `GET` and `psql` | 200 `{"instapay":"zzreceiver@zzbank","wallet":"01099887766"}`; `psql`: `INSTAPAY\|zzreceiver@zzbank`, `WALLET\|01099887766` | **PASS** |
| 5 | Visibility on `GET /groups/{gid}/balances` (owner, payer, receiver, plain member, member promoted to ADMIN, stranger, anonymous) | live, one group, receiver has both handles | payer 200 with handles; owner 200 with handles; member 200 `null`; receiver 200 `null`; ADMIN (promoted member) 200 with handles; stranger 404; anonymous 401. Transfer keys: `amountMinor, fromMemberId, hasDispute, openSettlementIds, pendingMinor, receiverHandles, toMemberId` | **PASS** |
| 6 | Values appear nowhere else | live scan: 4 viewers (owner, payer, member, stranger) × 10 reads (`/groups`, group detail, expenses, settlements, invites, join-requests, `/me`, invite preview, unknown group) | `leak scan (4 viewers x 10 reads): LEAK=0` | **PASS** |
| 7 | Arabic / Extended Arabic-Indic digits, dashes, spaces, `+20` | live, bodies sent from files with `\u` escapes | all six forms returned `{"wallet":"01099887766"}` | **PASS** |
| 8 | Removal is immediate | live: receiver `PUT {}`, then payer reads balances | `200 {"instapay":null,"wallet":null}`; payer's next call `receiverHandles=null`; `rows left for receiver: 0` | **PASS** |
| 9 | DB constraints hold with the service bypassed | direct `psql` inserts | wallet `12345` → `violates check constraint "ck_payment_handles_wallet"`; `Upper@Case` and `a@@b` → `ck_payment_handles_instapay`; type `PAYPAL` → `ck_payment_handles_type`. (The Arabic-digit wallet insert also failed, but the argument may have been mangled by the shell; `PaymentHandlesIT` covers it with real characters.) | **PASS** |
| 10 | No value in logs | `grep -c` of 8 distinct values (set, replaced, rejected, malformed) in the app log | 0 occurrences each. Our event is present with ids and types only (`payment_handles.updated user…`). `PaymentHandleLogsIT` (DEBUG, every logger) is green. | **PASS** |
| 11 | OpenAPI fidelity | `curl /v3/api-docs \| jq -S` vs `jq -S docs/openapi.json` (`servers` removed) | 0 differing lines (190508 bytes each). Operations `get`/`put /api/v1/me/payment-handles`; `PaymentHandlesView` has nullable `instapay` and `wallet`; `MemberDto` and `GroupDto` have no handle field. `docs/openapi.json` diff vs `HEAD`: `155 0` (additions only). `receiverHandles` is an optional `$ref`, the same convention as `ExpenseView.charges`. | **PASS** |
| 12 | Constant statement count; concurrent PUTs of one user | `PaymentHandleQueryCountIT`, `PaymentHandlesIT` | green (1 vs 20 transfers equal; handles query exactly once; none for a viewer who pays nothing; 10 rounds of two parallel PUTs never mixed). Not re-run by hand. | **PASS** (via IT only) |
| 13 | Visibility matrix incl. LEFT / unlinked / receiver left | `PaymentHandleVisibilityIT` (9 tests) | green. Not re-run live: LEFT and unlinked states need direct SQL on a shared dev database, which I did not alter. | **PASS** (via IT only) |
| 14 | "B10 matrix extended" (prompt requirement) | `git status` of `RoleMatrixIT.java`, `IdorMatrixIT.java` | both unchanged. No handle-specific row was added to either matrix. Substitute coverage is `PaymentHandleVisibilityIT`. | **FAIL (minor)**, F1 |

## 3. Adversarial probes (live, port 18090)

| Probe | Result |
|:--|:--|
| No token / garbage token on `PUT /me/payment-handles` | 401 `UNAUTHORIZED`. **PASS** |
| Stranger token on `GET /groups/{gid}` and its `/balances`, `/expenses`, `/settlements`, `/invites`, `/join-requests` (6 routes) | 404 on all six. Unknown group id and the real group id both 404. **PASS** |
| Bad wallet `0131234567x`; `JSON number 1012345678` | 422 `wallet must be an Egyptian mobile number…`, value not echoed. **PASS** |
| InstaPay: no `@`; two `@`; inner space; Arabic letters; 61 chars; 10 000 chars; SQL text `a'; drop table users;--@b` | 422 with the same constant message in every case, nothing echoed. **PASS** |
| `instapay` as JSON number `123` | coerced to the string `123`, then rejected 422 (validation runs after coercion, so no bypass). **PASS** |
| `instapay` as array / object; `wallet` `01012345678` as an unquoted number; malformed JSON; empty body | 400, `type: about:blank`, `detail: "Failed to read request"`, `code: VALIDATION_ERROR`; values not echoed. Same problem-type inconsistency (400 `about:blank` vs 422 validation type) already recorded in gate B13. **PASS** (F3, not B14-specific) |
| 2 MB body | 413 `Request body is too large`. **PASS** |
| Mass assignment: body with `userId` (another user's token prefix), `id`, `type` | 200; only the caller's own row changed (`payer@bank`); the receiver's handles were untouched. **PASS** |
| `Idempotency-Key` header with two different bodies | both 200, the second replaced the first. By design (A93: PUT is a replace, not a create). **PASS (as designed)** |
| `DELETE` and `POST` on `/me/payment-handles` | 405. **PASS** |
| Handle visible to an unrelated member (not payer, not admin) | `null` (row 5). **PASS** |
| Stale ETag; zero / negative / huge amounts; duplicate payer ids | **NOT RUN**: B14 writes no money, no expenses and no ETag-protected resource. The transfer amounts are unchanged by B14. |
| Replay with the same key and a different body on a create | **NOT APPLICABLE**: B14 adds no create endpoint. |

## 4. Diff hygiene (B14 files only)
- **New dependencies:** none (`backend/pom.xml` not modified).
- **Fixtures (`/fixtures/*.json`):** none changed.
- **Migrations:** only `V16__payment_handles.sql` added; V1–V15 untouched.
- **Disabled tests / TODO / FIXME / catch-all handlers in B14 files:** none (grep over the new main and test files).
- **Existing tests modified by B14 (3, mechanical):** `ApiContractCoverageIT` (+2 calls to the new operations), `SettlementApiSliceTest` (`TransferView(...)` gets a trailing `null` argument), `SecurityChainTest` (+1 `@MockitoBean PaymentHandleService`, needed because the slice now loads `MeController`). No expected value changed.
- **Existing main files edited:** `MeController`, `OpenApiConfig`, `BalanceService`, `BalanceView`, `Permission`, `Role`. `BalanceService`, `BalanceView` and `OpenApiConfig` also carry uncommitted B13 hunks, so B14's share cannot be isolated by `git diff`.
- **Docs edited:** `PROJECT_SPEC.md` (A90–A94 and two lines in 8.2), `PHASE2_SPEC.md` §7, `backend/README.md`, `docs/openapi.json`.
- **Files outside the milestone in the tree:** `mobile/**`, `.claude/mobile/SCREEN_MAP.md`, `docs/mobile-client.md` and B13 work were modified before B14 and are not B14's.
- **Dev database:** running the app applied V16 to the shared local `qesma` database and left probe data there: fake users `b14v…`, four groups and handle rows for the "payer" users (`payer@bank`, `k3@bank`). The receiver rows were removed by the probe itself. I did not delete anything.

## 5. Findings
- **F1 (minor, requirement not met):** the B14 prompt lists "B10 matrix extended" under Tests. `RoleMatrixIT` and `IdorMatrixIT` are unchanged. `GET`/`PUT /me/payment-handles` are not group-scoped, and the balances route is already in the matrix, but the handle visibility has no matrix row. `PaymentHandleVisibilityIT` covers the same roles (Owner, Admin, Member, payer, receiver, LEFT, unlinked, stranger).
- **F2 (documented deviation):** handles are not on `MemberDto`, although PHASE2_SPEC §7 says "transfer/member DTOs". The reason (`MemberDto` is embedded in `GroupDto`) and the choice are recorded in A91. Confirmed in the OpenAPI schema.
- **F3 (pre-existing, not B14):** non-validation JSON errors answer 400 with problem type `about:blank` while validation errors answer 422 with `validation-error`. Already listed in gate B13.
- **F4 (design note):** an Owner or Admin sees the handles of every receiver in the group, not only those of transfers they pay (A91, justified by recording on behalf of others and disputes). That is the widest exposure in B14.

## 6. Required fixes (minimal)
1. F1: add the handle-visibility rows to `RoleMatrixIT`/`IdorMatrixIT` (or record in the Decision Log that `PaymentHandleVisibilityIT` replaces the matrix extension and why). No code change to the feature is required.

## 7. Human check (done by the owner): ✔/✘ + notes
