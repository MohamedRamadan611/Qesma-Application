# ADR-001: Backend stack

Status: Accepted (B0) · Date: 2026-11-07

## Context
Solo developer, small VPS, Phase 1 single-organizer app with money-critical logic (spec sections 5.1, 11). Priorities: correctness, boring tooling, low operating cost.

## Decision
- **Java 21 + Spring Boot 3.5.16** (pinned). Verified on Maven Central as the latest 3.x release at generation time. Boot 4.x exists but the spec targets 3.x; revisit in a later phase with its own ADR.
- **Maven with wrapper** (Maven 3.9.16 pinned) for reproducible builds.
- **PostgreSQL 16** (image `postgres:16.6-alpine`, pinned in compose and tests) with **Flyway** forward-only migrations; `ddl-auto=validate`, `open-in-view=false`. Invariants are enforced by the schema.
- **Testcontainers** with real PostgreSQL for integration tests; never H2. **jqwik** for property tests (1.9.3, compatible with the JUnit platform managed by Boot).
- **springdoc-openapi 2.8.17**, enabled in the `local` profile only; the exported spec is the client contract.
- **Structured logging** via Spring Boot built-in ECS JSON format (no extra library).
- **CI:** GitHub Actions, `./mvnw verify`, gitleaks secret scan.

## Why no Redis / Kafka / microservices
Phase 1 load is tiny (about 15 members, 500 expenses per group). Idempotency keys, sessions (stateless JWT) and balances (computed on demand) all fit in PostgreSQL. A cache or broker would add operations cost and failure modes with no measured need. Introduce them only with a new ADR and evidence.

## Consequences
- One deployable, one database: simple backups and operations.
- JDK 21 required locally and in CI.
- Dependency set is fixed to the list above; additions need an ADR.
