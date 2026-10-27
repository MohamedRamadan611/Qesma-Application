---
description: "B4 — Expenses core (EQUAL, EXACT, multi-payer, idempotency)"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 6 (expenses, expense_payers, expense_splits, idempotency_keys), 7.2, 7.3, 7.5, 7.9 (participant snapshot), 8.1, 8.2, 8.3, 8.4, 8.5. Prerequisites: B2 and B3 are merged. Skills: think-before-coding, idempotency-and-side-effects, data-modeling-discipline, migration-safety, query-discipline, hunt-n-plus-one, security-discipline, error-handling-as-design, testing-with-discernment.

Step 0 (plan, wait for approval): six-step design, especially: the transaction boundary that contains the idempotency-key write and the business write; request-hash canonicalization; what is returned on replay; concurrent requests with the same key; and how "All" participants are resolved (explicit snapshot).

Implement ONLY these split types: EQUAL and EXACT (ITEMIZED comes in B5; reject it with VALIDATION_ERROR for now).
1. Flyway migrations: expenses (including the itemized columns, null for now), expense_payers, expense_splits, idempotency_keys, with all CHECK/FK/PK constraints from the spec. Review with migration-safety. Add indexes for listing expenses by group/date and for balance queries.
2. Request DTOs and validation per spec 8.4 (EQUAL: participantMemberIds; EXACT: shares; multi-payer: payers list). All members must belong to the group (MEMBER_NOT_IN_GROUP). Map errors to the codes in 8.5.
3. Service: validate -> call the engine (never duplicate money math) -> persist expense, payers, and the resolved splits (explicit participants and owed amounts) in one transaction.
4. POST /groups/{gid}/expenses requires Idempotency-Key. Same key + same body returns the stored response without creating anything; same key + different body returns IDEMPOTENCY_KEY_REUSED (422); a concurrent duplicate must still create exactly one expense (rely on the unique constraint, handle the race deterministically). A scheduled job deletes keys older than 24 hours.
5. GET /groups/{gid}/expenses (paged; filters fromDate, toDate, memberId; sorted by expenseDate desc, createdAt desc; soft-deleted excluded) and GET /groups/{gid}/expenses/{eid}. Responses include payers and per-member shares. Avoid N+1 (verify with a query count in a test).
6. Replace B2's default usage checkers so a member referenced by any payer/split blocks deletion, and a group with expenses cannot be deleted. Wire totalSpentMinor and lastExpenseAt in GET /groups.
7. Authorization through the central group access component; another user's group => 404.

Tests (Testcontainers): fixtures V1, V3, V4 (equal rounding, multi-payer) through the API; every validation error code for these types; idempotent replay (same key twice => one row, same response); concurrent duplicate requests (parallel threads) => one expense; key reuse with a different body; "All" snapshot persisted explicitly; query-count test for the list endpoint; IDOR tests.
Constraints: follow AGENTS.md; no editing/deleting expenses yet (B6); no itemized (B5). Done when ./mvnw verify passes. Then follow the Stop protocol.
