# Phase 2 (Collaboration) — prompt index

Everything Phase 2 is specified in `docs/PHASE2_SPEC.md`; the prompts are slash commands in `.claude/commands/`. Same discipline as Phase 1: **one prompt per fresh session**, Step 0 plan first and wait for approval, tests first for anything touching money, Stop protocol at the end, commit after each prompt, then run the review (`/r-review` for backend, `/flr-review` for Flutter) and the independent check (`/v-verify`, `/flv-verify`) in **new** sessions.

## Before the first prompt
1. Phase 1 gate is passed (PROJECT_PHASES: Gate 1 -> 2) and `./mvnw clean verify` is green on `main`; the Phase 1 uncommitted FL9 work is committed.
2. Read `docs/PHASE2_SPEC.md` once and answer or accept the **(decide)** defaults (each Step 0 will ask again for its own decisions).
3. Decision Log numbers continue from A65, ADRs from ADR-009. ADR-010 (FCM) only if you build B18.

## Run order

| Order | Command | What | Needs | Optional |
|---|---|---|---|---|
| 1 | `/b10-roles-authz` | roles, member status, central permission matrix | Phase 1 | |
| 2 | `/fl10-phase2-foundation` | client regen, role-aware UI, refresh strategy, scope guard + SCREEN_MAP | B10 | |
| 3 | `/b11-invites-join` | invites, join, approval | B10 | |
| 4 | `/fl11-invite-join` | invite sheet, join screen, deep link | B11, FL10 | |
| 5 | `/b12-member-lifecycle` | leave, roles, ownership transfer, LEFT | B11 | |
| 6 | `/fl12-members-v2` | members tab v2, requests inbox, leave, transfer | B12, FL11 | |
| 7 | `/b13-settlement-v2` | two-sided settlement, balance rule | B12 | |
| 8 | `/b14-payment-handles` | InstaPay / wallet handles | B13 | |
| 9 | `/fl13-settlement-v2` | transfer card, receiver view, chips, disputed detail | B13, B14, FL12 | |
| 10 | `/b15-activity-notifications` | events, activity feed, notification center | B14 | |
| 11 | `/b16-prefs-remind` | prefs, mute, Remind | B15 | |
| 12 | `/fl14-handles-remind` | profile handles, Remind button | B14, B16, FL13 | |
| 13 | `/fl15-notifications-activity` | center, activity, settings | B15, B16, FL14 | |
| 14 | `/b17-conflict-account-deletion` | conflict body, `DELETE /me` | B16 | |
| 15 | `/fl16-conflict-account-deletion` | conflict screen, delete account | B17, FL15 | |
| 16 | `/b18-push-fcm` | device tokens, FCM (needs ADR-010 + Firebase) | B17 | yes |
| 17 | `/fl17-push` | push in the app | B18, FL16 | yes |
| 18 | `/b19-phase2-hardening` | full matrix, OpenAPI, two-user smoke, acceptance | B10-B17 | |
| 19 | `/fl18-phase2-integration` | two-account scenarios, a11y, perf, release | B19, FL10-FL16 | |

Rules that make the interleaving safe: a Flutter prompt starts only after the backend prompt it lists is merged **and** the Dart client was regenerated (`docs/mobile-client.md`); B13 and B14 may swap places, B15 and B16 too; do not start B18/FL17 without the owner's Firebase project and approved ADR-010. B17 Part A and Part B are independent (two commits). The extras (ownership transfer/leave in B12/FL12, conflict screen and account deletion in B17/FL16) are real Phase 2 items (roadmap 2.4, 2.9, 2.10) even though Stitch has no screens for them.

## Coverage (nothing unowned)

| Roadmap item | Backend | Flutter | Design screen |
|---|---|---|---|
| 2.1 Invitations | B11 | FL11 | P12-01, P12-02 |
| 2.2 Link member to account | B11 | FL11, FL12 | P12-02, P12-03 |
| 2.3 Roles/permissions | B10 | FL10, FL12 | P12-03 |
| 2.4 Member lifecycle | B12 | FL12 | P12-03 (options), none for leave/transfer |
| 2.5 Settlement v2 | B13 | FL13 | P13-01, P13-02, P13-03 (x2) |
| 2.6 Payment handles | B14 | FL13, FL14 | P13-01, P13-05 |
| 2.7 Notifications, Remind, prefs | B15, B16 (push B18) | FL14, FL15 (push FL17) | P13-04, P14-03, none for the center list |
| 2.8 Activity feed | B15 | FL15 | P14-02 |
| 2.9 Conflict UX | B17 | FL16 | none |
| 2.10 Account deletion (email/password already done in Phase 1, A59) | B17 | FL16 | none |
| 2.13 Acceptance | B19 | FL18 | - |

## Known design/spec gaps (each prompt lists its own)
- P13-03 shows an attached transfer screenshot and a transaction number: no backend field, **omitted**.
- P12-02 shows per-member balances to a non-member: **omitted** (privacy); names only.
- The invite code in the design (`DHB-4821`) is too guessable: the backend uses a longer code (B11 decides the format).
- No screenshot for: notification center list, member options sheet, leave/transfer ownership, conflict screen, delete account.
- Two files share the `P13-03` number (status chips, disputed detail): open by content.

## Verification cadence per prompt
Backend: `./mvnw clean verify` -> `/r-review bNN` (fresh session) -> `/v-verify` for gate prompts (B13, B17, B19). Flutter: `flutter analyze` + `flutter test` -> `/flr-review flNN` -> `/flv-verify` for FL13, FL16, FL18. Record gates in `docs/gates/`.
