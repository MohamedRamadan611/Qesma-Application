# FLR review: FL0 + FL1 + FL2 (mobile)

**Date:** 2026-11-09 · **Method:** cold read-only subagent (fresh context, no execution), findings spot-checked by the author session (not independent; disclosure as in gate-b8). **Baseline:** `HEAD` = `32451d9`, mobile work uncommitted.

Result: no blockers. Five majors, thirteen minors, four nits.

## Majors
| id | file:line | finding | status |
|:--|:--|:--|:--|
| A1 | `lib/core/auth/auth_interceptor.dart:57-68`, `session_manager.dart` (`endAfterRejectedRetry`, `_end`) | A late 401 after the session ended or after sign-out takes the "token version differs" branch and is retried with no token or with a *newer* session's token. The retry's 401 then calls `endAfterRejectedRetry()`, which ends the **current** generation: it can wipe a session the user just re-established and emit a second expiry. Cross-account replay is possible for creates. No test covers it. | **Confirmed by reading the code** (author) |
| A2 | `google_id_token_source.dart:66-83`, `auth_controller.dart:68-81` | Only `GoogleSignInException` / `GoogleSignInFailure` are caught. Any other plugin error leaves state `AuthSigningIn` forever; `_isBusy` blocks retries. | Reviewer, by reading. Failure mode certain if the plugin throws another type |
| A3 | `app_ar.arb` / `app_en.arb` `sessionExpiredBody` | Says "a long time without activity"; real causes are revoke/reuse, ambiguous refresh (incl. 5xx), storage failure. False reason, blames the user. | Reviewer |
| A4 | `session_manager.dart:123-141` | Every non-401/429 answer that is not provably unsent ends the session, including 502/503/504 and bad certificate/cancel. A backend deploy signs everyone out. Safe but wider than needed. | Reviewer (read backend `RefreshTokenService`). Design trade-off recorded in ADR-006 |
| A5 | `android/app/build.gradle.kts:33-35` | Release is signed with the debug key (template TODO). Google sign-in fails on release SHA-1. FL9 scope. | Reviewer |

## Minors / nits (summary)
B1 placeholder legal URLs; B2 "fewest transfers" overclaims (spec says not guaranteed minimal); B3 sign-out race tests use fixed timers, can pass vacuously; B4 goldens contain the debug-only link, 0.5% tolerance can hide label changes, never run on Linux; B5 `contrast_test` print test asserts nothing (`// ignore: avoid_print`); B6 guard regex holes (multi-line `Text(`, `100 *`, `% 100`, no test pinning `kDebugMode` around the fake link); B7 CI has no release build, no `--enforce-lockfile`, no regenerate-and-diff, Dependabot misses `/mobile/packages/qesma_api` and `/mobile/android`, and the workflow has never run; B8 fake backend differs from real (login creates a new family, no shared 10/min limit); B9 `mobile/README.md` status line stale; B10 release build without `API_BASE_URL` fails lazily with a raw error; B11 text-field label not bound to the field for TalkBack; B12 timeouts mapped to "offline" copy; B13 `from=` survives sign-out; N1 white Google button vs filled CTA in the design (low-contrast border); N2 unused declared packages; N3 register mix ("حاول/جرّب تاني"), "مليم", `devFakeSignIn` string ships in release ARB; N4 Keystore read on every token-less request.

## Doubts attacked (reviewer verdicts)
- CancelToken lost on retry: **refuted** (same `RequestOptions` reused). Same refresh token sent twice / stale write after sign-out: **refuted**. `provablyNotSent` vs dio 5.11.1: **correct**.
- Release safety (fake token, `/_catalog`, `INITIAL_ROUTE`, debug link, manifest): **refuted as a risk at source level**; the release APK was built but not string-scanned (command declined) → artifact check **NOT VERIFIED**.
- `url_launcher` needs `<queries>`: **refuted** (only `canLaunchUrl` does).
- Contract hash: LF-normalised `docs/openapi.json` hash equals `mobile/openapi.sha256` (reviewer). Not regenerated (needs Docker).
- SCREEN_MAP Omit items built / unsupported backend features: **none found**.

## Good
Refresh core (single-flight, persist-before-use, generation counter, narrow "provably unsent"); log API with no free-text parameter; tokens confined by a guard; integer-only money; exhaustive error mapping with no server text shown; pure redirect function with open-redirect check; honest contrast corrections.

## Recommended fix order
1. A1 (bind each request to its session generation; `endAfterRejectedRetry` ends only that generation; tests for late 401 after end/sign-out). 2. A2 (catch-all to `GoogleFailureKind.failed`, test). 3. A3 + B2 copy. 4. A4 decision (treat 502/503/504/bad-certificate/cancel as not sent). 5. B3/B4 deterministic race tests and tighter goldens, first Linux CI run. 6. B7 CI and Dependabot; before FL9: A5, B1. 7. Housekeeping.
