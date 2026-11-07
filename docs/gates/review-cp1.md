# CP1 review — B0 (bootstrap), B3 (engine), B1 (auth), B2 (groups/members)

**Date:** 2026-11-07 · **Mode:** full review of the working tree (nothing from B0–B3 is committed; no `gate-*` tags)
**Reviewer:** the same session that wrote the code. This is a **self-review**, not the independent `V` gate. It does not satisfy any gate.
**Method:** read-only. No code, config or data was changed. No application or integration test was run for this report; the only build evidence is the earlier `./mvnw test` run (119 tests, 0 failures, JDK 21.0.12.1).

---

## 1. Decision summary

**Overall assessment.** The money engine and the ownership design are in good shape on paper: pure Java, exact integer arithmetic, one authorization door, uniform 401/404 bodies. The main risks are not algorithmic. They are a fail-open default profile with a committed dev signing key, broken B0 run instructions, and the fact that every database-backed claim (migrations V1–V4, concurrency, isolation, logging) has never been executed because Docker has not been available. **CP1 cannot be declared passed.** Review confidence: **Medium** (static reading only; the evidence ceiling for performance is *uninstrumented*, which caps performance findings at Medium).

**Top three actions**

| Order | Finding | Action | Why now |
|:--|:--|:--|:--|
| 1 | SEC-001 | Remove `spring.profiles.default: local` (or restrict the dev JWT secret to `fake-auth`). | A forgotten profile variable ships a publicly known signing key. |
| 2 | COR-001 | Fix the documented run command (`local,fake-auth`) or the startup message. | The documented B0 flow no longer starts. |
| 3 | — | Start Docker, run `./mvnw clean verify`, commit and tag, then run `V` for B0/B3/B1/B2. | Nothing database-backed has ever run. |

**Key unknowns**

| Unknown | Decision it changes | How to resolve |
|:--|:--|:--|
| Do V1–V4 apply and does Hibernate `ddl-auto=validate` accept the entities (notably `char(3)` currency, `bytea` hash)? | Whether B2 is releasable at all | `./mvnw verify` with Docker |
| Do the concurrency ITs hold (16 parallel member creates, double refresh, 8 parallel PATCH)? | Whether the locking design is correct | Same run |
| Does the CI secret-scan job pass with the committed dev/test secrets? | Whether CI is green | Push and read the job |

**Validation commands**

| Finding / unknown | Safety | Command | Decision it unlocks |
|:--|:--|:--|:--|
| All DB-backed unknowns | safe-on-production (local only) | `cd backend && ./mvnw clean verify` | GO / fix list for CP1 |
| SEC-001 | safe-on-production | `grep -n "default: local\|jwt-secret" backend/src/main/resources/*.yml` | Confirms the fail-open default is gone |
| COR-001 | safe-on-production | `./mvnw spring-boot:run -Dspring-boot.run.profiles=local` | Confirms the documented command starts (or fails clearly) |

---

## 2. CP1 STEP 3 checks — status

| CP1 requirement | Status | Why |
|:--|:--|:--|
| Re-run B3 engine and B1/B2 ownership checks together | **NOT VERIFIED** | Docker is stopped. Docker-free part ran: 119 unit/slice tests pass. Never run: `QesmaApplicationIT`, `AuthFlowIT`, `AuthRateLimitIT`, `GroupsMembersIT`, `DeleteRulesIT`; migrations V1–V4 on Postgres. |
| Every group-scoped route from the OpenAPI document returns 404 for user B | **BLOCKED** | `docs/openapi.json` does not exist (B8). Routes taken from code (6): `GET`/`PATCH`/`DELETE /groups/{gid}`, `POST /groups/{gid}/members`, `PATCH`/`DELETE /groups/{gid}/members/{mid}`. `GroupsMembersIT.anotherUsersGroupAndMembersAreNotFoundOnEveryVerb` covers all six plus a cross-group member id, but the list is hand-written (a new route is not covered automatically) and the test has not run. |
| Gate reports for B0/B3/B1/B2 exist and say GO / GO WITH FIXES | **MISSING** | `docs/gates/` did not exist before this file. Four independent `V` sessions are needed, each with Docker. |
| Clean build from the commit of the last gate tag | **BLOCKED** | No commit, no tags. |

**CP1: not passed.**

---

## 3. Scope and method

