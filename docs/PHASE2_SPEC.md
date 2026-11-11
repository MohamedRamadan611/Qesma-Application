# Qesma — Phase 2 spec addendum (Collaboration)

Status: **draft for the Phase 2 prompts (B10–B19, FL10–FL18)**. Source: `PROJECT_PHASES.md` section 2 (the roadmap) made concrete. `PROJECT_SPEC.md` stays authoritative for everything Phase 1 (money rules, idempotency 8.3, error format 8.5, invariants). Where this file and `PROJECT_SPEC.md` disagree about a Phase 2 topic, this file wins; every such change is recorded in the Decision Log of `PROJECT_SPEC.md` from **A65** (A64 is the last Phase 1 entry) and ADRs continue from **ADR-009**.

All Phase 1 invariants still hold: integer money, backend authoritative, pure engine, balances computed never stored, ledger never hard-deleted, every create idempotent, problem+json with stable codes, Testcontainers on real PostgreSQL, no secrets or personal data in logs.

Items marked **(decide)** are settled in the Step 0 plan of the prompt that owns them and written to the Decision Log. The recommended default is given so the prompt can propose it.

---

## 1. Scope and ownership of each item

| Roadmap item | Backend prompt | Flutter prompt |
|---|---|---|
| 2.3 Roles and permissions | B10 | FL10 |
| 2.1 Invitations, 2.2 Link member to account | B11 | FL11 |
| 2.4 Member lifecycle, ownership transfer | B12 | FL12 |
| 2.5 Settlement v2 | B13 | FL13 |
| 2.6 Payment handles | B14 | FL13, FL14 |
| 2.8 Activity feed, 2.7 in-app notifications | B15 | FL15 |
| 2.7 Remind, per-group mute, global toggle | B16 | FL14, FL15 |
| 2.9 Concurrency UX, 2.10 Account deletion | B17 | FL16 |
| 2.7 Push (FCM), device tokens (**optional**) | B18 | FL17 |
| 2.13 Acceptance, hardening, handoff | B19 | FL18 |

Out of Phase 2 (do not build): WhatsApp integration, real-time sockets, receipt/payment-proof image upload, disputes arbitrated by the app, percent/shares splits, refunds, categories, offline queue, multi-currency, payments of any kind (the app never moves money).

---

## 2. Roles and permissions (B10)

Roles: `OWNER` (exactly one per group), `ADMIN`, `MEMBER`. A linked member of a group (member row with `user_id` = caller, `status` ACTIVE) is a participant. `LEFT` members keep their row but have no access to the group and cannot be added to new expenses.

| Action | Owner | Admin | Member |
|---|:-:|:-:|:-:|
| Read group, members, expenses, balances, settlements, activity | yes | yes | yes |
| Add expense / record or declare settlement | yes | yes | yes |
| Edit / delete **own** expense (created_by = caller) | yes | yes | yes |
| Edit / delete **others'** expense | yes | yes | no |
| Add / rename / remove (ghost) members | yes | yes | no |
| Create / list / revoke invites; approve join requests; link / unlink member | yes | yes | no |
| Promote / demote admin | yes | no | no |
| Edit group (name, type) | yes | yes | no |
| Delete group (only while empty, A23) | yes | no | no |
| Close group (Phase 3) | yes | yes | no |
| Transfer ownership | yes | no | no |
| Leave group | no (transfer first) | yes | yes |
| Reactivate a LEFT member | yes | yes | no |
| Confirm / dispute a settlement addressed to me | participant | participant | participant |
| Cancel a PENDING settlement | its payer, or admin/owner | | |
| Resolve (confirm / cancel) a DISPUTED settlement | admin/owner, or the receiver (confirm) / payer (cancel) | | |

