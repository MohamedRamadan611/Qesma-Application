# Gate FL0 (bootstrap, generated client, core): verification report

**Date:** 2026-11-09 · **Independence:** run by the session that wrote FL0; **not** independent. Read-only: no source edited.

## Summary
Clean build and tests pass; everything that needs the real backend or Docker is NOT VERIFIED because the Docker engine is hung (`docker version` times out; Postgres accepts the port but the backend hangs at `HikariPool-1 - Starting...`).

| # | Check | Command | Evidence | Result |
|:--|:--|:--|:--|:--|
| 1 | Clean build | `flutter clean && flutter pub get && flutter analyze` | "No issues found" | PASS |
| 2 | Tests | `flutter test` ×5 | `+400 ~2: All tests passed` in 5 of 6 runs; **first run crashed the Dart VM** (native stack dump, `Dart_DetectNullSafety`), not reproduced in 5 reruns; a 6th cold run was interrupted by a session end | PASS with an unexplained intermittent crash (finding) |
| 3 | Skipped tests / suppressions | grep | 2 skips = integration tests waiting for `API_BASE_URL`; 1 `// ignore: avoid_print` (`contrast_test.dart:98`) | Finding (minor) |
| 4 | Contract hash | reviewer sha256 of LF-normalised `docs/openapi.json` | equals `mobile/openapi.sha256` | PASS (reviewer) |
| 5 | Regenerate client and diff | needs Docker | not run | NOT VERIFIED |
| 6 | Money hygiene | own grep for `double|num|/ 100|* 100|.round()|.toDouble()` outside `core/money` | only pixel/animation doubles in theme/widgets; no amount arithmetic | PASS |
| 7 | Dependencies | pubspec vs ADR-006 | only ADR-listed packages plus the three FL2 additions (ADR addendum) | PASS |
| 8 | CI workflow | static | never executed; no release build; Dependabot gaps (B7) | NOT VERIFIED / finding |
| 9 | Real-backend integration test | needs backend | not run | NOT VERIFIED |

**Verdict: GO WITH FIXES.** Fixes: investigate the one-off VM crash (rerun a cold `flutter clean && flutter test` a few times); regenerate-and-diff once Docker works; fix CI/Dependabot gaps (B7).
