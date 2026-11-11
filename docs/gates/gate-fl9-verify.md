# Gate FL9: verification (FLV)

Date: 2026-11-11 · Phone: Xiaomi M2007J3SY (`7c8ab4a2`) · Backend: local jar, profiles `local,fake-auth,seed,dev-mail`, port 18080.

**Verifier = the session that implemented FL9. This is NOT an independent verification** (the owner chose "verify here, skeptically"). Every claim in `docs/gates/gate-fl9.md` was treated as unverified and re-run; rows below quote this run's output. A cold re-run in a fresh session is still recommended. This file is separate from `gate-fl9.md` (the implementer's report) on purpose.

Rules kept: no tracked file was edited by the checks (`git status --short` identical before and after `flutter clean && pub get && analyze && test`; the only new file is this report). Temporary artifacts live outside the repo (`D:\Qesma\verify_gen`, see Hygiene).

## Verdict: GO WITH FIXES
Nothing found breaks the FL9 scope on the mobile side. One **backend defect** (silent truncation of non-integer money in JSON) must go through `f-bugfix` in a backend session, and several checks remain NOT VERIFIED (human/https/phone prompts). Minimal fix list at the end.

## Checks
| # | Check | Command | Evidence | Result |
|---|---|---|---|---|
| 1 | Clean build | `flutter clean && flutter pub get && flutter analyze && flutter test` | analyze: `No issues found!` (exit 0); test: `+1100 ~13: All tests passed!` (exit 0). 13 skipped = the live-backend files (no `API_BASE_URL`) | PASS (skips explained, see 3a) |
| 1b | `flutter clean` leaves tracked files alone | `git status --short` before/after | `diff` of the two outputs is empty | PASS |
| 1c | Lint suppressions | `grep -rn "// ignore"` | 4, all `avoid_print` in tests that print a live-backend observation | PASS (note) |
| 2a | Hash | `sha256sum` of `docs/openapi.json` (CRLF stripped) vs `mobile/openapi.sha256` | both `883548bc20943cc779cfa60bf2927e232d7eb90754f7075bd6e5aa6f5a91d762` | PASS |
| 2b | Client regenerated independently | openapi-generator v7.8.0 (Docker) into `D:\Qesma\verify_gen\out`, `dart pub get`, `dart run build_runner build` (exit 0, 88 outputs); `diff -r -x .dart_tool -x pubspec.lock -x build` against `mobile/packages/qesma_api` | `diff_exit=0`, 0 differing lines | PASS |
| 3a | Live Dart tests vs the real backend (13: auth, groups, expenses, itemized, balances, profile, password, FL9 scenarios) | `flutter test test/integration --dart-define=API_BASE_URL=http://localhost:18080` (backend with `--qesma.auth.rate-limit.max-requests=1000`) | `+13: All tests passed!` | PASS |
| 3b | Smoke at the DEFAULT rate limit | `bash scripts/smoke.sh` | 75 PASS, 0 FAIL, `== all 75 checks passed` | PASS |
| 3b2 | Smoke with the seed | `SMOKE_DAHAB=1 bash scripts/smoke.sh` (after the limit window) | 79 PASS: Dahab nets `-72000,-72000,-68803,101401,111402`, 4 transfers, 212803 moved | PASS |
| 3c | On-device: Dahab balances through the real UI | `flutter test integration_test/dahab_smoke_test.dart -d 7c8ab4a2` | `+1: All tests passed!` | PASS |
| 3c2 | On-device: payment, edit conflict, language | `integration_test/payment_conflict_language_test.dart` | `+1: All tests passed!` | PASS |
| 3c3 | On-device: create group, members, equal expense, balances | `integration_test/group_flow_test.dart` | **2 attempts in this run failed to install**: `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` (MIUI prompt not accepted). The test itself did not run. It passed earlier in the implementing session | NOT VERIFIED in this run |
| 3d | Contract/scope/a11y tests | included in 1 (`openapi_contract_test`, `scope_guard_test`, `all_screens_test` 96 tests, `guidelines_test`) | green | PASS |
| 3e | Release builds | `flutter build apk --release` / `appbundle --release` with `--dart-define=API_BASE_URL=https://api.qesma.example` | `app-release.apk (58.0MB)`, `app-release.aab (56.0MB)`, both exit 0 | PASS |
| 3e2 | Artifact hygiene | `bash mobile/tool/check_release_artifact.sh` | signed non-debug, signer SHA-1 `6c4d0bcf…5f00` (upload key), only `INTERNET`, not debuggable, no cleartext/network config, no `10.0.2.2`, `/_catalog`, `fake:`, `Debug sign-in`, `INITIAL_ROUTE`, key material or http URL; `RELEASE ARTIFACT OK`. AAB: `jarsigner -verify` = `jar verified.` | PASS |
| 3f | Secrets out of git | `git ls-files \| grep -E "keystore\|\.jks\|key\.properties\|\.env$"`; `git check-ignore -v mobile/android/key.properties` | empty; ignored by `mobile/android/.gitignore:12` | PASS |
| 3g | Release APK runs (R8 did not strip needed classes), real Google sign-in, https backend, TalkBack, three real receipts, dogfood, airplane-mode retry during a save | not run | needs an https backend / Google Cloud setup / a human | NOT VERIFIED |

