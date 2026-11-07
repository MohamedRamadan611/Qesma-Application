---
description: "FL3 — Groups list/create/edit/delete, group home shell, members tab"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md` (sections 3, 5, 7 are essential), docs/PROJECT_SPEC.md sections 3.1, 7.10, 8.2 (groups, members) and Decision Log A22-A24, A53+ (B9 decisions), and open the screens `P2-01-Group-List.png`, `P2-02-Create-Group.png`, `P2-03-Edit-Group.png`, `P2-03-Validate-Group.png`, `P3-01-Group-Home & Expenses-Tab.png`, `P4-Add-Member.png`. Prerequisite: FL2 merged and B9 merged (`MemberDto.isYou`, `GroupDto.yourMemberId`, `yourNetMinor`). Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): the six-step client design; the list of every element in these screens that you will NOT build (SCREEN_MAP section 3, "Omit" column) confirmed against the images; the list of states with no design (empty list, loading skeleton, delete-group confirm/blocked, members tab, member options, rename, delete-member confirm/blocked) and how you derive them from DESIGN.md; how pagination works (`page`/`size` 20, infinite scroll, pull to refresh); how the `ETag` of `GET /groups/{gid}` feeds `If-Match` on `PATCH`; how you avoid duplicate groups (no idempotency key on group create, A24).

Implement:
1. **Groups list** (P2-01): cards with name, type chip, last activity date, total spent, member count and, when `yourNetMinor` is not null, the "you are owed / you owe / settled" chip (sign + colour + word). The header summary shows a net total only when every listed group has the same currency (sum of `yourNetMinor`, computed by integer addition of values the server sent: allowed), otherwise it is omitted. Empty state and skeleton. FAB "new group".
2. **Create group** (P2-02): name (max 60), type chips (TRIP, HOUSING, OUTING, OTHER), currency displayed as fixed EGP; on submit disable the button; if the response is lost, re-read the list before offering a retry so no duplicate is created.
3. **Edit group** (P2-03, P2-03-Validate-Group): name and type via `PATCH` with `If-Match`; `VERSION_CONFLICT` dialog; created date; delete group with confirm and the `GROUP_NOT_EMPTY` blocked dialog.
4. **Group home shell** (P3-01): header (name, type, member count, total spent from `GroupDto`), three tabs in the design's RTL order (Expenses, Balances, Members); the Expenses and Balances tab bodies are placeholders owned by FL4/FL7 (route stubs, clearly marked).
5. **Members tab**: list with initials avatars, "(you)" badge from `isYou`, member options sheet (rename, delete), **add member sheet** (P4: name max 40, `DUPLICATE_MEMBER_NAME` inline error with the suggestion copy, no colour picker), rename, delete with confirm and the `MEMBER_HAS_TRANSACTIONS` blocked dialog (and the owner-member rule decided in B9).
6. State: Riverpod notifiers per feature, immutable models taken from the generated client (no hand-written DTOs), repository layer that is the only code touching the generated API.

Tests: repository and notifier tests with a fake adapter (paging, create, duplicate error, 409 on group edit, blocked deletes); widget tests for list/empty/error/skeleton, the sheets and dialogs in ar (RTL) and en; golden for the group card; a test that no omitted element exists (search the widget tree and ARB for the omitted strings); guard tests from FL0 green.
Constraints: SCREEN_MAP rules; no money arithmetic beyond summing server-provided `yourNetMinor`; no invitations, roles, photos or contact access. Done when analyze and tests pass. Then Stop protocol; do NOT start FL4 here.
