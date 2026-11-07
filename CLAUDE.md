@AGENTS.md

# Claude Code Guide — Qesma Backend & Mobile

Qesma ("قسمة") is an Arabic-first group expense-splitting application (trips, shared housing, outings) for Egypt. It only records who paid what and who owes whom; it never holds, moves, or processes money.

---

## Source of Truth & Project Documentation
- **Phase 1 Spec (authoritative):** [`docs/PROJECT_SPEC.md`]
- **Full Project Roadmap (Phases 0–5):** [`docs/PROJECT_PHASES.md`]
- **Backend Rules & Invariants:** [`AGENTS.md`] and [`backend/AGENTS.md`]
- **Mobile Guidelines:** [`mobile/AGENTS.md`]
- **UI/UX Prompts & Flows:** [`docs/STITCH_PROMPTS.md`] and [`docs/design/STITCH_PROTOTYPE_LINKING.md`]
- **Shared Test Vectors:** [`fixtures/*.json`]

---

## Tech Stack & Architecture

### Backend (`/backend`)
- **Runtime:** Java 21, Spring Boot 3.x (latest stable, pinned), Maven wrapper (`./mvnw`).
- **Database:** PostgreSQL with Flyway migrations (forward-only, schema-enforced invariants).
- **Testing:** JUnit 5, jqwik (property-based), Testcontainers (real PostgreSQL, **never H2**).
- **API Spec:** springdoc-openapi exporting to `docs/openapi.json`.
- **Base Package:** `app.qesma`
  - `engine`: **PURE Java only**. Strictly NO Spring, JPA, or I/O. All money math, rounding, and split algorithms live here.
  - `api`: REST controllers under `/api/v1`, Java record DTOs.
  - `domain`: JPA entities, DB constraints (CHECK, UNIQUE, FK, NOT NULL).
  - `service`: Business logic & transactions (`@Transactional` only on service methods).
  - `security`: Google Sign-In, JWT/tokens, central authorization enforcement.
  - `persistence`: Spring Data repositories.

### Mobile (`/mobile`)
- Flutter + Dart (Android-first).
- State: Riverpod. Routing: go_router.
- Networking: dio with API client generated from `docs/openapi.json`.

---

## Non-Negotiable Invariants (Always Follow)
1. **Integer Money:** Amounts are `long` minor units (piasters: 1 EGP = 100). Percentages are integer basis points (`int` bps: 1200 bps = 12.00%). **Never** use `float`, `double`, or `BigDecimal` for arithmetic in money paths. Use `Math.multiplyExact` or `BigInteger` for products before dividing.
2. **Authoritative Backend:** The backend is the single source of truth for calculations.
3. **Pure Engine:** All money calculations live in `app.qesma.engine` without external framework dependencies.
4. **Calculated Balances:** Net balances and settlement transfers are computed on demand; balances are **never** stored in the database.
5. **Immutable Ledger:** Ledger entries are never hard-deleted. Edits create new revisions; deletes are soft-deletes.
6. **Strict Idempotency:** Every create operation requires an `Idempotency-Key` header (spec 8.3). Key write and business write share one database transaction.
7. **Authorization & IDOR Defense:** Phase 1 is owner-only. Attempting to access another user's group returns `404 Not Found` (never `403 Forbidden`). All checks flow through a single centralized authorization component.
8. **Standardized RFC 7807 Errors:** Return `application/problem+json` with stable error `code` from spec 8.5. Never swallow exceptions; never expose stack traces to clients.
9. **Real Database Testing:** Integration tests run against real PostgreSQL via Testcontainers.
10. **Zero Secrets in Code/Logs:** Never log Authorization headers, tokens, or PII beyond IDs.

---

## Common Commands

Run commands from `/backend` unless otherwise noted:

```bash
# Build & run full verification suite (requires Docker running for Testcontainers)
./mvnw clean verify

# Run unit tests only (fast)
./mvnw test

# Run a single test class
./mvnw -q test -Dtest=ClassName

# Run a specific test method
./mvnw -q test -Dtest=ClassName#methodName

# Start local PostgreSQL container
docker compose up -d db

# Run Spring Boot with local profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# Check Flyway migration status
./mvnw flyway:info
```

---

## Workflow & Slash Commands

