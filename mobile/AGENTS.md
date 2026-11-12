# mobile/AGENTS.md — Flutter app (extends the root AGENTS.md)

Status: FL11 done (invite sheet for Owner/Admin, join screen with claim-or-new, code entry, App Link /join/<code>, pending invite kept across sign-in, scope guard has `invites` enabled). FL10 done (Phase 2 foundation: client regenerated for B10/B11, roles and `Permissions` hide group-level controls, a 403 re-reads the group, refetch on app resume, members tab pull-to-refresh, scope guard now per-feature with `enabledFeatures`; no Phase 2 screen yet). Dark theme (follow phone, Appearance setting) and accessibility audit done after FL8 (see docs/design/accessibility-audit-fl8.md). FL8 done (Account tab: profile hub, edit name, account settings, persisted language switch, version, global offline banner and shared error states; bottom bar Groups + Account). FL7 done before it (balances tab: suggested transfers, per-member nets, record payment, settlement history with delete). FL6 done before it (restaurant bill editor: items, assignees, service and tax, adjustment, live breakdown). FL5 done before it (add/edit expense: equal, selected, exact; paid-by editor; live server preview; idempotent save). FL4 done before it (expenses tab with filters, expense details with history and delete). FL3 done before it (groups list, create, edit, delete, group home shell, members tab). FL2 done before it (splash, welcome, Google sign-in, secure token storage, refresh rotation, session expiry; see README). FL1 done before it (design system: tokens, bundled font, shared widgets in `lib/core/widgets`, debug catalogue). FL0 done before it (bootstrap, generated client in `packages/qesma_api`, core helpers). Stack decisions: `../docs/adr/ADR-006-mobile-stack.md`. Run commands and layout: `README.md`. Never edit `packages/qesma_api`; regenerate with `tool/generate_api.sh`.

## Planned conventions (spec section 5.2)
- Flutter + Dart, Android first. State: Riverpod. Navigation: go_router. HTTP: dio with a client GENERATED from `docs/openapi.json` (never hand-write API models).
- Feature-first folders: `lib/features/{auth,groups,members,expenses,balances,settlements}`, `lib/core/`.
- Localization with ARB files (ar primary, en secondary); full RTL; Western digits (0–9) for amounts.
- Do NOT re-implement split/balance logic in Dart in Phase 1: call the backend `preview` and `balances` endpoints. (A Dart engine arrives in Phase 4, validated against `../fixtures`.)
- Design tokens: `../docs/design/DESIGN.md`. Screen images: `../docs/design/screens/` named by screen ID (e.g. `P7-04-itemized-service-and-tax.png`); open the exact file before implementing a screen.
- Online-only in Phase 1 (clear error + retry when offline).

## Skill Routing (Mobile App)
Follow root `AGENTS.md` (max 2–4 skills per task):
- **Allowed Mobile Skills:** `ui-ux-pro-max`, `design-system`, `design-handoff`, `design-critique`, `accessibility-review`, `ux-copy`.
- **API & Client Integration:** Use `api-doc-generator` / `api-docs-check` only when validating the generated client against `docs/openapi.json`.
- **STRICTLY FORBIDDEN:** Backend DB/Flyway migrations (`migration-safety`, `data-modeling-discipline`, `query-discipline`), Spring Boot server skills, and reimplementing split calculation arithmetic in Dart for Phase 1.