**Reviewed:** `backend/src/main` (engine, security, service, api, persistence, domain, resources, migrations V1–V4), `backend/src/test`, `pom.xml`, `Dockerfile`, `docker-compose.yml`, `.github/workflows/ci.yml`, `fixtures/engine`, `docs/adr`, `backend/README.md`, Decision Log A11–A24.
**Not reviewed:** runtime behaviour (nothing was started), real Google JWKS retrieval, CI execution, mobile.
**Evidence available:** Uninstrumented — no load test, no `EXPLAIN` output, no metrics endpoint exposed (actuator is health/info only). Counters exist in code but are not scraped.
**Ranking method:** structural signals only (static reading).
**Reference depth:** Postgres, REST and JVM reference files exist in the skill; the Spring/Hibernate specifics here are covered by category principles only.

---

## 4. Performance review (change-scoped to B0–B2; verdict **WARN**)

**Workload (assumed, from the spec, not measured):** one organizer per group, about 15 members and 500 expenses per group (spec 11), a few groups per user, a small VPS. No traffic figures exist; all workload-dependent findings are capped at Medium confidence.

**Critical paths:** `POST /auth/google` (one outbound HTTPS call to Google keys, then two short transactions), authenticated requests (in-process JWT check, no database hit), `GET /groups` (1 select + 1 count), member create (row-locked, serialized per group).

**Shared resources:** the Hikari connection pool (framework default), the per-group row lock, the in-memory rate-limit map.

### PERF-001 — Unbounded wait on row locks
| | |
|:--|:--|
| **Severity / Confidence / Priority** | Medium / Low / P3 |
| **Category** | concurrency |
| **Location** | `persistence/ExpenseGroupRepository.java:20`, `persistence/RefreshTokenRepository.java:17` |

**Problem.** `SELECT … FOR UPDATE` has no lock timeout. If a transaction holding a group row stalls, other requests for that group wait without limit and hold pool connections while waiting.
**Evidence.** No `jakarta.persistence.lock.timeout` or statement timeout anywhere in `src/main/resources`. No runtime evidence.
**Conditions.** Matters only if some transaction can stall while holding the lock (slow disk, a future ledger writer doing more work under the same lock in B4/B7) and a group sees concurrent requests.
**Counter-evidence.** Searched for lock/statement timeout settings: none. Current transactions are short and do no I/O besides SQL.
**Why this might not matter.** At one organizer per group, contention on one group row is rare.
**Recommendation.** Set a lock timeout and a statement timeout, chosen after measuring (no number is proposed here).
**Validation.** Hold a lock in one session (`BEGIN; SELECT … FOR UPDATE;`) and issue a member create from another; expect a bounded error instead of a hang — `not-safe-on-production`.

### Considered and not reported
- N+1 on `GET /groups`: member count is a correlated subquery inside the same statement; no loop. No `EXPLAIN` was captured, so index use is inferred from `ix_expense_groups_owner_created` and `uq_members_group_sort_order`.
- Network call inside a transaction: `AuthService` is not transactional; the Google call happens before any database work. Good.
- Rate-limit map growth: see SEC-004 (it is a resource-abuse point, listed there).

---

## 5. Adjacent and spec-compliance findings (severity-ranked)

Severity here is reviewer judgement (blocker / major / minor / nit), not the performance matrix.

| # | Sev | ID | Finding | Where |
|:--|:--|:--|:--|:--|
| 1 | **Major** | SEC-001 | Fail-open default profile with a committed dev signing key | `application.yml:5`, `application-local.yml:11` |
| 2 | **Major** | COR-001 | Documented run command no longer starts | `README.md:15`, `backend/AGENTS.md:7`, `NimbusGoogleIdTokenVerifier.java:77` |
| 3 | **Major** | SEC-002 | No cap on groups per user or members per group; unpaged member read | `MemberService.add`, `GroupService.create`, `MemberRepository.findByGroupIdOrderBySortOrderAsc` |
| 4 | Minor | COR-002 | PATCH group returns `members: []` although members are unchanged | `GroupController.java:68` |
| 5 | Minor | SEC-003 | Personal data can reach server logs via unexpected database errors | `GlobalExceptionHandler.java:92` |
| 6 | Minor | COR-003 | Every unmapped framework error is labelled `VALIDATION_ERROR` | `GlobalExceptionHandler.java:54` |
| 7 | Minor | MAINT-001 | Test profile (JWT secret, huge rate limit) ships in the production jar | `src/main/resources/application-test.yml` |
| 8 | Minor | MAINT-002 | CI secret scan will probably flag the base64 dev/test secrets | `.github/workflows/ci.yml` |
| 9 | Minor | SEC-004 | Rate limiter: proxy IP sharing; map trimmed only past 10,000 entries | `AuthRateLimitFilter.java:29,58,60` |
| 10 | Minor | COR-004 | Token for a deleted user could turn a group create into a 500 (not reachable in Phase 1) | `GlobalExceptionHandler.handleIntegrity` |
| 11 | Minor (tests) | MAINT-003 | Property test swallows `EngineException` when the adjustment is negative | `EnginePropertyTest.java:76` |
| 12 | Minor (tests) | MAINT-004 | Weak or unrun assertions (see detail) | `ItemizedCalculatorTest`, `GroupsMembersIT`, `AuthFlowIT` |
| 13 | Nit | — | `EQUAL` keeps zero-owed participants (A13); `totalSpentMinor` placeholders | `SplitCalculator`, `GroupDtos` |

