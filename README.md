# Qesma (قسمة)

Group expense splitting for trips, shared housing and outings. **Arabic first** (RTL), English second, default currency EGP, Android first (Flutter). Qesma only **records** who paid what and who owes whom; it never holds, moves or processes money. All interaction happens inside the app.

## Status

| Area | State |
|:--|:--|
| **Backend** (Java 21, Spring Boot, PostgreSQL) | **Phase 1 implemented** (milestones B0 to B8): 24 endpoints, 8 migrations, 214 unit + 157 integration tests passing on real PostgreSQL. |
| Backend gate G8 | Functionally verified (see `docs/gates/gate-b8.md`); **not yet tagged**: `scripts/smoke.sh`, first CI run, staging deploy over HTTPS and the human checks (real receipts, real device) are still open. |
| Backend addendum **B9** | Specified, not built: owner is member #1 ("you"), `yourNetMinor`, OpenAPI status fixes (`.claude/commands/b9-owner-member-contract.md`). |
| **Mobile** (Flutter) | Not started. Screens are designed (`docs/design/screens/`); the prompt set FL0 to FL9 is written (`.claude/mobile/README.md`). |

## What the backend does (Phase 1, "Organizer Mode")
- **Sign in with Google**; the backend issues its own 15-minute access token and a rotating 30-day refresh token (reuse of an old one ends the session).
- **Groups and members**: create, rename, delete (only when empty); ghost members added by name; owner-only access, another user's data always answers `404`.
- **Expenses** with one or more payers and three split types: **EQUAL** (all or selected members), **EXACT** (amounts per member) and **ITEMIZED** restaurant bills with independent optional **service charge** and **tax** (service only, tax only, both, neither), tax base choice and a signed rounding adjustment. A live **preview** endpoint returns exactly what a save would store.
- **Edit and delete** with optimistic concurrency (`If-Match`/`ETag`), soft delete and a full **revision history** (snapshot per change).
- **Balances** computed on demand (never stored) and the simplified "who pays whom" transfers; **settlements** (partial or larger payments, soft delete).
- **Safe retries**: every create takes an `Idempotency-Key`; the key and the business write commit in one transaction (24-hour replay window).
- **Exact money**: integer piasters and basis points only, largest-remainder rounding, an amount cap of 10^12 piasters, all rules in a pure-Java engine verified by shared vectors V1 to V8 (`fixtures/`) and property tests.
- **Errors** as RFC 7807 `application/problem+json` with stable `code`s; request ids on every response.

### Member lifecycle (Phase 2, B12)
- **Roles**: one `OWNER`, any number of `ADMIN`s, and `MEMBER`s. Only the Owner changes roles (`PATCH /groups/{gid}/members/{mid}` with `role`: `ADMIN` or `MEMBER`). An Admin may remove (`status: LEFT`) or reactivate (`status: ACTIVE`) members, never another Admin or the Owner.
- **Leave and rejoin**: `POST /groups/{gid}/leave`. The member row, history and balance stay; the group disappears from the person's list and answers `404` for them. The Owner gets `409 OWNER_MUST_TRANSFER`. A person who left comes back through a new invite (their old member row is reactivated) or an Admin reactivates them.
- **Members who left** stay in history, balances and suggested transfers, but cannot be used in new expenses, previews or settlements (`422 MEMBER_INACTIVE`). An existing expense that already includes them can still be edited.
- **Transfer ownership**: `POST /groups/{gid}/transfer-ownership {toMemberId}` (Owner only; the target must be an active member with an account; the old owner becomes Admin; one transaction).
- Details and the full transition table: Decision Log A77 to A82 in `docs/PROJECT_SPEC.md`.

