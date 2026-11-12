# ADR-009: Role-based authorization through group membership

Status: Accepted · Date: 2026-11-11 · Replaces the owner-only rule of Phase 1 (spec 3.1, AGENTS.md invariant 7)

## Context
Phase 1 let only the creator of a group reach it: every group-scoped call asked `expense_groups.owner_user_id`. Phase 2 (collaboration, `docs/PHASE2_SPEC.md`) needs several people with different rights in one group (owner, admin, member), added by invitation (B11) and able to leave (B12). The change must stay in one place, keep the IDOR defense, and not touch any money rule.

## Decision
- **Access = an ACTIVE member linked to the caller's account.** `members.role` (`OWNER | ADMIN | MEMBER`) and `members.status` (`ACTIVE | LEFT`) are new (V12). `members.role = 'OWNER'` is the single authority for ownership; `expense_groups.owner_user_id` stays as the immutable creator and is no longer used for authorization. At most one owner per group is a partial unique index; an owner must be linked and ACTIVE (CHECK).
- **One component.** `GroupAccessService` loads the group only if the caller has an ACTIVE member in it (one `exists` predicate, the same shape with a row lock for writes, so a stranger locks nothing) and then checks `Role -> Permission` (`Role`, `Permission`, `GroupContext`). Services never compare roles themselves.
- **Denials (A65).** Not a member, a LEFT member, or an unknown group: `404 NOT_FOUND`, identical body (no oracle, as before). A member whose role lacks the permission: `403 FORBIDDEN` (new code). Precedence: 401, 404, 403, then validation and conflicts. "Own versus others'" rules (expenses, settlements) use the creator already stored in `created_by_user_id`.
- **Phase 1 operations map to permissions (A67):** reads for every member; edit group for Owner/Admin; delete group for Owner; member add/rename/delete for Owner/Admin; create expense/settlement for every member; edit/delete own expense or settlement for every member, others' for Owner/Admin.
- **Migration V12** aborts with a clear message if any group has no member linked to its creator (groups created before B9), so no data is silently orphaned (A68).

## Consequences
- `GET /groups` lists every group where the caller is an ACTIVE member; the membership check is a join predicate in the list query (no per-group check, no N+1).
- `MemberDto` gains `role`, `status`, `hasAccount` (never an account id); group DTOs gain `yourRole`.
- Existing strangers' behaviour is unchanged (404, same body); the IDOR matrix keeps passing.
- B12's ownership transfer only changes `members.role`; nothing else has to move.
- Tests that need non-owner callers insert member rows directly until invitations exist (B11).

## Alternatives considered
- Keep `owner_user_id` and add a separate roles table: two sources of truth for ownership, rejected.
- Return 404 for every denial: hides real permission problems from legitimate members and makes the UI guess; rejected for members (still used for strangers).
- Postgres row-level security: the app uses one database role and pooled connections; adding RLS now would be new infrastructure without an ADR-worthy need at this scale.
