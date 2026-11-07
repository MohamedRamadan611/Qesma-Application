# Qesma backend

Java 21 · Spring Boot 3.5.16 · Maven wrapper · PostgreSQL 16 · Flyway. See `../docs/adr/ADR-001-stack.md`.

## Prerequisites
- JDK 21 (`JAVA_HOME` pointing at it)
- Docker running (local database and Testcontainers)

## Run
```bash
# from the repo root: start PostgreSQL
docker compose up -d db

# from /backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth
curl http://localhost:8080/actuator/health   # {"status":"UP"}
```
The `local` profile enables Swagger UI at `/swagger-ui.html` (disabled in every other profile).

## Test
```bash
./mvnw test      # unit tests (*Test)
./mvnw verify    # unit + integration tests (*IT) against real PostgreSQL via Testcontainers
./mvnw -q test -Dtest=ClassName
```

## Environment variables
| Variable | Used by | Default | Notes |
|---|---|---|---|
| `SPRING_PROFILES_ACTIVE` | app | `local` | `local`, `test`, `prod` |
| `DB_URL` | app (`prod` required) | local: `jdbc:postgresql://localhost:5432/qesma` | JDBC URL |
| `DB_USER` | app, compose | local: `qesma` | |
| `DB_PASSWORD` | app, compose | local: dev-only value | Required in `prod`; never commit |
| `DB_NAME`, `DB_PORT` | compose | `qesma`, `5432` | |
| `QESMA_JWT_SECRET` | app (`prod` required) | local: dev-only value | base64 of >= 32 random bytes (`openssl rand -base64 32`); startup fails if shorter |
| `GOOGLE_CLIENT_IDS` | app (`prod` required) | none | comma-separated OAuth client ids; the real Google verifier refuses to start with none |

## Try the auth flow locally (no Google needed)
```bash
docker compose up -d db
./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth     # fake-auth is local/test only; refused with prod

# token format: fake:<googleSubject>:<email>:<name>
curl -s -X POST localhost:8080/api/v1/auth/google -H 'Content-Type: application/json' \
     -d '{"idToken":"fake:sub1:ali@example.com:Ali Hassan"}'          # -> accessToken, refreshToken, user
curl -s localhost:8080/api/v1/me -H "Authorization: Bearer <accessToken>"
curl -s -X PATCH localhost:8080/api/v1/me -H "Authorization: Bearer <accessToken>" \
     -H 'Content-Type: application/json' -d '{"displayName":"Ali"}'
curl -s -X POST localhost:8080/api/v1/auth/refresh -H 'Content-Type: application/json' -d '{"refreshToken":"<refreshToken>"}'
curl -s -X POST localhost:8080/api/v1/auth/logout  -H 'Content-Type: application/json' -d '{"refreshToken":"<refreshToken>"}'
```
### Groups and members (same session, `$T` = access token)
```bash
H='Content-Type: application/json'
curl -si -X POST localhost:8080/api/v1/groups -H "Authorization: Bearer $T" -H "$H" \
     -d '{"name":"Dahab trip","type":"TRIP"}'                      # 201, Location + ETag: "1"; the creator is already member #1 (isYou: true) and can be renamed, not deleted
curl -s  "localhost:8080/api/v1/groups?page=0&size=20" -H "Authorization: Bearer $T"
curl -s  -X POST localhost:8080/api/v1/groups/<gid>/members -H "Authorization: Bearer $T" -H "$H" -d '{"displayName":"Sara"}'
curl -si -X PATCH localhost:8080/api/v1/groups/<gid> -H "Authorization: Bearer $T" -H "$H" -H 'If-Match: "1"' -d '{"name":"Dahab 2026"}'
curl -si -X DELETE localhost:8080/api/v1/groups/<gid> -H "Authorization: Bearer $T"      # 204
```
### Expenses (same session; `<m1>`, `<m2>` are member ids)
```bash
K=$(uuidgen)        # one Idempotency-Key per create action; reuse it when retrying the SAME action
curl -si -X POST localhost:8080/api/v1/groups/<gid>/expenses -H "Authorization: Bearer $T" -H "$H" -H "Idempotency-Key: $K" \
     -d '{"title":"Dinner","expenseDate":"2026-10-18","splitType":"EQUAL","totalMinor":10000,
          "payers":[{"memberId":"<m1>","amountMinor":10000}]}'     # omit participantMemberIds = all members; 201
# run the exact same command again: same body back, header "Idempotency-Replayed: true", no second expense
# same key + different body -> 422 IDEMPOTENCY_KEY_REUSED
curl -s "localhost:8080/api/v1/groups/<gid>/expenses?page=0&size=20&fromDate=2026-10-01&memberId=<m1>" -H "Authorization: Bearer $T"
```
### Itemized bill and preview (same session; `<m1>`, `<m2>`, `<m3>` are member ids)
```bash
BILL='{"title":"Seafood dinner","expenseDate":"2026-10-18","splitType":"ITEMIZED",
       "payers":[{"memberId":"<m1>","amountMinor":56179}],
       "items":[{"name":"Pizza","amountMinor":20000,"assigneeMemberIds":["<m1>","<m2>"]},
                {"name":"Pasta","amountMinor":15000,"assigneeMemberIds":["<m3>"]},
                {"name":"Drinks","amountMinor":9000,"assigneeMemberIds":["<m1>","<m2>","<m3>"]}],
       "service":{"bps":1200},"tax":{"bps":1400,"base":"SUBTOTAL_PLUS_SERVICE"},"adjustmentMinor":0}'
# preview: computes everything, saves nothing, no Idempotency-Key. payers may be empty while the UI is still being filled in.
curl -s -X POST localhost:8080/api/v1/groups/<gid>/expenses/preview -H "Authorization: Bearer $T" -H "$H" -d "$BILL"
# -> totalMinor 56179, subtotalMinor 44000, serviceMinor 5280, taxMinor 6899, members[...owedMinor 16599/16598/22982], payersTotalMatches true
curl -si -X POST localhost:8080/api/v1/groups/<gid>/expenses -H "Authorization: Bearer $T" -H "$H" -H "Idempotency-Key: $(uuidgen)" -d "$BILL"
```
`service` and `tax` are independent (either, both or neither). `tax.base` is `SUBTOTAL` or `SUBTOTAL_PLUS_SERVICE` (default). `totalMinor` is optional for ITEMIZED: the server computes it and the payers must add up to it (`PAYERS_TOTAL_MISMATCH`). Request bodies are limited to 64 KB (413), at most 100 items per bill.

