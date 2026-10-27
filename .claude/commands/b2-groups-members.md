---
description: "B2 — Groups & members"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 3.1, 6 (expense_groups, members), 7.10, 8.1, 8.2 (groups and members), 8.5, 12. Skills: think-before-coding, data-modeling-discipline, migration-safety, auth-and-authorization, security-discipline, query-discipline, testing-with-discernment.

Step 0 (plan, wait for approval): six-step design, including how sort_order is assigned safely under concurrency, and the extension points for rules that depend on tables that do not exist yet (expenses/settlements).

Implement:
1. Flyway migration for expense_groups and members exactly as in spec section 6 (CHECKs, FKs, unique index on (group_id, lower(display_name))). Indexes for the access paths you will use (owner's groups, group members).
2. A single central component (e.g. GroupAccessService) that loads a group only if owned by the current user, otherwise throws NOT_FOUND (404). Every group-scoped endpoint must go through it (spec section 12: Phase 2 will replace it with roles).
3. Endpoints: POST/GET /groups, GET/PATCH/DELETE /groups/{gid}, POST /groups/{gid}/members, PATCH and DELETE /groups/{gid}/members/{mid}. Validation: group name 1–60 trimmed; type in TRIP/HOUSING/OUTING/OTHER; currency valid ISO 4217 (default EGP); member name 1–40 trimmed; duplicate names rejected (DUPLICATE_MEMBER_NAME).
4. GET /groups returns, per group: id, name, type, currencyCode, memberCount, totalSpentMinor (0 for now), lastExpenseAt (null for now) — the UI needs them; B4 will wire the last two. Record this addition as a proposed entry in the spec Decision Log (A11). GET /groups/{gid} returns the group with its members ordered by sort_order.
5. sort_order assigned incrementally and never reused, safe under concurrent member creation (lock the group row or equivalent) — prove it with a concurrency test.
6. PATCH group uses optimistic concurrency (version + If-Match/ETag) -> VERSION_CONFLICT.
7. Delete rules need data from tables that do not exist yet. Create two small interfaces now (e.g. MemberUsageChecker, GroupUsageChecker) with default implementations returning "unused", wire them into DELETE member (MEMBER_HAS_TRANSACTIONS) and DELETE group (GROUP_NOT_EMPTY), and write tests against a stub that returns "used". B4 and B7 will replace the defaults.
8. List endpoints paginated (page, size with a hard max); avoid N+1 (memberCount via a single query).

Tests (Testcontainers): ownership isolation (user B gets 404 for user A's group, members, and on every verb); validation errors with codes; duplicate member names (case-insensitive); concurrent member creation yields distinct sort_order; optimistic concurrency conflict; deletion rules via the stub; pagination.
Constraints: follow AGENTS.md; no invites/roles/LEFT status; no expense logic. Done when ./mvnw verify passes and the security reflex checklist (IDOR, mass assignment, input validation) is stated in the summary. Then follow the Stop protocol.
