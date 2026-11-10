# ADR-008: Accounts are identified by a username (email recovery on hold)

Status: Accepted · Date: 2026-11-10 · Amends ADR-007

## Context
ADR-007 added password sign-in identified by an email address, with verification and reset links. There is still no mail provider, so those links cannot be delivered, and asking people for an email address that does nothing yet is friction. The owner decided to ship sign-up and sign-in with a **username** now and wait on email.

## Decision
- **Identifier:** a username, 3 to 30 characters: letters of any script (Arabic works) and digits, with dots, hyphens and underscores inside, starting with a letter or digit, no `@`, a few official-looking names reserved. It is trimmed and lower-cased; it is the account's `auth_subject` (`auth_provider = 'PASSWORD'`), so `UNIQUE (auth_provider, auth_subject)` arbitrates concurrent registrations. A taken name is `409 USERNAME_TAKEN` (replaces `EMAIL_ALREADY_USED`). A retry of register with the same username and password signs in (201).
- **No email is collected.** `users.email` stays null for these accounts (V11 drops the "password accounts need an email" check). `UserDto.username` is new (null for Google accounts).
- **Sign-in is lenient on the key:** login looks the typed text up as a normalized subject, so the few accounts made with an email address before this change still sign in with that address.
- **Unchanged from ADR-007:** BCrypt hashing and the password policy (a password equal to the username is refused), identical 401 for every failure with a timing-equalizing dummy comparison, 5-failure / 15-minute lockout, change-password ending other sessions, rotating refresh tokens, owner-only authorization, per-IP rate limit, no secrets in logs.
- **Email flows are dormant, not removed.** `forgot`, `reset`, `verify` and `verify/resend` still work for an account that has an email address on file (none is created today). They are kept, tested and documented so recovery can be switched on when an optional email address and a mail provider (its own ADR) are added; the app has no screens for them.

- **Register is a password check too.** Registering over an existing username succeeds only for its owner (same password); it respects the lockout and a wrong password counts as a failure, so it is not a second way to guess passwords.
- **BCrypt runs outside database transactions** (only the counter update takes the row lock), so slow hashing never holds a pooled connection.

## Consequences / known limits
- **A forgotten password cannot be recovered.** There is no email and no admin tool; the user must create a new account. Accepted for Phase 1 development; this is the main reason email recovery should come before a public release.
- A username is public-facing identity only inside the app (the owner sees "@name"); it is not shown to other members (members are separate named entries in a group).
- Access tokens of other devices stay valid until they expire (15 minutes) after a password change; the refresh tokens end at once (ADR-002 limit).
- Usernames are first come, first served; reserved names are a short list, not a moderation system.
- Registration reveals that a username is taken (409); mitigated by the per-IP rate limiter.
