# Gate FL1 (design system): verification report

**Date:** 2026-11-09 · **Independence:** author session; not independent. Read-only.

| # | Check | Evidence | Result |
|:--|:--|:--|:--|
| 1 | analyze/test | see gate-fl0 (400 passed) | PASS |
| 2 | Contrast table | `contrast_test` passes every text pair ≥4.5 and boundary ≥3 (values printed earlier: lowest text 4.51, outline 3.44) | PASS (test) |
| 3 | Font bundled, tabular figures, ASCII digits | `font_test` 4/4 | PASS (test) |
| 4 | Components in ar/en at 1.0x/2.0x, no overflow, 48 px | widget tests | PASS (test) |
| 5 | Goldens | 6 component + 3 auth goldens, Windows-generated, 0.5% tolerance; contain debug-only link; never run on Linux (B4) | PASS with weaknesses |
| 6 | Catalogue on the phone | earlier session: catalogue build installed, top of the screen captured (buttons, switches); rest not reachable because adb input is blocked | PARTIAL; 2.0x/en/LTR on device NOT VERIFIED |
| 7 | Release excludes `/_catalog`, `INITIAL_ROUTE`, fake token | source: all under `kDebugMode`; release APK built OK (52.6 MB) but string scan declined | PASS at source level; artifact NOT VERIFIED |
| 8 | Accessibility | semantics tests pass; reviewer: text-field label not bound (B11), white Google button border 1.48:1 (N1) | Findings (minor) |
| 9 | Design deviations | listed in the FL1 report; reviewer found none new | PASS |

**Verdict: GO WITH FIXES.** Fixes: B11, strengthen goldens (B4), device screenshots at 2.0x and LTR once input injection works (enable "USB debugging (Security settings)").
