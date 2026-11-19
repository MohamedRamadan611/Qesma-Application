# Gate SA11 — Khorouga calculator (local mode)

Verifier: independent session, 2026-11-19. Commit under test: `5902ac5` (SA10 and SA11 in one commit), compared with `dedf175`. Build, contract and full-suite results are shared with `gate-sa10.md`.

## Summary
- `flutter analyze`: clean. Full `flutter test`: **1862 passed, 13 skipped, 1 failed**. The failing test is the SA5 auto-backup guard (introduced by the SA9 commit, not by this diff).
- All SA11 tests pass when run on their own. Engine: `dart test test/ride` → `+33: All tests passed!`; the whole engine suite → `+133`.
- No device or emulator is attached (`adb devices` is empty; `flutter devices` shows only Chrome and Edge). All on-device checks are **NOT VERIFIED**.

## SA11 checks (prompt Implement/Tests lists)
| Check | Command | Evidence | Result |
|---|---|---|---|
| Engine `FuelSplit` (BigInt, round-half-up, LRM, limits) | `cd packages/qesma_engine && dart test test/ride` | `+33: All tests passed!`: rounding just below and exactly at half a piaster, limits (distance, consumption 1.0–30.0, price, ≤20 tolls, total ≤10^12), driver not a passenger, property test (sums, within one piaster, deterministic) | PASS |
| Engine `MultiStopSplit`; a leg with no riders → `VALIDATION_ERROR` (A141) | same | `legs without riders (A141)` and `compute rejects a trip with an empty leg` pass; limits 1..9 legs; property test (order-independent) | PASS |
| `fixtures/ride/*.json` (13 vectors) | `ride_fixture_test.dart` | each fixture runs; includes `fuel-half-piaster-rounds-up`, `fuel-tolls-only`, `fuel-driver-excluded`, `fuel-near-limits`, `fuel-over-limit-rejected`, `ride-join-and-leave`, `ride-uneven-legs`, `ride-zero-distance-legs-equal`, `ride-leg-without-riders-rejected` | PASS |
| Decimal parser (`Tenths.parse`): Arabic digits, comma, too many decimals | `flutter test test/core/money/tenths_test.dart` (in the combined run) | passes; covers `.`, `,`, `٫`, Arabic-Indic and Eastern digits, "1,200" rejected, range | PASS. Finding: U+060C `،` (Arabic comma) is not tested and not accepted |
| Saved fuel prices in drift (schema 6, CHECKs) | `fuel_prices_dao_test.dart`, `migration_test.dart` | upsert and replace; unknown type and out-of-range price refused; `v5 -> v6 keeps the existing data and adds the empty fuel_prices table` | PASS |
| Facade `lib/local/calculator/` is the only path to the engine (A149) | `source_guards_test.dart` | `qesma_engine is imported only under lib/local/` passes | PASS |
| Facade outcomes | `khorouga_calculator_test.dart` | engine result with driver as payer, "explains instead of throwing", names empty legs, zero fare / no riders | PASS |
| Calculator screen ar/en/text scale 2.0 | `calculator_screen_test.dart` | `fuel split, create the expense, ride with an empty leg (<config>)` passes for each config | PASS (in tests) |
| Prefill golden JSON of the `ExpenseCommand` | `prefill_golden_test.dart` | fuel (FUEL, driver pays) and ride (TRANSPORT, chosen payer) match `goldens/fuel_command.json` / `ride_command.json` | PASS |
| Backup accepts schema 6; fuel prices not exported | `backup_rejection_test.dart` | `the validator accepts the schema this app writes` passes | PASS |
| Scope guard words and route | `scope_guard_test.dart` | passes | PASS |
| On device: FAB menu → calculator, fuel chips with saved prices and "last updated", tolls, riders, live result, "Create expense" opens the EXACT form, leaving asks first | — | no device attached | NOT VERIFIED |

Combined targeted run (SA10 + SA11 files): `00:37 +121: All tests passed!`

## Adversarial probes
| Probe | Result |
|---|---|
| Distance or consumption with Arabic digits, `,` / `٫`, too many decimals, out of range | PASS (automated, `tenths_test`) |
| Sum of tolls near or over 10^12; 21 tolls; consumption 0.9 / 30.1 | PASS (automated, engine limit tests) |
| Leg with nobody on board | PASS (automated: engine rejects; facade names the leg) |
| Input `12،5` (Arabic comma) | NOT VERIFIED at runtime. From the code (`_normalize` does not map U+060C) it would be refused; no test covers it |
| Zero, negative or huge fuel price in the price dialog | NOT VERIFIED on device. The dialog caps at `maxPricePerLitreMinor` (code only) |
| Kill the app after "Create expense" before saving (nothing saved; the draft is not in the URL) | NOT VERIFIED (no device) |
| Text scale 200%, RTL/LTR, rotation on device | NOT VERIFIED (widget tests only) |

## Diff hygiene (SA11 part of `dedf175..5902ac5`)
- New dependencies: none.
- Fixtures: `fixtures/ride/*` added (Dart-only, A168(5)); no existing vector changed.
- Money math outside `lib/local/`, `packages/qesma_engine/`, `core/money`: none found (`grep` for `double|num|.round()|toDouble()|/ 100|* 100` over `lib/features/calculator`, `expense_draft.dart`: no hits).
- Catch-all: `lib/local/calculator/khorouga_calculator.dart:122` uses `} on Object {` around `FuelSplit.fuelMinor`, which cannot throw. It would turn any `Error` into "out of range". Finding.
- Disabled tests, `skip:`, `// ignore:`, TODO: none in SA11 files.
- Process: shares one commit with SA10 (see `gate-sa10.md`).

## Verdict: **GO WITH FIXES**
Minimal fixes:
1. The full suite must be green. Fix the SA9-era auto-backup guard failure (see `gate-sa10.md`, fix 1).
2. Narrow `on Object` at `khorouga_calculator.dart:122` to `on EngineException`, or remove it.
3. Accept U+060C `،` in `Tenths.parse` (STANDALONE_SPEC 11: "the comma is accepted") and add a test.
4. Do a device pass in local mode for the calculator flow and record the evidence.
