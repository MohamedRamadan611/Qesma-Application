# backend/AGENTS.md — Spring Boot backend (extends the root AGENTS.md)

## Commands (run from /backend)
- Build + all tests: `./mvnw verify` (integration tests need Docker running: Testcontainers + PostgreSQL)
- One test class: `./mvnw -q test -Dtest=ClassName`
- Local database: `docker compose up -d db`
- Run the app: `./mvnw spring-boot:run -Dspring-boot.run.profiles=local`

## Layout (base package `app.qesma`, placeholder)
`api` (controllers, DTO records) · `domain` (entities) · `engine` (PURE Java: no Spring/JPA/IO) · `service` · `security` · `persistence`
Migrations: `src/main/resources/db/migration` (Flyway, forward-only).
Shared test vectors: `../fixtures/*.json`.

## Reminders
- Money rules live only in `engine`. Controllers/services never compute money themselves.
- Integration tests use Testcontainers PostgreSQL, never H2.
- OpenAPI is generated from the code; `../docs/openapi.json` is the contract for the Flutter client.
