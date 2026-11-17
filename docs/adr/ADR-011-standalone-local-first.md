# ADR-011: Standalone local-first mode

Status: Accepted (SA0) · Date: 2026-11-17

## Context
The owner wants a first public release with no deployed server and $0 running cost, for one organizer. The Java backend (Phase 1 and Phase 2 through B17) is complete and green. The mobile app talks to it through a client generated from `docs/openapi.json` over dio, and every screen already depends on that contract. AGENTS.md invariants 3 and 4 say the engine is pure and the backend is authoritative; `mobile/AGENTS.md` forbids split math in Dart before Phase 4.

## Decision
1. **Local mode.** The app serves the existing `/api/v1` contract **in-process**: a `LocalBackend implements HttpClientAdapter` is plugged into `httpAdapterProvider`, backed by SQLite (drift). Repositories, DTOs and screens do not change. A build-time `QESMA_MODE=local|server` picks the mode; server mode is today's app.
2. **Two engines.** A pure Dart port (`mobile/packages/qesma_engine`) reproduces the Java engine. **Java remains the reference.** Equality is enforced by the shared `fixtures/` (every vector is run by both engines; any behaviour change adds a vector to both in the same commit).
3. **Invariants 3 and 4 hold inside the app.** The local backend is authoritative in local mode; money rules live only in `qesma_engine` and `lib/local/service/`; screens still do no money math. The "no Dart engine before Phase 4" rule is lifted for these two places only.
4. **Java is frozen, not deleted.** The repo is tagged `server-phase-ready` before SA1. The server phase later removes the `LocalBackend` override, adds an "upload my local data" endpoint and the multi-user features. Ids and JSON shapes stay server-compatible (STANDALONE_SPEC 5).
5. ADR-010 stays reserved for FCM. Dependencies are in ADR-012.

## Consequences
- **Benefits:** $0 hosting, works offline, no accounts, the existing UI and its tests are reused, and the server phase can resume from the tag.
- **Costs:** the money core exists twice. Mitigation: shared fixtures, a parity rule, review of every engine change in both languages, and a conformance suite that runs the repository and feature tests against `LocalBackend` as well as the fake servers.
- **Risk:** data lives only on the phone, so backup (STANDALONE_SPEC 6) is a launch requirement, and Android auto-backup replaces the FL2 `allowBackup="false"` rule (A128).
- Dart `int` is 64-bit on the supported targets (Android); web is not a supported target. Intermediate products that can exceed 2^63 use `BigInt`, exactly where Java uses `BigInteger`.
- Features that are server-only (invites, notifications, roles management, remind, confirm/dispute) answer `404 NOT_FOUND` locally and are hidden in the UI by one mode-aware mechanism.
- Two SA-era guard changes follow (STANDALONE_SPEC 15): path exemptions for `lib/local/`, and `qesma_engine` imported only under `lib/local/**`.
