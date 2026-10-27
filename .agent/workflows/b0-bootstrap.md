---
description: "B0 — Bootstrap & agent memory"
---

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
