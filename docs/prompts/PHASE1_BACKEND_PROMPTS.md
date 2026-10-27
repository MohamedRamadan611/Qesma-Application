# Phase 1 Backend — Agent Prompts (Claude Code / Antigravity)

Builds the Phase 1 backend of "Qesma" (Organizer Mode) exactly as specified in `PROJECT_SPEC.md` and `PROJECT_PHASES.md`. Stack: Java 21 · Spring Boot 3.x · PostgreSQL · Flyway · springdoc-openapi · JUnit 5 · jqwik · Testcontainers · Docker.

The work is split into **small prompts (B0–B8)**. Run them **one at a time, in order**, review and commit after each. Never paste two prompts into one session.

---

## 1. Setup before the first prompt

### 1.1 Put the project files in the repo
```
qesma/
  docs/PROJECT_SPEC.md
  docs/PROJECT_PHASES.md
  docs/STITCH_PROMPTS.md          (optional, UI reference)
  AGENTS.md                        (created by B0; content in section 3)
```

### 1.2 Make the skills available to the agent
The prompts name skills by their SKILL.md names. They are stack-agnostic backend disciplines (they work for Spring Boot).

- **Claude Code:** enable the plugin(s) that contain them, or copy each skill folder to `.claude/skills/<name>/SKILL.md` (project) or `~/.claude/skills/` (global). Claude Code reads `CLAUDE.md`; create `CLAUDE.md` containing the single line `@AGENTS.md` so both tools share one rules file.
- **Antigravity:** copy the skill folders to `<repo>/.agent/skills/<name>/SKILL.md` (workspace) or `~/.gemini/antigravity/skills/` (global). Antigravity skills are triggered by the agent when the task matches; also say the skill name in the prompt to force it. Rules live in `GEMINI.md`/`AGENTS.md`.
- **If a skill is not installed**, the prompts still work: `AGENTS.md` (section 3) contains the condensed rules, and each prompt restates the critical constraints.

### 1.3 Skills used
| Skill | Used for |
|---|---|
| `think-before-coding` | The 6-step design (context, data, failures, authz, idempotence, observability) **before** any endpoint |
| `data-modeling-discipline` | Constraints in the schema (CHECK/UNIQUE/FK), invariants |
| `migration-safety` / `review-migration` | Every Flyway migration |
| `query-discipline` / `hunt-n-plus-one` / `explain-this-query` | Repositories, list endpoints, balances query |
| `security-discipline` | Per-diff security reflex (IDOR/BOLA, mass assignment, injection, secrets) |
| `auth-and-authorization` | Google sign-in, JWT/refresh, owner-only access, central authorization |
| `idempotency-and-side-effects` | `Idempotency-Key` on creates |
| `error-handling-as-design` | problem+json, stable error codes, no swallowed exceptions |
| `observability-by-default` | Structured logs, request ids, RED metrics, real health check |
| `testing-with-discernment` | What to test (money math, authz, idempotency), what to skip |
| `performance-and-scaling` / `backend-performance-review` | Sizing assumptions, balance computation, indexes |
| `boring-by-default` | Resist unneeded tech (no Kafka/Redis/microservices) |
| `api-doc-generator` / `api-docs-check` | OpenAPI accuracy for the generated Dart client |
| `documentation`, `architecture` | README, runbook, ADRs |
| `code-review`, `audit` | Review after each milestone |
| `deploy-checklist` | Before first deploy |
| `debugging-discipline` | When something breaks |

> `senior-engineering-partner` is **not** used: its language scope is Python/Bash/JS/Swift, not Java.

### 1.4 How to run each prompt
1. Start a **fresh session** per prompt (clear context). The agent re-reads `AGENTS.md` and the spec sections named in the prompt.
2. Use **plan mode** (or "Planning" mode) if your tool has it: let the agent show its plan, approve it, then let it implement.
3. When it finishes: run the tests yourself (`./mvnw verify`), read the diff, run prompt **R** (review), then commit.
4. If the agent finds the spec ambiguous or contradictory, it must **stop and ask** (rule in `AGENTS.md`). Record the answer in the spec's Decision Log (use prompt **S**).

---

## 2. Run order and dependencies

```
B0 Bootstrap
 ├─ B3 Split engine (pure Java, no dependencies — can run right after B0, even before B1)
 ├─ B1 Auth & security foundation
 │    └─ B2 Groups & members
 │         └─ B4 Expenses core (needs B2 + B3)
 │              ├─ B5 Itemized expenses + preview
 │              └─ B6 Edit / delete / revisions / concurrency
 │                   └─ B7 Balances & settlements
 │                        └─ B8 Hardening, OpenAPI handoff, deploy
```
Recommended order: **B0 → B3 → B1 → B2 → B4 → B5 → B6 → B7 → B8** (engine first, because it is the riskiest and needs no infrastructure). Then, in parallel with the Flutter work, nothing else is needed from the backend except bug fixes (prompt **F**).