Rules:
1. Exactly one authorization component (successor of `GroupAccessService`) answers every question: `requireMember(groupId)`, `require(groupId, Permission.X)`. Controllers and services never compare roles themselves.
2. **(decide) Denial codes. Recommended:** caller is not an ACTIVE member of the group (or the group does not exist) -> `404 NOT_FOUND` (IDOR defense, as in Phase 1); caller is a member but the role lacks the permission -> `403 FORBIDDEN` (new code). Amend AGENTS.md invariant 7 and spec 8.5 accordingly.
3. The Owner can never be demoted, removed, or made LEFT; only `transfer-ownership` changes the Owner (new owner must be an ACTIVE linked member; the previous owner becomes ADMIN).
4. Every role/status change is an event in `group_events` (section 8).
5. The role is part of the read model: `GroupDto.yourRole`, `MemberDto.role`, `MemberDto.status`, `MemberDto.hasAccount` (boolean, derived from `user_id IS NOT NULL`; the account id itself is **never** exposed).

---

## 3. Data model additions (Flyway forward-only, V12 onwards; never edit V1-V11)

```
members:           + role text NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('OWNER','ADMIN','MEMBER'))
                   + status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','LEFT'))
                   + joined_at timestamptz, left_at timestamptz
                   unique (group_id) WHERE role = 'OWNER'            -- exactly one owner
                   (existing unique (group_id, user_id) WHERE user_id IS NOT NULL stays: one account <-> one member per group)
group_invites:     id uuid, group_id fk, code text unique, token_hash bytea unique (SHA-256 of the link token),
                   created_by_member_id fk, created_at, expires_at NOT NULL, max_uses int NULL CHECK (max_uses > 0),
                   use_count int NOT NULL DEFAULT 0 CHECK (use_count >= 0), requires_approval boolean NOT NULL,
                   revoked_at timestamptz NULL
join_requests:     id uuid, invite_id fk, user_id fk, claim_member_id fk NULL (NULL = create new),
                   new_member_name text NULL, status ('PENDING','APPROVED','REJECTED'), created_at, decided_at, decided_by_member_id
                   unique (invite_id, user_id) WHERE status = 'PENDING'
settlements:       + status ('PENDING','CONFIRMED','DISPUTED','CANCELLED') NOT NULL, declared_at, confirmed_at, disputed_at,
                   cancelled_at, recorded_by_admin boolean NOT NULL DEFAULT false, created_by_member_id
                   (V12 backfills every Phase 1 row to CONFIRMED, recorded_by_admin = true)
payment_handles:   id uuid, user_id fk, type ('INSTAPAY','WALLET'), value text, created_at, updated_at; unique (user_id, type)
group_events:      id uuid, group_id fk, actor_member_id fk NULL, type text, payload jsonb, created_at timestamptz  (index group_id, created_at DESC, id DESC)
notifications:     id uuid, user_id fk, group_id fk NULL, type text, payload jsonb, read_at NULL, created_at  (index user_id, created_at DESC)
notification_prefs:user_id fk, group_id fk NULL (NULL = global), muted boolean NOT NULL; unique (user_id, group_id)
remind_log:        group_id, from_member_id, to_member_id, created_at   (rate limit source of truth)
device_tokens:     (B18, optional) id uuid, user_id fk, token text unique, platform text, last_seen_at
users:             + deleted_at timestamptz NULL (B17: anonymised row kept for FK integrity)
```
Payload jsonb stores **ids and amounts only, never names or titles** at write time; names are resolved when read (account deletion and renames then stay consistent, and logs never carry personal data).

---

## 4. Invitations (B11)

