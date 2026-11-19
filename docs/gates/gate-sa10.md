# Gate SA10 — Pool & treasurer (local mode)

Verifier: independent session, 2026-11-19. Commit under test: `5902ac5` ("Sa10 and SA11 are done"), compared with `dedf175` (SA9). SA10 and SA11 were committed **together** in one commit, so this gate and `gate-sa11.md` cover the same diff.

## Summary
- `flutter analyze`: clean. Full `flutter test`: **1862 passed, 13 skipped, 1 failed**. The failure (an SA5 auto-backup guard) was introduced by the SA9 commit `dedf175` and is not in the SA10 diff, but the suite is red.
- All SA10 tests pass when run on their own. The engine package passes (`dart test`: 133).
- Nothing was run on a device: `adb devices` lists none, and `flutter devices` shows only Chrome and Edge. Every on-device check and every device adversarial probe is **NOT VERIFIED**.

## Build and contract
| Check | Command | Evidence | Result |
|---|---|---|---|
| Clean build + analyze | `flutter clean && flutter pub get && flutter analyze` | `No issues found! (ran in 104.2s)` | PASS |
| Full test suite | `flutter test` | `03:52 +1862 ~13 -1: Some tests failed.` Failing: `source_guards_test.dart: Android auto-backup is on and limited to the local database file` → `Expected: contains 'FlutterSecureStorage.xml'` in `backup_rules.xml` | **FAIL** (from SA9, see Hygiene) |
| Skipped tests | same | 13 skipped, all `Skip: set API_BASE_URL … to run against a local backend` (server integration tests). None are SA10 tests. | Finding (expected for no backend; nothing ran against the server) |
| Engine fixture parity | `cd packages/qesma_engine && dart test` | `+133: All tests passed!` | PASS |
| Contract hash | `cat mobile/openapi.sha256; sha256sum docs/openapi.json` | both `1113461966011782c3f98fd40e877b6a619939e06964a01ce5384daf77a4ba7f`; `docs/openapi.json` and `qesma_api` not in the diff | PASS (client not regenerated into a temp folder: NOT VERIFIED) |

## SA10 checks (prompt Implement/Tests lists)
| Check | Command | Evidence | Result |
|---|---|---|---|
| Local migration 4→5 (columns, CHECKs, defaults, triggers) | `flutter test test/local/db/migration_test.dart` (in the combined run) | `v4 -> v5 keeps the ledger and adds the pool columns with their defaults` passes; bad `kind`, `paid_from_pool = 2` and a cross-group treasurer all throw | PASS |
| Services match Java validation and codes | `pool_rules_test.dart` | no treasurer → 422 for an expense and a deposit; payer not the treasurer, two payers, edit into an invalid pool expense → 422; deposit not to the treasurer → 422; self-deposit rejected (A138); unknown kind → 422 | PASS |
| A137 lock, counting cancelled and soft-deleted rows | `pool_rules_test.dart` | locked after a deposit, after a pool expense, after a cancelled deposit, after a soft-deleted pool expense → 409 `INVALID_STATE_TRANSITION`; a plain payment does not lock | PASS |
| Fixture scenarios through the local HTTP contract | `pool_fixtures_test.dart` with `fixtures/pool/*.json` (6 files) | each fixture: meter, nets, transfers, and the read-model equals the meter; "identical nets when every deposit is a plain PAYMENT" passes for all 6 | PASS |
| Idempotency includes `kind` | `pool_rules_test.dart` | same key with another kind → `IDEMPOTENCY_KEY_REUSED` | PASS |
| Backup round trip and schema-4 import | `backup_pool_test.dart` | round trip keeps treasurer, meter, flag and kind; schema-4 file imports with defaults; a foreign treasurer is refused | PASS |
| SA10 flow in local mode | `flows_local_test.dart` | `pool & treasurer: deposits, a pool expense, the meter and the lock (SA10 flow) in local mode` passes | PASS |
| Widgets ar/en/text scale 2.0 | `test/features/pool/` | `pool card, pool screen, deposit sheet, expense switch, edit group (<config>)` passes for each config | PASS (in tests) |
| Goldens | `pool_goldens_test.dart` | 5 goldens match (card, negative meter, deposit sheet, expense form toggle, dark) | PASS |
| Guards: no meter arithmetic in widgets; scope words | `source_guards_test.dart`, `scope_guard_test.dart` | pool guard and its liveness test pass; scope guard passes | PASS |
| On device: section in group settings, pool card, deposit sheet, toggle, balances note, negative meter in words | — | no device attached | NOT VERIFIED |

Combined targeted run: `flutter test <SA10 + SA11 files>` → `00:37 +121: All tests passed!`

## Adversarial probes
| Probe | Result |
|---|---|
| Same Idempotency-Key, different body (`kind`) | PASS (automated, `pool_rules_test`) |
| Deposit to a non-treasurer, self-deposit, pool expense with two payers | PASS (automated) |
| Treasurer change after cancelled or soft-deleted pool rows | PASS (automated) |
| Export/import round trip with pool data | PASS (automated, `backup_pool_test`) |
| Kill the app during a deposit save, then reopen (no partial rows, one row on retry) | NOT VERIFIED (no device) |
| Stale `If-Match` on edit group while the pool was used in another screen | NOT VERIFIED on device. The code maps 409 `INVALID_STATE_TRANSITION` to a snackbar, but no test or run exercised a version conflict combined with a treasurer change |
| Zero, negative, huge or Arabic-digit deposit amounts on device; 500-expense group | NOT VERIFIED (no device). Deposit amounts use the existing `Money.parse` path |
| Text scale 200%, RTL/LTR, rotation on device | NOT VERIFIED (only covered in widget tests) |

## Diff hygiene (`dedf175..5902ac5`)
- New dependencies: none (`pubspec.yaml` files unchanged).
- Changed fixtures or expected values: none. `fixtures/pool/*` were added; `fixtures/README.md` changed (docs only).
- Changed goldens: none modified, 5 added.
- Changed existing tests: 13 files. The only removed lines are `ExpenseRow(` / `SettlementRow(` constructors replaced by the same call plus the new required field (`paidFromPool: 0` / `kind`), and one ARB prefix list extended. No assertion was weakened.
- Disabled tests, `skip:`, `// ignore:`: none in the new SA10 files.
- TODO/FIXME: none.
- Catch-all handlers: none in SA10 files.
- Process: SA10 and SA11 landed as **one commit** (131 files, +29,706 lines including regenerated drift code). AGENTS asks for small, reviewable commits.
- Outside this milestone but blocking the suite: in commit `dedf175` (SA9), `<exclude domain="sharedpref" path="FlutterSecureStorage.xml"/>` was removed from `mobile/android/app/src/main/res/xml/backup_rules.xml` and `data_extraction_rules.xml`. The SA5 guard (`source_guards_test.dart:251`) and A164 still require that exclude.

## Verdict: **GO WITH FIXES**
SA10 behaviour is verified by automated tests only. Minimal fixes before SA12:
1. Make the suite green: reconcile `backup_rules.xml` / `data_extraction_rules.xml` with the A164 guard. Either restore the exclude, or record the change in the Decision Log and update the guard. The suite must not stay red.
2. Do a device pass in local mode (pool card, deposit, pool expense, negative meter, kill during save) and record the evidence. Until then, the on-device items stay NOT VERIFIED.
