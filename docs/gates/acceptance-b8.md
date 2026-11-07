# B8 acceptance run and final audit

**Date:** 2026-11-07 · **Reviewer:** the session that built B0–B8 (a self-review, not the independent `V` gate).
**Build evidence:** `./mvnw -o clean verify` (JDK 21.0.12.1, Docker, PostgreSQL 16.6) → **214 unit + 157 integration tests, 0 failures, 0 skipped, BUILD SUCCESS.**
**State of the repository:** everything from B4 onward is **uncommitted**; there are no `gate-*` tags and no independent `V` reports; the GitHub workflow has never run.

## 1. Phase 1 acceptance criteria (spec section 10)

| # | Criterion | Result | Evidence |
|:--|:--|:--|:--|
| 1 | Vectors V1–V8 are automated tests | **PASS** | Engine: `FixtureTest` (fixtures V1–V8). Through the API: V1/V2 `BalancesSettlementsIT`, V3/V4 `ExpensesIT`, V5–V8 `ItemizedExpensesIT` (exact spec numbers, incl. the V5 tie-break). |
| 2 | Contract tests cover every endpoint and every error code | **PASS** | `ApiContractCoverageIT`: one scripted walk answers **all 24 operations** of the generated OpenAPI with 2xx and produces **all 14 error codes** on real responses with the documented status. `OpenApiExportIT` proves the 24 operations equal the endpoint list of spec 8.2 and nothing extra is exposed. |
| 3 | Full flow on a real Android device | **NOT VERIFIED (HUMAN)** | No device or Flutter app exists yet. Backend side of the flow (sign in → group → members → equal, multi-payer and itemized expenses → balances → settlement → balances) is covered by `ApiContractCoverageIT`, `BalancesSettlementsIT` and `DevSeedIT`. |
| 4 | Editing and deleting update balances correctly and leave revisions | **PASS** | `ExpenseEditDeleteIT` (recalculation, revisions after create/update/delete, 16 parallel edits → one winner), `BalancesSettlementsIT` (balances follow edits, deletes and settlement deletes), `Cp2LedgerInvariantIT` (200 random create/edit/delete steps: Σ net = 0, revisions = versions). |
| 5 | A retried create never duplicates | **PASS** | `ExpenseIdempotencyIT` (20 parallel same-key requests → 1 expense), settlement equivalent in `BalancesSettlementsIT`, atomicity ITs (key row and business rows roll back together), stranger-vs-owner key races in `Cp2LedgerInvariantIT`. |
| — | CP2: 3 real receipts match | **NOT VERIFIED (HUMAN)** | Not provided (see `review-cp2.md` section 3). |

## 2. Non-functional requirements (spec section 11)

| Requirement | Result | Evidence |
|:--|:--|:--|
| HTTPS only | **PASS locally, NOT VERIFIED on a real host** | Production stack built and run with `DOMAIN=localhost` (Caddy internal CA): HTTP/2 over TLS, `http://` → 308 → `https://`, HSTS added, `Server` header removed, `/actuator`, `/v3/api-docs`, `/swagger-ui.html` answer 404 at the proxy. No Let's Encrypt issuance (needs DNS). |
| Short-lived tokens, rotating hashed refresh tokens, authorization on every group route, input validation | **PASS** | B1/B2 ITs; `IdorMatrixIT` (all 17 group-scoped routes from the OpenAPI, as another user and anonymous, identical 404 body, owner data unchanged); `MassAssignmentIT`. |
| Rate limiting on auth | **PASS** | `AuthRateLimitIT`, `ApiContractCoverageIT` (429). In memory, per instance. |
| No sensitive data in logs | **PASS** | `NoSensitiveDataInLogsIT`: a full flow with recognizable tokens, emails, names, titles, item names and notes at DEBUG; nothing appears in any log event. Credential DTOs redact `toString`. On the running stack the backend log and Caddy's access log (`Authorization: REDACTED`) contained no token. |
| Performance p95 < 500 ms, 15 members / 500 expenses | **PASS** (in-process) | `BalancesPerformanceIT`: all typical requests p95 ≤ 46 ms on the maximum dataset; balances 22 ms. Excludes network time. See `docs/perf-notes.md`. |
| Daily automated backups, tested restore | **PASS** | `backup` container ran on the local stack ("backup ok"); `scripts/test-restore.sh` exit 0: restore into a fresh server gives identical schema, rows and balances; restoring over the live database and from a corrupted file are refused. |
| Forward-only migrations | **PASS** | V1–V4 byte-identical to `HEAD`; V5–V8 add new objects only. |
| Structured logs with request ids, health endpoint | **PASS** | `OperationalEndpointsIT`: request ids echoed/generated; liveness/readiness on the management port; readiness goes DOWN when the database health fails. |
| RED metrics per endpoint | **PASS** | `http.server.requests` (per URI template, status, duration histogram) read from `/actuator/metrics` on the management port; not served on the public port (verified in `OperationalEndpointsIT` and on the running stack). |
| No paid services | **PASS** | Caddy, PostgreSQL, free Google verification. |
| Privacy / accessibility / i18n | **Out of scope for the backend** | Privacy policy and account deletion are Phase 2/3; ARB files belong to the mobile app. |