Spec milestone mapping: B0+B1 = M1 · B2 = M2 · B3 = M3 · B4+B5+B6 = M4 · B7 = M5 · B8 = M7.

---

## 3. AGENTS.md (created by B0; content to use)

```markdown
# AGENTS.md — Qesma backend rules (read before every task)

## Source of truth
- docs/PROJECT_SPEC.md (Phase 1 detail) and docs/PROJECT_PHASES.md (whole project). Section numbers are cited in prompts.
- If the spec is ambiguous or contradicts itself or the task, STOP and ask. Never guess money rules. Record answers in the spec's Decision Log.

## Non-negotiable invariants
1. Money = `long` minor units (piasters). Percentages = integer basis points. No float/double/BigDecimal-for-math in money paths. Use Math.multiplyExact/BigInteger for intermediate products.
2. The app never holds, moves, or processes money. It only records.
3. The engine package (`engine`) is pure Java: no Spring, JPA, or I/O. All money rules live there.
4. The backend is authoritative for all calculations.
5. Ledger is never hard-deleted. Edits create revisions; deletes are soft. Balances are computed, never stored.
6. Every create endpoint is idempotent via `Idempotency-Key` (spec 8.3). Key write and business write share one transaction.
7. Authorization: Phase 1 = owner-only. Another user's group => 404 (not 403). All checks go through one central component.
8. Errors: RFC 7807 problem+json with a stable `code` from the spec's list (8.5). No swallowed exceptions. No stack traces to clients.
9. Schema invariants live in the database (CHECK, UNIQUE, FK, NOT NULL). Flyway migrations are forward-only and reviewed.
10. No secrets in code, logs, or git. Never log tokens, Authorization headers, or personal data beyond ids.
11. Do not build anything outside the Phase 1 scope (spec 3.2). Do not add libraries or infrastructure (Redis, Kafka, microservices) without an ADR and my approval.

## Working method
- Before writing code for a component: do the 6-step design (context/load, data & invariants, failure modes, authorization, replay/concurrency, observability) and summarize it in 10–20 lines. Wait for approval if I asked for plan mode.
- Tests first for money logic. Test what matters (money, authz, idempotency, concurrency); do not write coverage-only tests. Integration tests use Testcontainers (real PostgreSQL), never H2.
- Verify before asserting: run the build/tests and quote real output. Do not invent library versions, config keys or APIs: check the dependency's documentation/sources or Maven Central.
- Small, reviewable commits. Do not refactor unrelated code. Do not widen scope silently.
- Definition of done: compiles, all tests pass, migrations included and reviewed, OpenAPI accurate, no TODO for in-scope behavior, summary of what changed + assumptions + how to verify.

## Conventions
- Java 21, Spring Boot 3.x (latest stable at generation time; pin it), Maven wrapper.
- Base package: `app.qesma` (placeholder; keep in one place). Subpackages: api, domain, engine, service, security, persistence.
- DTOs as Java records; no Lombok. Constructor injection. `@Transactional` on service methods only.
- REST under `/api/v1`. UUID ids. Timestamps UTC `timestamptz`.
- Shared test vectors live in `/fixtures/*.json` at the repo root.

## Stop protocol
After finishing a prompt: (1) run the full test suite, (2) list assumptions and open questions, (3) list files changed, (4) do NOT start the next milestone.
```

---

## B0 — Bootstrap & agent memory
**Skills:** `boring-by-default`, `think-before-coding` (light), `documentation`, `architecture` (one ADR), `observability-by-default`

```text
Read docs/PROJECT_SPEC.md sections 0, 5, 11, 13 and docs/PROJECT_PHASES.md sections 0.1 and 6. If AGENTS.md does not exist, create it with exactly the content pasted after this prompt (section 3 of this document), plus a one-line CLAUDE.md containing "@AGENTS.md".

Goal: bootstrap the monorepo and an empty-but-production-shaped Spring Boot skeleton. NO business logic yet.

Plan first (short), then implement:
1. Repo layout: /backend, /mobile (README placeholder only), /docs (the spec files), /fixtures (README explaining the shared test-vector format).
2. Backend: Java 21, Spring Boot 3.x — use the latest stable release and VERIFY the version from start.spring.io or Maven Central; do not guess. Maven with wrapper. Base package app.qesma with subpackages api, domain, engine, service, security, persistence.
3. Dependencies: spring-boot-starter-web, validation, security, data-jpa, actuator; PostgreSQL driver; flyway-core + the PostgreSQL Flyway module; springdoc-openapi (Spring Boot 3 starter); test: spring-boot-starter-test, spring-security-test, Testcontainers (postgresql + junit-jupiter), jqwik, AssertJ. No Lombok. No extra libraries.
4. Config: application.yml with profiles local/test/prod; every secret from environment variables; commit a .env.example; spring.jpa.hibernate.ddl-auto=validate; open-in-view=false.
5. Docker: docker-compose.yml with PostgreSQL (version pinned) for local dev; a multi-stage Dockerfile for the backend running as non-root.
6. Flyway: V1__baseline.sql (empty/comment) just to prove the pipeline.
7. Cross-cutting foundations only: (a) a request-id filter that puts a request id in the MDC and the response header; (b) structured JSON logging; (c) a global exception handler skeleton producing RFC 7807 problem+json with a stable "code" field and no stack traces; (d) Actuator exposing only health/info with a real DB health check; (e) springdoc enabled in local profile only.
8. CI: GitHub Actions workflow running ./mvnw verify (Testcontainers needs Docker), caching Maven; add a secret-scanning step if a free, simple option exists.
9. docs: backend/README.md (run, test, env vars) and docs/adr/ADR-001-stack.md (Maven, Spring Boot version pinned, PostgreSQL, why no Redis/Kafka).
10. One smoke integration test using Testcontainers proving: context starts, Flyway ran, /actuator/health is UP.

Constraints: follow AGENTS.md. Do not create entities, controllers or auth in this prompt.
Done when: ./mvnw verify passes locally; docker compose up starts the DB; the app starts; /actuator/health is UP; CI file is valid. Then follow the Stop protocol in AGENTS.md.
```

---

## B3 — Split engine (pure Java)
**Skills:** `think-before-coding` (data & failure modes), `testing-with-discernment`, `error-handling-as-design`, `data-modeling-discipline` (invariants)
*(Run right after B0.)*

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 2, 6 (only the money columns), 7 (all), 10 (all). This prompt builds ONLY the `engine` package in /backend: pure Java 21, no Spring, no JPA, no I/O. It is the most critical code in the project.

Step 0 (plan, wait for my approval): propose the engine API (types and method signatures), the validation/exception design (typed exceptions mapping later to the spec's error codes), and the fixture JSON format. Keep it small and boring.

Then implement with TESTS FIRST:
1. Types: member reference (id + sortOrder), money as long minor units, bps as int. Immutable records.
2. Largest Remainder Method (spec 7.1): exact shares with Math.multiplyExact/BigInteger (never floating point); floor + distribute remaining units by largest fractional remainder; tie-break lower sortOrder; zero total weight => equal weights; negative totals allocate abs and re-apply sign. round_half_up for bps amounts.
3. EQUAL (7.2), EXACT (7.3) with the exact validations and typed errors (SPLIT_TOTAL_MISMATCH etc.).
4. Payers validation (7.5): >=1 payer, amounts > 0, no duplicate member, sum == total (PAYERS_TOTAL_MISMATCH). Payers need not be participants.
5. ITEMIZED (7.4): item shares by LRM among assignees; optional service (own bps); optional tax (own bps, base SUBTOTAL or SUBTOTAL_PLUS_SERVICE, default SUBTOTAL_PLUS_SERVICE); optional signed adjustment allocated by LRM on item subtotals; every combination (service only / tax only / both / neither) must work; members with owed == 0 are dropped; total must be > 0; return per-member breakdown (items, service, tax, adjustment, owed) plus subtotal/service/tax totals.
6. Balances (7.6): nets from expenses (payers, splits) and settlements; invariant sum(net) == 0.
7. Simplification (7.7): the deterministic greedy algorithm with the exact tie-breaks.
8. Shared fixtures: create /fixtures/engine/*.json for ALL vectors V1–V8 from spec section 10 with exact expected numbers (minor units), plus a JUnit test that loads and runs every fixture. Fixture format: { name, input, expected } so a future Dart engine can reuse them.
9. Extra example tests worth writing: remainder ties, zero weights, item shared by 7 people, negative adjustment, tax base variants, rejecting mismatched payers/exacts, large amounts (1,250,000.50 EGP), overflow protection.
10. Property tests with jqwik: LRM parts sum exactly to the total and each part is within 1 minor unit of its exact share; sum(owed) == total; sum(net) == 0 after random sequences of expenses and settlements; applying the simplified transfers zeroes all nets; results are deterministic for the same input.

Constraints: follow AGENTS.md; no Spring imports anywhere under engine; no floating point; no randomness without a fixed seed in non-property tests; do not touch the database or HTTP layers.
Done when: all V1–V8 fixtures pass, property tests pass over thousands of cases, and I can read each rule in code next to its spec section number (reference the spec section in Javadoc). Then follow the Stop protocol.
```

---

## B1 — Auth & security foundation
**Skills:** `think-before-coding`, `auth-and-authorization`, `security-discipline`, `data-modeling-discipline`, `migration-safety`, `error-handling-as-design`, `observability-by-default`, `testing-with-discernment`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 5.1, 6 (users), 8.1, 8.2 (auth + /me), 8.5, 11, 14 (Decision A4: Google Sign-In only). Skills to apply: think-before-coding, auth-and-authorization, security-discipline, data-modeling-discipline, migration-safety, error-handling-as-design, observability-by-default, testing-with-discernment.

Step 0 (plan, wait for approval): the six-step design for the auth component: context/load, data model and invariants (users, refresh tokens), failure modes (invalid/expired Google token, refresh reuse, replayed refresh, clock skew), authorization map, replay/concurrency (two simultaneous first logins for the same Google account), observability.

Implement:
1. Flyway migrations: users (spec section 6) and refresh_tokens (id, user_id FK, family_id, token_hash, expires_at, revoked_at, replaced_by_id, created_at; indexes; CHECKs). Review them against migration-safety.
2. GoogleIdTokenVerifier as an INTERFACE. Real implementation validates the Google ID token (signature via Google's keys, issuer, audience against configured client IDs from env, expiry). A fake implementation is used in tests. Use an official/standard library; verify the dependency from its documentation; do not hand-roll crypto.
3. POST /api/v1/auth/google {idToken} -> creates the user if new (race-safe: unique constraint + upsert, never two users for one provider subject), returns { accessToken, refreshToken, user }.
4. Access token: short-lived JWT (about 15 minutes), signing key from env (document minimum length). Refresh token: opaque random 256-bit value, only its SHA-256 hash stored, rotating on every use, about 30 days. Reuse of a rotated refresh token revokes the whole family.
5. POST /auth/refresh, POST /auth/logout (revokes the family), GET /me, PATCH /me (displayName trimmed, 1–60 chars).
6. Spring Security: stateless filter chain; /auth/**, /actuator/health, and (local profile only) API docs are public; everything else requires a valid access token; authenticated principal exposes the user id; CORS disabled (mobile client).
7. Rate limiting on /auth/** (simple in-memory limiter is fine for one instance; document the limitation).
8. Error responses via the global problem+json handler with codes UNAUTHORIZED / VALIDATION_ERROR. Never reveal which part of a token failed.
9. Logging: never log tokens or Authorization headers; log auth events (login, refresh, reuse-detected) as structured events with user id and request id; add counters for logins and failures.

Tests (Testcontainers + fake verifier): first login creates one user even under concurrent calls; invalid audience/expired token rejected; refresh rotation works; reusing an old refresh token revokes the family; logout revokes; protected endpoint returns 401 without a token; /me update validates input; tokens never appear in logs (assert on captured log output).
Constraints: follow AGENTS.md; no email/password flow; no Phase 2 features. Done when ./mvnw verify passes and I can run the flow with curl using the fake verifier profile. Then follow the Stop protocol.
```

---

## B2 — Groups & members
**Skills:** `think-before-coding`, `data-modeling-discipline`, `migration-safety`, `auth-and-authorization`, `security-discipline` (IDOR/BOLA), `query-discipline`, `testing-with-discernment`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 3.1, 6 (expense_groups, members), 7.10, 8.1, 8.2 (groups and members), 8.5, 12. Skills: think-before-coding, data-modeling-discipline, migration-safety, auth-and-authorization, security-discipline, query-discipline, testing-with-discernment.

Step 0 (plan, wait for approval): six-step design, including how sort_order is assigned safely under concurrency, and the extension points for rules that depend on tables that do not exist yet (expenses/settlements).

Implement:
1. Flyway migration for expense_groups and members exactly as in spec section 6 (CHECKs, FKs, unique index on (group_id, lower(display_name))). Indexes for the access paths you will use (owner's groups, group members).
2. A single central component (e.g. GroupAccessService) that loads a group only if owned by the current user, otherwise throws NOT_FOUND (404). Every group-scoped endpoint must go through it (spec section 12: Phase 2 will replace it with roles).
3. Endpoints: POST/GET /groups, GET/PATCH/DELETE /groups/{gid}, POST /groups/{gid}/members, PATCH and DELETE /groups/{gid}/members/{mid}. Validation: group name 1–60 trimmed; type in TRIP/HOUSING/OUTING/OTHER; currency valid ISO 4217 (default EGP); member name 1–40 trimmed; duplicate names rejected (DUPLICATE_MEMBER_NAME).
4. GET /groups returns, per group: id, name, type, currencyCode, memberCount, totalSpentMinor (0 for now), lastExpenseAt (null for now) — the UI needs them; B4 will wire the last two. Record this addition as a proposed entry in the spec Decision Log (A11). GET /groups/{gid} returns the group with its members ordered by sort_order.
5. sort_order assigned incrementally and never reused, safe under concurrent member creation (lock the group row or equivalent) — prove it with a concurrency test.
6. PATCH group uses optimistic concurrency (version + If-Match/ETag) -> VERSION_CONFLICT.
7. Delete rules need data from tables that do not exist yet. Create two small interfaces now (e.g. MemberUsageChecker, GroupUsageChecker) with default implementations returning "unused", wire them into DELETE member (MEMBER_HAS_TRANSACTIONS) and DELETE group (GROUP_NOT_EMPTY), and write tests against a stub that returns "used". B4 and B7 will replace the defaults.
8. List endpoints paginated (page, size with a hard max); avoid N+1 (memberCount via a single query).

Tests (Testcontainers): ownership isolation (user B gets 404 for user A's group, members, and on every verb); validation errors with codes; duplicate member names (case-insensitive); concurrent member creation yields distinct sort_order; optimistic concurrency conflict; deletion rules via the stub; pagination.
Constraints: follow AGENTS.md; no invites/roles/LEFT status; no expense logic. Done when ./mvnw verify passes and the security reflex checklist (IDOR, mass assignment, input validation) is stated in the summary. Then follow the Stop protocol.
```

---

## B4 — Expenses core (EQUAL, EXACT, multi-payer, idempotency)
**Skills:** `think-before-coding`, `idempotency-and-side-effects`, `data-modeling-discipline`, `migration-safety`, `query-discipline`, `hunt-n-plus-one`, `security-discipline`, `error-handling-as-design`, `testing-with-discernment`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 6 (expenses, expense_payers, expense_splits, idempotency_keys), 7.2, 7.3, 7.5, 7.9 (participant snapshot), 8.1, 8.2, 8.3, 8.4, 8.5. Prerequisites: B2 and B3 are merged. Skills: think-before-coding, idempotency-and-side-effects, data-modeling-discipline, migration-safety, query-discipline, hunt-n-plus-one, security-discipline, error-handling-as-design, testing-with-discernment.

Step 0 (plan, wait for approval): six-step design, especially: the transaction boundary that contains the idempotency-key write and the business write; request-hash canonicalization; what is returned on replay; concurrent requests with the same key; and how "All" participants are resolved (explicit snapshot).

Implement ONLY these split types: EQUAL and EXACT (ITEMIZED comes in B5; reject it with VALIDATION_ERROR for now).
1. Flyway migrations: expenses (including the itemized columns, null for now), expense_payers, expense_splits, idempotency_keys, with all CHECK/FK/PK constraints from the spec. Review with migration-safety. Add indexes for listing expenses by group/date and for balance queries.
2. Request DTOs and validation per spec 8.4 (EQUAL: participantMemberIds; EXACT: shares; multi-payer: payers list). All members must belong to the group (MEMBER_NOT_IN_GROUP). Map errors to the codes in 8.5.
3. Service: validate -> call the engine (never duplicate money math) -> persist expense, payers, and the resolved splits (explicit participants and owed amounts) in one transaction.
4. POST /groups/{gid}/expenses requires Idempotency-Key. Same key + same body returns the stored response without creating anything; same key + different body returns IDEMPOTENCY_KEY_REUSED (422); a concurrent duplicate must still create exactly one expense (rely on the unique constraint, handle the race deterministically). A scheduled job deletes keys older than 24 hours.
5. GET /groups/{gid}/expenses (paged; filters fromDate, toDate, memberId; sorted by expenseDate desc, createdAt desc; soft-deleted excluded) and GET /groups/{gid}/expenses/{eid}. Responses include payers and per-member shares. Avoid N+1 (verify with a query count in a test).
6. Replace B2's default usage checkers so a member referenced by any payer/split blocks deletion, and a group with expenses cannot be deleted. Wire totalSpentMinor and lastExpenseAt in GET /groups.
7. Authorization through the central group access component; another user's group => 404.

Tests (Testcontainers): fixtures V1, V3, V4 (equal rounding, multi-payer) through the API; every validation error code for these types; idempotent replay (same key twice => one row, same response); concurrent duplicate requests (parallel threads) => one expense; key reuse with a different body; "All" snapshot persisted explicitly; query-count test for the list endpoint; IDOR tests.
Constraints: follow AGENTS.md; no editing/deleting expenses yet (B6); no itemized (B5). Done when ./mvnw verify passes. Then follow the Stop protocol.
```

---

## B5 — Itemized restaurant bill + preview endpoint
**Skills:** `think-before-coding`, `data-modeling-discipline`, `migration-safety`, `error-handling-as-design`, `testing-with-discernment`, `security-discipline`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 3.1 (itemized, optional service/tax), 6 (expense_items, expense_item_assignees, itemized columns), 7.4, 8.2 (preview), 8.4, 10 (vectors V5–V8), 14 (A1, A2). Prerequisite: B4 merged. Skills: think-before-coding, data-modeling-discipline, migration-safety, error-handling-as-design, testing-with-discernment, security-discipline.

Step 0 (plan, wait for approval): how the preview and create paths share one mapping/validation pipeline so they cannot diverge; how items and assignees are persisted; response shape of the preview (per-member breakdown, totals, payersTotalMatches).

Implement:
1. Flyway migration for expense_items and expense_item_assignees (constraints, indexes).
2. Support splitType ITEMIZED on create: items with >= 1 assignee each, amount > 0; optional service {bps}; optional tax {bps, base} with base defaulting to SUBTOTAL_PLUS_SERVICE; optional signed adjustmentMinor. Service and tax are INDEPENDENT: service only, tax only, both, or neither must all work. Validate bps range 0–10000. The expense total is computed by the engine; payers must sum to it (PAYERS_TOTAL_MISMATCH). Persist subtotal, service, tax, adjustment, tax_base, items, assignees, and the per-member resolved breakdown in expense_splits.
3. POST /groups/{gid}/expenses/preview (same body as create, no Idempotency-Key, persists nothing, safe to call repeatedly): returns totalMinor, subtotalMinor, serviceMinor, taxMinor, per-member { memberId, itemsMinor, serviceMinor, taxMinor, adjustmentMinor, owedMinor }, and payersTotalMatches. It works for EQUAL, EXACT and ITEMIZED. Add basic abuse protection (request size limits, max items per bill, e.g. 100).
4. GET expense endpoints return itemized details (items with assignees, charges, per-member breakdown).
5. Update the OpenAPI annotations so the request/response models and examples reflect all three split types.

Tests (Testcontainers): vectors V5, V6, V7, V8 end to end through the API with the exact numbers from spec section 10 (including the tie-break in V5); preview and create return identical breakdowns for the same body; validation (item without assignee, bps out of range, no items, payers mismatch); a payer who is not a participant; a bill where one member has no items (dropped from splits); negative adjustment; preview persists nothing (row-count assertion).
Constraints: follow AGENTS.md; do not change engine rules (if a rule seems wrong, stop and ask); no edit/delete yet. Done when ./mvnw verify passes. Then follow the Stop protocol.
```

---

## B6 — Edit, delete, revisions, optimistic concurrency
**Skills:** `think-before-coding`, `idempotency-and-side-effects`, `data-modeling-discipline`, `security-discipline`, `error-handling-as-design`, `testing-with-discernment`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 6 (expense_revisions), 7.9, 8.1, 8.2 (PUT, DELETE, revisions), 8.5. Prerequisite: B5 merged. Skills: think-before-coding, idempotency-and-side-effects, data-modeling-discipline, security-discipline, error-handling-as-design, testing-with-discernment.

Step 0 (plan, wait for approval): the six-step design for update/delete — transaction scope, how the version check is enforced atomically (no check-then-write race), what the revision snapshot contains, what a replayed or concurrent edit does.

Implement:
1. Flyway migration for expense_revisions (unique (expense_id, version), jsonb snapshot).
2. Write a revision on CREATE (retrofit into the create path from B4/B5), UPDATE and DELETE. The snapshot contains the full expense: header, payers, resolved splits, items, charges.
3. PUT /groups/{gid}/expenses/{eid} with If-Match (version): replaces payers/splits/items atomically through the same validation + engine pipeline as create, increments version, writes a revision. The client sends the explicit participant list (never silently add members who joined later). Missing/stale If-Match => VERSION_CONFLICT (409). Two concurrent updates with the same version: exactly one wins, the other gets 409 (enforce with an atomic conditional update or optimistic locking).
4. DELETE /groups/{gid}/expenses/{eid} with If-Match: soft delete (deleted_at), increment version, write a revision. Soft-deleted expenses disappear from lists and balances but remain in revisions. Deleting an already-deleted expense is a clean 404 or idempotent success (choose one, state it).
5. GET /groups/{gid}/expenses/{eid}/revisions: chronological list with changedBy, changedAt, changeType, and the snapshot (or a diff-friendly representation).
6. ETag/version returned on GET and in create/update responses.

Tests (Testcontainers): update recalculates splits correctly (use V5 then change service from 12% to 10%); revision count and content after create -> update -> delete; stale version => 409 and nothing changes; concurrent updates (parallel threads) => exactly one success; deleted expense excluded from list; IDOR on update/delete/revisions; edit cannot move an expense to another group; validation errors identical to create.
Constraints: follow AGENTS.md; no roles/permissions (owner-only). Done when ./mvnw verify passes. Then follow the Stop protocol.
```

---

## B7 — Balances & settlements
**Skills:** `think-before-coding`, `query-discipline`, `explain-this-query`, `idempotency-and-side-effects`, `data-modeling-discipline`, `performance-and-scaling`, `testing-with-discernment`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 6 (settlements), 7.6, 7.7, 7.8, 8.2 (balances, settlements), 8.3, 10 (V1, V2 and property tests). Prerequisite: B6 merged. Skills: think-before-coding, query-discipline, explain-this-query, idempotency-and-side-effects, data-modeling-discipline, performance-and-scaling, testing-with-discernment.

Step 0 (plan, wait for approval): decide how nets are computed — SQL aggregates for paid/owed/settlement sums feeding the engine's simplifier, versus loading rows and using the engine end to end. Justify with the expected load (up to ~15 members and ~500 expenses per group) and keep the engine as the only place with money rules.

Implement:
1. Flyway migration for settlements (CHECKs: amount > 0, from <> to), with indexes for group lookups.
2. POST /groups/{gid}/settlements (Idempotency-Key required; same machinery as expenses), GET /groups/{gid}/settlements, DELETE /groups/{gid}/settlements/{sid} (soft delete; reverses its effect). Both members must belong to the group (MEMBER_NOT_IN_GROUP). Partial amounts and amounts larger than the suggested transfer are allowed (spec 7.8).
3. GET /groups/{gid}/balances returns nets per member (including members with 0) and the simplified transfers from the engine; invariant: sum of nets == 0 (assert it at runtime and fail loudly if violated).
4. Replace remaining default usage checkers: a member in any settlement (including soft-deleted) blocks member deletion; a group with settlements cannot be deleted.
5. Run EXPLAIN on the balance and list queries against a generated dataset (15 members, 500 expenses, 200 settlements); add any index that is justified; record the findings in docs/perf-notes.md.

Tests (Testcontainers): V1 (nets M +100.00, S -20.00, A -80.00; transfers A->M 80.00, S->M 20.00) and V2 (after settlement A->M 80.00) through the API; soft-deleting a settlement or an expense updates balances; partial and excess settlements; idempotent settlement creation; IDOR; a randomized scenario test (create/edit/delete expenses and settlements) asserting sum(net)==0 and that applying the returned transfers zeroes all nets; performance sanity (balances for the large dataset under a reasonable bound, stated in the test).
Constraints: follow AGENTS.md; no two-sided confirmation (Phase 2). Done when ./mvnw verify passes. Then follow the Stop protocol.
```

---

## B8 — Hardening, OpenAPI handoff, deploy
**Skills:** `observability-by-default`, `security-discipline`, `backend-performance-review`, `api-doc-generator`, `api-docs-check`, `deploy-checklist`, `documentation`, `audit`

```text
Read AGENTS.md, docs/PROJECT_SPEC.md sections 8, 10 (acceptance criteria), 11, 13 and docs/PROJECT_PHASES.md section 3.8 (release readiness, for context only). Prerequisite: B7 merged. Skills: observability-by-default, security-discipline, backend-performance-review, api-doc-generator, api-docs-check, deploy-checklist, documentation, audit.

Step 0 (plan, wait for approval): list what is missing against the Phase 1 acceptance criteria (spec section 10) and the non-functional requirements (section 11).

Implement and verify:
1. API contract: generate the OpenAPI document from the app (springdoc), commit it to docs/openapi.json, and run an api-docs-check style comparison between the real routes and the spec section 8.2 endpoint list; fix any mismatch. Ensure every error code in 8.5 appears in the OpenAPI responses, request/response examples exist (including the three split types), and money fields are documented as integer minor units.
2. Dart client handoff: add docs/mobile-client.md with the exact openapi-generator command/config to generate the Dart (dio) client, and CI verification that the OpenAPI file is valid. Do not generate or commit Flutter code.
3. Observability: RED metrics per endpoint (Micrometer), structured logs with request id, health/readiness endpoints that really check the database, no sensitive data in logs (test it).
4. Security review of the whole backend using security-discipline: IDOR/BOLA on every endpoint (a table-driven test that calls every group-scoped route as another user and expects 404), mass assignment, input size limits, rate limiting on auth, secrets handling, dependency scan, CORS, headers. Fix findings.
5. Performance review (backend-performance-review): connection pool sizing for a single small VPS, indexes confirmed by EXPLAIN, no N+1 anywhere (query-count tests on the list endpoints).
6. Deploy: production Dockerfile and docker-compose.prod.yml for a single small VPS behind a reverse proxy with HTTPS (Caddy or Nginx — choose the simplest, document why), environment variable reference, daily pg_dump backup script and a documented, TESTED restore procedure.
7. Dev seed: a local-profile seeder (or SQL script) that creates the Dahab sample from docs/STITCH_PROMPTS.md (group, 5 members, the three expenses, resulting balances) so the Flutter app has realistic data.
8. Documentation: backend/README.md runbook (start, test, deploy, backup/restore, rotating the JWT secret, rotating Google client ids), docs/adr for any decision made during B1–B8, and a "Known limitations" section (single instance rate limiter, online-only, greedy simplification).
9. Run the full acceptance checklist from spec section 10 and report each item as PASS/FAIL with evidence. Run a final audit and produce a severity-ranked findings list (do not fix beyond what is asked without my approval).
Constraints: follow AGENTS.md; no new features. Done when ./mvnw verify passes, the acceptance checklist is PASS (or each FAIL is explained), and docs/openapi.json is committed. Then follow the Stop protocol.
```

---

# Utility prompts (use any time)

## R — Milestone review (run after every B prompt, in a NEW session)
**Skills:** `code-review`, `audit`, `security-discipline`, `testing-with-discernment`

```text
Read AGENTS.md and the diff of the last milestone ([B#] — use `git diff main...HEAD` or the last commit range). Review it as a strict senior reviewer WITHOUT changing code. Check, citing file:line and the spec section for each finding:
1. Spec compliance (rules, error codes, endpoints, field names).
2. Money correctness: any floating point, rounding or tie-break deviation, overflow risk.
3. Authorization: every group-scoped path goes through the central component; another user's resource returns 404.
4. Idempotency, transactions and concurrency (check-then-write races, missing unique constraints).
5. Migrations (locking, irreversibility, constraints) and queries (N+1, missing indexes, unbounded lists).
6. Error handling (swallowed exceptions, wrong codes, leaked internals) and logging (secrets, personal data).
7. Tests: tests that mock what they claim to test, missing money/authz/concurrency cases, flaky patterns.
8. Scope creep: anything outside Phase 1.
Output: a severity-ranked table (blocker/major/minor/nit), what is good, and a recommended fix order. Do not edit files.
```

## F — Bug-fix prompt template
**Skills:** `debugging-discipline`, `testing-with-discernment`

```text
Read AGENTS.md. Bug: [what happened, expected vs actual, request/response or test output, spec section if relevant].
Do NOT change code until you can explain the bug. Steps: (1) reproduce with a failing test (red) at the lowest level that shows it (engine fixture first if it is a money bug); (2) read the actual logs/outputs; (3) state one falsifiable hypothesis and verify it; (4) fix the root cause, not the symptom; (5) show the test now passing and the full suite green; (6) add the case as a permanent regression test (and a fixture in /fixtures if it is a money rule). If the fix needs a rule change, STOP and ask. Summarize cause, fix, and any similar places that might have the same bug.
```

## S — Spec change / decision recording
```text
Read AGENTS.md and docs/PROJECT_SPEC.md. Decision to record: [describe the decision or rule change and the reason]. Update ONLY the affected sections of docs/PROJECT_SPEC.md (and docs/PROJECT_PHASES.md if scope moves between phases), add a numbered entry to the Decision Log (section 14) with status Decided/To verify, and list every code path, fixture, test and migration that must change as a result. Do not change code in this step.
```

## Q — "Explain what you built" (learning prompt, optional)
```text
Read AGENTS.md. Explain the code added in [B#] to me as a mid-level Java developer who knows Spring Boot but not this codebase: package map, the request flow for [endpoint], where each spec rule is enforced, and the three riskiest parts with how they are tested. Keep it under one page.
```

---

## 4. Your checklist per prompt
- [ ] New session; skills available (or rules in AGENTS.md).
- [ ] Approve the plan before code is written.
- [ ] `./mvnw verify` passes on your machine, not just in the agent's summary.
- [ ] Read the diff, especially migrations, authorization and money code.
- [ ] Run prompt **R** in a fresh session; fix blockers/majors (prompt **F**).
- [ ] Commit with a clear message; tag the milestone (`phase1-b3`, ...).
- [ ] Record any new decision (prompt **S**).
