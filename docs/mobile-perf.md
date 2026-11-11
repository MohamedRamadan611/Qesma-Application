# Mobile performance notes (FL9)

What was measured, what was not. Backend numbers are in `docs/perf-notes.md` ("HTTP-edge measurement").

## Measured
- **The 500-expense list stays lazy.** `test/features/expenses/expenses_scale_test.dart` loads 500 expenses (25 pages of 20) into the real expenses stack and flings to the end: only page 0 is requested on open, every page is requested exactly once (no repeat, none after the last), fewer than 15 `ExpenseCard`s exist at any time (a `ListView.builder` builds what is on screen) and one more fling at the end calls the server no more. This is a structural check, not a frame-time measurement.
- **Round trips are small.** Over HTTP the endpoints the screens use answer in 9-20 ms p50 and under 25 ms p95 with 500 expenses and 200 settlements in one group.

## Not measured (and why)
- **Frame times, cold start and jank on the phone.** A profile or release build refuses a non-https `API_BASE_URL` (`ApiConfig`, by design) and the cleartext config exists only in the debug manifest, so a profile run against the local backend is not possible without either an https endpoint or weakening that rule. A debug-mode number would be several times slower than a release build and would say nothing about real behaviour. It stays on the device checklist (`docs/gates/mobile-device-checklist.md`) for when a staging backend with https exists: `flutter drive --profile` with `traceAction` on the expenses list, and `adb shell am start -W app.qesma.app/.MainActivity` for cold start.

## Observations from reading the code (no change made)
- `ExpensesTab._list` regroups every loaded item by date on each build (`groupByDate(state.items)`): O(n) per rebuild, fine at 500 rows, it would matter above a few thousand. Rebuilds follow state changes (a new page, loading flags), not scrolling.
- Each page is a separate request of 20 items with no prefetch. On a slow connection the user sees the loading row at the end of the list (covered by the skeleton and "try again" tests).
