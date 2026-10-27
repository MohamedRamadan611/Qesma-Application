---
description: "B8 — Hardening, OpenAPI handoff, deploy"
---

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
