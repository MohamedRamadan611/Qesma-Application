---
description: "R — Milestone review (run after every B prompt, in a NEW session)"
---

Read AGENTS.md and the diff of the last milestone ($ARGUMENTS — use `git diff main...HEAD` or the last commit range). Review it as a strict senior reviewer WITHOUT changing code. Check, citing file:line and the spec section for each finding:
1. Spec compliance (rules, error codes, endpoints, field names).
2. Money correctness: any floating point, rounding or tie-break deviation, overflow risk.
3. Authorization: every group-scoped path goes through the central component; another user's resource returns 404.
4. Idempotency, transactions and concurrency (check-then-write races, missing unique constraints).
5. Migrations (locking, irreversibility, constraints) and queries (N+1, missing indexes, unbounded lists).
6. Error handling (swallowed exceptions, wrong codes, leaked internals) and logging (secrets, personal data).
7. Tests: tests that mock what they claim to test, missing money/authz/concurrency cases, flaky patterns.
8. Scope creep: anything outside Phase 1.
Output: a severity-ranked table (blocker/major/minor/nit), what is good, and a recommended fix order. Do not edit files.
