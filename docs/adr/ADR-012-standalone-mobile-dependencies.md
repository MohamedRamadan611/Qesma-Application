# ADR-012: New mobile dependencies for the standalone release

Status: Accepted (SA0) · Date: 2026-11-17 · Extends ADR-006 (exact pins, no `^`; added by the prompt that uses them).

Versions were read from the pub.dev API on **2026-11-17** (latest stable; "published" is the pub.dev date). All fit the pinned toolchain (Flutter 3.47.9, Dart 3.13.7): the strictest constraints are Dart `^3.12` and Flutter `>=3.44` (firebase_*, speech_to_text). Licences are the pub.dev tags. **Size** figures are estimates, to be measured by the adding prompt on a release APK split per ABI (NOT VERIFIED until then).

| Package | Exact version | Published | Licence | Added by | Purpose | Size impact (estimate) | Alternative rejected |
|---|---|---|---|---|---|---|---|
| `drift` | 2.35.4 | 2026-11-08 | MIT | SA2 | typed SQLite layer, schema versioning, migration tests | small (Dart only) | `sqflite` + hand-written SQL (no typed schema or migration tests); `isar`/`hive` (no CHECK/UNIQUE/FK) |
| `drift_dev` (dev) | 2.35.3 | 2026-11-08 | MIT | SA2 | code generation and schema export for drift | none at runtime | none |
| `build_runner` (dev) | 2.17.1 | 2026-10-14 | BSD-3-Clause | SA2 | runs drift_dev (already used for the generated client) | none at runtime | none |
| `sqlite3` | 3.9.1 | 2026-11-08 | MIT | SA2 | bundles the SQLite native library through build hooks, FFI bindings used by drift | about 1 MB per ABI | `sqlite3_flutter_libs` (below) |
| `path_provider` | 2.1.6 | 2026-06-15 | BSD-3-Clause | SA2 | app documents / temp directory for the DB file and share files | negligible | hard-coded paths (not portable) |
| `file_picker` | 13.4.0 | 2026-11-16 | MIT | SA5 | pick a backup file to restore | small | `image_picker` for files (wrong tool); typing a path |
| `image_picker` | 1.2.4 | 2026-10-06 | Apache-2.0, BSD-3-Clause | SA12 | camera or gallery photo of a receipt | small | `camera` package (more code, preview handling) |
| `firebase_core` | 5.2.0 | 2026-11-16 | BSD-3-Clause | SA12 | required base of Firebase | small to medium | none (prerequisite of the next two) |
| `firebase_ai` | 5.2.0 | 2026-11-16 | Apache-2.0 | SA12 | Firebase AI Logic client for Gemini (Developer API, free tier) | small to medium | a hand-written Gemini REST call (would ship an API key); on-device ML Kit OCR (weak on Arabic receipts, no structured output) |
| `firebase_app_check` | 0.5.2 | 2026-11-16 | BSD-3-Clause | SA12 | Play Integrity attestation so only the genuine app can use the quota | small | no App Check (anyone could drain the free quota) |
| `speech_to_text` | 7.5.0 | 2026-09-14 | BSD-3-Clause | SA14 (update 1) | Egyptian Arabic voice entry (ar-EG, on-device when available) | small | cloud speech APIs (cost, privacy) |

Already present and reused: `share_plus` 13.3.1 (image and text share), `url_launcher` 6.3.3 (`wa.me` link).

## Deviations from the SA0 prompt and notes
- **`sqlite3_flutter_libs` is not used.** Its latest version is `0.6.0+eol` ("not used anymore, update to version 3.x of package:sqlite3"): `sqlite3` 3.x bundles SQLite through Dart build hooks. SA2 pins `sqlite3` 3.9.1 and documents how the native library is provided for `flutter test` on Windows.
- `drift` depends on `sqlite3 ^3.4.0`; pinning `sqlite3` explicitly keeps the transitive version reproducible.
- `firebase_app_check` is **0.x**: its API can change between minor versions. SA12 reads the current documentation before Step 0 and pins exactly.
- Firebase packages pull Google Play services and add a `google-services.json` (not a secret; not edited by hand). No other Firebase product is added.

**SA5 (2026-11-17):** `file_picker` 13.4.0 added (exact pin); API read from the package source: `FilePicker.pickFile()` returns a `PlatformFile` with `length()` and `readAsBytes()`. APK size impact not measured here (no release build in this session).

## Source guard
The test in `mobile/test/guards/source_guards_test.dart` that bans the substring `firebase` in `pubspec.yaml` is narrowed to allow **exactly** `firebase_core`, `firebase_ai` and `firebase_app_check`. `analytics`, `crashlytics`, `sentry`, `amplitude`, `mixpanel`, `shared_preferences`, `connectivity_plus` and `package_info_plus` stay banned. SA12 applies the change in the same commit as the dependency.

## Consequences
- Each prompt adds only its own packages, with exact pins, after `flutter pub get`, `flutter analyze` and `flutter test` pass; Dependabot proposes later bumps as in ADR-006.
- Small settings are stored in drift, not `shared_preferences` (A148).
- No analytics or crash SDK ships at launch (privacy, $0); Phase 3's Crashlytics plan is deferred.
- OCR is the only feature that sends data off the phone at launch; the privacy policy (SA13) and the in-app consent say so.