- Admin/Owner creates an invite: `expiresInDays` (default 7, max 30), `maxUses` (optional), `requiresApproval` (default false).
- Two secrets: a short human **code** (typed) and a long random **link token** (in the URL; only its SHA-256 is stored). **(decide) code format. Recommended:** 8 characters from an unambiguous 32-symbol alphabet displayed as `XXXX-XXXX` (the design shows `DHB-4821`, which is only ~1.7e8 combinations; do not derive it from the group name). Case/dash-insensitive on input.
- Link: `https://<host>/join/<token>` as an Android App Link; unauthenticated browsers get a small landing page that points to the Play Store (landing page itself is outside the prompts; document the URL contract).
- `GET /invites/{codeOrToken}` (authenticated, any signed-in user) returns a **preview**: group name, type, inviter display name, member count, and the list of **unclaimed ghost member names** (name + id only; **no balances, no expense counts**: the design `P12-02` shows amounts to a non-member, which is a privacy leak and is omitted).
- `POST /invites/{codeOrToken}/join` body `{ claimMemberId | newMemberName }` (exactly one), `Idempotency-Key` required. Outcomes: `201` member created/linked (`JoinResult{status: JOINED, member}`), or `202` `{status: PENDING_APPROVAL}` when the invite requires approval. Joining requires sign-in.
- Rules: one account <-> at most one member per group (`ALREADY_MEMBER` 409, idempotent replay returns the same result); a ghost can be claimed once (`MEMBER_ALREADY_CLAIMED` 409, enforced by the DB unique index plus a row lock, tested with parallel joins); `newMemberName` follows the member-name rules (40, duplicate check `DUPLICATE_MEMBER_NAME`); `use_count` increments only on JOINED/APPROVED; an invite past `expires_at`, over `max_uses` -> `410 INVITE_EXPIRED`; revoked -> `410 INVITE_REVOKED`; unknown code/token -> `404 NOT_FOUND`.
- Approval flow: `GET /groups/{gid}/join-requests`, `POST .../join-requests/{rid}/approve|reject` (Admin/Owner). The requester sees their own request state via `GET /invites/{...}` (state `PENDING_APPROVAL`) so the UI can show "waiting".
- `DELETE /groups/{gid}/invites/{iid}` revokes (sets `revoked_at`, never hard-deletes).
- Abuse: code guessing is rate-limited per user and per IP (reuse `AuthRateLimitFilter` approach); a failed lookup never reveals whether a code existed once.
- Admin may `POST /groups/{gid}/members/{mid}/unlink` (account removed from member, row and history kept, member becomes a ghost again; the unlinked user loses access) and `.../link` is only possible through an invite or a join-request approval (no admin typing in account ids).

---

## 5. Member lifecycle (B12)

- `PATCH /groups/{gid}/members/{mid}` body `{ name?, role?, status? }` (role changes: Owner only; status changes per matrix); `If-Match` is not required (members have no version).
- `POST /groups/{gid}/leave` (self; Owner gets `409 OWNER_MUST_TRANSFER`): status -> LEFT, `left_at`, balance and history kept; the left user's group disappears from `GET /groups` and `GET /groups/{gid}` is `404` for them.
- Reactivate (Admin/Owner) sets ACTIVE again; a left user rejoins only through a new invite (claiming their old member row).
- LEFT members cannot be added as payers/participants in new expenses or settlements (`MEMBER_INACTIVE` 422), but still appear in historical expenses, balances and suggested transfers (their balance is real money owed).
- `POST /groups/{gid}/transfer-ownership` body `{ toMemberId }`, Owner only, target must be ACTIVE and linked. One transaction: new OWNER, old becomes ADMIN, event logged.
- Phase 1 "remove member only if no transactions" stays for ghost members.

---

## 6. Settlement v2 (B13)

State machine (one table in code, one test per cell):

| From | Action | To | Who |
|---|---|---|---|
| (new) | declare "I paid" | PENDING | the payer (from member) or any member for themselves |
| (new) | record on behalf of two members | CONFIRMED, `recorded_by_admin = true` | Admin/Owner |
| PENDING | confirm "received" | CONFIRMED | the receiver (to member) or Admin/Owner |
| PENDING | dispute "not received" | DISPUTED | the receiver |
| PENDING | cancel | CANCELLED | the payer, or Admin/Owner |
| DISPUTED | confirm | CONFIRMED | the receiver, or Admin/Owner |
| DISPUTED | cancel | CANCELLED | the payer, or Admin/Owner |
| CONFIRMED / CANCELLED | any | invalid -> `409 INVALID_STATE_TRANSITION` | |

- Partial amounts allowed (amount 1..10^12 piasters as in Phase 1). Each action is `POST /groups/{gid}/settlements/{sid}/confirm|dispute|cancel`, idempotent by state (repeating the same transition returns the current view, never a second event) and by `Idempotency-Key` for the create.
- **(decide) Balance rule. Recommended:** nets and suggested transfers count **CONFIRMED only**. PENDING and DISPUTED settlements are returned as informational data: `BalanceView.transfers[]` gains `pendingMinor` (sum of PENDING settlements between that exact pair) and `hasDispute` (boolean), computed by the backend; the client never subtracts them. `Sum of nets = 0` must still hold (jqwik property over random settlement statuses).
- Phase 1 `DELETE /groups/{gid}/settlements/{sid}` is replaced: only CANCELLED via the `cancel` action (soft), the endpoint is removed from the contract and OpenAPI (B13 decides how; record in the Decision Log). History keeps cancelled rows (shown with a chip).
- Disputed settlements are visible to both parties and to Admin/Owner; resolution is manual; the app does not arbitrate. No payment-proof image and no transaction reference are stored (omitted from `P13-03`).