### Edit, delete, history (same session; `<eid>` = expense id)
```bash
curl -si localhost:8080/api/v1/groups/<gid>/expenses/<eid> -H "Authorization: Bearer $T"          # ETag: "1"
curl -si -X PUT localhost:8080/api/v1/groups/<gid>/expenses/<eid> -H "Authorization: Bearer $T" -H "$H" \
     -H 'If-Match: "1"' -d "$BILL_EDITED"          # 200, ETag "2"; same body/validation/errors as create; send the explicit participant list
curl -si -X PUT ... -H 'If-Match: "1"' ...          # stale -> 409 VERSION_CONFLICT; no If-Match -> 428
curl -si -X DELETE localhost:8080/api/v1/groups/<gid>/expenses/<eid> -H "Authorization: Bearer $T" -H 'If-Match: "2"'   # 204 (soft delete)
curl -s  localhost:8080/api/v1/groups/<gid>/expenses/<eid>/revisions -H "Authorization: Bearer $T"   # CREATE, UPDATE, DELETE with full snapshots
```
Two edits racing on the same version: exactly one wins, the other gets 409. A deleted expense is gone from lists, detail (404) and totals but its revisions stay readable.

### Balances and settlements (same session; `<m1>` owes `<m2>`)
```bash
curl -s localhost:8080/api/v1/groups/<gid>/balances -H "Authorization: Bearer $T"
# -> {"nets":[{"memberId":"<m1>","netMinor":-8000},{"memberId":"<m2>","netMinor":8000}],
#     "transfers":[{"fromMemberId":"<m1>","toMemberId":"<m2>","amountMinor":8000}]}   (positive net = is owed)
curl -si -X POST localhost:8080/api/v1/groups/<gid>/settlements -H "Authorization: Bearer $T" -H "$H" -H "Idempotency-Key: $(uuidgen)" \
     -d '{"fromMemberId":"<m1>","toMemberId":"<m2>","amountMinor":8000,"settledOn":"2026-10-20","note":"cash"}'   # 201; same key = same answer
curl -s  "localhost:8080/api/v1/groups/<gid>/settlements?page=0&size=20" -H "Authorization: Bearer $T"
curl -si -X DELETE localhost:8080/api/v1/groups/<gid>/settlements/<sid> -H "Authorization: Bearer $T"             # 204, soft delete
```
Partial amounts and amounts above the suggested transfer are allowed. Amounts are limited to 1 000 000 000 000 piasters (10 billion EGP).

