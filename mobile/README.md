# mobile/ — Qesma (قسمة) Flutter app

Android-only Flutter app. Arabic first (RTL), English secondary. It records who paid what; it never moves money. Rules: `AGENTS.md` here, `../.claude/mobile/SCREEN_MAP.md`, decisions: `../docs/adr/ADR-006-mobile-stack.md`.

Status: **FL1 (design system)**. There are no feature screens yet: generated API client, money/error/idempotency/ETag helpers, localization and routing, plus the theme, bundled font and shared widgets.

## Prerequisites
| Tool | Version |
|:--|:--|
| Flutter (stable) | **3.47.9** (Dart 3.13.7) |
| Android SDK + platform tools | needed for `flutter build apk` / running on a device (`flutter doctor` must show the Android toolchain ticked) |
| Docker | only to regenerate the API client |
| JDK 17+ | used by Gradle (bundled with Android Studio) |

`minSdk` is 24 (Android 7.0); raise it only if a plugin requires it, and say why here.

## Everyday commands (run in `mobile/`)
```bash
flutter pub get
flutter analyze
flutter test                      # includes the contract hash test and the source guards
flutter gen-l10n                  # after editing lib/core/l10n/*.arb (also runs on pub get / build)
flutter build apk --debug
```

## Run against the local backend
```bash
# backend (from backend/): ./mvnw spring-boot:run -Dspring-boot.run.profiles=local,fake-auth,seed
# If port 8080 is busy on your machine, add -Dspring-boot.run.arguments=--server.port=18080
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:18080
```
- `API_BASE_URL` is the server **origin only**; the generated client already adds `/api/v1`.
- `10.0.2.2` is how the Android emulator reaches your computer. Cleartext HTTP is allowed to `10.0.2.2` and `localhost` in **debug builds only** (`android/app/src/debug`).
- Debug builds default to `http://10.0.2.2:8080` when `API_BASE_URL` is not given. Release builds must be given an `https` URL and refuse to start otherwise.
- The fake-auth sign-in token (`fake:<sub>:<email>:<name>`) exists only in `lib/core/api/dev_settings.dart`, behind `kDebugMode`.

## The generated API client
`packages/qesma_api` is generated from `../docs/openapi.json` and committed. Never edit it.

```bash
# from the repository root, with Docker running and flutter/dart on PATH
bash mobile/tool/generate_api.sh        # Windows PowerShell: mobile\tool\generate_api.ps1
```
It runs the pinned `openapitools/openapi-generator-cli:v7.8.0`, then `build_runner`, then rewrites `openapi.sha256`. After a backend contract change: regenerate, review the diff, commit the package and `openapi.sha256` together. `flutter test` (and CI) fail with this exact instruction if you forget.

## Layout
```
lib/
  main.dart, app.dart           ProviderScope, MaterialApp.router, Arabic default
  core/
    api/        Dio factory, ApiConfig, IdempotentAction, ETagStore, UUID v4, debug-only dev settings
    errors/     ApiProblem (RFC 7807 + stable codes), ApiFailure (sealed), mapApiError
    money/      Money, Bps — int piasters / basis points, no floating point
    l10n/       app_ar.arb (template), app_en.arb, generated/ (committed), locale provider
    router/     go_router configuration
    theme/      tokens, ThemeData, balance colours, text scale (FL1)
    widgets/    shared components + debug catalogue (FL1)
  features/     one folder per feature (FL2 onward); home/ holds the FL0 placeholder
packages/qesma_api/             GENERATED client (never edited)
tool/generate_api.*             regeneration script
test/                           unit, contract, guard and widget tests
```

## Rules enforced by tests (see `test/guards`)
No `double`/`num`/`/ 100`/`* 100`/`.round()` outside `core/money` (`double` allowed for pixel sizes in `core/theme` and `core/widgets`); no hard-coded UI strings; no prints; the fake token appears only in `dev_settings.dart`; the release manifest has no cleartext and no emulator host.

## Design system (FL1)
Tokens, theme and shared widgets are in `lib/core/theme` and `lib/core/widgets` (import `core/widgets/widgets.dart`). Light theme only. Source of values: `docs/design/DESIGN.md` prose and the English spec; ADR-006 addendum lists where they were corrected for contrast.

