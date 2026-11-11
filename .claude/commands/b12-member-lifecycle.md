---
description: "B12 — Phase 2: member status (leave/reactivate), role changes, ownership transfer"
---

Read AGENTS.md, **docs/PHASE2_SPEC.md sections 2, 5, 10, 11**, docs/PROJECT_PHASES.md 2.3-2.4, Decision Log A53-A58 and A65+, `MemberService`, `ExpenseValidator`, `ExpenseMemberUsageChecker`, `BalanceService`, B10's permission component. Prerequisite: B11 merged. Skills (max 4): think-before-coding, auth-and-authorization, data-modeling-discipline, query-discipline.

Step 0 (plan, wait for approval): the six-step design, and settle (Decision Log):
1. **State and role transitions.** A table of every (actor role, target role/status, action) cell -> result, including: Owner cannot be demoted/removed/left; Admin cannot touch Owner or other Admins' roles; only Owner promotes/demotes; self-leave; reactivate; what happens to a user who leaves while they have PENDING settlements or unsettled balance (recommended: allowed, the balance stays, a warning is a client concern).
2. **LEFT semantics.** LEFT member: no access to the group (404, like a stranger, B10), disappears from their `GET /groups`; stays in history, balances and suggested transfers; **cannot be a payer/participant/assignee/settlement party in new records** (`MEMBER_INACTIVE` 422; list every place that validates member ids: expense create/update/preview, settlements). Editing an existing expense that already includes a LEFT member: decide (recommended: allowed to keep them, not to add them). Rejoin = new invite claiming the old member row (B11 must allow claiming a LEFT ghost-like member: decide whether LEFT members that were linked become claimable after `unlink`).
3. **Ownership transfer.** `POST /groups/{gid}/transfer-ownership {toMemberId}`: target ACTIVE and linked, one transaction, old owner -> ADMIN, the one-OWNER unique index never violated mid-statement (order the updates or use a deferrable approach: state which), `FORBIDDEN` for non-owners, `409 OWNER_MUST_TRANSFER` on owner leave.
4. **Endpoints.** `PATCH /groups/{gid}/members/{mid}` extends rename with `role` and `status`; `POST /groups/{gid}/leave`. Confirm the mass-assignment boundary: which fields a caller can set per role.
5. **Group delete interplay** (A23): a group with more than the owner's member or with history stays non-deletable; leaving members do not make it deletable.

Implement: service rules, validators, endpoints, DTOs, error codes (`MEMBER_INACTIVE`, `OWNER_MUST_TRANSFER`), OpenAPI + regeneration, seed, Decision Log, README.
Tests (Testcontainers): the full transition table (one test per cell); LEFT member rejected in expense create/update/preview and settlement create, kept in history/balances/transfers; balances sum to zero with LEFT members present (reuse the balances scenario); transfer ownership atomicity + concurrent double transfer; leave as owner -> 409; stranger/LEFT cannot read; reactivate; B10 matrix extended; no N+1 in the member list with roles.
Constraints: follow AGENTS.md; do not change engine rules; do not delete member rows with history. Done when `./mvnw clean verify` passes. Then Stop protocol; tell the owner `mobile` must regenerate the client.
