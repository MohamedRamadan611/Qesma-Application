# Gate FL9: integration against the real backend, release build, device checklist

Date: 2026-11-10 · Phone: Xiaomi M2007J3SY (Android 16 build tools target) · Backend: local jar, profiles `local,fake-auth,seed,dev-mail`, port 18080,
auth rate limit raised for the test run (`--qesma.auth.rate-limit.max-requests=1000`; the production default stays 10/min).

## Verified (with the command that proves it)
| Item | Evidence |
|---|---|
| Seeded Dahab balances against the real backend | `test/integration/fl9_scenarios_test.dart` (a): nets 1,014.01 / 1,114.02 / -688.03 / -720.00 / -720.00 (owner member is named "محمد رمضان" in the seed), sum 0, four transfers whose per-person totals settle every debtor |
| Lost response, same Idempotency-Key on the retry | scenario (e): the first POST is processed but its response is dropped; the retry reuses the key; the list has exactly 1 expense and the group total counts it once |
| Expired access token refreshed once | scenario (f): one `/auth/refresh`, the same call then succeeds |
| Offline then back | scenario "offline": the failure is retryable; the same call works afterwards |
| Real UI on the phone | `integration_test/dahab_smoke_test.dart` on device `7c8ab4a2`: welcome → debug sign-in → "رحلة دهب" → Balances tab shows "4 transfers needed", transfers 720.00 / 394.02 / 294.01 and, after scrolling, nets 1,014.01 / 1,114.02 / 688.03. Result `All tests passed` |
| All live tests together | `flutter test test/integration --dart-define=API_BASE_URL=http://localhost:18080` → `+13: All tests passed!` (needs the raised rate limit: 10 `/auth` requests per minute per IP is below what the 9 live files use) |
| Contract | `test/contract/openapi_contract_test.dart`: hash matches, 31 operations generated, every operation the app calls is in `docs/openapi.json` |
| Scope audit | `test/guards/scope_guard_test.dart`: no omitted/Phase 2 word, icon or route (SCREEN_MAP section 3, P12-P14). One allow-listed false positive (Arabic "ضيف" = "add") |
| Release build | `flutter build apk --release` (58.0 MB) and `appbundle --release` (55.9 MB) succeed with R8 and resource shrinking on, signed with the upload key (SHA-1 `6C:4D:0B:CF:BE:5C:08:0B:C5:32:71:B9:E1:FB:B6:AA:C5:18:5F:00`) |
| Release artifact hygiene | `bash mobile/tool/check_release_artifact.sh` → `RELEASE ARTIFACT OK`: non-debug signature, only `INTERNET`, not debuggable, no cleartext/network config, no `10.0.2.2`, `/_catalog`, `fake:`, debug sign-in label, `INITIAL_ROUTE`, key material or http API URL. The first run caught two biometric permissions merged by a plugin; removed with `tools:node="remove"` |
| App icon | Legacy PNGs rendered from the brand logo (`tool/generate_launcher_icons_test.dart`) + adaptive vector icon (`drawable/ic_launcher_foreground.xml`, teal `#0F766E` background); `aapt dump badging` shows `mipmap-anydpi-v26/ic_launcher.xml` |
| Username keyboard bug (found on the phone) | The keyboard inserted a space after a dot ("Phone. Tester1" was refused). Username fields now set `autocorrect: false`; on the phone `Fl9.Tester15772` is accepted and registration lands on the groups screen (Arabic, RTL) |
| Unit/widget suite | Earlier full run: 1008 passed; the only failures were the live files hitting the auth rate limit (fixed by the raised limit above) |

## Deviations and findings
- The seed's owner member is "محمد رمضان" while `docs/STITCH_PROMPTS.md` and the README say "محمد". The test follows the real data. Not a defect; the docs could be aligned.
- `integration_test` is an on-device smoke only; the whole matrix (b)-(d), (g) of the FL9 prompt through the UI is NOT automated.
- The launcher icon was verified from the rendered PNG and the packaged resource, not from a home-screen screenshot.

## Round 2 (2026-11-11): the leftovers
| Item | Result |
|---|---|
| Smoke test | `scripts/smoke.sh` run against the live backend: 61/61 originally; extended with the password-auth block (ADR-008) and an optional Dahab seed check (`SMOKE_DAHAB=1`): **79/79 passed**. See backend/README.md |
| Contract regeneration (Docker, openapi-generator 7.8.0) | `bash mobile/tool/generate_api.sh` exit 0: **empty diff** on `mobile/packages/qesma_api`, `openapi.sha256` unchanged (`883548bc…a762`) |
| 500-expense performance, backend (HTTP edge, 100 extra groups) | p95 under 25 ms on every read endpoint; table in docs/perf-notes.md |
| 500-expense list in the app | `expenses_scale_test.dart`: lazy list, every page once. Frame times NOT measured (https rule), see docs/mobile-perf.md |
| A11y on every routed screen | `test/a11y/all_screens_test.dart`: 12 screens x light/dark x ar/en, guidelines at 1.0x and no overflow while scrolling at 2.0x text: **96 tests passed** |
| UI flows on the phone (real UI, real backend) | `integration_test/group_flow_test.dart` (b)+(c): create group, 2 members, EQUAL expense 100.00, details show 33.34 / 33.33 / 33.33, balances show the server's nets: **passed**. `integration_test/payment_conflict_language_test.dart` (c)(d)(g): record the suggested payment -> everyone settled; a stale edit -> conflict dialog, the server holds 110.00 as version 2; language to Arabic -> RTL and Arabic text: **passed** |

## NOT DONE / NOT VERIFIED
| Item | State |
|---|---|
| UI flow (b): itemized bills (service/tax, V5-V8) and a multi-payer expense through the screens on the phone; deleting an expense in the UI | NOT DONE on the phone (V5-V8 are covered by the widget tests, the smoke script and the live API tests; the flows in Round 2 cover create, equal split, payment, conflict, history and language) |
| TalkBack walkthrough; RTL review against the design images; sheets and dialogs under the guideline tests | NOT DONE (sheets and dialogs are covered where opened by the feature tests; TalkBack is on the checklist) |
| Performance on the phone: frame times, cold start | NOT MEASURED (profile builds need an https backend; see docs/mobile-perf.md). Backend and list laziness are measured above |
| Release APK run on the phone against an https backend (R8 check) | NOT RUN (no https backend yet) |
| Real Google sign-in | NOT VERIFIED (Google Cloud setup pending) |
| Items in `docs/gates/mobile-device-checklist.md` | all NOT VERIFIED until a human runs them |

## Open items that block a public release
Account deletion, privacy-policy and terms URLs, password recovery, Google Cloud OAuth clients, a production https backend. Details: `docs/mobile-release.md`.

Recommended next step: run `flv-verify` in a fresh session, then decide whether the NOT DONE rows above are required before the first internal-testing upload.