EXACT uses `"splitType":"EXACT"` and `"shares":[{"memberId":"<m1>","amountMinor":4000},{"memberId":"<m2>","amountMinor":6000}]`.
Amounts are integer piasters (10000 = 100.00 EGP). Keys are kept 24 hours.

Another user's group id always answers 404 (never 403). PATCH needs `If-Match` (missing = 428, stale = 409 `VERSION_CONFLICT`).

Using an already-used refresh token again returns 401 and ends that whole session (rotation reuse detection).
Auth endpoints are limited to 10 requests/minute per IP (in memory, per instance); behind a reverse proxy enable forwarded headers (`server.forward-headers-strategy=native`) so the real client IP is used. See `../docs/adr/ADR-002-auth.md`.

Copy `../.env.example` to `../.env` (git-ignored) to override compose defaults.

## Smoke test (end to end, against a running backend)
`scripts/smoke.sh` (bash + curl + jq) signs in two fake users, then walks the Phase 1 flow and asserts exact minor-unit values: group + 5 members, equal expense (V3), idempotent replay, user B gets 404, multi-payer (V4), itemized V5-V8 with preview parity, edit/ETag/stale ETag/delete/revisions, V1 balances and transfers, `yourNetMinor`, settlement and V2 balances. It prints one `PASS`/`FAIL` line per check and exits non-zero on the first failure. Each run creates fresh users and groups, so it can be repeated.
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth     # in backend/
BASE_URL=http://localhost:8080 ../scripts/smoke.sh                       # default BASE_URL is http://localhost:8080
```
Only for local/staging with the fake verifier; never against production. Auth endpoints are rate limited (10/min per IP): the script uses 2 logins.

## Docker image
```bash
docker build -t qesma-backend .
docker run --rm -e SPRING_PROFILES_ACTIVE=prod -e DB_URL=... -e DB_USER=... -e DB_PASSWORD=... -p 8080:8080 qesma-backend
```
The container runs as a non-root user.

## Development data (Dahab trip)
```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth,seed
```
Creates the group "رحلة دهب" with 5 members and the three expenses from `docs/STITCH_PROMPTS.md` (documented balances: محمد +1,014.01, عاصم +1,114.02, محسن −688.03, يوسف −720.00, كريم −720.00). Sign in with the fake token printed in the log: `fake:dahab:mohamed@example.com:محمد`. Running it again changes nothing. The `seed` profile only works together with `local`.

## OpenAPI and the mobile client
`../docs/openapi.json` is generated by the app (`OpenApiExportIT`); the build fails if the committed file is stale. Regeneration and the Dart client command are in `../docs/mobile-client.md`. While running with `local`, Swagger UI is at `/swagger-ui.html`.

## Deploy (single small VPS)
Design and reasons: `../docs/adr/ADR-005-deploy.md`. You need a server with Docker + Compose, a DNS name pointing at it and ports 80/443 open.
```bash
cp .env.prod.example .env.prod          # at the repository root; fill DOMAIN, ACME_EMAIL, DB_PASSWORD, QESMA_JWT_SECRET, GOOGLE_CLIENT_IDS
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
docker compose --env-file .env.prod -f docker-compose.prod.yml ps        # backend must become "healthy"
curl -i https://$DOMAIN/api/v1/me                                         # 401 problem+json = the API is reachable over HTTPS
```
Generate secrets on the server: `openssl rand -base64 32` (JWT secret, at least 32 random bytes) and `openssl rand -base64 24` (database password). There is **no default profile**: starting without `SPRING_PROFILES_ACTIVE` fails on purpose; the image sets `prod`.

**Update to a new version:** take a backup first (below), `git pull`, `docker compose ... up -d --build`. Migrations are forward-only and run at start-up; to go back you restore the backup and the previous image.
**Logs:** `docker compose ... logs -f backend` (structured JSON with `requestId`; never contains tokens, emails, names or titles). Caddy's access log is on its container.
**Metrics and probes** are on the internal management port only (not published): `docker compose ... exec backend wget -qO- http://127.0.0.1:8081/actuator/metrics/http.server.requests` (request rate, errors by status and latency per URI template: the RED metrics), `.../actuator/health/readiness` (includes the database) and `.../actuator/health/liveness`.

