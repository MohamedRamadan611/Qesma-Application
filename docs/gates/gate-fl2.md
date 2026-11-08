# Gate FL2 (auth, session): verification report

**Date:** 2026-11-09 · **Independence:** author session plus a cold read-only reviewer (see `review-fl0-fl2.md`). Not a fresh-session FLV.

| # | Check | Evidence | Result |
|:--|:--|:--|:--|
| 1 | analyze/test | clean; 400 passed, 2 skipped | PASS |
| 2 | 10 parallel 401 → one refresh; old refresh token never resent; persist-before-retry; failure policy | session_manager tests against the author's fake backend | PASS (fake backend only; fidelity gaps B8) |
| 3 | Late 401 after expiry or sign-out | no test; reviewer traced a defect (A1), confirmed by author reading `auth_interceptor.dart:57-68` | **FAIL (defect)** |
| 4 | Google sign-in error handling | non-Google exceptions leave `AuthSigningIn` stuck (A2) | **FAIL (defect, by reading)** |
| 5 | Real backend: login, `/me`, rotation, reuse, logout | integration test written, skipped; backend would not start (Docker hung, DB connection stalls) | NOT VERIFIED |
| 6 | Device flow: welcome → sign-in → fake sign-in → home → sign-out; restore; offline; expiry dialog | earlier session: app launched, log showed `auth.restoreStart` then `auth.restoreSignedOut`; screen was locked so no screenshot; adb input blocked | NOT VERIFIED beyond first launch |
| 7 | 429 on sign-in, kill backend during refresh | needs backend | NOT VERIFIED |
| 8 | No tokens in logs | canary tests pass; logcat grep not done | PASS (test) / device NOT VERIFIED |
| 9 | Real Google sign-in, Google button branding | needs owner's Google Cloud console | NOT VERIFIED |
| 10 | Release safety | source-level PASS; APK string scan declined | NOT VERIFIED at artifact level |
| 11 | Copy | `sessionExpiredBody` gives a false reason (A3); "fewest transfers" overclaim (B2) | Findings |

**Verdict: NO-GO for tagging.** Minimal fixes: A1 (with tests), A2 (with test), A3 copy; decide A4; then run the integration test and the device flow against a working backend. A5/B1 before FL9.

## Update 2026-11-09: fixes applied (author session)
A1, A2, A3 and B2 fixed with regression tests; analyze clean, `flutter test` 403 passed, 2 skipped. A1: each request carries its session generation; a 401 for an older generation is neither retried nor allowed to end the current session (`auth_interceptor.dart`, `session_manager.dart`). The new late-401 test was run with the guard disabled and failed, then passed with it restored. A2: catch-alls in `PlayGoogleIdTokenSource.signIn` and `AuthController.signInWithGoogle`. A3/B2: session-expired body no longer claims inactivity; welcome card no longer claims the fewest transfers. Still open: A4 (decision), A5/B1 (FL9), B3-B13, and every NOT VERIFIED row (needs working Docker and device input). Verdict stays **NO-GO for tagging** until rows 5-7 are run.
