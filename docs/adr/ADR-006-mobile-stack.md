# ADR-006: Mobile stack and generated API client

Status: Accepted (FL0) · Date: 2026-11-08

## Context
Spec 5.2 fixes Flutter, Riverpod, go_router and dio, with an API client generated from `docs/openapi.json`. AGENTS.md rule 11 requires an ADR before adding libraries. The mobile app is built by one person; the stack must be boring, pinned, and cheap to keep green. Money rules (SCREEN_MAP 1-3) forbid floating point and client-side split logic in Phase 1.

## Decision
**Toolchain (pinned):** Flutter 3.47.9 (stable), Dart 3.13.7. Pinned in `pubspec.yaml` (`environment`), `.github/workflows/mobile.yml` and `mobile/README.md`. Android only, `applicationId` / namespace `app.qesma.app`, `minSdk 24`.

**Runtime dependencies (exact versions, no `^`; Dependabot proposes bumps):**

| Package | Version | Why | Rejected alternative |
|:--|:--|:--|:--|
| `flutter_riverpod` | 3.5.0 | state and DI (spec 5.2). No `riverpod_generator`, no codegen | Provider / BLoC |
| `go_router` | 18.1.3 | navigation, redirect guard for session expiry (FL2) | hand-rolled Navigator |
| `dio` | 5.11.1 | HTTP, interceptors, cancel; the generator target is `dart-dio` | `http` (no interceptors) |
| `built_value`, `built_collection` | 8.13.0, 5.1.2 | models returned by the generated client | `json_serializable` (not what the pinned generator emits) |
| `intl`, `flutter_localizations` | 0.20.3, SDK | ARB localization, RTL | hand-rolled maps |
| `qesma_api` | path | the generated client (below) | hand-written DTOs (forbidden) |

Dev: `flutter_lints 6.0.0`, `crypto 3.0.8` (contract hash test only). No mocking library: tests use hand-written fakes. No `uuid` package: the Idempotency-Key is a v4 UUID from `Random.secure()` (unit-tested). No `freezed`, `equatable`, `decimal` or `money2`: money is `int` piasters with our own parser/formatter (`core/money`).

**Approved now, added by the milestone that uses them (no new ADR needed):** `flutter_secure_storage` and `google_sign_in` (FL2), `connectivity_plus` (FL8, only if dio errors prove insufficient).

**Generated client.** `mobile/packages/qesma_api` is produced by `mobile/tool/generate_api.sh` with `openapitools/openapi-generator-cli:v7.8.0` (`-g dart-dio`, `serializationLibrary=built_value`) followed by `build_runner`. It is **committed**, so CI and contributors need no Docker; it is never edited by hand and is excluded from lint. `mobile/openapi.sha256` holds the SHA-256 of `docs/openapi.json` with line endings normalised to LF (so Windows and Linux agree). A test fails when the contract changes without a regeneration, printing the command. A second test asserts that each of the 24 operations exists in the generated package under its `operationId` (names fixed in the backend by B9/FL0 Step A).

**Environment rules.**
- The generated client already contains `/api/v1` in every path. `API_BASE_URL` (`--dart-define`) is the server **origin** only.
- Release builds require an `https` `API_BASE_URL` and have no default. Debug builds default to `http://10.0.2.2:8080`; cleartext is allowed to `10.0.2.2` and `localhost` only by `android/app/src/debug` (network security config), never in `main`.
- Developer settings (base URL override, fake-auth token) live in `core/api/dev_settings.dart`, guarded by `kDebugMode`; a guard test keeps the token format out of every other file.

## Consequences
- Updating the backend contract means: export `docs/openapi.json`, run `mobile/tool/generate_api.sh` (needs Docker once), commit the regenerated package and hash. Forgetting is caught by `flutter test` and CI.
- The generated package depends on `built_value` 8.x and `dio` 5.x; upgrading either is a deliberate change that regenerates the client.
- Exact pins mean Dependabot PRs are the only way versions move; each one must pass `flutter analyze` and `flutter test`.
- Guard tests (no `double`/`num`/`/ 100`/`.round()` outside `core/money`, no hard-coded UI strings, no fake token outside `dev_settings.dart`, no prints) make the SCREEN_MAP rules mechanical instead of review-dependent. `double` is allowed in `core/theme` and `core/widgets` for pixel sizes only.
- Android SDK and Docker are developer-machine prerequisites; CI installs Flutter and the Android toolchain itself.

