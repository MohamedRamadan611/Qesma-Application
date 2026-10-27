---
description: "B1 — Auth & security foundation"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 5.1, 6 (users), 8.1, 8.2 (auth + /me), 8.5, 11, 14 (Decision A4: Google Sign-In only). Skills to apply: think-before-coding, auth-and-authorization, security-discipline, data-modeling-discipline, migration-safety, error-handling-as-design, observability-by-default, testing-with-discernment.

Step 0 (plan, wait for approval): the six-step design for the auth component: context/load, data model and invariants (users, refresh tokens), failure modes (invalid/expired Google token, refresh reuse, replayed refresh, clock skew), authorization map, replay/concurrency (two simultaneous first logins for the same Google account), observability.

Implement:
1. Flyway migrations: users (spec section 6) and refresh_tokens (id, user_id FK, family_id, token_hash, expires_at, revoked_at, replaced_by_id, created_at; indexes; CHECKs). Review them against migration-safety.
2. GoogleIdTokenVerifier as an INTERFACE. Real implementation validates the Google ID token (signature via Google's keys, issuer, audience against configured client IDs from env, expiry). A fake implementation is used in tests. Use an official/standard library; verify the dependency from its documentation; do not hand-roll crypto.
3. POST /api/v1/auth/google {idToken} -> creates the user if new (race-safe: unique constraint + upsert, never two users for one provider subject), returns { accessToken, refreshToken, user }.
4. Access token: short-lived JWT (about 15 minutes), signing key from env (document minimum length). Refresh token: opaque random 256-bit value, only its SHA-256 hash stored, rotating on every use, about 30 days. Reuse of a rotated refresh token revokes the whole family.
5. POST /auth/refresh, POST /auth/logout (revokes the family), GET /me, PATCH /me (displayName trimmed, 1–60 chars).
6. Spring Security: stateless filter chain; /auth/**, /actuator/health, and (local profile only) API docs are public; everything else requires a valid access token; authenticated principal exposes the user id; CORS disabled (mobile client).
7. Rate limiting on /auth/** (simple in-memory limiter is fine for one instance; document the limitation).
8. Error responses via the global problem+json handler with codes UNAUTHORIZED / VALIDATION_ERROR. Never reveal which part of a token failed.
9. Logging: never log tokens or Authorization headers; log auth events (login, refresh, reuse-detected) as structured events with user id and request id; add counters for logins and failures.

Tests (Testcontainers + fake verifier): first login creates one user even under concurrent calls; invalid audience/expired token rejected; refresh rotation works; reusing an old refresh token revokes the family; logout revokes; protected endpoint returns 401 without a token; /me update validates input; tokens never appear in logs (assert on captured log output).
Constraints: follow AGENTS.md; no email/password flow; no Phase 2 features. Done when ./mvnw verify passes and I can run the flow with curl using the fake verifier profile. Then follow the Stop protocol.
