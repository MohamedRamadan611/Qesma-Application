# Gate SA12 — Receipt OCR (local mode)

Implementer session, 2026-11-19. Branch `release/standalone-flutter-v1` (uncommitted). Spec: STANDALONE_SPEC 13, A144–A146, A169, A170.

## Automated results
| Check | Command | Result |
|---|---|---|
| Analyze | `flutter analyze` | see summary in the hand-off message |
| Receipt tests | `flutter test test/features/receipt_scan` | parser (9 fixtures + edge cases), Cairo day/DST, JPEG strip, service (cap 20/21, every failure kind, hiding, no file created), UI ar/en x 1.0/2.0 (consent once, each error message + "type manually", retry), end-to-end editor (scan -> unsaved draft -> assign -> match / mismatch banner) |
| Guards | `flutter test test/guards` | Firebase limited to exactly three packages; Firebase / image_picker imported only under `lib/features/receipt_scan/`; the feature writes no file; `receiptScan` scope key alive |
| Migration | `flutter test test/local/db/migration_test.dart` | v6 -> v7 keeps data, defaults, CHECKs |
| Known failure before this work | `source_guards_test`: "Android auto-backup is on ... FlutterSecureStorage.xml" | pre-existing since SA9 (also in `gate-sa11.md`); not touched here |

## Human steps the owner must do (I cannot)
| # | Step | Done |
|---|---|---|
| H1 | Create a Firebase project on the **Spark** plan, no billing account | |
| H2 | Register the Android app `app.qesma.app` with debug, release and Play App Signing SHA-1 / SHA-256 | |
| H3 | Console > AI Services > AI Logic > Get started > **Gemini Developer API** | |
| H4 | App Check > register the app with **Play Integrity**; enforce for AI Logic; run a debug build once and register the debug token printed in logcat (Manage debug tokens) | |
| H5 | AI Studio rate-limit table: write the **Flash-Lite free-tier RPM / RPD** here and compare with 20 scans/device/day × expected users (A145): ______ | |
| H6 | Put `google-services.json` in `mobile/android/app/` (download from the console; not a secret, not edited by hand). Then `flutterfire configure` is NOT needed: `Firebase.initializeApp()` reads the Android config | |
| H7 | Re-read the Gemini API terms before release and confirm the consent wording (A146) and the Egypt-only Play listing (A170) | |

Without H6 the app builds and runs; the scan entry points and the profile row are hidden (initialisation fails quietly).

## Manual checks on a real phone (not done in this session: no device attached)
| # | Check | Result |
|---|---|---|
| M1 | 10 real Egyptian receipts (Arabic, English, mixed, Arabic-Indic digits, crumpled, with and without service/tax): items right, amounts right, total banner correct. Note accuracy per receipt: | NOT VERIFIED |
| M2 | Provoke offline, quota, App Check refusal: record the **exception class and message** seen for each (403 has no documented Dart class; the app matches on the message) | NOT VERIFIED |
| M3 | Portrait and landscape, camera and gallery: is the photo upright after the EXIF strip? If a rotated photo reads badly, keep only the orientation tag | NOT VERIFIED |
| M4 | logcat shows no image bytes and no model text; debug App Check token flow works; a release-signed build passes Play Integrity | NOT VERIFIED |
| M5 | The model id `gemini-3.5-flash-lite` answers for this project | NOT VERIFIED |
| M6 | Release APK size per ABI with the three Firebase packages | NOT VERIFIED |

## Assumptions and open questions
- Decisions taken as recommended in the plan: hide after 3 consecutive permission errors for 7 days (Q1); Egypt-only listing (Q2, A170); Egypt DST rule in code (Q3); count a scan when sent (Q4).
- The 20/day cap is per device, the quota is per project: the cap cannot protect the free quota (A169).
- Consent and counters are device state: excluded from the backup; a restored phone asks for consent again.