- **Component catalogue (debug builds only):** `flutter run --dart-define=INITIAL_ROUTE=/_catalog`. In Git Bash on Windows prefix the command with `MSYS_NO_PATHCONV=1` (otherwise `/_catalog` is rewritten into a Windows path); PowerShell needs nothing. It shows every component with switches for Arabic/RTL ↔ English/LTR and text scale 1.0x ↔ 2.0x. The route does not exist in release builds.
- **Adding a colour or size:** put it in `lib/core/theme/tokens.dart`, then add the text/background pair to `test/core/theme/contrast_test.dart`. Raw `Color(0x…)`, `Colors.*` and physical left/right layout fail the guard tests.
- **Strings:** only through `lib/core/l10n/app_ar.arb` (template) and `app_en.arb`; key names start with an area prefix (`common`, `field`, `balance`, `money`, `state`, `error`). Number placeholders are `String`. `flutter gen-l10n` regenerates `lib/core/l10n/generated` (committed).
- **Goldens:** `flutter test --update-goldens test/goldens` after an intentional visual change; review the PNG diffs in git. A 0.5% tolerance absorbs OS anti-aliasing differences.
- **Money in widgets:** `MoneyText` and `BalanceStatusChip` take `int` piasters; spoken text ("minus 80 pounds") comes from `moneySpoken`. Wrap other numbers and ids in `ltrIsolate()` when they sit inside Arabic sentences.

## Running on a phone with the local backend (USB)
```bash
adb devices                                  # the phone must say "device"
adb reverse tcp:18080 tcp:18080              # the phone's localhost now reaches your computer
flutter run --dart-define=API_BASE_URL=http://localhost:18080
```
`localhost` is allowed in debug builds only (`android/app/src/debug`). On Xiaomi/MIUI also enable "Install via USB" in Developer options. The emulator uses `10.0.2.2` instead of `adb reverse`.

## Sign-in and sessions (FL2)
- **Flow:** splash (restores the session with `GET /me`) → welcome → sign-in (Google) → app. The refresh token is the only thing stored (Keystore-backed `flutter_secure_storage`); the access token lives in memory. The refresh protocol and its failure policy are in the ADR-006 addendum and `lib/core/auth/session_manager.dart`.
- **Debug sign-in without Google:** debug builds show a "debug sign-in" link that sends the backend's `fake-auth` token. Run the backend with `local,fake-auth,seed`.
- **Tokens never in UI code:** only `lib/core/auth` and `lib/features/auth/application` may mention `accessToken`/`refreshToken`/`idToken` (guard test).

### Google Cloud setup — NOT VERIFIED (needs the owner's Google Cloud console)
Real Google sign-in cannot work until this is done; everything else is verified against the backend's `fake-auth` profile.
1. **OAuth consent screen:** configure it (external, testing mode is fine for development) and add your Google accounts as test users.
2. **Android OAuth client:** type "Android", package name `app.qesma.app`, and the **SHA-1 of the signing key**. Debug key: `keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\.android\debug.keystore -storepass android -keypass android` (PowerShell) and copy the SHA1 line. Add the release keystore's SHA-1 later.
3. **Web OAuth client:** type "Web application". Its **client id** is the `serverClientId`: it becomes the `aud` of the ID token.
4. **Tell both sides the same id:**
   - app: `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>.apps.googleusercontent.com`
   - backend: `GOOGLE_CLIENT_IDS=<web client id>.apps.googleusercontent.com` (comma-separated list; if it is missing every login is rejected with 401).
5. The phone needs Google Play services and a Google account. If the button shows "not configured" in a debug build, the define in step 4 is missing.

### Real-backend integration test
```bash
# backend: local,fake-auth profile running (see backend/README.md), then:
cd mobile
MSYS_NO_PATHCONV=1 flutter test test/integration --dart-define=API_BASE_URL=http://localhost:18080
```
Runs the real login, `GET /me`, refresh rotation, reuse detection and logout. Skipped when `API_BASE_URL` is not given. The backend allows 10 `/auth/**` requests per minute per IP: wait a minute between repeated runs.

### Open items from FL2
- Terms and Privacy links point to placeholder pages (`https://qesma.app/terms`, `/privacy`, see `LegalLinks`); real pages and a Play Store privacy policy are needed before release.
- The logo is a code-drawn placeholder (`BrandLogo`); the welcome hero photo from the mock-up is omitted (no licensed image).

## Groups and members (FL3)
- **Screens:** groups list (`/`, paged 20 at a time with infinite scroll and pull to refresh), create (`/groups/new`), group home shell (`/groups/:gid?tab=expenses|balances|members`), edit (`/groups/:gid/edit`). Expenses and Balances tabs are marked placeholders until FL4 and FL7. Members tab: add, rename, delete; the owner's own member ("you") can only be renamed.
- **Layers:** `features/groups/data` (repository: the only code that touches the generated API), `application` (Riverpod notifiers), `presentation`. A guard test enforces that widgets and notifiers never use the generated API.
- **No duplicate groups:** `POST /groups` has no idempotency key, so after an attempt whose outcome is unknown the app re-reads the list and looks for the group before it ever POSTs again (`create_group_controller.dart`).
- **Edits:** opening edit re-reads the group; `PATCH` sends `If-Match` from the ETag; on a conflict the dialog offers to load the latest version while the typed text stays.
- **Temporary:** the overflow menu on the groups list holds "sign out" until the profile screen (FL8).
- **Tests run on a fake server** (`test/support/fake_groups_server.dart`): paging, ETag/`If-Match`, 409s, duplicate names, a lost create response. The same flows also run against a real local backend (`test/integration/groups_flow_test.dart`).

