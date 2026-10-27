---
description: "B6 — Edit, delete, revisions, optimistic concurrency"
---

Read AGENTS.md, docs/PROJECT_SPEC.md sections 6 (expense_revisions), 7.9, 8.1, 8.2 (PUT, DELETE, revisions), 8.5. Prerequisite: B5 merged. Skills: think-before-coding, idempotency-and-side-effects, data-modeling-discipline, security-discipline, error-handling-as-design, testing-with-discernment.

Step 0 (plan, wait for approval): the six-step design for update/delete — transaction scope, how the version check is enforced atomically (no check-then-write race), what the revision snapshot contains, what a replayed or concurrent edit does.

Implement:
1. Flyway migration for expense_revisions (unique (expense_id, version), jsonb snapshot).
2. Write a revision on CREATE (retrofit into the create path from B4/B5), UPDATE and DELETE. The snapshot contains the full expense: header, payers, resolved splits, items, charges.
3. PUT /groups/{gid}/expenses/{eid} with If-Match (version): replaces payers/splits/items atomically through the same validation + engine pipeline as create, increments version, writes a revision. The client sends the explicit participant list (never silently add members who joined later). Missing/stale If-Match => VERSION_CONFLICT (409). Two concurrent updates with the same version: exactly one wins, the other gets 409 (enforce with an atomic conditional update or optimistic locking).
4. DELETE /groups/{gid}/expenses/{eid} with If-Match: soft delete (deleted_at), increment version, write a revision. Soft-deleted expenses disappear from lists and balances but remain in revisions. Deleting an already-deleted expense is a clean 404 or idempotent success (choose one, state it).
5. GET /groups/{gid}/expenses/{eid}/revisions: chronological list with changedBy, changedAt, changeType, and the snapshot (or a diff-friendly representation).
6. ETag/version returned on GET and in create/update responses.

Tests (Testcontainers): update recalculates splits correctly (use V5 then change service from 12% to 10%); revision count and content after create -> update -> delete; stale version => 409 and nothing changes; concurrent updates (parallel threads) => exactly one success; deleted expense excluded from list; IDOR on update/delete/revisions; edit cannot move an expense to another group; validation errors identical to create.
Constraints: follow AGENTS.md; no roles/permissions (owner-only). Done when ./mvnw verify passes. Then follow the Stop protocol.
