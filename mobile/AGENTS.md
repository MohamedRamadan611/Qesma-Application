# mobile/AGENTS.md — Flutter app (extends the root AGENTS.md)

Status: placeholder. Mobile work starts after the backend API contract (`docs/openapi.json`) exists.

## Planned conventions (spec section 5.2)
- Flutter + Dart, Android first. State: Riverpod. Navigation: go_router. HTTP: dio with a client GENERATED from `docs/openapi.json` (never hand-write API models).
- Feature-first folders: `lib/features/{auth,groups,members,expenses,balances,settlements}`, `lib/core/`.
- Localization with ARB files (ar primary, en secondary); full RTL; Western digits (0–9) for amounts.
- Do NOT re-implement split/balance logic in Dart in Phase 1: call the backend `preview` and `balances` endpoints. (A Dart engine arrives in Phase 4, validated against `../fixtures`.)
- Design tokens: `../docs/design/DESIGN.md`. Screen images: `../docs/design/screens/` named by screen ID (e.g. `P7-04-itemized-service-and-tax.png`); open the exact file before implementing a screen.
- Online-only in Phase 1 (clear error + retry when offline).
