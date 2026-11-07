# ADR-003: Dependency and image scanning in CI

Status: Accepted (B8) · Date: 2026-11-07

## Context
The backend ships third-party code (Spring Boot, Nimbus, PostgreSQL driver, the JRE image). AGENTS.md requires an ADR and approval before adding infrastructure; the B8 security review needs a dependency scan. The project is built by one person on a free tier: the tooling must cost nothing and need no server.

## Decision
- **Trivy** (`aquasecurity/trivy-action`, pinned) runs in GitHub Actions: a filesystem scan of `backend/` (Maven dependencies, Dockerfile/compose misconfiguration) and a scan of the built production image. HIGH and CRITICAL findings with an available fix fail the job (`ignore-unfixed: true`).
- **Dependabot** (`.github/dependabot.yml`) opens weekly update PRs for Maven, the Docker base images and GitHub Actions, and raises security advisories.
- Nothing is added to the application: no runtime dependency, no agent, no server.
- Gitleaks (already in CI since B0) stays the secret scan.

## Consequences
- A new CVE in a transitive dependency can turn the build red without any code change; the answer is the Dependabot PR or a documented, time-boxed ignore.
- The scans only see what is in the repository and the image; they say nothing about the host OS, Postgres container updates on the VPS or Caddy. Those are handled by pinned image tags and the runbook (update procedure in `backend/README.md`).
- The workflow had not been executed on GitHub when this ADR was written; the first run is part of the CP3 check.
