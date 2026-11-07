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
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
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
     -d '{"name":"Dahab trip","type":"TRIP"}'                      # 201, Location + ETag: "1"
curl -s  "localhost:8080/api/v1/groups?page=0&size=20" -H "Authorization: Bearer $T"
curl -s  -X POST localhost:8080/api/v1/groups/<gid>/members -H "Authorization: Bearer $T" -H "$H" -d '{"displayName":"Sara"}'
curl -si -X PATCH localhost:8080/api/v1/groups/<gid> -H "Authorization: Bearer $T" -H "$H" -H 'If-Match: "1"' -d '{"name":"Dahab 2026"}'
curl -si -X DELETE localhost:8080/api/v1/groups/<gid> -H "Authorization: Bearer $T"      # 204
```
Another user's group id always answers 404 (never 403). PATCH needs `If-Match` (missing = 428, stale = 409 `VERSION_CONFLICT`).

Using an already-used refresh token again returns 401 and ends that whole session (rotation reuse detection).
Auth endpoints are limited to 10 requests/minute per IP (in memory, per instance); behind a reverse proxy enable forwarded headers (`server.forward-headers-strategy=native`) so the real client IP is used. See `../docs/adr/ADR-002-auth.md`.

Copy `../.env.example` to `../.env` (git-ignored) to override compose defaults.

## Docker image
```bash
docker build -t qesma-backend .
docker run --rm -e SPRING_PROFILES_ACTIVE=prod -e DB_URL=... -e DB_USER=... -e DB_PASSWORD=... -p 8080:8080 qesma-backend
```
The container runs as a non-root user.

## Cross-cutting behaviour
- Every response carries `X-Request-Id` (a safe inbound value is echoed, otherwise generated); it is in the log MDC as `requestId`.
- Logs are structured JSON (ECS) in `test`/`prod`, readable text in `local`.
- Errors are `application/problem+json` with a stable `code` and `requestId`; no stack traces reach clients.
- Actuator exposes only `health` and `info`; health includes a real database check.
