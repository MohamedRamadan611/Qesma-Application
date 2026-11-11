---
description: "FL12 — Members tab v2: connected/name-only badges, role chips, options sheet, join requests, leave, transfer ownership"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md` (Phase 2 table), docs/PHASE2_SPEC.md sections 2, 4 (join requests, unlink), 5, 10, docs/design/STITCH_PROMPTS.md Prompt 11 part 3, and open `P12-03-Member-Tab-Update.png` plus the Phase 1 members tab (FL3 code in `mobile/lib/features/groups`). Prerequisite: FL11 and B12 merged. Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): the design; mapping to `MemberDto` (`role`, `status`, `hasAccount`, `isYou`); **the options-sheet action matrix** (rows = viewer role Owner/Admin/Member and target Owner/Admin/Member/ghost/LEFT/self; columns = rename, delete (existing Phase 1 rules), promote to admin, demote, unlink account, mark as left / reactivate, transfer ownership; every cell show/hide, driven by `Permissions`); the destructive-action confirmations (copy via ux-copy: unlink explains that the history stays, leave explains that the balance stays and a new invite is needed to return, transfer ownership explains the old owner becomes admin); behaviour for `OWNER_MUST_TRANSFER` (route the owner to the transfer flow), `MEMBER_INACTIVE`, `FORBIDDEN`; the join-requests inbox placement (a banner/section at the top of the members tab visible to Admin/Owner with a count); missing designs list (options sheet, transfer ownership picker, leave confirm, join request card).

Implement:
1. Members tab list: badge "متصل بحساب" vs "اسم فقط" (from `hasAccount`, text + icon, never colour alone), role chips "مالك" / "أدمن" (members have none), LEFT members greyed with a "غادر" chip and kept in the list, the "(you)" badge from `isYou`.
2. Member options sheet per the matrix: ترقية لأدمن / إلغاء الأدمن, فصل الحساب, عضو غادر / إعادة التفعيل, plus the Phase 1 rename and delete.
3. Join requests inbox (Admin/Owner): list of pending requests (requester display name from the DTO, claim target or new name, time), approve/reject, empty state, `MEMBER_ALREADY_CLAIMED` handling on approve.
4. **Leave group** (members/profile entry for non-owners) with confirm, then back to the list; **Transfer ownership** (Owner only): pick an ACTIVE linked member, confirm, role chips update after refetch.
5. Refetch strategy: after every mutation refetch members, group and balances; LEFT members still appear in balances (server data), do not hide or recompute.
6. ARB strings; extend the scope-guard allow-list only for the words this prompt introduces.

Tests: widget tests for the action matrix (parametrised over the whole table, ar/en, 2.0 text scale); badges and chips semantics (text present with colour); approve/reject flows; leave and transfer flows incl. the owner-must-transfer redirect; error codes -> UX; refetch after mutations; golden for the members tab with mixed roles/statuses; guard: no client-side balance arithmetic.
Constraints: SCREEN_MAP rules; roles are never decided on the client (hide/disable only, handle 403); no account ids shown. Done when analyze and tests pass. Then Stop protocol; do NOT start FL13.