## Adversarial probes
| Probe | Evidence | Result |
|---|---|---|
| Dropped create response, same key reused | `fl9_scenarios_test.dart` (e) in the 13 live tests: key reused on the retry, list has exactly 1 expense, total counted once | PASS |
| Backend killed mid-save, then restarted | only the dropped-response simulation (above); no real kill during a UI save | NOT VERIFIED (UI) |
| Two parallel 401s -> one refresh | `session_manager_test.dart:57` "10 parallel requests with an expired access token cause exactly ONE refresh" (in the 1100) and the live expired-token scenario (f): one `/auth/refresh` | PASS |
| Expired / revoked refresh token, no loop | `auth_controller_test.dart:195` (ten parallel calls end the session once) and live reuse detection in `auth_flow_test.dart` (old token 401, whole family revoked) | PASS |
| Stale `If-Match` -> conflict dialog, input kept | phone: dialog "This expense was edited" shown (3c2); `expense_form_screens_test.dart:423` "your input stays" | PASS |
| 429 on sign-in | curl, default limit, 13 `POST /auth/google`: `401 x10, then 429 429 429`; body `{"code":"RATE_LIMITED",…}` + `Retry-After: 58`. App copy: `auth_controller_test.dart:101,227` (`SignInError.rateLimited`) | PASS |
| Zero / negative / huge amounts | `POST …/expenses` with totalMinor `0`, `-500`, `10^13` -> `422 VALIDATION_ERROR` each; `10^12` accepted | PASS |
| **Non-integer amounts** | totalMinor `10.5` -> **201, stored 10**; `10.99` -> **201, stored 10**; `"100"` (string) -> 201, stored 100; `1e2` -> 201, stored 100 | **FAIL (backend, see F1)** |
| 100 items / 101 items | itemized with 100 items -> 201; 101 items -> `422 VALIDATION_ERROR` | PASS |
| Arabic-digit amounts | `test/core/money` parse tests (in the 1100) | PASS (unit level only) |
| Empty and 500-expense lists | `expenses_scale_test.dart` (lazy, 25 pages once); `perf-seed.sh` 500 expenses over HTTP, p95 < 25 ms (implementer's run, not repeated here) | PASS (list); perf not repeated |
| 200% text, RTL/LTR | `all_screens_test.dart` 96 tests; on the phone the language flow flips to RTL | PASS |
| Rotate the device, background/foreground during a save | not run (phone shows lock screen / install prompts; app does not lock orientation: `grep setPreferredOrientations` empty) | NOT VERIFIED |

## Scope and money hygiene
- `grep -rnE "/ 100|\* 100|\.round\(\)|\.toDouble\(\)" mobile/lib` outside `lib/core/money`: **0 hits**. `double`/`num`/`.toInt()` outside money: 29 hits, all UI geometry (spacing tokens, widths, opacity, `lerp`); none touches an amount.
- Calculations not from preview/balances: none found in `lib/` by the grep above; the guard `source_guards_test.dart` (money arithmetic) is green.
- Phase 2 / omitted elements (`invite|notification|dispute|remind|receipt|instapay|wallet|export|guest|coming soon|contacts|cover photo|pay now|delete account|monthly`): no hit in the ARB files; in `lib/` only Dart `export` statements and a `receipt` icon in the debug-only component catalogue.

## Hygiene findings
| # | Sev | Finding |
|---|---|---|
| F1 | **Major (backend)** | `totalMinor` / payer amounts accept `10.99` and `"100"`/`1e2`: Jackson coerces them to `long` and truncates (`10.99` -> 10 piasters). The contract says integer minor units; a client that sends pounds-with-decimals silently records the wrong amount. Not fixed here (rule: report). Fix in a backend session (`f-bugfix`): disable `ACCEPT_FLOAT_AS_INT` / `ALLOW_COERCION_OF_SCALARS` for money fields (or a strict deserializer) and add a test returning `422 VALIDATION_ERROR` |
| F2 | Minor | The 13 live tests and `integration_test/` never run in CI (`API_BASE_URL` unset; no device). Plain `flutter test` reports `~13` skipped. Needs a documented command or a CI job with a backend |
| F3 | Minor | `integration_test` added to `pubspec.yaml` (SDK dev dependency) without a note in ADR-006 (the repo rule asks an ADR for new dependencies); also `mobile/pubspec.lock` changed |
| F4 | Minor | `mobile/android/build/` (AGP `reports/`) shows as untracked: not covered by `mobile/android/.gitignore`. Add `/build/` there |
| F5 | Minor | `group_flow_test.dart` could not be re-verified in this run (install prompt). Install-prompt friction on MIUI makes the on-device suite hard to automate |
| F6 | Note | 13 `catch (_)` in `lib/`: each reviewed here; all either map to a defined failure state (sign-in failed, storage failed, session ended) or are documented best-effort (preference not remembered, logout cleanup, token write). No swallowed business error |
| F7 | Note | Changed goldens in the working tree: none (`git status` shows no golden). The `sign_in_error_ar.png` golden regenerated during FL9 is already committed in HEAD |
| F8 | Note | Generated code: `mobile/packages/qesma_api` byte-identical to a fresh generation (2b). `lib/core/l10n/generated` unchanged in the working tree |
| F9 | Note | The FL9 diff in the working tree is 14 modified + 29 untracked paths (signing/R8/manifest/icons, smoke + perf scripts, new tests, docs). Earlier username-auth and `autocorrect` changes are already in HEAD, not part of this diff |
| F10 | Note | Temp folder `D:\Qesma\verify_gen` (generated client, ~tens of MB) is outside the repo; delete it |

## What is still NOT VERIFIED
Release APK behaviour at runtime (R8), real Google sign-in, https backend, TalkBack, real receipts, dogfood, real backend kill during a UI save, orientation change and background/foreground during a save, frame times and cold start (https rule, see `docs/mobile-perf.md`), `group_flow_test.dart` in this run.

## Minimal fix list before relying on FL9
1. Backend (`f-bugfix`): reject non-integer / string money values with 422 (F1).
2. Add `/build/` to `mobile/android/.gitignore` (F4); add the `integration_test` note to ADR-006 (F3).
3. Decide how the live and on-device suites run outside this machine (F2): one documented command, and a CI job once a backend is available.
4. Re-run `group_flow_test.dart` with the install prompt accepted; run the NOT VERIFIED rows in `docs/gates/mobile-device-checklist.md`.
5. Ideally repeat this whole gate cold in a fresh session.

## Stop protocol
- Assumptions: the dev backend on 18080 is representative (jar built earlier this session); backend suites were not re-run (no backend code changed).
- Open questions: should the money-coercion fix block the first internal-testing upload? (It is a backend change, so it needs `f-bugfix`.)
- Files created by this verification: `docs/gates/gate-fl9-verify.md` only (plus out-of-repo `D:\Qesma\verify_gen`).
