# Flutter prompt set (Phase 1)

How to use: one prompt per fresh Claude Code session, in order, exactly like the backend `b*` prompts: plan first (wait for approval), implement, run the checks, follow the Stop protocol, then review (`flr-review`) and verify (`flv-verify`) in NEW sessions. Shared context for every prompt: `.claude/mobile/SCREEN_MAP.md` (scope, naming warning, API and error maps).

| Order | Command | Delivers | Screens (files in `docs/design/screens/`) |
|:--|:--|:--|:--|
| 0 | `b9-owner-member-contract` (backend) | owner is member #1 (`isYou`), `yourNetMinor`, truthful OpenAPI statuses | - |
| 1 | `fl0-bootstrap` | project, ADR-006, generated client, money/error/idempotency core | - |
| 2 | `fl1-design-system` | theme, shared widgets, Arabic copy, accessibility | P3-01, P9-01, P9-02, P4, P11-01..03 (as references) |
| 3 | `fl2-auth-session` | splash, welcome, Google sign-in, refresh rotation, session expiry | P1-01..03, P11-04 |
| 4 | `fl3-groups-members` | groups list/create/edit/delete, group shell, members | P2-01..03, P3-01, P4 |
| 5 | `fl4-expenses-read` | expenses tab, filters, expense details, history, delete | P3-01, P7-01 (details) |
| 6 | `fl5-expense-entry` | add/edit expense, paid-by, live preview, idempotent save | P5-01, P6-01 |
| 7 | `fl6-itemized-editor` | restaurant bill editor with service/tax | P8-01 (editor) |
| 8 | `fl7-balances-settlements` | balances, transfers, record payment, history | P9-01, P9-02 |
| 9 | `fl8-profile-states` | profile, language, sign out, offline/error states | P10-01..03, P11-01..05 |
| 10 | `fl9-integration-release` | real-backend integration tests, a11y/perf, release build, device checklist | - |
| any | `flr-review`, `flv-verify` | review and independent verification of one milestone | - |

Backend close-out that should happen in parallel (not blocking the prompts above except B9 before FL3): `x-smoke` (create `scripts/smoke.sh`), commit and tag the backend gates, first CI run, staging deploy, decide A11 (V4 transfer order), the three real receipts (see `docs/gates/gate-b8.md` section 6).

Scope decisions behind the set: Phase 1 only (invites, roles, notifications, activity, payment handles, transfer confirmation/disputes, photos, categories, exports, account deletion are not built; the backend has no support); the owner is a member so the app can show "you"; every number comes from the backend (preview, balances); the API client is generated, never hand-written.
