---
description: "FL2 — Splash, welcome, Google sign-in, token storage, refresh rotation, session expiry"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/adr/ADR-002-auth.md, docs/PROJECT_SPEC.md sections 8.2 (auth), 8.5, 11, and open the screens `P1-01-splash.png`, `P1-02-Welcome.png`, `P1-03-Sign-in.png`, `P11-04-Session-Expired.png`. Prerequisite: FL0 and FL1 merged. Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review. Forbidden: backend skills.

Step 0 (plan, wait for approval), with the six-step design applied to the client: (1) context/load; (2) what is stored where (access token in memory, refresh token in `flutter_secure_storage`, nothing else sensitive); (3) failure modes: no network, 401, 429 `RATE_LIMITED`, 503 `AUTH_PROVIDER_UNAVAILABLE`, Google cancelled, token expired mid-use; (4) authorization on the client = route guards only; (5) **refresh concurrency**: the backend rotates the refresh token on every use and treats reuse of an old one as theft (ends the whole session), so the client must refresh **single-flight** (one refresh for N parallel 401s), persist the new refresh token **before** retrying the queued requests, and never retry a refresh with a token that was already sent; what happens if the app is killed between the response and the write (explain the residual risk and the recovery: sign in again); (6) observability: log events without tokens.

Implement:
1. Splash (restore session via `GET /me`), Welcome (static value props, start button, terms/privacy links to placeholder URLs recorded as an open item), Sign-in (Google button, loading, error states per code). Omit "explore as a guest".
2. `google_sign_in` with the server client id so the ID token audience matches `GOOGLE_CLIENT_IDS` on the backend; document the Google Cloud setup the owner must do (OAuth client for Android with the debug/release SHA-1, web client id used as `serverClientId`) in mobile/README.md. This cannot be verified without the owner's console: mark it NOT VERIFIED.
3. `AuthController` (Riverpod): states signed-out / signing-in / signed-in(user) / session-expired; `POST /auth/google`; `GET /me`; sign-out = `POST /auth/logout` best effort then wipe storage.
4. Dio auth interceptor: attach the bearer token, on 401 run the single-flight refresh, retry the original request once, on refresh failure raise session-expired (dialog P11-04 with Google sign-in again; omit "continue as guest").
5. go_router redirect guard: unauthenticated users only reach splash/welcome/sign-in; deep state restoration after sign-in.
6. Debug-only fake sign-in (from FL0) wired to the same controller so the app runs against `local,fake-auth,seed`.
7. 429 and 503 copy (ARB), offline handling with the shared no-internet state and retry.

Tests: 10 parallel 401s produce exactly one refresh call and all requests succeed afterwards; a failed refresh produces session-expired once; the old refresh token is never sent twice (assert on the fake server); tokens never appear in logs (capture the logger, assert); sign-out wipes storage; guard redirects; widget tests for sign-in states in ar and en. Use a fake Dio `HttpClientAdapter` (no new dependency). Add one integration-style test file that is skipped unless `API_BASE_URL` is set and runs the real login/refresh/logout against a local backend (documented command).
Constraints: no feature screens beyond auth; no tokens in logs, crash output or the widget tree; follow SCREEN_MAP rules. Done when analyze and tests pass. Then Stop protocol; do NOT start FL3 here.
