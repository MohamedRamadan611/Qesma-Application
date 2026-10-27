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
