---
description: "FL10 — Phase 2 foundation: regenerated client, role-aware UI, multi-device refresh, scope guard and SCREEN_MAP update"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md` (sections 1, 3 Phase 2 table, 7), docs/PHASE2_SPEC.md sections 1, 2, 10, docs/mobile-client.md, `mobile/test/guards/scope_guard_test.dart`, docs/gates/gate-fl9.md. Prerequisite: B10 merged (B11-B17 are not needed yet). Skills (max 4): think-before-coding, design-system, accessibility-review, ux-copy.

Why this exists: Phase 1 forbids every Phase 2 word, icon and route (`scope_guard_test.dart`), the generated client predates roles, and nothing handles "another person changed the data". Do the shared groundwork once so FL11-FL16 only add screens.

Step 0 (plan, wait for approval): the client design; the new generated-client diff (regenerate per `docs/mobile-client.md` after B10; list renamed/removed operations); how `yourRole` / `MemberDto.role/status/hasAccount` flow into state (Riverpod providers); the `Permissions` helper API (pure functions of role and, for expenses, `isMine`); the **refresh strategy** for acceptance 2.13 #1 (pull-to-refresh on every list, refetch on app resume and on returning to a screen after a mutation, no polling timers, no sockets; list which providers invalidate on resume and how it avoids request storms); the `403 FORBIDDEN` UX (role changed under the user: short message, refetch group and role); the 404-after-leave/removal UX (group no longer available, return to the list); the scope-guard plan (below).

Implement:
1. Regenerate the Dart client; fix compile fallout only (no feature work); contract test (`openapi_contract_test.dart`) updated.
2. `Permissions` helper + tests (every row of the PHASE2_SPEC matrix). **It only hides or disables UI**; the server is the authority and every call still handles 403/404.
3. App-resume and pull-to-refresh plumbing as designed; `FORBIDDEN` mapping in the error layer (FL0 error mapper) with ARB strings (ar primary, en).
4. **Update `scope_guard_test.dart`**: move the Phase 2 words (`invite`, `invitation`, `notification(s)`, `dispute`, `remind`, `reminder`, `instapay`, `wallet`, `delete account`, ...) from forbidden to an explicit per-feature allow-list that is **enabled prompt by prompt** (a map feature -> words -> the route/ARB keys allowed), keep the permanently forbidden words (guest, receipt/scan, export, contacts, premium, ads, coming soon, cover photo, pay now, ...) and the arithmetic guard. The guard must still fail if a Phase 2 element appears before its prompt.
5. Rewrite SCREEN_MAP section 3 row `P12-*, P13-*, P14-*` into the Phase 2 table from the plan of this prompt (screen file -> prompt FL11-FL16 -> endpoints -> build / omit), including: omit the **payment-proof screenshot and transaction number** (P13-03), **per-member balances on the join screen** (P12-02), avatar photos; list **missing designs** (notification center list has no screenshot, member options sheet details, conflict screen, delete-account flow, leave-group, transfer-ownership) and the new error codes -> UX rows (section 7: `FORBIDDEN`, `INVITE_EXPIRED`, `INVITE_REVOKED`, `ALREADY_MEMBER`, `MEMBER_ALREADY_CLAIMED`, `MEMBER_INACTIVE`, `OWNER_MUST_TRANSFER`, `INVALID_STATE_TRANSITION`, `REMIND_RATE_LIMITED`).

Tests: permission matrix; role provider updates after refetch; resume refetch happens once per resume (fake clock/lifecycle); `FORBIDDEN` mapping; guard test passes with Phase 2 off and fails when a Phase 2 word is injected in a test ARB fixture; existing widget/golden tests still green.
Constraints: SCREEN_MAP rules (no money arithmetic, API client generated only); no Phase 2 screen is built here. Done when analyze and tests pass. Then Stop protocol; do NOT start FL11.
