---
description: "B5 — Itemized restaurant bill + preview endpoint"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 3.1 (itemized, optional service/tax), 6 (expense_items, expense_item_assignees, itemized columns), 7.4, 8.2 (preview), 8.4, 10 (vectors V5–V8), 14 (A1, A2). Prerequisite: B4 merged. Skills: think-before-coding, data-modeling-discipline, migration-safety, error-handling-as-design, testing-with-discernment, security-discipline.

Step 0 (plan, wait for approval): how the preview and create paths share one mapping/validation pipeline so they cannot diverge; how items and assignees are persisted; response shape of the preview (per-member breakdown, totals, payersTotalMatches).

Implement:
1. Flyway migration for expense_items and expense_item_assignees (constraints, indexes).
2. Support splitType ITEMIZED on create: items with >= 1 assignee each, amount > 0; optional service {bps}; optional tax {bps, base} with base defaulting to SUBTOTAL_PLUS_SERVICE; optional signed adjustmentMinor. Service and tax are INDEPENDENT: service only, tax only, both, or neither must all work. Validate bps range 0–10000. The expense total is computed by the engine; payers must sum to it (PAYERS_TOTAL_MISMATCH). Persist subtotal, service, tax, adjustment, tax_base, items, assignees, and the per-member resolved breakdown in expense_splits.
3. POST /groups/{gid}/expenses/preview (same body as create, no Idempotency-Key, persists nothing, safe to call repeatedly): returns totalMinor, subtotalMinor, serviceMinor, taxMinor, per-member { memberId, itemsMinor, serviceMinor, taxMinor, adjustmentMinor, owedMinor }, and payersTotalMatches. It works for EQUAL, EXACT and ITEMIZED. Add basic abuse protection (request size limits, max items per bill, e.g. 100).
4. GET expense endpoints return itemized details (items with assignees, charges, per-member breakdown).
5. Update the OpenAPI annotations so the request/response models and examples reflect all three split types.

Tests (Testcontainers): vectors V5, V6, V7, V8 end to end through the API with the exact numbers from spec section 10 (including the tie-break in V5); preview and create return identical breakdowns for the same body; validation (item without assignee, bps out of range, no items, payers mismatch); a payer who is not a participant; a bill where one member has no items (dropped from splits); negative adjustment; preview persists nothing (row-count assertion).
Constraints: follow AGENTS.md; do not change engine rules (if a rule seems wrong, stop and ask); no edit/delete yet. Done when ./mvnw verify passes. Then follow the Stop protocol.
