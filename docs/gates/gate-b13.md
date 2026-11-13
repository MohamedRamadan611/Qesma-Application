# Gate B13 — Settlement v2 (two-sided settlements) — 2026-11-13

**Scope:** the uncommitted B13 working tree on `main` (HEAD `2389b18`, B12). No `gate-*` tags exist, so diff hygiene is against `HEAD` (working tree).
**Gate definition used:** `docs/PHASE1_VALIDATION_GATES.md` has no B13 row (Phase 1 only). I used the B13 prompt (`.claude/commands/b13-settlement-v2.md`, "Tests" list), PHASE2_SPEC §6 and §12 criterion 3, and Decision Log A83–A89.

> **Independence disclosure.** The verifier session was the same Claude conversation that reviewed this diff earlier in the session (`/r-review`). It did not write the code, but it is not a fresh session. Every result below comes from a command run in this session.

## 1. Summary
The test suite is green with no skipped tests, and the live probes behaved as specified on every point of the lifecycle and authorization surface. The OpenAPI document served by the running app is identical to `docs/openapi.json`. Two defects were found, both on money and error-format handling: a fractional or string `amountMinor` is silently accepted (1.5 became 1 piaster), and malformed JSON gets an `about:blank` problem type with 400, not 422. Neither is new in B13. The two-user role/state paths were not probed live; I relied on the integration tests for them (marked as such).

**Verdict: GO WITH FIXES.**

## 2. Checks