## 3. B8 checklist

| Item | Result |
|:--|:--|
| 1 OpenAPI committed, routes compared with spec 8.2, error codes, examples (3 split types), money documented | **Done** (`docs/openapi.json`, OpenAPI 3.0.1; `OpenApiExportIT`) |
| 2 Dart client handoff, CI validation | **Done**: `docs/mobile-client.md`; generation with `openapi-generator-cli:v7.8.0` run into a temp folder without errors (money fields come out as `int`, nullable only where the API can return null); `validate` reports "No validation issues detected"; CI job added. `build_runner` not run (no Flutter project; none committed). |
| 3 Observability | **Done** (see section 2) |
| 4 Security review | **Done**: findings below; table-driven IDOR and mass-assignment tests; headers/CORS test; SEC-001 and COR-001 fixed. Dependency scan: **not run locally** (Trivy's vulnerability database download timed out twice on this network); Trivy + Dependabot are configured in CI (ADR-003), first run pending. |
| 5 Performance | **Done**: pool/Tomcat/JVM sizing with reasons, EXPLAIN of all remaining queries, statement-count tests for every list endpoint, p95 table (`docs/perf-notes.md`) |
| 6 Deploy | **Done and exercised locally**: `docker-compose.prod.yml`, Caddy (chosen over Nginx: automatic certificates, ADR-005), `.env.prod.example`, backup/restore scripts, restore tested. Whole stack built and run: backend healthy, 337 MiB of 768 MiB. |
| 7 Dev seed | **Done**: `DevSeedRunner` (`local,fake-auth,seed`), `DevSeedIT` reproduces the documented Dahab balances and transfers exactly and is idempotent |
| 8 Documentation | **Done**: README runbook (deploy, backup/restore, rotation, troubleshooting, known limitations), ADR-003/004/005, Decision Log A31–A52 |
| 9 Acceptance run and audit | This document |

## 4. Final audit: findings (severity ranked)

| ID | Severity | Finding | Status |
|:--|:--|:--|:--|
| AUD-001 | **Major** (process) | B4–B8 uncommitted; no `gate-*` tags; no independent `V` reports; the CI workflow (including the new `openapi-valid`, `restore-test`, `dependency-scan` jobs) has never run on GitHub. A clean build from a tagged commit is impossible today. | **Open: needs your decision** (commit/tag, then run `V` in a fresh session) |
| AUD-002 | **Major** (acceptance) | Criterion 3 (real Android device) and the three real receipts are NOT VERIFIED. | **Open (HUMAN)** |
| AUD-003 | Minor | No vulnerability scan result exists yet (Trivy database download failed locally). | Open: first CI run, or re-run `trivy` with a working network |
| AUD-004 | Minor | No rate limit on write endpoints (only body/amount/list caps); the auth limiter is per instance and in memory (SEC-002). | Documented in Known limitations |
| AUD-005 | Minor | `GET …/revisions` is not paged and edits per expense are unlimited (CP2-004). | Documented |
| AUD-006 | Minor | Backups stay on the server unless copied off; the first backup runs when the container starts (it may be of an empty database on a first deploy) and the 24 h loop is not wall-clock aligned. | Documented in ADR-005 and the runbook |
| AUD-007 | Minor | `forward-headers-strategy: native` trusts `X-Forwarded-For` from any peer: safe only because the backend is reachable through Caddy alone (compose publishes no backend port). | Documented in ADR-005; do not publish port 8080 |
| AUD-008 | Minor | Expired refresh-token rows are never purged (ADR-002). | Open, small table |
| AUD-009 | Minor | Error responses per operation come from a rule table in `OpenApiConfig`; a new code path inside an existing operation needs the table updated by hand (`ApiContractCoverageIT` only proves each code is produced somewhere). | Documented in ADR-004 |
| AUD-010 | Nit | Running the production compose file locally creates a git-ignored `backups/` folder in the repository root; the Dart generator warns that `get` is renamed `callGet`. | Harmless |

**Fixed during B8 (found by the new tests or by running the stack):**
- SEC-001 / COR-001 (no default profile; startup without a profile fails with an instruction; documented run commands corrected in `backend/README.md`, `backend/AGENTS.md` and `CLAUDE.md`).
- CP2-001 (amount cap) was fixed in B7.
- Credential-bearing request/response records printed their tokens in `toString` (visible if a framework log level is raised): now redacted.
- The management port was behind the API's authentication (probes and metrics returned 401): now served by Spring's endpoint matcher on the management port only.
- The B0 `Dockerfile` had never been built: it failed on Windows (CRLF in `mvnw`). Fixed, `.gitattributes` added for shell scripts, `mvnw`, SQL, YAML and Dockerfiles.
- The OpenAPI document: no schema for the ETag header, OpenAPI 3.1 (only experimentally supported by the Dart generator) → 3.0.1, nothing marked required → non-null Dart types, `*/*` media types, opaque `JsonNode` snapshot schema.

## 5. Not verified, stated plainly
No real HTTPS certificate issuance, no real VPS, no Android device, no real receipts, no CI run on GitHub, no vulnerability scan result. `build_runner` for the Dart client was not run.