Milestone prompts and utilities are located in `.claude/commands/`.

### Recommended Milestone Order:
```
B0 (Bootstrap) → B3 (Split Engine) → B1 (Auth) → B2 (Groups/Members) → B4 (Expenses Core) → B5 (Itemized/Preview) → B6 (Edit/Revisions) → B7 (Balances) → B8 (Hardening/OpenAPI)
```
*(Engine B3 runs early because it is pure Java and holds the highest algorithmic risk without depending on DB/infra).*

### Command Reference:
- `/b0-bootstrap`: Initialize project, Maven wrapper, base config, and health checks.
- `/b1-auth`: Auth foundation (Google token verification, JWT issuance, owner context).
- `/b2-groups-members`: Group creation, ghost members, owner-only authorization.
- `/b3-engine`: Pure Java split engine (EQUAL, EXACT, ITEMIZED with largest-remainder rounding).
- `/b4-expenses-core`: Core expenses persistence, multi-payer support, idempotency keys.
- `/b5-itemized-preview`: Itemized restaurant bill calculation, tax/service toggles, preview endpoint.
- `/b6-edit-delete-revisions`: Soft delete, expense revisions history, optimistic concurrency (`version`).
- `/b7-balances-settlements`: Balance aggregation, simplified transfer calculation, settlement recording.
- `/b8-hardening-handoff`: Production configuration, security hardening, OpenAPI export handoff.
- `/r-review <milestone>`: Run in a fresh session to audit completed milestone against senior discipline.
- `/f-bugfix <description>`: Targeted bug fix template with root-cause analysis and regression tests.
- `/s-spec-change`: Record an architectural decision or resolve spec ambiguity in the Decision Log.

---

## Skill Routing & Execution Discipline

To avoid context dilution and conflicting instructions, **never activate all skills at once**. Limit active skills to at most **2–4 relevant skills** per prompt:

### By Directory & Subsystem:
- **`backend/.../engine/` (PURE Java):** `think-before-coding`, `test-driven-development`, `testing-with-discernment`.
  - *Strictly FORBIDDEN:* DB/Flyway/ORM (`migration-safety`, `query-discipline`, etc.), HTTP/API, or UI skills.
- **`backend/.../persistence/` & Flyway migrations:** `data-modeling-discipline`, `migration-safety`, `review-migration`, `query-discipline`, `explain-this-query`, `hunt-n-plus-one`.
- **`backend/.../api/`:** `api-doc-generator`, `api-docs-check`, `error-handling-as-design`, `auth-and-authorization`, `idempotency-and-side-effects`, `security-discipline`.
- **`backend/.../service/` & `security/`:** `think-before-coding`, `auth-and-authorization`, `idempotency-and-side-effects`, `observability-by-default`, `backend-performance-review`, `security-discipline`.
- **`mobile/`:** `ui-ux-pro-max`, `design-system`, `design-handoff`, `design-critique`, `accessibility-review`, `ux-copy`.
  - *Strictly FORBIDDEN:* Backend DB/migration skills and server-side framework skills.
- **Cross-cutting / Architecture (`/`, `docs/`):** `think-before-coding`, `architecture`, `boring-by-default`, `documentation`, `deploy-checklist`.
- **Maintenance & Debugging (Global):** `code-review`, `audit`, `debugging-discipline`.

### By Workflow / Milestone:
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

---

## Working Method & Discipline

1. **One Milestone Per Session:** Start a fresh Claude Code session for each `/b*` milestone to preserve a clean context.
2. **Plan Mode First:** Before writing code, perform the 6-step design:
   - (1) Context & load, (2) Data & schema invariants, (3) Failure modes & error codes, (4) Authorization, (5) Replay & concurrency, (6) Observability.
   - Summarize the design in 10–20 lines and wait for user approval before writing code.
3. **Test-First for Money Math:** Write unit tests for split algorithms, edge cases, and rounding before implementing engine code.
4. **Code Quality:** Java records for DTOs; constructor injection; no Lombok; small reviewable commits.
5. **Stop Protocol:** Upon milestone completion:
   - Run `./mvnw verify` and verify output.
   - List assumptions made and open questions.
   - List all files modified or created.
   - **Do NOT** start the next milestone in the same session.
