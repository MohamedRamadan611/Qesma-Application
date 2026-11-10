# ADR-007: Email + password sign-in

Status: Accepted · Date: 2026-11-10 · Supersedes Decision A4 ("Google only"); extends ADR-002 · **Amended by ADR-008: the identifier is a username, not an email; where this text says email as the sign-in identifier, read username.**

## Context
Phase 1 shipped Google Sign-In only. Real Google sign-in needs the owner's Google Cloud setup (Android + Web OAuth clients), and some users cannot or will not use a Google account. Decision A4 had deferred email/password because it needs password-reset emails; there is still no mail provider, no cost budget for one, and the spec forbids new infrastructure without an ADR.

## Decision
- **Identifier:** email + password. The normalized email (trimmed, lower-cased) is the account's `auth_subject` (`auth_provider = 'PASSWORD'`), so the existing `UNIQUE (auth_provider, auth_subject)` arbitrates concurrent registrations.
- **No new dependency:** hashing uses Spring Security's own `DelegatingPasswordEncoder` with BCrypt (cost 12; 4 in tests). The stored value starts with `{bcrypt}`, so the algorithm can be upgraded later without a migration. BCrypt reads 72 bytes, so the policy caps a password at **72 UTF-8 bytes** (an Arabic letter is 2 bytes) and requires **8 characters**; the most common passwords are refused; no composition rules.
- **Schema (V10, additive):** `users.auth_provider` accepts `PASSWORD`; `users.email_verified_at`; `user_passwords` (hash, failed-attempt counter, lock time); `email_tokens` (SHA-256 of an opaque 256-bit token, purpose `VERIFY_EMAIL`/`RESET_PASSWORD`, single use).
- **Sessions are unchanged:** the same 15-minute access JWT and rotating refresh token families (ADR-002). A password login starts a new family exactly like Google login. Authorization is unchanged (owner-only, 404 for others).
- **Accounts are never merged.** A Google account and a password account with the same email are two accounts; registering an address that a Google account uses is refused (`409 EMAIL_ALREADY_USED`). Auto-linking on an unverified email would allow account takeover.
- **Endpoints:** `POST /auth/register`, `/auth/login`, `/auth/password/forgot`, `/auth/password/reset`, `/auth/email/verify`, `/auth/email/verify/resend` (signed in) and `POST /me/password`. All `/auth/**` stay behind the per-IP rate limiter.
- **Answers that never disclose:** every sign-in failure (unknown email, wrong password, locked, Google-only account, malformed email) is the same `401 UNAUTHORIZED`; an unknown email still spends one BCrypt comparison. `forgot` always answers 204.
- **Lockout:** 5 consecutive failures lock the account 15 minutes (counter reset by a success or a finished lock); the answer stays 401. A wrong *current* password on change-password is a `422`, not a 401, so a signed-in app is not signed out by it.
- **Password change / reset** end every login session of the account (change: except the one making the request, which gets fresh tokens).
- **Mail is an interface** (`MailSender`). `NoopMailSender` (default) sends nothing and logs only that mail is not configured; `DevConsoleMailSender` (`dev-mail` profile) prints links and refuses to start with `prod`. A real SMTP sender needs its own ADR and a provider account.

## Consequences / known limits
- **Until SMTP exists, forgot-password cannot deliver in production** (the endpoint and token flow are built and tested). The mobile app does not offer forgot-password or verification screens yet.
- Registration reveals whether an email is registered (409) until verification gates sign-up; mitigated only by the rate limiter. Accepted for Phase 1.
- Lockout can be used to lock a known email out for 15 minutes; bounded by the per-IP limiter.
- A verified email does not gate any feature in Phase 1; `emailVerified` is informational.
- The rate limiter, like the rest of ADR-002, is per instance and in memory.
