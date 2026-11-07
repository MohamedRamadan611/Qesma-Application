---
description: "FLR — Flutter milestone review (run after every FL prompt, in a NEW session)"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md` and the diff of the last mobile milestone ($ARGUMENTS: e.g. `git diff main...HEAD -- mobile` or a commit range). Review as a strict senior reviewer WITHOUT changing code. Open the screen images the milestone implements and compare. Cite file:line and the SCREEN_MAP/spec rule for each finding:
1. **Scope:** any Phase 2 / unsupported element built or faked (SCREEN_MAP section 3 "Omit" column); anything built that the backend does not support; disabled "coming soon" UI.
2. **Money:** any `double`/`num`/division/multiplication/rounding on amounts or percentages outside `core/money`; any split, balance, service or tax calculation in Dart; "half"/percent shortcuts; amounts that do not come from preview/balances; Western digits and `ج.م` formatting.
3. **API usage:** hand-written models, edited generated code, stale `openapi.sha256`, wrong status/headers; `Idempotency-Key` lifecycle (one per action, reused only for the same body); `If-Match` on every edit/delete; explicit participant list on edit; paging and filters.
4. **Auth and security:** refresh is single-flight, the new refresh token is persisted before retries, an old one is never sent twice; tokens only in secure storage; nothing sensitive in logs, errors, crash output or the widget tree; dev-only code cannot ship in release.
5. **Error handling:** every error code of SCREEN_MAP section 7 mapped, no swallowed exceptions, no raw server text shown to users, offline and retry states.
6. **UX fidelity and accessibility:** RTL correctness, deviations from the design image, 200% text scale, semantics labels, contrast, tap targets, colour not the only signal, Arabic copy quality.
7. **State and performance:** rebuild storms, lists virtualised, stale previews shown as current, cancelled requests, memory leaks (controllers, streams).
8. **Tests:** tests that fake the thing they claim to test, missing cases (concurrency, lost response, conflict, offline), goldens that assert nothing, flaky timing.
9. **Dependencies and hygiene:** new packages without the ADR, TODOs, lint suppressions, files outside the milestone.
Output: a severity-ranked table (blocker/major/minor/nit), what is good, and a recommended fix order. Do not edit files.