## Addendum (FL1, 2026-11-08): design system, fonts and accessibility policy
No new pub dependency was added.

- **Font:** IBM Plex Sans Arabic (SIL OFL 1.1) is bundled as an asset (`mobile/assets/fonts`, four weights, source commit and SHA-256 in its README) and its licence is registered with `LicenseRegistry`. No runtime download, no `google_fonts` package. Tabular figures and Western digits are verified by `test/core/theme/font_test.dart`.
- **Tokens live in `lib/core/theme/` only.** Values come from `docs/design/DESIGN.md` prose and the English spec, not from the auto-generated Material palette in its front-matter. Where the design's colour pairs fail WCAG AA (owed `#059669` 3.58:1, owes `#E11D48` 4.28:1, settled `#64748B` 4.34:1) the AA-passing pairs of the English spec are used (4.57, 4.52, 6.92). The input outline is darkened to 3.6:1 (the mock-up's `#CBD5E1` is 1.48:1). `test/core/theme/contrast_test.dart` lists every text and boundary pair and fails below 4.5:1 (text) or 3:1 (boundaries).
- **Guards added:** no raw colours outside `core/theme`; no physical left/right layout (`EdgeInsets.only(left:)`, `Alignment.centerLeft`, `TextAlign.right`, ...); the `/_catalog` route exists only under `kDebugMode` and nothing else imports it.
- **Western digits:** ARB placeholders for numbers are `String`s formatted by our code, so `intl` cannot emit Arabic-Indic digits. Material built-ins that format digits themselves (text-field counter, date picker) are not used; the date picker needs its own decision in FL5.
- **Goldens:** six component goldens in `test/goldens`, compared with a 0.5% tolerance (Windows vs Linux anti-aliasing). Update with `flutter test --update-goldens test/goldens` and review the PNG diff before committing.

## Addendum (FL2, 2026-11-08): session, token storage and Google sign-in
New dependencies (exact pins): `google_sign_in` 7.2.0 (Google ID token; 7.x is a rewrite of the API: singleton, `initialize` once, `authenticate`), `flutter_secure_storage` 11.2.0 (Keystore-backed storage for the refresh token; Android minSdk 24 matches ours), `url_launcher` 6.3.3 (the Terms and Privacy links; not in the original list, approved with the FL2 plan). No mocking library: tests use a fake `HttpClientAdapter` that behaves like the backend's auth.

- **Storage:** the refresh token alone is persisted (`SecureTokenStore`); the access token and the user are memory only. `android:allowBackup="false"` (a guard test checks it) because a restored backup cannot unwrap a Keystore key.
- **Refresh protocol** (ADR-002 rotation): single-flight refresh; the new refresh token is saved before the new access token is used; a generation counter stops a late refresh from resurrecting a signed-out session; a refresh token that may have reached the server is never sent again. Only a provable non-send (connection refused/DNS or a connect timeout) or a 429 keeps the token; a 401, a timeout after sending, a dropped connection after sending, a 5xx or an unreadable answer ends the session. Cost: a flaky network during a refresh can cost one Google tap; benefit: no risk of revoking the session family by resending a rotated token.
- **Token hygiene:** `AuthLog` accepts only an event, an enum and an HTTP status (no free text, so no token can be passed in); `GoogleSignInAuthentication.toString()` prints the ID token, so that object is never interpolated; a guard test keeps the identifiers `accessToken`/`refreshToken`/`idToken` inside `lib/core/auth` and `lib/features/auth/application`.
- **Google "G" asset:** `assets/brand/google_g.png`, Google's unmodified standard-colour mark from gstatic.com, SHA-256 `5b95eed86b7603081f22edd5da01de4c028b118b20885793b9b3ad5f6cbe1e71`. Whether the button's overall styling follows Google's current branding guidelines is NOT VERIFIED.
