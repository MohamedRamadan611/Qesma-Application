# mobile/AGENTS.md — Flutter app (extends the root AGENTS.md)

Status: FL5 done (add/edit expense: equal, selected, exact; paid-by editor; live server preview; idempotent save; the restaurant bill is a stub until FL6). FL4 done before it (expenses tab with filters, expense details with history and delete). FL3 done before it (groups list, create, edit, delete, group home shell, members tab). FL2 done before it (splash, welcome, Google sign-in, secure token storage, refresh rotation, session expiry; see README). FL1 done before it (design system: tokens, bundled font, shared widgets in `lib/core/widgets`, debug catalogue). FL0 done before it (bootstrap, generated client in `packages/qesma_api`, core helpers). Stack decisions: `../docs/adr/ADR-006-mobile-stack.md`. Run commands and layout: `README.md`. Never edit `packages/qesma_api`; regenerate with `tool/generate_api.sh`.

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
