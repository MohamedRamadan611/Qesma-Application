---
description: "FL6 — Itemized restaurant bill editor: items, assignees, service and tax toggles, live breakdown"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/PROJECT_SPEC.md sections 3.1 (itemized), 7.4, 8.4, 10 (V5-V8), Decision Log A1, A2, A31-A36, and open the screen `P8-01-Expense-Details.png` (**this file is the itemized bill EDITOR**, see SCREEN_MAP section 2) plus `P6-01-Paid by.png` for the shared payers sheet. Prerequisite: FL5 merged. Skills (max 4): think-before-coding, ui-ux-pro-max, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): the form model (items, assignees, service on/off + percent, tax on/off + percent + base, adjustment, payers) and its mapping to the request of spec 8.4 / `ExpenseCommand` (`items[{name, amountMinor, assigneeMemberIds}]`, `service {bps}`, `tax {bps, base}`, `adjustmentMinor`; service and tax are **independent**: service only, tax only, both or neither must all work); percent text -> bps by string parsing (`core/money` `Bps`); the default tax base (SUBTOTAL_PLUS_SERVICE, shown as a two-option chip pair: "subtotal only" / "subtotal + service"); which numbers come from preview (subtotal, service amount, tax amount, per-person items/service/tax/adjustment, total, `payersTotalMatches`); omitted elements (scan receipt, item icons/descriptions).

Implement:
1. **Items editor**: add/remove items (name max 100, amount, at least one assignee chip each, up to 100 items), inline error "item without assignee" before saving and the server errors by code; the item subtotal line is server data (from preview) once available.
2. **Service charge** and **Tax** toggles each with a percent field (0..100.00, two decimals) and the amount it adds (from preview); tax base chips; **adjustment** (signed, +/- controls in 0.01 EGP steps, typed amounts allowed; negative totals or negative shares come back as `VALIDATION_ERROR`: show the server message mapped to copy).
3. **Per-person breakdown** (items + service + tax + adjustment = owed) and the total row, all from preview; members with zero items do not appear (server drops them), payers banner "matches / does not match" from `payersTotalMatches`, shared payers sheet from FL5.
4. Save/edit exactly like FL5 (`IdempotentAction`, `If-Match`, conflict dialog). On edit, load `items`, `charges.service.bps`, `charges.tax.{bps, base}`, `charges.adjustmentMinor` from the expense and display bps as percent (1200 -> "12").
5. The ITEMIZED tab of the add/edit screen now opens this editor; remove the FL5 stub.

Tests: for each of V5, V6, V7, V8 (spec section 10) the editor state produces the exact request body (golden JSON) and, given the backend's real preview response for that input, shows exactly the spec numbers (561.79 / 492.80 / 501.60 / 440.00 and the per-person owed amounts); percent parsing ("12", "12.5", "100", "100.01" rejected, "-1" rejected); toggles off remove the field from the request (not 0 bps); item validation; debounce/stale preview; edit round trip (GET -> form -> PUT body equals the original plus changes); widget tests ar/en/2.0 text scale, golden for the editor.
Constraints: SCREEN_MAP rules; no calculation of service, tax, rounding or totals in Dart; the percentage-to-bps parser is string-based. Done when analyze and tests pass. Then Stop protocol; do NOT start FL7 here.