## Expenses: list, details, history, delete (FL4)
- **Screens:** the Expenses tab of the group home (newest first, grouped by `expenseDate` with Today/Yesterday headers, 20 per page with infinite scroll and pull to refresh, date-range and member filters as removable chips), expense details (`/groups/:gid/expenses/:eid`: header, payers, items and charges for itemized bills, everyone's share), the history sheet, and delete with a confirmation. The add and edit buttons open the form (FL5; itemized bills are FL6). The Balances tab is still a placeholder until FL7.
- **Server numbers only:** nothing is recalculated. The one sum on screen is the payers' own list ("total paid"). A test feeds numbers that do not add up and checks they come out unchanged. Zero charges are not drawn (a service-only bill has no tax row); "your share" shows only when the server has a `shares[]` row for you.
- **Delete:** a soft delete (the button says "delete"; the confirmation does not promise a history the app cannot open afterwards). It sends `If-Match` from the details read; list items carry no ETag, so a delete is only possible from the details page. A 409 shows the conflict dialog and reloads; a 404 counts as already deleted, which also covers a lost reply to the first attempt.
- **Accessibility (FL4 review fixes):** rows, chips and tabs expose a tap action; spoken labels use amounts in words and real dates, with no bidi control characters; person and history rows are one stop each; pull to refresh is also a named screen-reader action; a failed next page shows a "try again" row (scrolling no longer retries by itself); Arabic counts use singular, dual, 3-10 and 11+ forms.
- **History:** `GET .../revisions`, shown newest first, read-only (version, kind of change, time, total, payers). It keeps working after a delete.
- **Date picker:** the Material date picker, in Arabic when the app is Arabic. The app's own dates are always Western digits; the picker's own labels follow the system.
- **Tests:** real backend responses are saved in `test/fixtures/expenses` (EQUAL, EXACT, the four itemized variants V5-V8, an edited expense, its history, a list page). `test/support/fake_expenses_server.dart` serves them with paging, filters, ETag, `If-Match` and a lost delete reply. `test/integration/expenses_flow_test.dart` runs the same flows against a real local backend; it creates its data through the generated client (the add form has its own live test).

## Add and edit expense (FL5)
- **Screens:** the form (`/groups/:gid/expenses/new`, `.../:eid/edit`): name, total, date, who paid, and the split tabs Everyone / Selected / Exact amounts; the paid-by sheet (one or several payers, with what is left to assign). The Restaurant-bill tab opens a clearly marked stub (`.../expenses/new/itemized`) until FL6; editing an itemized bill opens the same stub.
- **Server numbers only:** every per-member amount comes from `POST .../expenses/preview` (`ExpensePreviewController`: 300 ms debounce, the previous HTTP call is cancelled, a reply for older input is ignored, and the old numbers are dropped at once so a stale preview is never drawn as current). The Exact tab starts from the server's equal split; "split equally among the payers" copies the server's numbers. The only arithmetic is adding up what the user typed (the "left to assign" / "split total" lines).
- **One place builds the request:** `application/expense_command_builder.dart` (a guard test enforces it). Golden JSON files in `test/fixtures/expense_commands` pin the exact bodies: a create with everyone omits `participantMemberIds` (the server resolves it), an edit always sends the explicit list, Selected sends the chosen members, Exact sends the typed shares. The backend validates the title even for a preview, so a preview sent before the user typed a title carries the placeholder `x` (never saved, never shown).
- **Saving a new expense:** an `IdempotentAction` key is created on the first tap, reused for every retry while the body is unchanged (a lost reply ends as the stored expense, flagged `Idempotency-Replayed`, no duplicate), replaced as soon as the user edits, and forgotten after success or a definitive refusal. `VALIDATION_ERROR` carries no field name, so it shows as a form-level message.
- **Editing:** `PUT` with `If-Match` and the explicit participant list. A member who joined after the expense is shown unchecked, never added silently. On a 409 the dialog loads the latest version and keeps what the user typed; if the latest version is exactly what we tried to save (a lost PUT reply), the edit ends cleanly instead of in an error.
- **Leaving:** a form with typed changes asks before it is discarded.
- **Tests:** `test/support/fake_expenses_server.dart` now also answers preview, create (idempotency) and edit with the engine's rounding rules, so the app is tested against realistic server numbers (the app itself never calculates them). `test/integration/expense_form_flow_test.dart` sends the form's requests to a real local backend.