## Backup and restore
The `backup` container writes `qesma-<UTC time>.dump` (+ `.sha256`) to `BACKUP_PATH` (default `./backups`) at start and every 24 hours and keeps 14 days. **Copy that directory off the server** (rsync/rclone to another machine or bucket): a backup on the same disk does not survive losing the server.
```bash
# list and restore into a NEW database first, check it, then decide
docker compose --env-file .env.prod -f docker-compose.prod.yml exec backup ls -l /backups
docker compose --env-file .env.prod -f docker-compose.prod.yml exec backup \
    sh /scripts/restore.sh /backups/qesma-<time>.dump qesma_check
docker compose --env-file .env.prod -f docker-compose.prod.yml exec db psql -U qesma -d qesma_check -c "select count(*) from expenses"
# disaster recovery into the live name: stop the backend, then
docker compose --env-file .env.prod -f docker-compose.prod.yml stop backend
docker compose --env-file .env.prod -f docker-compose.prod.yml exec backup \
    sh /scripts/restore.sh /backups/qesma-<time>.dump qesma --replace --live
docker compose --env-file .env.prod -f docker-compose.prod.yml start backend
```
The procedure is tested by `../scripts/test-restore.sh` (needs only Docker; also a CI job): it builds the real schema, loads a ledger, backs up, restores into a fresh server and requires identical schema, rows and balances, and that restoring over the live database or from a corrupted file is refused. Run it after every schema or script change.

## Rotating secrets
- **JWT signing secret (`QESMA_JWT_SECRET`):** generate a new one, update `.env.prod`, `docker compose ... up -d backend`. All access tokens (15 minutes) become invalid at once; clients refresh with their refresh token and get new access tokens, so users are not signed out. Do this at once if the secret may have leaked, and also expect to rotate if a backup of `.env.prod` leaked.
- **Google client ids (`GOOGLE_CLIENT_IDS`):** comma-separated list. To rotate: add the new id (`old,new`), release the app that uses it, remove the old id once old app versions are gone. Tokens whose audience is not in the list are rejected.
- **Database password:** change it in PostgreSQL (`ALTER USER`), then in `.env.prod`, then restart `backend` and `backup`.
- A leaked **refresh token**: it ends with its session (logout) or when the user signs in again; reuse of an old one revokes the whole family.

## Troubleshooting
| Symptom | Look at |
|:--|:--|
| Backend restarts in a loop | `logs backend`: missing/short `QESMA_JWT_SECRET`, empty `GOOGLE_CLIENT_IDS`, database unreachable, or a failed migration (never edit a committed migration; add a new one). |
| `curl` over HTTPS fails | DNS must point at the server and 80/443 must be open; `logs caddy` shows the certificate attempts. |
| 429 on sign-in | Auth limit is 10 requests/minute per client IP (in memory). Behind Caddy the real client IP is used. |
| 500 `INTERNAL_ERROR` | Search `logs backend` for the `requestId` from the response body. `balance.invariant_violated` is a bug: keep the log and the database. |

## Known limitations (Phase 1)
- **One instance.** The auth rate limiter is in memory and per instance (resets on restart); there is no high availability.
- **Online only.** The app needs the server for every action; there is no offline queue or sync.
- **Greedy simplification.** Suggested transfers use the deterministic greedy rule of spec 7.7, not a guaranteed minimum number of payments.
- **No rate limit on write endpoints** other than the 64 KB body cap, amount caps and list caps (auth endpoints are limited).
- **Replay answers are historical.** A repeated create with the same key (24 h) returns the answer as at creation, even if the expense was edited or deleted since.
- **Revisions are not paged** and there is no limit on edits per expense.
- **Access tokens cannot be revoked** before their 15 minutes pass (ADR-002). Expired refresh tokens are not purged yet.
- **Group currency** is fixed at creation; amounts assume 100 minor units per unit (Decision A22). No multi-currency.
- **Backups stay on the server** unless you copy them off; HTTPS certificates need a real DNS name.
- Real-device and real-receipt acceptance checks are manual (`../docs/gates/acceptance-b8.md`).

## Cross-cutting behaviour
- Every response carries `X-Request-Id` (a safe inbound value is echoed, otherwise generated); it is in the log MDC as `requestId`.
- Logs are structured JSON (ECS) in `test`/`prod`, readable text in `local`.
- Errors are `application/problem+json` with a stable `code` and `requestId`; no stack traces reach clients.
- Locally, actuator exposes `health` and `info` on the API port; in `prod`, `health`, `info` and `metrics` are served on the internal management port only. Readiness includes a real database check.
- Security headers on every response (`X-Content-Type-Options`, `Cache-Control: no-store`, `X-Frame-Options`), no `Server` banner, CORS disabled.