---

## 7. Payment handles (B14)

- `GET /me/payment-handles`, `PUT /me/payment-handles` body `{ instapay: string|null, wallet: string|null }` (null removes). Validation: wallet = Egyptian mobile `01[0125]XXXXXXXX` normalised to digits (spec says the design shows `010XXXXXXXX`), InstaPay = `local@bank`-style address (3..60 chars, one `@`, no spaces). Both optional.
- Visibility: a user's handles appear **only** (a) to the user themself and (b) on the transfer/member DTOs of groups they share with the viewer, where the viewer is an ACTIVE member. Never in group lists, activity, notifications, logs or error bodies. Integration tests: a non-member and a member of another group never see them; removal is immediate.
- The app only displays and copies them; it never initiates a transfer. Lawyer review noted in the decision log (personal data, PDPL No. 151/2020).

---

## 8. Activity feed and in-app notifications (B15, B16)

Event catalogue (type -> payload ids/amounts only -> who is notified; the actor is never notified of their own action):

| Type | Payload | Notified |
|---|---|---|
| `EXPENSE_ADDED` | expenseId, totalMinor, actorMemberId | participants/payers with an account, except actor |
| `EXPENSE_EDITED`, `EXPENSE_DELETED` | expenseId, version | same, only those still in the latest/previous participant set |
| `SETTLEMENT_PENDING` | settlementId, amountMinor | the receiver |
| `SETTLEMENT_CONFIRMED`, `SETTLEMENT_DISPUTED`, `SETTLEMENT_CANCELLED` | settlementId, amountMinor | the other party (+ Admin/Owner on DISPUTED) |
| `REMINDER` | fromMemberId, toMemberId, amountMinor | the debtor |
| `MEMBER_JOINED`, `MEMBER_LEFT`, `INVITE_ACCEPTED`, `JOIN_REQUESTED` | memberId | invite creator / Admins |
| `ROLE_CHANGED`, `OWNERSHIP_TRANSFERRED` | memberId, role | the affected member |

- Events and notifications are inserted **in the same database transaction** as the business write (no outbox worker needed in Phase 2; push in B18 reads committed notifications). A rollback leaves no event.
- Activity feed `GET /groups/{gid}/activity?limit&before` (keyset pagination on `(created_at, id)`, max 50): returns event type, actor member id, payload ids/amounts; the client renders Arabic sentences from the type using member names it already has. Expense titles are resolved by the server at read time into `subject` (title) when the expense still exists.
- Notification center: `GET /notifications?limit&before`, `GET /notifications/unread-count`, `POST /notifications/read` body `{ ids: [...] | all: true }`.
- `PUT /groups/{gid}/notification-prefs` `{ muted }`, `PUT /me/notification-prefs` `{ enabled }` (global). A muted/disabled recipient gets **no notification row** (events still go to the activity feed). `REMINDER` ignores group mute? **(decide) Recommended:** no, mute is respected.
- **Remind** `POST /groups/{gid}/transfers/remind` body `{ fromMemberId, toMemberId }`, `Idempotency-Key`: caller must be the creditor's account (to member) or Admin/Owner; a suggested transfer between exactly that pair must currently exist; at most one per (group, debtor) per 24 h (**decide**, recommended) -> `429 REMIND_RATE_LIMITED` with `nextAllowedAt`; the transfers view returns `canRemindAt` per transfer so the UI can disable the button without guessing.
- Retention: events/notifications older than 180 days are purged by a scheduled job (like `IdempotencyCleanupJob`); activity of expenses remains reconstructable from revisions.

---

## 9. Concurrency UX and account deletion (B17)

