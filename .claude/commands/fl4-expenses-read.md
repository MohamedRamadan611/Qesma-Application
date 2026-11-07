---
description: "FL4 — Expenses tab (list, filters) and expense details with history and delete"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/PROJECT_SPEC.md sections 7.9, 8.2 (expenses), 8.4 and Decision Log A26-A41, and open the screens `P3-01-Group-Home & Expenses-Tab.png` (list) and `P7-01-Itemized restaurant.png` (**this file is the expense DETAILS page**, see SCREEN_MAP section 2). Prerequisite: FL3 merged. Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): the client design; the mapping from `ExpenseView` fields to every visible element of both screens (a table: element -> field -> how derived), flagging each element with no data behind it (location text, payment method per payer, category/item icons, promo tip): these are omitted; how you group by `expenseDate` headers client-side; how "your share" is read (`shares[]` entry whose `memberId` equals `GroupDto.yourMemberId`, shown only when present); which wording replaces "delete permanently" (it is a soft delete with history: say "delete"); how the delete uses `If-Match` and handles 409/404.

Implement:
1. **Expenses tab**: list newest first with infinite scroll (`size` 20), pull to refresh, skeleton, empty state, FAB "add expense" (opens FL5's route, stub until then). Item: title, total, split-type chip (EQUAL "بالتساوي", EXACT "مبالغ محددة", ITEMIZED "فاتورة مفصلة"), payer text from `payers` joined with member names, participant count from `shares`, "your share". **Filters**: date range (`fromDate`/`toDate`, validation `from <= to`) and member (`memberId`: payer or participant), shown as removable chips, resetting the page.
2. **Expense details** (P7-01 file): header (title, date, total, split-type badge, "edited (version N)" when `version > 1`), payers block (amounts; the "matches total" line is a statement the server guarantees, show only the sum), items with assignee names (ITEMIZED), charges block (`charges.subtotalMinor`, service `bps` and amount, tax `bps`/base/amount, adjustment: all server numbers), per-person breakdown from `shares[]` (items + service + tax + adjustment; EQUAL/EXACT: only the owed amount), edit button (routes to FL5/FL6 flows, stub until then), delete with confirm.
3. **History**: `GET .../revisions` in a sheet (version, type CREATE/UPDATE/DELETE, time; a read-only snapshot summary of totals and payers per revision).
4. Errors: 404 -> "no longer available", back and refresh; 409 -> conflict dialog; offline -> shared state with retry.
5. `ETag`/version kept in the expense state so FL5/FL6 can send `If-Match`.

Tests: list mapping tests from real JSON fixtures (copy backend responses for EQUAL, EXACT, ITEMIZED with service only, tax only, both, neither, V5-V8 numbers must be shown exactly); grouping by date; filters produce the right query parameters; "your share" present/absent; delete flow (204, 409, 404); widget tests ar/en, text scale 2.0; golden for a list item and the details page; omitted-element search test.
Constraints: display server numbers only, no recomputation (a test asserts the breakdown numbers on screen equal the fixture numbers and never recalculates); SCREEN_MAP rules. Done when analyze and tests pass. Then Stop protocol; do NOT start FL5 here.
