---
description: "FL7 — Balances tab, suggested transfers, record payment, settlement history"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/PROJECT_SPEC.md sections 7.6-7.8, 8.2 (balances, settlements), 9 (items 10-11), Decision Log A42-A47, and open the screens `P9-01-Balance-Tab.png` and `P9-02-Pay.png`. Prerequisite: FL6 merged (FL5 is enough to create expenses). Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): the client design; the mapping of every visible element to `BalanceView` / `SettlementView` fields; **how "N transfers needed" and "all settled" are derived** (count of `transfers`, nothing else); the refresh strategy (after recording or deleting a payment and after any expense change refetch balances and settlements; balances are never cached across edits); the decision on the design's undo snackbar (the backend has no restore: use a confirmation dialog instead and say so); omitted elements (payment-method chips, "half amount" shortcut, immediate-effect panel, per-member activity captions).

Implement:
1. **Balances tab** (P9-01): header total spent (from `GroupDto`), settlement status text from the transfers count, **suggested transfers** list (from -> to, amount, "Record payment" button), **per-member nets** (sign + colour + word: owed / owes / settled, the "(you)" badge from `isYou`), all-settled state.
2. **Record payment sheet** (P9-02): from and to pickers (prefilled from the tapped transfer, any two different members), amount prefilled with the transfer amount (editable, 1..10^12 piasters; partial and larger amounts are allowed by the spec), date (default today), note (max 200), confirm. Create with `IdempotentAction` (key per attempt, reused on retry, new key when the body changes). Errors by code (`MEMBER_NOT_IN_GROUP` reload members, `VALIDATION_ERROR` e.g. from equals to).
3. **Settlement history** (`GET .../settlements`, paged): list newest first with amount, from -> to, date, note, delete with confirm (`DELETE`, 204); both lists and balances refresh afterwards.
4. Empty/loading/error/offline states from FL1.

Tests: transfers and nets rendering from the backend's real V1 and V2 responses (nets 100.00/-80.00/-20.00; after the payment 20.00/0/-20.00 and one transfer); sign, colour and word present together (semantics test); key lifecycle for the payment; refresh after create and delete; amount and note validation; widget tests ar/en/2.0 text scale; golden for the balances tab; omitted-element search test; guard test (no arithmetic on balances).
Constraints: SCREEN_MAP rules: balances and transfers only from the endpoint, no "effect of this payment" computation. Done when analyze and tests pass. Then Stop protocol; do NOT start FL8 here.