- `409 VERSION_CONFLICT` problem body gains `currentVersion` and the latest `ExpenseView` (`current`), so the conflict screen compares "yours" with "latest" without a second request and can re-apply by re-sending with the new `If-Match`.
- `DELETE /me` body `{ confirm: "DELETE" }` (or password for password accounts, **decide**): the `users` row is anonymised (`display_name` -> "Deleted user", email/username/provider id nulled or replaced by a random tombstone, `deleted_at`), credentials, refresh tokens, handles, devices, prefs, notifications purged; member rows keep their ids and become `hasAccount = false`, displayed with the member's own name (not the account's); the ledger is untouched so **every other member's balances are identical before and after** (property/IT test). **(decide)** an Owner with other active members must transfer ownership first (`409 OWNER_MUST_TRANSFER`), a sole member's empty group is deleted. Returns `204`; all sessions end. Lawyer review of the retention approach is an open item.

---

## 10. New error codes (add to `ErrorCode`, OpenAPI `Problem` enum, `ApiContractCoverageIT`)

| Code | HTTP | Meaning |
|---|---|---|
| `FORBIDDEN` | 403 | member lacks the role permission |
| `INVITE_EXPIRED` | 410 | expired or used up |
| `INVITE_REVOKED` | 410 | revoked by an admin |
| `ALREADY_MEMBER` | 409 | caller already has a member in this group |
| `MEMBER_ALREADY_CLAIMED` | 409 | ghost claimed by someone else |
| `MEMBER_INACTIVE` | 422 | LEFT member used in a new expense/settlement |
| `OWNER_MUST_TRANSFER` | 409 | owner cannot leave / delete account with other members |
| `INVALID_STATE_TRANSITION` | 409 | settlement action not allowed from this state |
| `REMIND_RATE_LIMITED` | 429 | reminder already sent in the window (`nextAllowedAt` in the body) |

(`NOT_FOUND`, `VALIDATION_ERROR`, `VERSION_CONFLICT`, `IDEMPOTENCY_KEY_REUSED`, `RATE_LIMITED` are reused.)

---

## 11. API summary (all under `/api/v1`; create operations require `Idempotency-Key`)

```
GET    /groups/{gid}/invites                       POST /groups/{gid}/invites          DELETE /groups/{gid}/invites/{iid}
GET    /invites/{codeOrToken}                      POST /invites/{codeOrToken}/join
GET    /groups/{gid}/join-requests                 POST /groups/{gid}/join-requests/{rid}/approve | /reject
PATCH  /groups/{gid}/members/{mid}                 POST /groups/{gid}/members/{mid}/unlink
POST   /groups/{gid}/leave                         POST /groups/{gid}/transfer-ownership
POST   /groups/{gid}/settlements (status PENDING)  POST /groups/{gid}/settlements/{sid}/confirm | /dispute | /cancel
GET    /me/payment-handles                         PUT  /me/payment-handles
POST   /groups/{gid}/transfers/remind
GET    /notifications   GET /notifications/unread-count   POST /notifications/read
PUT    /groups/{gid}/notification-prefs            PUT /me/notification-prefs
GET    /groups/{gid}/activity
DELETE /me
POST   /devices   DELETE /devices/{id}             (B18, optional)
```
Operation ids are fixed in `OpenApiConfig.OPERATION_IDS` for the generated Dart client (naming: verbs as in Phase 1).

---

## 12. Acceptance criteria (verified by B19 / FL18)

1. Two phones: A creates a group and invites B by link/code; B claims a ghost or joins as new; both see the same data after pull-to-refresh or resume (no sockets).
2. Role permissions are enforced server-side for every endpoint: the role x endpoint matrix test covers all operations.
3. Settlement lifecycle: pending -> confirmed; pending -> disputed -> cancelled; balances move only on CONFIRMED.
4. Notifications appear in the center for each event type; mute works; Remind is rate-limited; (push received if B18 is built).
5. Deleting an account leaves every other member's balances unchanged.

## 13. Risks
Invite-link leakage (expiry, revoke, approval option, rate limit); notification spam (mute, 24 h remind limit, actor excluded); confusion pending vs confirmed (UI copy shows both explicitly, server provides both numbers); payment-handle privacy (strict visibility tests); the join preview must not leak balances to non-members.