| # | Check | Command | Evidence | Result |
|:--|:--|:--|:--|:--|
| 1 | Clean build (re-run, 2026-11-13 after stopping the stale process PID 17828 that locked the jar, with the owner's approval) | `cd backend && ./mvnw clean verify` | exit 0, `Tests run: 234, Failures: 0, Errors: 0, Skipped: 0` (unit), `Tests run: 284, Failures: 0, Errors: 0, Skipped: 0` (integration), `BUILD SUCCESS`, total time 09:11 min. `failsafe-summary.xml`: completed 284, errors 0, failures 0, skipped 0. The first attempt failed at the `clean` step on the jar lock (`being used by another process`). | **PASS** |
| 1b | Earlier fallback build (superseded by row 1) | `./mvnw test-compile surefire:test failsafe:integration-test failsafe:verify` | same counts, `BUILD SUCCESS` | PASS |
| 2 | Stack starts, health | `docker compose up -d db`; `./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth --server.port=18090` (ports 8080 and 18080 are held by other processes, PIDs 7980 and 17828; not touched) | db `Up 24 hours (healthy)`. `GET /actuator/health` → `{"status":"UP","groups":["liveness","readiness"]}`. Flyway V15 applied on startup (app reached UP; `flyway_schema_history` not queried directly). | **PASS** |
| 3 | V15 backfill keeps balances identical | `SettlementStatusMigrationIT` | 2 tests, 0 failures. Not re-checked by hand on a pre-V15 database. | **PASS** (via IT only) |
| 4 | Balance rule: only CONFIRMED moves nets; `Σ nets = 0` | `SettlementBalanceRuleIT` (4), `SettlementBalancePropertyIT` (jqwik, real PostgreSQL), `BalanceRuleFilterTest` | all green, 0 failures. Live: after four CONFIRMED settlements of 1000 + 1 + 10 + 7, `GET /balances` → nets `1018 / -1018 / 0` | **PASS** |
| 5 | State machine, every cell and actor | `SettlementTransitionsTest`, `SettlementLifecycleIT` (11) | green. Live (owner = manager, ghost-to-ghost settlement, CONFIRMED): cancel → 409 `INVALID_STATE_TRANSITION`, confirm → 200 (no-op), dispute → 403 `FORBIDDEN`. | **PASS** (live probe covers 3 cells; the rest via IT) |
| 6 | Parallel confirm vs cancel, one winner | `SettlementConcurrencyIT` (2 tests × 25 rounds) | green: `[200, 409]` in every round | **PASS** (via IT only) |
| 7 | Constant statement count (1 vs 50) | `SettlementQueryCountIT` | 2 tests, 0 failures | **PASS** (via IT only) |
| 8 | Idempotent create; key write and business write atomic | `SettlementAtomicityIT`; live replay | live: same key + same body → 201 with the stored body; same key + different body → 422 `IDEMPOTENCY_KEY_REUSED` | **PASS** |
| 9 | Authorization (payer cannot confirm own payment; stranger 404; member 403 on record-on-behalf) | `IdorMatrixIT`, `RoleMatrixIT`; live stranger probe | live: a non-member token on all 7 routes (create, list, balances, confirm, dispute, cancel, DELETE) → 404 `NOT_FOUND` each. Payer-confirm and member-403 paths were NOT exercised live (they need two linked accounts); covered by `RoleMatrixIT` only. | **PASS** (stranger live; rest via IT) |
| 10 | Mass assignment (client cannot set status or timestamps) | live: POST with `"status":"PENDING","confirmedAt":"2020-01-01T00:00:00Z","recordedByAdmin":false` | 201 created; unknown fields ignored. I did not read the stored row back, so the effect on the stored status is NOT VERIFIED beyond the IT. | **NOT VERIFIED** (live); IT covers it |
| 11 | Ledger immutability: Phase 1 DELETE removed | live `DELETE /groups/{gid}/settlements/{sid}` as owner | 404 (route gone) | **PASS** |
| 12 | OpenAPI fidelity | `GET /v3/api-docs` vs `docs/openapi.json`, both `jq -S` | `diff` = 0 lines; `ApiContractCoverageIT` green | **PASS** |
| 13 | Seed adds one PENDING and one DISPUTED settlement | `DevSeedIT` | green. The seed profile (`local & seed`) was not started. | **PASS** (via IT only) |

## 3. Adversarial probes (live, port 18090, owner token unless noted)

| Probe | Result |
|:--|:--|
| Stranger token on every group-scoped settlement route (7) | 404 `NOT_FOUND` on all. **PASS** |
| No token / garbage token | 401 / 401. **PASS** |
| Same Idempotency-Key, different body | 422 `IDEMPOTENCY_KEY_REUSED`. **PASS** |
| Missing Idempotency-Key | 422 `VALIDATION_ERROR`. **PASS** |
| `amountMinor` 0 / -5 | 422 `VALIDATION_ERROR` ("must be greater than zero"). **PASS** |
| `amountMinor` 10^12+1 and Long.MAX_VALUE | 422 `VALIDATION_ERROR` ("at most 1000000000000"). **PASS** |
| `amountMinor` 9223372036854775808 (Long.MAX+1) | 400, `type: about:blank`, `detail: "Failed to read request"`, `code: VALIDATION_ERROR`. Status and problem type differ from the 422 used elsewhere. **FAIL (minor)** |
| `amountMinor` `1.5` | **201, stored as `amountMinor: 1`**: the fraction is silently truncated. **FAIL** (invariant 1) |
| `amountMinor` `"10"` (string) | **201, stored as 10**: a string is coerced to a number. **FAIL (minor)** |
| Unknown `fromMemberId` | 422 `MEMBER_NOT_IN_GROUP`. **PASS** |
| `from == to` | 422 `VALIDATION_ERROR`. **PASS** |
| Malformed JSON | 400, `type: about:blank`, `code: VALIDATION_ERROR`. Same inconsistency as the Long.MAX+1 row. **FAIL (minor)** |
| 2 MB `note` | 413 `VALIDATION_ERROR` ("Request body is too large"). **PASS** |
| Settlement id of another group through own group path | 404. **PASS** |
| Unknown settlement id | 404. **PASS** |
| `?status=BOGUS` / `?size=101` | 422 / 422. **PASS** |
| Stale ETag | **NOT RUN**: settlements have no ETag or `If-Match`; this is an expense feature unchanged in B13. |
| Duplicate member ids in payers | **NOT RUN**: expense feature, not touched in B13. |

## 4. Diff hygiene
- **New dependencies:** none (`backend/pom.xml` not in the diff).
- **Fixtures (`/fixtures/*.json`):** none changed.
- **Disabled tests / TODO / FIXME / catch-all handlers:** none in the added lines.
- **Existing tests modified (contract change, expected values changed):**
  - `BalancesSettlementsIT`: the "delete a settlement" test now asserts 409 `INVALID_STATE_TRANSITION` and that the confirmed payment stays. Expected nets changed from `-3000 / 0` to `-8000 / 5000` in the follow-up assertion, and from `-1000 / -2000 / 3000` to `-9000 / 6000 / 3000`. The new values are consistent with the settlement no longer being deletable. Phase 1 V1/V2 scenarios themselves are covered by `SettlementStatusMigrationIT`, which I did not re-derive.
  - `IdorMatrixIT`, `RoleMatrixIT`, `ApiContractCoverageIT` (operations 26 → 28), `DevSeedIT`, `BalancesPerformanceIT`, `SettlementApiSliceTest`: updated for the new routes and statuses.
  - Two tests now soft-cancel through raw SQL (`update settlements set status = 'CANCELLED' ...`) because the API can no longer cancel a CONFIRMED row.
- **Outside B13 scope:** `DevSeedRunner` and `scripts/smoke.sh` carry B12 work (invite, join, leave seed; member count 5 → 4). Not harmful, but it makes B13 not a clean commit.
- **Environment:** `./mvnw clean` fails because another process locks `backend/target/*.jar` (documented quirk).

## 5. Findings

| # | Severity | Finding |
|:--|:--|:--|
| F1 | Major | `amountMinor` `1.5` is stored as 1 piaster and `"10"` is accepted as 10 (see section 3). This violates AGENTS.md invariant 1 (integer money only) at the API boundary. `SettlementCommand` is not in the diff, so this predates B13, but a money endpoint should reject it. |
| F2 | Minor | Malformed JSON and a number above Long.MAX return 400 with `type: about:blank` instead of a 422 problem. AGENTS.md invariant 8 asks for a stable code; the code is present but the status and type are inconsistent with the other validation errors. |
| F3 | Closed | The true clean build now passes (row 1); the earlier lock came from a stale `java -jar` process (PID 17828) left over from an earlier session. |
| F4 | Minor | B12 seed and smoke changes are bundled in the B13 working tree. |
| F5 | Info | The role/state paths (payer cannot confirm own payment, a member recording between two others gets 403, receiver-only dispute) were not exercised against the running app, only by `RoleMatrixIT` and `SettlementLifecycleIT`. |

## 6. Verdict: GO WITH FIXES

Minimal fixes:
1. Reject fractional and string `amountMinor` (strict long parsing, 422 `VALIDATION_ERROR`) on settlement create, and check the expense endpoints for the same coercion.
2. Return the malformed-JSON and out-of-range-number cases as 422 problems with a stable type (or document 400 as the contract and add it to the error table).
3. Split the B12 seed and smoke changes from the B13 commit.