### SEC-001 — Fail-open default profile and committed dev secret
| | |
|:--|:--|
| **Kind / Confidence / Risk** | Security / High / High |
| **Location** | `backend/src/main/resources/application.yml:5`, `application-local.yml:11` |

**Problem.** `spring.profiles.default: local` activates the local profile whenever `SPRING_PROFILES_ACTIVE` is unset. The local profile supplies a default `jwt-secret` that is committed to git, enables Swagger and DEBUG logging.
**Evidence.** The two lines above. `application-prod.yml` has no secret default, so prod fails safely only if the prod profile is actually active; the Dockerfile sets it, other deployment paths may not.
**Impact.** A deployment that forgets the profile variable accepts access tokens signed with a publicly known key, so anyone could forge a token for any user id (High risk).
**Recommendation.** Remove the default profile (fail fast with no profile), or allow the dev secret only when `fake-auth` is active.
**Trade-offs.** Developers must pass `-Dspring-boot.run.profiles=…` (already documented).
**Validation.** Start with no profile and no `QESMA_JWT_SECRET`: expect startup failure.
**Would need.** A dedicated security review before the first real deployment (B8).

### COR-001 — Documented run command no longer starts
**Problem.** After B1, the real Google verifier refuses to start without `GOOGLE_CLIENT_IDS`; local defaults it to empty. `README.md:15` and `backend/AGENTS.md:7` still show `-Dspring-boot.run.profiles=local` and expect `/actuator/health` UP. **Evidence:** `application-local.yml:13`, `NimbusGoogleIdTokenVerifier.java:77`. **Risk:** Medium (blocks every new developer). **Recommendation:** document `local,fake-auth` as the default local command, or use a clearer failure message. **Validation:** run the documented command.

### SEC-002 — No growth caps
**Problem.** Any signed-in user can create unlimited groups and members; `GET /groups/{gid}` returns every member in one response. Only `/api/v1/auth/**` is rate limited. **Evidence:** no limit or cap in `MemberService`/`GroupService`; spec 11 assumes about 15 members. **Risk:** Medium (storage and response growth, abuse). **Recommendation:** per-user and per-group caps plus a general request limit in B8; record the numbers in the Decision Log. **Would need:** the B8 security pass.

### COR-002 — PATCH response contains a false empty member list
`GroupController.update` builds `GroupDto.from(updated, List.of())`, so a client that replaces its state with the response loses its members. **Risk:** Medium for the mobile client. **Recommendation:** return the real members, or a response type without the field. **Validation:** contract test comparing PATCH and GET bodies.

### SEC-003 — Personal data in logs
Unexpected `DataIntegrityViolationException`s are logged with the full exception (`log.error("Unhandled exception", ex)`); PostgreSQL's message may include the offending row values, i.e. member or group names. AGENTS invariant 10 allows ids only. **Risk:** Medium. **Recommendation:** for database exceptions log only the exception class and constraint name. **Validation:** trigger a CHECK violation and grep the log for the inserted name.

### COR-003 — Wrong stable code for unmapped errors
`handleExceptionInternal` defaults to `VALIDATION_ERROR` for anything that is not 404 (405, 406, 415 …). **Risk:** Low; clients keyed on `code` will misreport. **Recommendation:** map by status; keep codes within the spec list plus the documented additions.

