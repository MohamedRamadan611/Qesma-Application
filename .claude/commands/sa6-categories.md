---
description: "SA6 — Expense categories in the local backend and the expense form, list, details and filters"
---

Read AGENTS.md, mobile/AGENTS.md, `.claude/mobile/SCREEN_MAP.md`, docs/STANDALONE_SPEC.md (categories) and Decision Log entries, the BSA1 contract changes in `docs/openapi.json`, `lib/local/db/`, `lib/local/service/` (expenses), `lib/features/expenses/` (form, list, details, filters, `expense_command_builder.dart`), docs/design/DESIGN.md, and open `P3-01-Group-Home & Expenses-Tab.png` and `P5-01-Add Expense.png`. Prerequisite: BSA1 merged. Skills (max 4): ui-ux-pro-max, design-system, ux-copy, accessibility-review.

Step 0 (plan, wait for approval): (1) local DB migration adding `category` (+ CHECK) mirroring BSA1, revision snapshot, filter in the local list query; (2) category picker UX in the expense form and the itemized editor (chips or grid; default OTHER; one tap), icon + colour per category from DESIGN.md tokens (accessible contrast, not colour-only); (3) where the category shows (expense card icon, details header, filter sheet); (4) Arabic and English names for the nine categories (ux-copy); (5) scope guard additions.

Implement: local schema migration + services + conformance test update, form/editor field (sent through `ExpenseCommand`), card/details display, list filter by category, ARB strings, icons.

Tests: local backend round trip with category (create, edit, revision shows the old category, filter); conformance tests in both modes; builder golden JSON includes `category`; widget tests ar/en/text scale 2.0 for picker, card and filter; goldens; guard tests.
Constraints: SCREEN_MAP rules; no money math in the UI. Done when analyze and tests pass. Then Stop protocol; do NOT start SA7.
