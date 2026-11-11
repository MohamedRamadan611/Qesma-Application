# Mobile device checklist (human run)

Run on a real phone with a **release** build (`docs/mobile-release.md`, section 3) against an https backend, or a debug build against the local
backend for the rows marked (debug OK). Everything is **NOT VERIFIED** until someone ticks it with a date and a note. FL9 could not run these.

Backend for a local run: `docker compose up -d db`, then `java -jar backend/target/qesma-backend-0.0.1-SNAPSHOT.jar --server.port=18080
--spring.profiles.active=local,fake-auth,seed,dev-mail` and `adb reverse tcp:18080 tcp:18080` (JDK 21).

| # | Check | Expected | Status |
|---|---|---|---|
| 1 | Install the release APK/AAB build from the internal track on a clean phone | installs, opens to the welcome screen, no crash | NOT VERIFIED |
| 2 | **Sign in with a real Google account** | lands on the groups list; relaunching keeps the session; the profile hub shows the account email | NOT VERIFIED (needs Google Cloud setup, release guide section 2) |
| 3 | Register with a username, sign out, sign in again, change password, sign in with the new one | each step succeeds; old password refused with the generic message (debug OK) | NOT VERIFIED on device (automated against the real backend: `test/integration/password_auth_flow_test.dart`) |
| 4 | **Acceptance criterion 3** (spec section 10): create a group, add 5 members (you are member #1), add an equal expense, a multi-payer expense and an itemized restaurant bill with service and tax; check the numbers against a calculator | per-person shares equal the backend preview; totals add up to the bill to the piaster | NOT VERIFIED |
| 5 | Balances: record a payment for a suggested transfer; balances and transfer list update; delete the payment | net values return to the earlier state | NOT VERIFIED |
| 6 | **Poor connection:** start saving an expense, switch airplane mode on/off during the save, retry | exactly one expense exists afterwards (idempotent retry); an offline banner shows while offline | NOT VERIFIED (idempotent replay is proven by tests: `idempotent_action_test.dart`, `balances_flow_test.dart`; the radio toggle is not) |
| 7 | **Backend killed mid-request**, then restarted | the app shows the offline/error state, never a blank screen; "Try again" works after the restart | NOT VERIFIED |
| 8 | **Token expiry:** leave the app 20 minutes, then open a group | the access token refreshes silently; no sign-in screen | NOT VERIFIED |
| 9 | **Three real receipts** from the last outings entered as itemized bills | the app total equals the printed total; shares are fair; note anything confusing | NOT VERIFIED |
| 10 | **TalkBack** (Arabic and English): sign in, open a group, add an expense, view balances, record a payment | every control is announced with a name and role; amounts read as "x pounds y piasters"; focus order follows the screen; errors are announced | NOT VERIFIED |
| 11 | **Font size and display size at maximum** (Settings → Display) | no clipped text or overlapping controls on any screen | NOT VERIFIED on device (automated at 2.0x: `test/a11y/guidelines_test.dart`) |
| 12 | **Dark mode**: switch the phone theme and the in-app Appearance row (System/Light/Dark) | every screen readable; the choice persists after relaunch | NOT VERIFIED beyond the screens seen in FL9 (goldens exist) |
| 13 | **Arabic ↔ English** from the profile hub | all text, layout direction and number formatting switch; the choice persists | NOT VERIFIED on device |
| 14 | **Release build against the production URL** (R8 check, release guide section 4): sign in, create group, add expense, sign out | no crash from stripped classes | NOT VERIFIED |
| 15 | **Dogfood outing:** use the app for a real trip or outing with friends | note every wrong number or confusing screen; none are acceptable | NOT VERIFIED |

Record results in `docs/gates/gate-fl9.md` (date, build number, phone model, what failed).
