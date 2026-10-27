---
description: "B7 — Balances & settlements"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 6 (settlements), 7.6, 7.7, 7.8, 8.2 (balances, settlements), 8.3, 10 (V1, V2 and property tests). Prerequisite: B6 merged. Skills: think-before-coding, query-discipline, explain-this-query, idempotency-and-side-effects, data-modeling-discipline, performance-and-scaling, testing-with-discernment.

Step 0 (plan, wait for approval): decide how nets are computed — SQL aggregates for paid/owed/settlement sums feeding the engine's simplifier, versus loading rows and using the engine end to end. Justify with the expected load (up to ~15 members and ~500 expenses per group) and keep the engine as the only place with money rules.

Implement:
1. Flyway migration for settlements (CHECKs: amount > 0, from <> to), with indexes for group lookups.
2. POST /groups/{gid}/settlements (Idempotency-Key required; same machinery as expenses), GET /groups/{gid}/settlements, DELETE /groups/{gid}/settlements/{sid} (soft delete; reverses its effect). Both members must belong to the group (MEMBER_NOT_IN_GROUP). Partial amounts and amounts larger than the suggested transfer are allowed (spec 7.8).
3. GET /groups/{gid}/balances returns nets per member (including members with 0) and the simplified transfers from the engine; invariant: sum of nets == 0 (assert it at runtime and fail loudly if violated).
4. Replace remaining default usage checkers: a member in any settlement (including soft-deleted) blocks member deletion; a group with settlements cannot be deleted.
5. Run EXPLAIN on the balance and list queries against a generated dataset (15 members, 500 expenses, 200 settlements); add any index that is justified; record the findings in docs/perf-notes.md.

Tests (Testcontainers): V1 (nets M +100.00, S -20.00, A -80.00; transfers A->M 80.00, S->M 20.00) and V2 (after settlement A->M 80.00) through the API; soft-deleting a settlement or an expense updates balances; partial and excess settlements; idempotent settlement creation; IDOR; a randomized scenario test (create/edit/delete expenses and settlements) asserting sum(net)==0 and that applying the returned transfers zeroes all nets; performance sanity (balances for the large dataset under a reasonable bound, stated in the test).
Constraints: follow AGENTS.md; no two-sided confirmation (Phase 2). Done when ./mvnw verify passes. Then follow the Stop protocol.
