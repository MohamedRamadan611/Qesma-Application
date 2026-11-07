# ADR-002: Authentication and token design

Status: Accepted (B1) · Date: 2026-11-07

## Context
Phase 1 is Google Sign-In only (Decision A4). The backend verifies a Google ID token, then issues its own session (spec 5.1, 8.2, 11).

## Decision
- **One new dependency:** `spring-boot-starter-oauth2-resource-server` (Spring Security 6.5.x + Nimbus JOSE, version managed by Spring Boot). It verifies Google's RS256 ID tokens against Google's JWKS (signature, issuer, audience, expiry) and signs/validates our own HS256 access tokens. No hand-written cryptography. `google-api-client` was rejected: a second, larger dependency tree for the same job.
- **Google verification** sits behind the `GoogleIdTokenVerifier` interface. The fake implementation exists only under the `fake-auth` profile; startup fails if `fake-auth` and `prod` are both active.
- **Access token:** JWT, HS256, 15 minutes, `sub` = user id, `iss` = `qesma`. Key from `QESMA_JWT_SECRET` (base64, at least 32 bytes, checked at startup).
- **Refresh token:** opaque 256-bit random value, only its SHA-256 stored, 30 days, rotated on every use. Tokens of one login form a *family*. Presenting an already-rotated token revokes the whole family. Rotation is serialized with `SELECT ... FOR UPDATE`, so two simultaneous uses of one token yield one success and a revoked family.
- **Users** are created with `INSERT ... ON CONFLICT DO NOTHING` then a read; the unique constraint on `(auth_provider, auth_subject)` is the arbiter under concurrency.
- **Errors:** every authentication failure is the same 401 `UNAUTHORIZED` problem+json; the cause is never disclosed. Unreachable Google keys give 503.
- **Rate limit:** in-memory fixed window per client IP on `/api/v1/auth/**`, 10 requests per minute by default.
- **CORS is disabled** (the only client is the mobile app); CSRF is off because there are no cookies or sessions.

## Consequences / known limits
- Access tokens cannot be revoked before they expire (up to 15 minutes after logout). Acceptable for Phase 1; revisit if a "sign out everywhere now" requirement appears.
- A client that loses the response to a refresh call has used the token without receiving the new one; its next attempt looks like reuse and ends the session, so the user signs in again. Safe, slightly inconvenient.
- The limiter is per instance and resets on restart. Behind a reverse proxy, forwarded headers must be enabled or all clients share one bucket.
- Expired refresh-token rows are not purged yet (small table; cleanup job planned for B8).
- Only verified Google emails are stored.
