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
7. Authorization: a caller reaches a group only through an ACTIVE linked member and may do what their role allows (ADR-009, A65-A67). A non-member's access => 404 (identical to an unknown id); a member lacking the permission => 403 `FORBIDDEN`. All checks go through one central component (`GroupAccessService`).
8. Errors: RFC 7807 problem+json with a stable `code` from the spec's list (8.5). No swallowed exceptions. No stack traces to clients.
9. Schema invariants live in the database (CHECK, UNIQUE, FK, NOT NULL). Flyway migrations are forward-only and reviewed.
10. No secrets in code, logs, or git. Never log tokens, Authorization headers, or personal data beyond ids.
11. Do not build anything outside the Phase 1 scope (spec 3.2), except while running a Phase 2 prompt (`/b10`-`/b19`, `/fl10`-`/fl18`): then the scope is `docs/PHASE2_SPEC.md` and that prompt only, or while running a standalone prompt (`/sa0`-`/sa17`, `/bsa1`, `/bsa2`): then the scope is `docs/STANDALONE_SPEC.md` and that prompt only. Do not add libraries or infrastructure (Redis, Kafka, microservices) without an ADR and my approval.

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

## Skill Routing & Execution Discipline
To avoid prompt dilution and conflicting rules, **never activate all skills at once**. Limit active skills to at most **2–4 relevant skills** per prompt based strictly on directory and task scope:

### By Directory & Subsystem
- **Cross-cutting / Architecture (`/`, `/docs/`):** `think-before-coding`, `architecture`, `boring-by-default`, `documentation`, `deploy-checklist`.
- **Pure Engine (`backend/src/.../engine/`):** `think-before-coding`, `test-driven-development`, `testing-with-discernment`.
  - *Strictly FORBIDDEN in Engine:* DB/JPA/Flyway skills (`data-modeling-discipline`, `migration-safety`, `query-discipline`, `explain-this-query`, `hunt-n-plus-one`), HTTP/API skills (`api-doc-generator`, `api-docs-check`), and all UI/UX skills.
- **Standalone engine (`mobile/packages/qesma_engine/`):** same skills and the same *strictly FORBIDDEN* list as the Pure Engine above (`think-before-coding`, `test-driven-development`, `testing-with-discernment`); pure Dart, no Flutter, no I/O.
- **Standalone local backend (`mobile/lib/local/`):** `think-before-coding`, `data-modeling-discipline`, `migration-safety`, `testing-with-discernment` (SQLite/drift schema, services and the in-process backend; no UI skills here).
- **Database & Persistence (`backend/.../persistence/`, `backend/.../db/migration/`):** `data-modeling-discipline`, `migration-safety`, `review-migration`, `query-discipline`, `explain-this-query`, `hunt-n-plus-one`.
- **API & Controllers (`backend/.../api/`):** `api-doc-generator`, `api-docs-check`, `error-handling-as-design`, `auth-and-authorization`, `idempotency-and-side-effects`, `security-discipline`.
- **Services & Security (`backend/.../service/`, `backend/.../security/`):** `think-before-coding`, `auth-and-authorization`, `idempotency-and-side-effects`, `observability-by-default`, `backend-performance-review`, `security-discipline`.
- **Mobile Client (`mobile/`):** `ui-ux-pro-max`, `design-system`, `design-handoff`, `design-critique`, `accessibility-review`, `ux-copy`.
  - *Strictly FORBIDDEN in Mobile:* Backend DB/migration skills and server-side framework skills. Phase 1 forbids client-side split calculations (must call backend API).
- **User Research & UX Specs (`docs/design/`, `docs/user-research/`):** `user-research`, `research-synthesis`, `design-critique`, `ux-copy`.
- **Maintenance, Audit & Bugs (Global):** `code-review`, `audit`, `debugging-discipline`.

### By Workflow / Milestone
- `/b0-bootstrap`: `think-before-coding`, `observability-by-default`, `deploy-checklist`
- `/b3-engine`: `think-before-coding`, `test-driven-development`, `testing-with-discernment`
- `/b1-auth`: `think-before-coding`, `auth-and-authorization`, `security-discipline`, `error-handling-as-design`
- `/b2-groups-members`: `think-before-coding`, `data-modeling-discipline`, `migration-safety`, `auth-and-authorization`, `api-doc-generator`
- `/b4-expenses-core`: `think-before-coding`, `data-modeling-discipline`, `migration-safety`, `idempotency-and-side-effects`, `error-handling-as-design`
- `/b5-itemized-preview`: `think-before-coding`, `api-doc-generator`, `error-handling-as-design`, `testing-with-discernment`
- `/b6-edit-delete-revisions`: `think-before-coding`, `data-modeling-discipline`, `migration-safety`, `idempotency-and-side-effects`, `audit`
- `/b7-balances-settlements`: `think-before-coding`, `query-discipline`, `backend-performance-review`, `api-doc-generator`
- `/b8-hardening-handoff`: `api-doc-generator`, `api-docs-check`, `security-discipline`, `deploy-checklist`, `audit`
- `/r-review`: `audit`, `code-review`, `security-discipline`, `migration-safety` (if DB touched)
- `/f-bugfix`: `debugging-discipline`, `testing-with-discernment`, `test-driven-development`
- `/s-spec-change`: `architecture`, `boring-by-default`, `documentation`

## Token discipline (applies to every prompt and every session)
- **One milestone per session.** Run `/clear` before starting the next prompt. Use `/compact` only after a milestone's tests pass, never mid-change.
- **Models:** Opus 5.5 for planning (Step 0) and for money or security implementation (engine, balances, pool, calculators, OCR parsing, Java contract). Sonnet 5.5 for other implementation. Haiku 5.5 only for small docs edits.
- **Read narrowly:** never read `docs/openapi.json`, `docs/PROJECT_SPEC.md` or `docs/PHASE2_SPEC.md` whole. Use Grep to find a section, then Read with `offset` and `limit`. Do not re-read a file already read in this session unless it changed.
- **Search before reading:** use Grep with `head_limit` (or `output_mode: "files_with_matches"`) before opening files. Use one Explore agent only when the search spans many areas; a known file needs a direct Read or Grep, not an agent.
- **Short test output:** print only failures and the summary, for example `./mvnw test ... 2>&1 | grep -E "Tests run:|FAIL|ERROR\]   "` or the equivalent for `flutter test`. Run the full suite once at the end of a milestone, not after each edit. Never paste full logs into the conversation.
- **Short replies:** keep status updates and final summaries under about 300 words unless the prompt asks for more. Use tables for lists of files, tests or results. Describe a failure with the file, line and message, not the full stack trace or a screenshot.
- **Stop reading when you have enough:** once the facts needed for a decision are established, act. Do not re-derive facts already in the conversation.

## Stop protocol
After finishing a prompt: (1) run the full test suite, (2) list assumptions and open questions, (3) list files changed, (4) do NOT start the next milestone.