## Repository layout
| Path | Contents |
|:--|:--|
| `backend/` | Spring Boot service. Packages: `engine` (pure money rules), `api`, `service`, `persistence`, `domain`, `security`, `dev` (local seed). Flyway migrations V1 to V8. |
| `mobile/` | Flutter app (placeholder until FL0). |
| `fixtures/` | Shared test vectors (engine input/expected values). |
| `docs/` | Spec, phases, validation gates, ADRs, design assets, OpenAPI, perf notes, gate reports. |
| `docs/openapi.json` | The API contract the mobile client is generated from. Produced by the backend itself; the build fails if it is stale. |
| `deploy/`, `docker-compose.prod.yml`, `scripts/` | Production deployment (Caddy HTTPS, PostgreSQL, daily backup) and backup/restore scripts. |
| `.claude/commands/` | Milestone prompts: `b0` to `b9` (backend), `fl0` to `fl9` (Flutter), plus review (`r-review`, `flr-review`), verification (`v-verify`, `flv-verify`) and utility prompts. |
| `.claude/mobile/` | Shared reference for the Flutter prompts (screen map, API map, scope rules). |
| `AGENTS.md`, `CLAUDE.md`, `backend/AGENTS.md`, `mobile/AGENTS.md` | Rules for AI agents working in the repo. |

## Run the backend locally
Needs JDK 21 and Docker.
```bash
docker compose up -d db
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth,seed   # profiles are always explicit: there is no default
curl http://localhost:8080/actuator/health
```
`fake-auth` lets you sign in without Google (token `fake:<subject>:<email>:<name>`); `seed` creates the Dahab trip from `docs/STITCH_PROMPTS.md` (5 members, 3 expenses, documented balances) and prints the token to use. Swagger UI is at `/swagger-ui.html` in the `local` profile. Full instructions, curl walkthroughs, deployment, backup/restore, secret rotation and known limitations: **`backend/README.md`**.

## Test
```bash
cd backend
./mvnw test          # unit tests
./mvnw clean verify  # unit + integration tests against PostgreSQL (Testcontainers; Docker must be running)
bash ../scripts/test-restore.sh   # proves backup and restore on throwaway containers
```

## Architecture decisions
`docs/adr/`: ADR-001 stack, ADR-002 authentication, ADR-003 dependency scanning (Trivy + Dependabot in CI), ADR-004 OpenAPI generated by a test, ADR-005 single-VPS deployment with Caddy. Assumptions and rule decisions are in the Decision Log at the end of `docs/PROJECT_SPEC.md` (A1 to A52).

## Production
One small VPS with Docker Compose (`docker-compose.prod.yml`): PostgreSQL, the backend, Caddy (automatic HTTPS) and a daily `pg_dump` backup. Probes and metrics are on an internal management port. The local production stack was built and run end to end; issuance of a real certificate needs a DNS name and has not been tried. See `docs/adr/ADR-005-deploy.md`.

## Quality gates and reviews
`docs/PHASE1_VALIDATION_GATES.md` defines the gates. Reports so far: `docs/gates/review-cp1.md`, `review-cp2.md`, `acceptance-b8.md`, `gate-b8.md`. Performance evidence: `docs/perf-notes.md` (balances for 15 members, 500 expenses and 200 settlements in about 26 ms).

## Start working
1. Read `AGENTS.md` and `docs/PROJECT_SPEC.md` (authoritative for Phase 1) and `docs/PROJECT_PHASES.md` (whole project).
2. Backend close-out, in a fresh session each: `/b9-owner-member-contract`, `/x-smoke`, then commit and tag, run CI, deploy a staging host and do the human checks in `docs/gates/gate-b8.md`.
3. Mobile: run the Flutter prompts in the order of `.claude/mobile/README.md` (FL0 to FL9), one per fresh session, each followed by review and verification prompts.

## Scope
Phase 1 is deliberately small: invitations, roles, notifications, payment handles, two-sided settlement confirmation, disputes, refunds, categories, exports, offline mode and multi-currency belong to later phases (`docs/PROJECT_PHASES.md`). Account deletion is not in the Phase 1 backend and is required before a public release.
