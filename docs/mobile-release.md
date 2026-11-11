# Mobile release guide (Android)

Status: FL9. Everything here is what the owner needs to take the app from "works on my phone" to "installed by testers".
What is **not done yet** is listed first, because it blocks a public release.

## Open items that block a PUBLIC release
| # | Item | Why it blocks | Who |
|---|---|---|---|
| 1 | **Account deletion** (in the app and a web page). The backend has no delete-account endpoint. | Google Play requires an in-app deletion path and a public deletion URL for apps with accounts. | Backend session (new endpoint + ADR, owner decision on what happens to ledger rows: they are never hard-deleted, so the account would be anonymised), then a mobile row |
| 2 | **Privacy policy and Terms URLs.** The in-app links are placeholders (`LegalLinks`). | Play requires a privacy-policy URL; the sign-in screen links to it. | Owner (hosted pages), then set the URLs |
| 3 | **Password recovery.** Username accounts have no email, so a forgotten password cannot be reset (ADR-008). | A locked-out user must create a new account and loses their groups. | Owner decision: optional email + a mail provider (own ADR) before public release |
| 4 | **Real Google Cloud OAuth setup** (below). Google sign-in has never run against real Google. | Sign-in with Google fails until the clients exist. | Owner |
| 5 | **Production backend URL (https).** Release builds refuse a non-https `API_BASE_URL`. | No server to point at yet. | Owner (VPS per `docs/gates/gate-b8.md`) |

Internal testing (a few invited testers) does **not** need items 1-3, but needs 4 and 5 for Google sign-in; username sign-in needs only 5.

## 1. Signing
- The release build is signed from `mobile/android/key.properties` (git-ignored) or, for CI, from the environment variables
  `QESMA_KEYSTORE_FILE`, `QESMA_KEYSTORE_PASSWORD`, `QESMA_KEY_ALIAS`, `QESMA_KEY_PASSWORD`. See `mobile/android/app/build.gradle.kts`.
- An upload key was generated on the owner's machine at `D:\Qesma\keys\qesma-upload.jks` (alias `qesma-upload`, RSA 2048, valid to 2054).
  **Back this file and its password up somewhere safe (not in git).** If the upload key is lost, Play can reset it, but only after a support request.
- Use Play App Signing (recommended): Google keeps the app-signing key; this upload key only proves uploads come from you. Both the upload key's
  SHA-1 and Play's app-signing SHA-1 must be registered as Android OAuth clients (section 2).
- Without `key.properties` the release build falls back to the **debug** key so `flutter run --release` works; `tool/check_release_artifact.sh`
  rejects such an artifact. Never upload one.
- Print the SHA-1 again any time: `keytool -list -v -keystore D:\Qesma\keys\qesma-upload.jks -alias qesma-upload`.

## 2. Google Cloud OAuth (sign in with Google)
1. Google Cloud Console → create/select a project → **OAuth consent screen** (External, app name "Qesma", support email, test users while in Testing).
2. **Credentials → Create OAuth client ID → Web application.** Copy its client id: this is the **server client id**.
   - App build: `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>`
   - Backend: environment variable `GOOGLE_CLIENT_IDS=<same web client id>` (a mismatch makes every login return 401).
3. **Create OAuth client ID → Android**, package name `app.qesma.app`, SHA-1 of the signing key. Create one for each key that signs installs:
   the **upload key** (sideloaded/test APKs), the **debug key** (development), and **Play app signing** (from Play Console → Setup → App signing) once the app is on Play.
   (Android clients have no secret and are not passed to the app: Google matches package + SHA-1.)
4. Publishing status Testing allows only listed test users; move to Production when the privacy policy URL exists.

## 3. Build commands
Run from `mobile/`. `API_BASE_URL` must be https in release (`ApiConfig` throws otherwise).
```
flutter build apk --release       --dart-define=API_BASE_URL=https://<api host> --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id> --dart-define=APP_VERSION=<x.y.z+n>
flutter build appbundle --release --dart-define=API_BASE_URL=https://<api host> --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id> --dart-define=APP_VERSION=<x.y.z+n>
bash tool/check_release_artifact.sh build/app/outputs/flutter-apk/app-release.apk
```
- `applicationId` = `app.qesma.app`. The version comes from `pubspec.yaml` (`version: 0.1.0+1`); bump it for every upload (the `+n` build number must increase).
  The first real release number is the owner's call.
- The release APK/AAB contain only `INTERNET`; cleartext and the emulator host exist in the debug manifest only; the dev sign-in and
  component catalogue are behind `kDebugMode` and are checked for absence by `tool/check_release_artifact.sh` (and `test/guards/source_guards_test.dart` for the sources).

## 4. R8 check
R8 (code + resource shrinking) is on for release. The generated API client is Dart (compiled by Flutter, invisible to R8); R8 only shrinks the Java
side (Flutter embedding, `flutter_secure_storage`, `google_sign_in`, `url_launcher`). Rules are in `mobile/android/app/proguard-rules.pro`.
After any plugin upgrade: build release, install it on a phone, and run **sign in, create a group, add an expense, sign out** (a stripped class shows up
as a crash on sign-in or on reading secure storage). This run needs an https backend or a local https proxy, so it is on the device checklist
(`docs/gates/mobile-device-checklist.md`).

## 5. Internal testing track (Play Console)
1. Create the app (name Qesma, default language Arabic, free). 2. Setup → App signing: opt in to Play App Signing. 3. Testing → Internal testing →
   create a release → upload the `.aab` → add testers (email list). 4. Complete **Data safety** (account info: username/name/email optional; app activity:
   expenses; no data sold; encrypted in transit; deletion request path = open item 1) and **content rating**. 5. Register the Play app-signing SHA-1 in
   Google Cloud (section 2, step 3). 6. Testers install through the opt-in link.

## 6. What the app collects (for the privacy policy and Data safety form)
Display name; username or Google account id and email; group, member and expense data the user enters; a hashed password (BCrypt) for username
accounts; IP address in server logs/rate limiter. No analytics or crash SDKs, no advertising id, no location, no contacts, no files. Tokens live in
Android secure storage. The app never holds or moves money.