### MAINT-001 / MAINT-002 — Test config in the jar; CI secret scan
`application-test.yml` sits in `src/main/resources` (JWT secret, client id, rate limit 1000), so it is packaged. Move it to `src/test/resources`. The committed base64 secrets (`application-local.yml:11`, `application-test.yml:5`) will likely trigger gitleaks' generic-key rule; add an allowlist or restructure. CI has never run, so this is unverified.

### SEC-004 — Rate limiter limits
Keys on `request.getRemoteAddr()`; behind a reverse proxy all clients share one bucket unless forwarded headers are enabled (documented, not configured). The map is only pruned once it exceeds 10,000 entries and then only drops expired windows. **Risk:** Low–Medium.

### COR-004 — Token for a missing user
A valid access token whose user no longer exists would make `POST /groups` hit the `owner_user_id` FK and return 500. No user deletion exists in Phase 1, so not reachable today.

### MAINT-003 — Hidden rule in the property test
`EnginePropertyTest.java:76` catches any `EngineException` when the adjustment is negative and asserts only the code. It cannot tell the "total must be positive" rejection from the "adjustment makes a member's share negative" guard (Decision A12). My earlier statement that the guard is effectively unreachable was **not proven**; rounding at the edge may reach it. Add a direct test with an adjustment close to the total, and assert on the specific reason.

### MAINT-004 — Weak or unrun assertions
- `ItemizedCalculatorTest.hugeItemAmountsFail…` asserts only the exception type.
- The `handleIntegrity` → `DUPLICATE_MEMBER_NAME` mapping has no test.
- The optimistic-lock → `VERSION_CONFLICT` mapping is covered only by an IT that has not run.
- `AuthFlowIT`'s log test asserts the logs do not contain the word "Authorization"; any dependency logging that word would make it flaky.

---

## 6. Review per prompt item

1. **Spec compliance:** endpoints, field names and error codes follow 8.2/8.5. Documented additions: `INTERNAL_ERROR`, `RATE_LIMITED`, `AUTH_PROVIDER_UNAVAILABLE` (A15), 428 for a missing `If-Match` (A21), `member_seq` column (A20).
2. **Money:** no `float`/`double`/`BigDecimal` in `engine` (`EnginePurityTest`); LRM uses `BigInteger`; fixtures V1–V8 and three property tests pass; overflow becomes a typed error. See MAINT-003 for the one untested corner.
3. **Authorization:** every group-scoped path goes through `GroupAccessService`; `LayeringTest` forbids repository use outside services; 404 bodies are identical for missing and foreign resources (IT written, not run).
4. **Idempotency / concurrency:** no create endpoint uses `Idempotency-Key` yet (A16, A24); first-login race is arbitrated by the unique constraint; member creation is serialized by the group row lock; refresh rotation uses `FOR UPDATE`. All unrun against Postgres.
5. **Migrations and queries:** V2–V4 create new tables only (no locks on existing data), with CHECK/UNIQUE/FK. List query: one select plus one count. Unbounded member read: SEC-002.
6. **Errors and logging:** no stack traces to clients; auth failures are one generic 401. See SEC-003 and COR-003.
7. **Tests:** see MAINT-003/004. Slice tests mock services but exercise the real security chain, so they do test what they claim.
8. **Scope creep:** none found; the extra error codes and the `member_seq` column are recorded decisions.

## 7. What is good
Pure, fixture-driven engine with enforced purity; a single authorization door with a layering guard; uniform 401/404 responses that do not reveal which check failed; refresh rotation that revokes the whole token family on reuse; counter-based `sort_order` that is never reused; no network call inside a database transaction.

## 8. Recommended fix order (separate F step)
1. SEC-001, COR-001.
2. SEC-003, COR-003, COR-002 (each with a test).
3. MAINT-001, MAINT-002.
4. Start Docker; `./mvnw clean verify`; fix what the unrun tests reveal; commit B0–B2; tag.
5. Independent `V` sessions for B0, B3, B1, B2 → `docs/gates/gate-b0.md`, `gate-b3.md`, `gate-b1.md`, `gate-b2.md`.
6. Backlog for B8 / tests: SEC-002, SEC-004, PERF-001, COR-004, MAINT-003, MAINT-004.

**If only one thing is done:** run `./mvnw clean verify` with Docker running; every claim of B1 and B2 depends on it.

## 9. Notes on this review
No runtime metric in this report was estimated. Findings are graded by evidence; none is `Confirmed` because no runtime artifact exists. The machine-readable JSON block of the performance template was not produced: there is one low-confidence performance finding and no scripted `stable_id` run, so the Markdown is the only artifact.
