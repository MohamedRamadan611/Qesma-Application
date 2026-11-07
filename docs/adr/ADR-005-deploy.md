# ADR-005: Deployment on a single small VPS

Status: Accepted (B8) · Date: 2026-11-07

## Context
Phase 1 needs one reachable HTTPS endpoint for the mobile app at near-zero cost (spec 11): roughly 2 vCPU / 2 GB, one operator, no orchestration, daily backups with a restore that is actually tested.

## Decision
- **Docker Compose** (`docker-compose.prod.yml`) with four services: `db` (PostgreSQL 16.6), `backend`, `caddy`, `backup`. Only Caddy publishes ports (80, 443). The database and backend exist on the compose network only.
- **Caddy, not Nginx.** It obtains and renews Let's Encrypt certificates and redirects HTTP to HTTPS from a six-line config; no certbot, no cron, one container. It also adds HSTS, strips the `Server` header, caps request bodies at 100 KB, refuses `/actuator`, `/v3/api-docs` and `/swagger-ui` and redacts the `Authorization` header in its access log. Nginx would need an extra certificate tool for the same result.
- **Backend hardening:** non-root user, read-only root filesystem with a tmpfs `/tmp`, all capabilities dropped, `no-new-privileges`, memory limits, JVM sized by percentage (`MaxRAMPercentage=65`) and `ExitOnOutOfMemoryError` so the restart policy replaces a sick JVM. Hikari pool 10, Tomcat threads 50 (`application-prod.yml`).
- **Probes and metrics** (Spring Boot actuator) live on the internal management port 8081, which is not published and not routed by Caddy. Readiness includes the database. `forward-headers-strategy: native` is safe only because the backend is reachable through Caddy alone; the real client address is what the auth rate limiter counts.
- **Backups:** the `backup` container runs `scripts/backup.sh` at start and every 24 hours: `pg_dump` custom format, SHA-256 file, a read-back check, 14 days retention. `scripts/restore.sh` restores into a new database name, verifies the checksum and refuses to touch the live database without `--live`. `scripts/test-restore.sh` proves the procedure on throwaway containers (schema, every row and the balances must be identical, a corrupt dump and a live restore must be refused); CI runs it.
- **Secrets** only through `.env.prod` (git-ignored; template `.env.prod.example`); compose refuses to start when one is missing.

## Consequences
- Single host, single instance: no high availability; a reboot or image update is a short outage. The in-memory auth rate limiter is per instance (fine for one).
- Backups live on the same server by default (`BACKUP_PATH`). They protect against mistakes and corruption, not against losing the server: copy them off-site (rsync/rclone, runbook) before public release.
- The 24-hour loop is not wall-clock aligned; it drifts by the time the container was restarted. Use host cron with `docker compose run backup` if a fixed hour matters.
- HTTPS issuance needs a real DNS name and open ports 80/443; it was exercised locally with `DOMAIN=localhost` (Caddy's internal CA) but not against Let's Encrypt.
- Updating = `git pull` + `docker compose ... up -d --build`; Flyway migrations are forward-only, so take a backup first (runbook).
