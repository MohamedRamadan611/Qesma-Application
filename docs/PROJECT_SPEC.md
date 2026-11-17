# Qesma (working title) — Group Expense Splitting App
## Project Specification v0.1 — Phase 1 ("Organizer Mode") in full detail

> Working title "Qesma" (قسمة) is a placeholder. Package names, app id and branding are TBD.
> This file details **Phase 1 only**. The whole project (Phases 0–5, with scope, data model and API additions, gates and risks) is in `PROJECT_PHASES.md`. UI design prompts are in `STITCH_PROMPTS.md`.
> This document is the source of truth for coding agents. If something is ambiguous, check the **Decision Log** (section 14) and the **Test Vectors** (section 10) before guessing.

---

## 0. Instructions for the coding agent

1. Build strictly in the milestone order of section 4. Do **not** add features outside Phase 1 scope (section 3).
2. The money logic lives in a **pure Java module** (`engine` package, no Spring, no DB) with exhaustive unit tests and property-based tests (e.g. jqwik). Write and pass these tests **before** writing any controller that uses the engine.
3. The backend is the single source of truth for all calculations. The mobile app never re-implements split logic; it calls the `preview` endpoint.
4. Never use floating point for money. All amounts are `long` minor units (EGP piasters: 1 EGP = 100).
5. The app **never holds, moves, or processes money**. It only records.
6. Every state-changing endpoint that creates records must support idempotency (section 8.3).
7. Nothing is hard-deleted in Phase 1. Deletions are soft; edits create revisions.
8. When a rule here conflicts with a convenience, the rule wins. Propose a change instead of silently deviating.

---

## 1. Product overview

A mobile app (Android first, Flutter) that lets a group of friends track shared spending on trips, shared housing, and outings, and shows **who owes whom** at the end. All interaction happens inside the app (no WhatsApp/chat integration). Primary language: Egyptian Arabic (RTL), secondary: English. Default currency: EGP.

Core promise: record who paid what and for whom, and always show correct balances and the fewest practical transfers to settle up.

### 1.1 Goals
- Correct, explainable balances (every number traceable to expenses).
- Very fast expense entry, including multiple payers and restaurant bills with optional service charge and tax.
- Low running cost (a single small VPS; no paid third-party services required in Phase 1).

### 1.2 Non-goals (whole project)
- Holding, transferring, or processing money. Settlement is recorded manually.
- Bank/wallet/InstaPay API integrations.
- Live chat / messaging.

---

## 2. Glossary

| Term | Meaning |
|---|---|
| Group | A trip/housing/outing container with members, expenses, settlements. DB table: `expense_groups`. |
| Member | A person inside a group. May be a **ghost member** (name only, no account). |
| Organizer / Owner | The user who created the group. In Phase 1 the only user with access. |
| Expense | A spending event: one or more payers, split among participants. |
| Payer | A member who paid part/all of an expense. |
| Participant | A member who owes a share of an expense. |
| Split type | `EQUAL`, `EXACT`, `ITEMIZED` (Phase 1). |
| Net balance | Per member: total paid − total owed ± settlements. Positive = is owed money; negative = owes money. |
| Settlement | A recorded real-world transfer from one member to another. |
| Minor units | Integer smallest currency unit (piasters). |
| bps | Basis points. 1200 bps = 12.00%. |

---

## 3. Scope

### 3.1 Phase 1 — IN scope ("Organizer Mode")
**Account**
- Sign in with Google **or with a username + password** (A59, A64, ADR-007, ADR-008). Basic profile (display name). Sign out. Arabic RTL UI.

**Groups & members**
- Create group (name, type: TRIP/HOUSING/OUTING/OTHER, currency code, default EGP). List groups. Edit name. Delete group only if it has no expenses/settlements.
- Add members by name (ghost members), any time. Rename member. Remove member only if they have no transactions. The creator of a group is automatically its first member, linked to their account (so the app can show "you"); that member can be renamed but not removed (Decision A53/A54).

**Expenses**
- Create/edit/soft-delete expenses with: title, total, date, **one or more payers (each with an amount)**, and a split.
- Split types: **EQUAL** (all members or a selected subset), **EXACT** (explicit amounts per member), **ITEMIZED** (restaurant bill).
- **Multiple payers**: any number of payers, amounts must sum to the expense total. A payer does not have to be a participant.
- **Itemized restaurant bill with optional service charge and optional tax**: the user may enable *service only*, *tax only*, *both*, or *neither*, and enters each percentage. Details in section 7.4.
- Participants of each expense are **snapshotted** at creation (an "All" selection is resolved to the explicit member list at that moment).
- Rounding rule (largest remainder) so totals always match exactly.
- Edit history (revisions stored), soft delete.
- Live preview endpoint for entry screens.

**Balances & settlements**
- Net balance per member.
- Simplified "who pays whom" list.
- Record a settlement (organizer records that A paid B an amount). Partial amounts allowed. Soft-delete a settlement.

**Platform**
- Idempotency for create operations. Integer money. Optimistic concurrency (`version`) on edits.

### 3.2 Phase 1 — OUT of scope (do not build)

> The **standalone release** (`STANDALONE_SPEC.md`, A121-A150) overrides this list for exactly its own features (categories, My share, trip recap, pool, calculator, reminder tones, receipt OCR, backup, offline local mode), only while running a standalone prompt (AGENTS.md rule 11).
Invites/links/codes, member↔account linking, roles, member "left" status, push notifications, payment handles (InstaPay/wallet), two-sided settlement confirmation, disputes, percent/shares splits, refunds, categories, trip summary/statistics, detailed (non-simplified) view, closing a trip, exports, receipt images/OCR, offline mode, multi-currency conversion, recurring bills, sub-groups, kitty, subscriptions/paywall, iOS, account deletion UI, email/password auth.

---

## 4. Roadmap

| Phase | Name | Content | Rough effort at 10–12 h/week* |
|---|---|---|---|
| 0 | Validation & Design (parallel to Phase 1 start) | 10 user interviews; UI/UX design (see STITCH_PROMPTS.md); clickable prototype; competitor check | 2 weeks |
| **1** | **Organizer Mode (this spec)** | Everything in 3.1 | 9–11 weeks |
| 2 | Collaboration | Invite by link/code; link ghost member to account; roles (admin/member) and edit permissions; member leaves ("LEFT"); two-sided settlement ("I paid"/"Received"), partial payments, disputed state; payment handles (InstaPay/wallet) with copy button; push notifications (FCM) and "Remind" button; activity feed; version-conflict UI; account deletion | 6–8 weeks |
| 3 | Trip power features & release | Percent and shares split; refunds; categories; trip summary; detailed balances view; close trip + final statement image; duplicate-expense warning; privacy policy/ToS; Play Store release; crash reporting | 5–6 weeks |
| 4 | Offline & multi-currency | Local cache + pending-operation queue; per-trip exchange rate and per-expense override | 4–6 weeks |
| 5 | Monetization & growth | Paywall experiments (price per group or household plan — test, not decided); PDF/CSV export; receipt scanning (AI); shared kitty; recurring bills for housing groups; sub-groups; dispute button on expenses; iOS | ongoing |

\*Estimates are rough, include learning Flutter, and must be revisited after Phase 0.

### 4.1 Phase 1 milestones
- **M1** Repo + backend skeleton: Spring Boot, Postgres (Docker Compose), Flyway, OpenAPI, Google sign-in, JWT, CI.
- **M2** Groups & members API + authorization (owner only).
- **M3** `engine` module: allocation, equal/exact/itemized, balances, simplification — **with all tests in section 10 passing**.
- **M4** Expenses API: multi-payer, itemized, preview, revisions, soft delete, idempotency, version checks.
- **M5** Balances & settlements API.
- **M6** Flutter app: auth, groups, members, add/edit expense (all types), expense details, balances, record settlement. (Can start after M2 using the generated OpenAPI client.)
- **M7** Hardening: error handling, logging, backups, deploy to a single VPS, internal test with real groups.

---

## 5. Architecture & tech stack

### 5.1 Backend
- Java 21, Spring Boot 3.x (latest stable), Spring Web, Spring Security, Spring Data JPA, Bean Validation.
- PostgreSQL + Flyway migrations (no schema auto-generation).
- springdoc-openapi (the OpenAPI spec is the contract; the Dart client is generated from it).
- Testing: JUnit 5, AssertJ, jqwik (property tests), Testcontainers (Postgres) for integration tests.
- Auth: client obtains Google ID token → `POST /auth/google` → backend verifies the token → issues own short-lived access JWT + rotating refresh token (stored hashed).
- Packaging: Docker; deploy on a single small VPS with a reverse proxy (HTTPS). CI via GitHub Actions (or Azure DevOps).

### 5.2 Mobile
- Flutter (Android first) + Dart. State management: Riverpod. Navigation: go_router. HTTP: dio with generated client. Localization: `intl` with ARB files (ar primary, en secondary), full RTL.
- Feature-first folder structure: `features/auth`, `features/groups`, `features/members`, `features/expenses`, `features/balances`, `features/settlements`, `core/`.
- Online-only in Phase 1 (clear error + retry UI when offline).

### 5.3 Repository layout (monorepo)
```
/backend
  /src/main/java/<base>/api        (controllers, DTOs)
  /src/main/java/<base>/domain     (entities)
  /src/main/java/<base>/engine     (PURE Java: no Spring, no JPA)
  /src/main/java/<base>/service
  /src/main/java/<base>/security
  /src/main/resources/db/migration
/mobile
/docs   (this spec, design exports, API notes)
```

---

## 6. Data model (PostgreSQL)

All ids are UUIDs. All timestamps are `timestamptz` (UTC). All money columns are `bigint` minor units.

```sql
CREATE TABLE users (
  id uuid PRIMARY KEY,
  auth_provider text NOT NULL,            -- 'GOOGLE'
  auth_subject text NOT NULL,             -- provider user id
  email text,
  display_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (auth_provider, auth_subject)
);

CREATE TABLE expense_groups (
  id uuid PRIMARY KEY,
  owner_user_id uuid NOT NULL REFERENCES users(id),
  name text NOT NULL,
  type text NOT NULL,                     -- TRIP | HOUSING | OUTING | OTHER
  currency_code char(3) NOT NULL DEFAULT 'EGP',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  version int NOT NULL DEFAULT 1
);

CREATE TABLE members (
  id uuid PRIMARY KEY,
  group_id uuid NOT NULL REFERENCES expense_groups(id),
  display_name text NOT NULL,
  user_id uuid REFERENCES users(id),      -- null = ghost member; the group owner is member #1 and linked (B9, A53)
  sort_order int NOT NULL,                -- stable ordering; used by tie-break rules
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_members_group_name ON members (group_id, lower(display_name));

CREATE TABLE expenses (
  id uuid PRIMARY KEY,
  group_id uuid NOT NULL REFERENCES expense_groups(id),
  title text NOT NULL,
  split_type text NOT NULL,               -- EQUAL | EXACT | ITEMIZED
  total_minor bigint NOT NULL CHECK (total_minor > 0),
  expense_date date NOT NULL,
  -- itemized-only fields (null otherwise)
  subtotal_minor bigint,
  service_bps int CHECK (service_bps IS NULL OR service_bps BETWEEN 0 AND 10000),
  service_minor bigint,
  tax_bps int CHECK (tax_bps IS NULL OR tax_bps BETWEEN 0 AND 10000),
  tax_minor bigint,
  tax_base text,                          -- SUBTOTAL | SUBTOTAL_PLUS_SERVICE
  adjustment_minor bigint,                -- signed, optional
  created_by_user_id uuid NOT NULL REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  version int NOT NULL DEFAULT 1
);

CREATE TABLE expense_payers (
  expense_id uuid NOT NULL REFERENCES expenses(id),
  member_id uuid NOT NULL REFERENCES members(id),
  amount_minor bigint NOT NULL CHECK (amount_minor > 0),
  PRIMARY KEY (expense_id, member_id)
);

-- Final resolved participants and amounts (the snapshot). "All" is resolved here.
CREATE TABLE expense_splits (
  expense_id uuid NOT NULL REFERENCES expenses(id),
  member_id uuid NOT NULL REFERENCES members(id),
  owed_minor bigint NOT NULL CHECK (owed_minor >= 0),
  -- itemized breakdown (null otherwise); owed = items + service + tax + adjustment
  items_minor bigint,
  service_minor bigint,
  tax_minor bigint,
  adjustment_minor bigint,
  PRIMARY KEY (expense_id, member_id)
);

CREATE TABLE expense_items (
  id uuid PRIMARY KEY,
  expense_id uuid NOT NULL REFERENCES expenses(id),
  name text NOT NULL,
  amount_minor bigint NOT NULL CHECK (amount_minor > 0),
  sort_order int NOT NULL
);

CREATE TABLE expense_item_assignees (
  item_id uuid NOT NULL REFERENCES expense_items(id),
  member_id uuid NOT NULL REFERENCES members(id),
  PRIMARY KEY (item_id, member_id)
);

CREATE TABLE expense_revisions (
  id uuid PRIMARY KEY,
  expense_id uuid NOT NULL REFERENCES expenses(id),
  version int NOT NULL,
  change_type text NOT NULL,              -- CREATE | UPDATE | DELETE
  snapshot jsonb NOT NULL,                -- full expense incl. payers, splits, items
  changed_by_user_id uuid NOT NULL REFERENCES users(id),
  changed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (expense_id, version)
);

CREATE TABLE settlements (
  id uuid PRIMARY KEY,
  group_id uuid NOT NULL REFERENCES expense_groups(id),
  from_member_id uuid NOT NULL REFERENCES members(id),   -- the one who paid
  to_member_id uuid NOT NULL REFERENCES members(id),     -- the one who received
  amount_minor bigint NOT NULL CHECK (amount_minor > 0),
  settled_on date NOT NULL,
  note text,
  created_by_user_id uuid NOT NULL REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CHECK (from_member_id <> to_member_id)
);

CREATE TABLE idempotency_keys (
  user_id uuid NOT NULL REFERENCES users(id),
  key text NOT NULL,
  endpoint text NOT NULL,
  request_hash text NOT NULL,
  response_status int NOT NULL,
  response_body jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, key)
);
```

Notes:
- All members referenced by an expense/settlement must belong to the same group (enforce in service layer; add integrity tests).
- Balances are always **computed** from non-deleted expenses and settlements, never stored.

---

## 7. Business rules (the engine)

### 7.1 Money and rounding
- All amounts: `long` minor units. Percentages: integer bps.
- **Largest Remainder Method (LRM)** is the single allocation primitive: allocate an integer `total` across members proportionally to integer weights so that the allocated parts sum exactly to `total`.
  1. For each member compute exact share = `total × weight_i / Σweights` (use `BigInteger`/`Math.multiplyExact`; never floating point).
  2. Give each member `floor(exact share)`.
  3. Distribute the remaining minor units, one each, to members with the largest fractional remainders.
  4. **Tie-break:** lower `sort_order` first.
  5. If `Σweights == 0`, allocate equally (weights all 1).
  6. For negative totals (adjustment), allocate `abs(total)` and apply the sign.
- Percentage-of-amount computation: `round_half_up(amount × bps / 10000)` to minor units.

### 7.2 EQUAL split
Input: total, list of participant member ids (≥ 1; "All" is resolved to the current member list by the client or server before saving). Allocation: LRM with weight 1 each. Extra minor units go to participants with lower `sort_order`.

### 7.3 EXACT split
Input: list of (member, amount). Rules: each amount ≥ 0, at least one > 0, Σ amounts must equal the expense total, otherwise `SPLIT_TOTAL_MISMATCH`.

### 7.4 ITEMIZED split (restaurant bill)
Input:
- `items[]`: `{ name, amountMinor, assigneeMemberIds[] }` (≥ 1 assignee per item; amount > 0).
- `service`: optional `{ bps }` — enabled only if present.
- `tax`: optional `{ bps, base }` — enabled only if present. `base` ∈ `SUBTOTAL` | `SUBTOTAL_PLUS_SERVICE` (default `SUBTOTAL_PLUS_SERVICE`; see Decision Log A1).
- `adjustmentMinor`: optional signed integer (e.g. restaurant rounding or tip), default 0.

Algorithm:
1. **Item shares:** each item is split equally among its assignees using LRM (weight 1, tie by `sort_order`). `itemsMinor[m]` = Σ of member m's item shares. `subtotal = Σ items`.
2. **Service:** if enabled, `serviceTotal = round_half_up(subtotal × service_bps / 10000)`; allocate to members by LRM with weights `itemsMinor[m]`. Otherwise 0.
3. **Tax:** if enabled, `taxBaseTotal = subtotal` or `subtotal + serviceTotal` per `base`; `taxTotal = round_half_up(taxBaseTotal × tax_bps / 10000)`; allocate by LRM with weights = each member's own base (`itemsMinor[m]` or `itemsMinor[m] + serviceMinor[m]`). Otherwise 0.
4. **Adjustment:** if ≠ 0, allocate by LRM with weights `itemsMinor[m]` (sign applied after).
5. `owed[m] = items + service + tax + adjustment`. `total = subtotal + serviceTotal + taxTotal + adjustment` must be > 0.
6. Members with `owed == 0` are not stored as participants.
7. Payers' amounts must sum to `total` (see 7.5).

Any combination of service/tax on/off must work: service only, tax only, both, neither.

### 7.5 Payers
- ≥ 1 payer. Each amount > 0. No duplicate member. Σ payer amounts == expense total, otherwise `PAYERS_TOTAL_MISMATCH`.
- Payers need not be participants.

### 7.6 Balances
For member `m`:
```
net[m] = Σ paid[m] (non-deleted expenses)
       − Σ owed[m] (non-deleted expenses)
       + Σ settlement amounts where from == m
       − Σ settlement amounts where to == m
```
Invariant: `Σ net[m] == 0` for every group at all times. Positive = is owed; negative = owes.

### 7.7 Simplification (who pays whom)
Deterministic greedy:
1. Creditors = members with net > 0; debtors = net < 0.
2. Repeat: take the creditor with the largest net (tie: lower `sort_order`) and the debtor with the most negative net (tie: lower `sort_order`); create transfer `debtor → creditor` of `min(creditor.net, −debtor.net)`; update both; remove zeros.
3. Stop when all nets are 0.
This is not guaranteed to be the global minimum number of transfers; that is acceptable.

### 7.8 Settlements
A settlement `from → to, amount` is a recorded real-world payment. Amount may be partial and may exceed the suggested transfer (the excess flips the balance). It affects balances per 7.6. Soft-deleting a settlement reverses its effect.

### 7.9 Edits and deletes
- Edit = replace the expense's payers/splits/items atomically, increment `version`, write a revision with the full snapshot. Requires the client to send the current `version` (`If-Match`); mismatch → `VERSION_CONFLICT` (409).
- Delete = set `deleted_at`, increment `version`, write a revision.
- Participants snapshot: editing an expense does **not** silently add members who joined later; the client must send the explicit participant list.

### 7.10 Members
- Add anytime. Name unique per group (case-insensitive). Rename allowed.
- Delete only if the member appears in no expense (payer/split/item assignee) and no settlement (including soft-deleted ones); otherwise `MEMBER_HAS_TRANSACTIONS`.
- `sort_order` assigned incrementally at creation and never reused.
- The creator of a group is created as member #1 (linked to their account, named after their profile, cut to 40 characters). It can be renamed; deleting it is refused with `OWNER_MEMBER_PROTECTED`. A user is at most one member of a group (unique index). Groups created before B9 have no linked member.

---

## 8. API (REST, JSON, `/api/v1`)

### 8.1 Conventions
- Auth: `Authorization: Bearer <access JWT>`. All endpoints except the public `/auth/*` ones require it (public: `google`, `refresh`, `logout`, `register`, `login`, `password/forgot`, `password/reset`, `email/verify`; `/auth/email/verify/resend` needs a token like the rest).
- Authorization (since B10, A65-A67, ADR-009): a user reaches a group only through an ACTIVE member linked to their account and may do what their role allows. A non-member (stranger, LEFT member, unknown id) gets **404**, identical to a group that does not exist; a member whose role lacks the permission gets **403 `FORBIDDEN`**. (Phase 1 was owner-only with 404 for everyone else.)
- Money: integer minor units + group `currencyCode`. Dates: ISO-8601.
- Errors: RFC 7807 `application/problem+json` with a stable `code` field.
- Pagination: `?page=&size=` for lists; expenses sorted by `expenseDate desc, createdAt desc`.
- Optimistic concurrency: `ETag`/`If-Match` carrying the entity `version`.

### 8.2 Endpoints
```
POST   /auth/google                 { idToken } -> { accessToken, refreshToken, user }
POST   /auth/refresh                { refreshToken } -> { accessToken, refreshToken }
POST   /auth/logout                 { refreshToken }
POST   /auth/register               { username, password, displayName? } -> { accessToken, refreshToken, user }  (201)
POST   /auth/login                  { username, password } -> { accessToken, refreshToken, user }
POST   /auth/password/forgot        { email } -> 204 (always; never says whether the address has an account)
POST   /auth/password/reset         { token, newPassword } -> 204 (one-time link; ends every session)
POST   /auth/email/verify           { token } -> 204
POST   /auth/email/verify/resend    -> 204 (signed in)
POST   /me/password                 { currentPassword, newPassword } -> { accessToken, refreshToken }
GET    /me
PATCH  /me                          { displayName }
GET    /me/payment-handles
PUT    /me/payment-handles          { instapay?, wallet? }   null/blank removes; 422 names the field

POST   /groups                      { name, type, currencyCode? }
GET    /groups
GET    /groups/{gid}                (includes members and a summary, e.g. total spent)
PATCH  /groups/{gid}                { name?, type? }   If-Match
DELETE /groups/{gid}                (only if no expenses/settlements)

POST   /groups/{gid}/members        { displayName }
PATCH  /groups/{gid}/members/{mid}  { displayName }
DELETE /groups/{gid}/members/{mid}

POST   /groups/{gid}/expenses/preview   (same body as create; returns computed breakdown, saves nothing)
POST   /groups/{gid}/expenses           (Idempotency-Key required)
GET    /groups/{gid}/expenses           (paged; filter: fromDate, toDate, memberId)
GET    /groups/{gid}/expenses/{eid}
PUT    /groups/{gid}/expenses/{eid}     If-Match
DELETE /groups/{gid}/expenses/{eid}     If-Match
GET    /groups/{gid}/expenses/{eid}/revisions

GET    /groups/{gid}/balances           -> { nets: [{memberId, netMinor}], transfers: [{fromMemberId, toMemberId, amountMinor, pendingMinor, hasDispute, openSettlementIds}] }  (CONFIRMED only, A83)
POST   /groups/{gid}/settlements        { fromMemberId, toMemberId, amountMinor, settledOn, note? } (Idempotency-Key required)
GET    /groups/{gid}/settlements         ?status=PENDING|CONFIRMED|DISPUTED|CANCELLED (repeatable; default all, cancelled ones included)
# Phase 2, B13 (A83-A89): two-sided settlements. The Phase 1 DELETE /groups/{gid}/settlements/{sid} is REMOVED (A87).
POST   /groups/{gid}/settlements/{sid}/confirm   (receiver, or Owner/Admin who is not the payer) -> SettlementView
POST   /groups/{gid}/settlements/{sid}/dispute   (receiver) -> SettlementView
POST   /groups/{gid}/settlements/{sid}/cancel    (payer, or Owner/Admin) -> SettlementView

# Phase 2, B11 (A70-A76): invitations, joining, join requests, unlink
POST   /groups/{gid}/invites                     { expiresInDays?, maxUses?, requiresApproval? } -> { id, code, link, status, ... } (Idempotency-Key required; Owner/Admin)
GET    /groups/{gid}/invites                     (paged, with codes; Owner/Admin)
DELETE /groups/{gid}/invites/{iid}               (revoke; Owner/Admin)
GET    /invites/{code}                           (preview for a signed-in person: group name, inviter, count, unclaimed members; no balances)
POST   /invites/{code}/join                      { claimMemberId | newMemberName } -> 201 JOINED | 202 PENDING_APPROVAL (Idempotency-Key required)
GET    /groups/{gid}/join-requests               (pending, oldest first; Owner/Admin)
POST   /groups/{gid}/join-requests/{rid}/approve  (Owner/Admin)
POST   /groups/{gid}/join-requests/{rid}/reject   (Owner/Admin)
POST   /groups/{gid}/members/{mid}/unlink        (detach the account, keep the member; Owner/Admin) -> 204

# Phase 2, B12 (A77-A82): member lifecycle
PATCH  /groups/{gid}/members/{mid}               { displayName?, role?, status? } (at least one; see A77/A80) -> MemberDto
POST   /groups/{gid}/leave                       (the caller leaves; Owner -> 409 OWNER_MUST_TRANSFER) -> 204
POST   /groups/{gid}/transfer-ownership          { toMemberId } (Owner only) -> 204

# Phase 2, B15 (A95-A103): activity feed and in-app notification center
GET    /groups/{gid}/activity                    ?limit (1..50, default 20) &before (opaque cursor) (every ACTIVE member) -> { items: [{id, type, actorMemberId, createdAt, payload, subject}], nextBefore }
GET    /notifications                            ?limit &before -> { items: [{id, groupId, groupName, type, actorMemberId, actorName, createdAt, readAt, payload, subject}], nextBefore }
GET    /notifications/unread-count               -> { count }
POST   /notifications/read                       { ids: [<=100] | all: true } (exactly one) -> { marked, unreadCount } (not a create: no Idempotency-Key)
# Phase 2, B16 (A104-A112): notification preferences and Remind
PUT    /me/notification-prefs                    { enabled } -> { enabled } (global switch; not a create: no Idempotency-Key; read via UserDto.notificationsEnabled)
PUT    /groups/{gid}/notification-prefs          { muted } -> { muted } (any ACTIVE member for themselves; not a create; read via GroupDto.muted)
POST   /groups/{gid}/transfers/remind            { fromMemberId, toMemberId } -> 201 { fromMemberId, toMemberId, amountMinor, remindedAt, canRemindAt } (Idempotency-Key required; the creditor, or Owner/Admin; 429 REMIND_RATE_LIMITED with nextAllowedAt)
# Phase 2, B17 (A113-A120): account deletion
DELETE /me                                       { confirm: "DELETE", password? } -> 204 (password accounts must send the current password; 409 OWNER_MUST_TRANSFER with { groups: [{id, name}] }; a repeated call is 401; not a create: no Idempotency-Key)
```

### 8.3 Idempotency
Creating endpoints require header `Idempotency-Key` (client-generated UUID). Server stores `(user, key, endpoint, request_hash, response)`. Same key + same body → return the stored response (no duplicate record). Same key + different body → `IDEMPOTENCY_KEY_REUSED` (422). Keys expire after 24 hours (cleanup job).

### 8.4 Create/preview expense body (illustrative)
```json
{
  "title": "Seafood dinner",
  "expenseDate": "2026-10-18",
  "splitType": "ITEMIZED",
  "payers": [ { "memberId": "…", "amountMinor": 30000 }, { "memberId": "…", "amountMinor": 26179 } ],
  "items": [
    { "name": "Pizza", "amountMinor": 20000, "assigneeMemberIds": ["A","B"] },
    { "name": "Pasta", "amountMinor": 15000, "assigneeMemberIds": ["C"] },
    { "name": "Drinks","amountMinor": 9000,  "assigneeMemberIds": ["A","B","C"] }
  ],
  "service": { "bps": 1200 },
  "tax": { "bps": 1400, "base": "SUBTOTAL_PLUS_SERVICE" },
  "adjustmentMinor": 0
}
```
For `EQUAL`: `{ "splitType": "EQUAL", "participantMemberIds": [...] }`. For `EXACT`: `{ "splitType": "EXACT", "shares": [ { "memberId": "…", "amountMinor": … } ] }`.
`preview` response includes: `totalMinor`, `subtotalMinor`, `serviceMinor`, `taxMinor`, per-member breakdown `{ memberId, itemsMinor, serviceMinor, taxMinor, adjustmentMinor, owedMinor }`, and `payersTotalMatches` (boolean) so the UI can show a live mismatch warning.

### 8.5 Error codes
`VALIDATION_ERROR`, `PAYERS_TOTAL_MISMATCH`, `SPLIT_TOTAL_MISMATCH`, `MEMBER_NOT_IN_GROUP`, `MEMBER_HAS_TRANSACTIONS`, `DUPLICATE_MEMBER_NAME`, `OWNER_MEMBER_PROTECTED`, `FORBIDDEN` (A65), `INVALID_STATE_TRANSITION` (A84), `VERSION_CONFLICT`, `IDEMPOTENCY_KEY_REUSED`, `GROUP_NOT_EMPTY`, `NOT_FOUND`, `UNAUTHORIZED`, `USERNAME_TAKEN` (A64).

---

## 9. Mobile app — screens and flows (Phase 1)

UI design is produced separately from `STITCH_PROMPTS.md`. Required screens:

1. **Sign in** (Google).
2. **Groups list** (empty state + list with last activity and total spent).
3. **Create/edit group** (name, type, currency).
4. **Group home** with tabs: **Expenses**, **Balances**, **Members**.
5. **Add/edit member** (bottom sheet).
6. **Add/edit expense**: title, total (or computed for itemized), date, **Paid by** (single or multiple payers), **Split** (All / Selected / Exact / Itemized).
7. **Multi-payer editor**: list of payers with amounts and a running "remaining" indicator that must reach 0.
8. **Itemized bill editor**: items with assignee chips; **Service charge** toggle + % field; **Tax** toggle + % field (each independently optional); optional adjustment; live per-person breakdown from the preview endpoint; totals row.
9. **Expense details**: payers, per-person breakdown, items (if itemized), "edited" badge, edit/delete.
10. **Balances tab**: per-member net (green = is owed, red/orange = owes) and the simplified transfers list; each transfer has **Record payment**.
11. **Record payment** (bottom sheet: from, to, amount prefilled, date, note).
12. **Settings**: language (ar/en), sign out.

Client rules:
- Debounce calls to `preview` (≈300 ms) on the itemized and multi-payer screens.
- Show server validation errors inline using the `code` field.
- Generate a new `Idempotency-Key` per create action and reuse it on retries of the same action.
- Amounts are displayed with Western digits (0–9) in both languages (Decision Log A3).

---

## 10. Test vectors and acceptance criteria

All vectors use EGP minor units (1 EGP = 100). Members listed in `sort_order`.

### V1 — Basic exact split with payer not participating (the founder's example)
Members: Mohamed (M), Asem (A), Mohsen (S).
- E1: paid by M **100.00**; EXACT: A 50.00, S 50.00.
- E2: paid by S **30.00**; EXACT: A 30.00.
Expected nets: **M +100.00, S −20.00, A −80.00**.
Expected transfers: **A → M 80.00**, **S → M 20.00**.

### V2 — Settlement effect
After V1 record settlement A → M 80.00. Expected nets: M +20.00, S −20.00, A 0. Transfers: **S → M 20.00**.

### V3 — Equal split rounding
Total 100.00 equal among M1, M2, M3 → owed **33.34, 33.33, 33.33** (extra piaster to lowest `sort_order`). Sum = 100.00.

### V4 — Multiple payers
Members X, Y, Z, W. Total 500.00, payers X 300.00 and Y 200.00, EQUAL among X, Y, Z, W (125.00 each).
Nets: X +175.00, Y +75.00, Z −125.00, W −125.00.
Transfers (greedy, tie by sort_order): **Z → X 125.00**, **W → X 50.00**, **W → Y 75.00**.

### V5 — Itemized, service + tax (tax on subtotal + service)
Members A, B, C. Items: Pizza 200.00 (A,B), Pasta 150.00 (C), Drinks 90.00 (A,B,C). Service 12%, tax 14% on `SUBTOTAL_PLUS_SERVICE`, adjustment 0.
- Item shares: A 130.00, B 130.00, C 180.00; subtotal 440.00.
- Service total 52.80 → A 15.60, B 15.60, C 21.60.
- Tax total = round_half_up((440.00 + 52.80) × 14%) = **68.99** (68.992 rounded). LRM with weights 145.60 / 145.60 / 201.60 → exact shares 20.3834 / 20.3834 / 28.2232 → floors 20.38 / 20.38 / 28.22 (sum 68.98); the remaining 0.01 goes to the largest remainder; A and B tie → **A** (lower `sort_order`).
- Owed: **A 165.99, B 165.98, C 229.82**. Total **561.79**.

### V6 — Itemized, service only (12%)
Same items. Service 52.80. Owed: A 145.60, B 145.60, C 201.60. Total **492.80**.

### V7 — Itemized, tax only (14% on subtotal)
Same items, `base = SUBTOTAL`. Tax total 61.60. Owed: A 148.20, B 148.20, C 205.20. Total **501.60**.

### V8 — Itemized, neither
Owed: A 130.00, B 130.00, C 180.00. Total 440.00.

### Property-based tests (must hold for random inputs)
- LRM: allocated parts sum exactly to the total; each part differs from its exact share by less than 1 minor unit.
- Expense: `Σ owed == total`; `Σ payers == total` for accepted expenses.
- Group: `Σ net == 0` after any sequence of create/edit/delete expenses and settlements.
- Simplification: applying all returned transfers to the nets results in all zeros.
- Idempotency: replaying the same create request N times yields exactly one expense.

### Acceptance criteria for Phase 1
1. All vectors V1–V8 pass as automated tests.
2. API contract tests cover every endpoint and every error code.
3. A user can complete the full flow on a real Android device: sign in → create group → add 5 members → add an equal expense, a multi-payer expense, and an itemized expense (with service only, tax only, and both) → see correct balances → record a settlement → see updated balances.
4. Editing and deleting an expense updates balances correctly and leaves revisions in the DB.
5. Retrying a create request with a poor connection never creates duplicates.

---

## 11. Non-functional requirements

- **Security:** HTTPS only; short-lived access tokens, rotating refresh tokens stored hashed; authorization check on every group-scoped endpoint; input validation; rate limiting on auth endpoints; no sensitive data in logs.
- **Privacy / compliance:** Names and financial data are personal data under Egypt's Personal Data Protection Law No. 151 of 2020. Collect the minimum; no receipt images or contact-list access in Phase 1. A privacy policy and account-deletion flow are required before public release (Phase 2/3). Have a lawyer review before release. Verify current Google Play account-deletion requirements before publishing.
- **Performance:** p95 under ~500 ms for typical requests on the small VPS; a group of up to ~15 members and ~500 expenses must load balances quickly.
- **Reliability:** daily automated database backups; Flyway migrations are forward-only.
- **Observability:** structured logs with request ids; basic health endpoint.
- **Cost:** no paid third-party services required in Phase 1 (Google sign-in verification is free).
- **Accessibility/i18n:** full RTL, scalable text, sufficient contrast; all strings in ARB files.

---

## 12. Out-of-scope reminders for future phases (design hooks, do not build now)

> Standalone release: see `STANDALONE_SPEC.md`; its features are built under their own prompts (A121-A150).
- Members will later gain `status` (ACTIVE/LEFT) and invitations; keep member queries going through a service so this is additive.
- Roles/permissions replaced the owner-only checks in B10 (A65-A67): authorization lives in `GroupAccessService`.
- Multi-currency will add per-expense currency and exchange rates; keep `currency_code` on the group and never assume EGP in code.
- Settlements will gain status (PENDING/CONFIRMED/DISPUTED); keep it a separate table.

---

## 13. Definition of done (every task)
Code compiles; unit + integration tests pass; OpenAPI updated; migrations included; no TODOs left for in-scope behavior; money math reviewed against section 7.

---

## 14. Decision Log (assumptions to verify)

| # | Decision | Status |
|---|---|---|
| A1 | In itemized bills, tax defaults to being computed on **subtotal + service** (configurable per bill). Real Egyptian receipts may differ. **Verify against real receipts before relying on the default.** | To verify |
| A2 | The UI may prefill common values (service 12%, tax 14%) but they are always editable and optional. They are suggestions, not legal references. | To verify |
| A3 | Western digits (0–9) are used for amounts in the Arabic UI. | Assumption |
| A4 | ~~Phase 1 supports Google Sign-In only; email/password deferred to Phase 2.~~ **Superseded by A59 / ADR-007**: email + password sign-in is added next to Google. | Superseded |
| A5 | Debt simplification uses a deterministic greedy algorithm, not a guaranteed-minimum solver. | Decided |
| A6 | Phase 1 is online-only; offline queue is Phase 4. | Decided |
| A7 | Backend is authoritative for all calculations; the app uses the `preview` endpoint. | Decided |
| A8 | A payer may be a non-participant; a participant may owe without paying. | Decided |
| A9 | Tie-breaks for rounding use `sort_order` (member creation order). | Decided |
| A10 | Pricing, paywall and monetization are Phase 5 hypotheses to be tested with real users, not decided. | Open |
| A11 | V4 transfer order: applying 7.7 literally yields `Z→X 125.00`, `W→Y 75.00`, `W→X 50.00` (largest creditor is re-picked each round). Same set and amounts as the V4 text; the fixture follows the rule's order. | Decided (B3) |
| A12 | ITEMIZED: if an adjustment would make any single member's `owed` negative, the bill is rejected with `VALIDATION_ERROR` (in addition to total > 0). | Decided (B3) |
| A13 | Engine arithmetic overflow is reported as `VALIDATION_ERROR` (no new error code). EQUAL and EXACT keep participants whose share is 0; only ITEMIZED drops zero-owed members (7.4 step 6). | Decided (B3) |
| A14 | Service and tax rates are limited to 0–10000 bps (0–100%). | Assumption (B3) |
| A15 | Error codes beyond spec 8.5: `INTERNAL_ERROR` (500), `RATE_LIMITED` (429, auth endpoints), `AUTH_PROVIDER_UNAVAILABLE` (503, Google keys unreachable). | Decided (B0/B1) |
| A16 | `POST /auth/google` is naturally idempotent and does not use `Idempotency-Key` (8.3 applies to expense/settlement creates). Logout always returns 204. | Decided (B1) |
| A17 | Access JWT 15 min; refresh token 30 days, rotating, reuse revokes the whole family. Access tokens are not revocable before expiry. See ADR-002. | Decided (B1) |
| A18 | Only a Google-verified email is stored. Display name defaults to Google's name, else the email local part, else "Qesma user"; max 60 characters (code points). | Decided (B1) |
| A19 | `GET /groups` returns per group `id, name, type, currencyCode, memberCount, totalSpentMinor, lastExpenseAt` (the UI needs them); the last two are `0` / `null` until expenses exist (B4). Paged: `page` (0-based, default 0), `size` (default 20, max 100, out of range = 422), newest group first, envelope `{items, page, size, totalElements, totalPages}`. | Decided (B2) |
| A20 | `expense_groups.member_seq` counter and `UNIQUE (group_id, sort_order)` are added to the spec 6 tables so `sort_order` is never reused (7.10), even after the newest member is deleted. The counter moves under a row lock on the group and does not change `version`. | Decided (B2) |
| A21 | Group PATCH needs `If-Match: "<version>"`: missing = 428 `VALIDATION_ERROR`, malformed = 422 `VALIDATION_ERROR`, stale = 409 `VERSION_CONFLICT`. `ETag` is the quoted version. Adding members does not change it. Member rename is last-write-wins (members have no version column). | Decided (B2) |
| A22 | Group currency is fixed at creation (default EGP; any ISO 4217 code with a minor unit, case-normalized). Currencies whose minor unit is not 1/100 (e.g. JPY, KWD) are accepted but the app assumes 100 minor units per unit. | Assumption (B2), to review |
| A23 | Groups and members are hard-deleted (they are not ledger rows); deleting a group also deletes its members. Both deletes first ask `GroupUsageChecker` / `MemberUsageChecker`, which B4/B7 implement (defaults say "unused"). | Decided (B2) |
| A24 | `POST /groups` and `POST /groups/{gid}/members` do not use `Idempotency-Key` in B2 (spec 8.2/8.3 require it only for expenses and settlements); a retried group create can duplicate a group, a retried member create is stopped by the unique-name rule. Revisit with the B4 mechanism. | Decided (B2) |
| A25 | Idempotency (spec 8.3) in B4 applies to `POST /groups/{gid}/expenses` only, through a reusable `IdempotencyService`. Groups and members still do not use it (A24 stays open for B8). `Idempotency-Key` must be a UUID (case-insensitive); missing or malformed = 422 `VALIDATION_ERROR`. Keys are per user. A key reused with another body, group or endpoint = 422 `IDEMPOTENCY_KEY_REUSED`. | Decided (B4) |
| A26 | Replay returns the stored status (201) and body plus header `Idempotency-Replayed: true`. Only successful responses are stored; a failed request (4xx) can be retried with the same key. The stored `jsonb` body is content-identical to the original (formatting may differ). Keys older than 24 hours count as unused even before the hourly cleanup job removes them. Same-key requests are serialized by a transaction-scoped PostgreSQL advisory lock, then the group row lock. | Decided (B4) |
| A27 | `GET /groups` and `GET /groups/{gid}`: `totalSpentMinor` = sum of `total_minor` of non-deleted expenses; `lastExpenseAt` = newest `created_at` of non-deleted expenses (null when none). `PATCH /groups/{gid}` now returns the same full body as GET (real members and totals). | Decided (B4) |
| A28 | EQUAL with `participantMemberIds` omitted means all current members, resolved by the server and stored as explicit `expense_splits` rows (zero-owed participants included, A13); an explicit empty list is 422. Members added later are never added to existing expenses. EQUAL/EXACT require `totalMinor`. | Decided (B4) |
| A29 | Expense input limits: title 1–100 characters (code points, trimmed); `expenseDate` between 2000-01-01 and 2100-12-31; at most 100 payers, participants or shares per request. (ITEMIZED was rejected until B5; see A31.) | Assumption (B4), to review |
| A30 | Delete rules use the ledger: a member that is a payer or participant of any expense, and a group with any expense, soft-deleted ones included, cannot be deleted (`MEMBER_HAS_TRANSACTIONS`, `GROUP_NOT_EMPTY`). Added error codes `PAYERS_TOTAL_MISMATCH`, `SPLIT_TOTAL_MISMATCH`, `MEMBER_NOT_IN_GROUP` (422) and `IDEMPOTENCY_KEY_REUSED` (422) are all from spec 8.5. | Decided (B4) |
| A31 | ITEMIZED create/preview body: `items[{name, amountMinor, assigneeMemberIds[]}]`, optional `service {bps}`, optional `tax {bps, base?}` (base default `SUBTOTAL_PLUS_SERVICE`, A1), optional signed `adjustmentMinor` (default 0). `totalMinor` is optional for ITEMIZED (the engine computes it); when given it must equal the computed total, otherwise `SPLIT_TOTAL_MISMATCH`. Service and tax are independent; a rate of 0 bps is "enabled with 0", absent is "off". Limits: at most 100 items, 100 assignees per item, item name 1–100 characters. | Assumption (B5), to review |
| A32 | `POST /groups/{gid}/expenses/preview` uses the same validation and the same calculator as create (`ExpenseCalculator`), needs no `Idempotency-Key`, takes no group lock and writes nothing. `payers` may be empty in preview (shares can be shown before payers are chosen); `payersTotalMatches` is false then and whenever the payers do not add up. Unknown or foreign members in payers/assignees are still `MEMBER_NOT_IN_GROUP`. | Decided (B5) |
| A33 | Response shape: expenses gain `items[{id, name, amountMinor, assigneeMemberIds[]}]` and `charges {subtotalMinor, service{bps, amountMinor}\|null, tax{bps, base, amountMinor}\|null, adjustmentMinor}`; each `shares[]` entry gains `itemsMinor/serviceMinor/taxMinor/adjustmentMinor`. All of these are `null` for EQUAL/EXACT. Preview returns `{totalMinor, subtotalMinor, serviceMinor, taxMinor, adjustmentMinor, members[], payersTotalMatches}` with the same member shape; its itemized-only totals are `null` for EQUAL/EXACT. | Assumption (B5), to review |
| A34 | ITEMIZED splits store only members who owe more than 0 (spec 7.4 step 6; EQUAL/EXACT keep zero rows, A13). A member who is an item assignee but owes 0 after rounding is not a participant, yet still counts as "used": they cannot be deleted (`MEMBER_HAS_TRANSACTIONS`). | Decided (B5) |
| A35 | Schema (V6): `expense_items`, `expense_item_assignees`, and CHECKs that an ITEMIZED expense carries all charges and `total = subtotal + service + tax + adjustment`, no service/tax amount without its rate, a tax base exactly when there is a tax rate, and that a split's breakdown is all-or-nothing and sums to `owed_minor`. "Items sum to subtotal" and "members belong to the group" remain engine/service rules proven by tests. | Decided (B5) |
| A36 | Abuse protection: every `/api/v1` request body is capped at 64 KB (declared length checked up front; undeclared/chunked bodies counted while read). Over the cap answers 413 `application/problem+json` with code `VALIDATION_ERROR` (no new error code). The preview endpoint has no per-user rate limit yet (the limiter covers `/auth/**` only); to revisit in B8. | Assumption (B5), to review |
| A37 | `PUT /groups/{gid}/expenses/{eid}` and `DELETE …/{eid}` require `If-Match: "<version>"` (missing 428, malformed 422, stale 409 `VERSION_CONFLICT`). They take no `Idempotency-Key` (spec 8.3 covers creates only): the version is the retry guard, so a repeated PUT with the old version is a 409 and a repeated DELETE is a 404. The check and the write are atomic because both run under the group-row lock that every ledger writer takes; `UNIQUE (expense_id, version)` on revisions is the backstop. | Decided (B6) |
| A38 | DELETE of an already deleted expense (and PUT on it) is a plain `404 NOT_FOUND`, not an idempotent success: a soft-deleted expense is no longer reachable. Soft-deleted expenses leave lists, detail and group totals, but still block deleting their members and group (A30). | Decided (B6) |
| A39 | PUT replaces the whole expense through the same validator, engine and error codes as create, and may change the split type (EQUAL/EXACT/ITEMIZED). Payers, shares and items are replaced (new item ids); history lives in `expense_revisions`. The client must send the explicit participant list; an omitted EQUAL list still means "all current members", exactly like create. | Decided (B6) |
| A40 | `expense_revisions` (V7): one row per CREATE (version 1), UPDATE and DELETE, written in the same transaction as the change; `snapshot` is the full expense JSON (the same representation the API returns) as it was after the change. `GET …/{eid}/revisions` lists them oldest first, as a plain array, and keeps working after the expense was deleted. Expenses created before V7 (development data only) have no CREATE revision. | Decided (B6) |
| A41 | `ETag: "<version>"` is returned on GET detail, on create (also on idempotent replays), on PUT (200) and on DELETE (204, the new version). List items carry `version` in the body but no per-item ETag. PUT/DELETE have no rate limit yet (B8). | Assumption (B6), to review |
| A42 | Balances are computed on demand from ONE grouped SQL statement that only adds up per-member sums (paid, owed, settlements sent, settlements received) over live rows; the rule `net = paid − owed + sent − received`, the zero-sum check and the simplification are the engine's (`BalanceCalculator.netsFromTotals`, `Simplifier`). One statement plus a REPEATABLE READ read-only transaction means a concurrent write cannot skew the result. If Σ net ≠ 0 the call fails with 500 and an ERROR log (`balance.invariant_violated`) rather than returning wrong money. The row-based `BalanceCalculator.nets` stays as the reference used by tests. | Decided (B7) |
| A43 | Money cap (review CP2-001): every stored amount is between its natural minimum and 10^12 piasters (10 billion EGP): expense total, payer, share, item, itemized computed total, adjustment (±), settlement. Enforced in the validators/calculator (422 `VALIDATION_ERROR`) and as CHECK constraints (V8). Group sums can then overflow `long` only beyond ~9 million expenses per group (accepted; balances would fail loudly). | Decided (B7) |
| A44 | `POST /groups/{gid}/settlements` requires `Idempotency-Key` and uses the same machinery as expenses (advisory key lock, group lock, stored response, replay header). Amount 1..cap, `settledOn` 2000-01-01..2100-12-31, optional note ≤ 200 characters (trimmed, blank = none). Partial and larger-than-suggested amounts are allowed (7.8). Both members must belong to the group (`MEMBER_NOT_IN_GROUP`); from = to is a `VALIDATION_ERROR`. | Decided (B7) |
| A45 | `DELETE /groups/{gid}/settlements/{sid}` is a soft delete without `If-Match` (settlements have no version and no revisions); deleting an already deleted settlement is a plain 404. `GET …/settlements` is paged (default 20, max 100), newest `settledOn` first, deleted ones not listed. | Decided (B7) |
| A46 | Delete rules (7.10, 3.1) now include settlements: a member on either side of any settlement, deleted ones included, cannot be deleted (`MEMBER_HAS_TRANSACTIONS`); a group with any settlement cannot be deleted (`GROUP_NOT_EMPTY`). | Decided (B7) |
| A47 | `GET /groups/{gid}/balances` returns `{nets:[{memberId, netMinor}], transfers:[{fromMemberId, toMemberId, amountMinor}]}`: every member in sort order (zeros included), positive = is owed; transfers are the deterministic greedy suggestion of 7.7. | Decided (B7) |
| A48 | There is no default Spring profile (review SEC-001/COR-001): starting without `SPRING_PROFILES_ACTIVE` fails immediately with an instruction (`ProfileRequiredPostProcessor`). Development uses `local,fake-auth` (+ `seed`); production sets `prod`, whose secrets have no defaults. | Decided (B8) |
| A49 | `docs/openapi.json` (OpenAPI 3.0.1) is generated by `OpenApiExportIT` and must equal the committed file (ADR-004). The document declares which response fields can be null (`nullable`/absent from `required`), makes `Idempotency-Key` and `If-Match` required where the API needs them, lists the error codes of every operation and states that `*Minor` fields are integer piasters. | Decided (B8) |
| A50 | Observability: RED metrics are Micrometer's `http.server.requests` (per URI template, status and outcome). In `prod` actuator `health`, `info` and `metrics` run on management port 8081, not published and not routed by the proxy; readiness includes the database, liveness does not. Locally actuator stays on the API port (`health`, `info`). | Decided (B8) |
| A51 | Request/response objects that carry credentials (`GoogleLoginRequest`, `RefreshRequest`, `AuthResponse`, `TokenResponse`) redact themselves in `toString`, so raising a framework log level cannot print a token (invariant 10; test `NoSensitiveDataInLogsIT`). | Decided (B8) |
| A53 | The creator of a group is created as its first member (member #1, `sort_order` 1, `members.user_id` = creator, named after their profile cut to 40 code points, "Me" if blank), in the same transaction as the group. This lets the app know "who am I in this group" (the "(you)" label, "your share", "you are owed / you owe") without a new concept: Phase 2 invitations will link further members the same way. It amends the earlier statement that all Phase 1 members are ghosts. The member counts as a normal member everywhere (equal splits "among all members", balances, member counts). | Decided (B9) |
| A54 | The owner's member can be renamed but not deleted: `409 OWNER_MEMBER_PROTECTED` (new error code beyond spec 8.5, like A15). Deleting a group (only possible while it has no expenses or settlements) removes it with the other members. | Decided (B9) |
| A55 | No backfill: groups created before B9 have no linked member (only local development data exists). V9 adds the unique index `(group_id, user_id) WHERE user_id IS NOT NULL` so a user is at most one member of a group. For such groups `yourMemberId` and `yourNetMinor` are null. | Decided (B9) |
| A56 | `yourNetMinor` on `GET /groups` items and `GET /groups/{gid}`: the caller's own balance in that group (`paid - owed + sent - received`, positive = owed to them), in integer piasters of the group's currency, null without a linked member. Computed in ONE SQL statement per request (page) that only adds sums; the rule is the engine's `BalanceCalculator.memberNet`. Clients must not add amounts of groups with different currencies. | Decided (B9) |
| A57 | `MemberDto.isYou` (boolean) is computed by the server; `GroupDto.yourMemberId` is the caller's member id. No account id is ever exposed and no request body can set any of these (tested). `POST /groups` now answers with the full group including the owner member. | Decided (B9) |
| A58 | OpenAPI fidelity: the generated document must declare the real success status of every operation (201 for creates, 204 for deletes) and document `Location`, `ETag` and `Idempotency-Replayed` headers; `ApiContractCoverageIT` fails if the real 2xx statuses differ from the declared ones. Found in review: B8 had declared 200 for four operations that answer 201/204. | Decided (B9) |
| A59 | Email + password sign-in is added next to Google (reverses A4; ADR-007). The normalized email is the account subject (`auth_provider = 'PASSWORD'`); BCrypt through Spring Security (no new dependency); password 8 characters to 72 UTF-8 bytes, common passwords refused. Google and password accounts are never merged: registering an address used by a Google account is `409 EMAIL_ALREADY_USED`. | Decided (BA1); **identifier amended by A64** (username, not email) |
| A60 | Every sign-in failure (unknown email, wrong password, locked, Google-only account) is the same `401 UNAUTHORIZED`; an unknown email still spends one hash comparison. 5 consecutive failures lock the account 15 minutes (still 401). Registration reveals whether an email is registered (accepted risk until verification gates sign-up). A retry of `/auth/register` with the same email and password signs the user in (201). | Decided (BA1); **identifier amended by A64** (username, not email) |
| A61 | `POST /me/password`: a wrong current password is `422 VALIDATION_ERROR` (not 401); success ends every other login session and returns fresh tokens for this one. Google accounts have no password (`UserDto.hasPassword` false) and get 422. | Decided (BA1); **identifier amended by A64** (username, not email) |
| A62 | Password reset and email verification use one-time opaque tokens (only the SHA-256 is stored; reset 30 minutes, verify 24 hours; a new link replaces the old one; consumption is one atomic UPDATE). Reset ends every session and also verifies the address. Sending goes through the `MailSender` interface: the default sends nothing, so **forgot-password cannot deliver in production until an SMTP implementation is added with its own ADR**. | Decided (BA1); **identifier amended by A64** (username, not email) |
| A63 | `UserDto` gains `hasPassword` and `emailVerified` (Google accounts are verified). Request objects carrying credentials redact themselves in `toString` (A51). `EMAIL_ALREADY_USED` (409) is a new error code beyond spec 8.5. | Decided (BA1); **identifier amended by A64** (username, not email) |
| A64 | Password accounts are identified by a **username** (3 to 30 characters: letters of any script, digits, dots, hyphens, underscores; case-insensitive; no `@`; a few reserved names), not an email (ADR-008; amends A59-A63). A taken name is `409 USERNAME_TAKEN` (replaces `EMAIL_ALREADY_USED`). No email is collected; a forgotten password cannot be recovered until optional email + a mail provider exist. The emailed-link endpoints stay, dormant, for accounts that have an address on file. `UserDto.username` is new. | Decided (BA2) |
| A52 | Deployment is one VPS with Docker Compose and Caddy (ADR-005); backups are a daily `pg_dump` with a tested restore (`scripts/test-restore.sh`). Dependency scanning is Trivy + Dependabot in CI (ADR-003). Backups live on the same host until copied off by the operator. | Decided (B8) |
| A65 | Roles (Phase 2, B10, ADR-009): a caller reaches a group only through an ACTIVE member linked to their account. Not a member, a LEFT member or an unknown group: `404 NOT_FOUND` with the identical body (IDOR defense unchanged). A member whose role lacks the permission: `403 FORBIDDEN` (new error code beyond 8.5, like A15). Precedence: 401, 404, 403, then validation/conflict. | Decided (B10) |
| A66 | `members.role` (`OWNER`/`ADMIN`/`MEMBER`) is the single authority for ownership; exactly one OWNER per group (partial unique index; an owner is linked and ACTIVE, CHECK). `expense_groups.owner_user_id` stays as the immutable creator and is no longer used for authorization. `members.status` (`ACTIVE`/`LEFT`) with `joined_at`/`left_at` exists from V12; a LEFT member is treated like a stranger (404) until B12 adds leaving. | Decided (B10) |
| A67 | Phase 1 operations map to permissions: reads, expense preview, expense and settlement creation for every member; edit group for Owner/Admin; delete group (empty only) for Owner; add/rename/delete member for Owner/Admin (deleting a linked member stays `409 OWNER_MEMBER_PROTECTED` after the 403 check); edit/delete an expense and delete a settlement: the creator (`created_by_user_id`) or Owner/Admin. One `Role -> Permission` table, one component (`GroupAccessService`). | Decided (B10) |
| A68 | V12 aborts with a clear error if any group has no member linked to its creator (groups created before B9, see A55), so no data is silently orphaned; delete or re-seed such local data first. No backfill. | Decided (B10) |
| A69 | `GET /groups` lists every group where the caller has an ACTIVE member; `memberCount` counts ACTIVE members; `GroupSummaryDto`/`GroupDto` gain `yourRole`, `MemberDto` gains `role`, `status`, `hasAccount` (never an account id). The list query joins the caller's member inside one statement (no per-group check). `YourNetQuery` only sums the caller's own member rows. | Decided (B10) |
| A70 | Invitations (Phase 2, B11): **one secret per invite**, the 8-character code (alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, ~2^40, from `SecureRandom`, stored normalised), typed by hand and also the end of the link `qesma.invites.link-base` + code. Supersedes the two-secret (code + hashed link token) design of PHASE2_SPEC 4: a token would sit in the stored create response for 24 h and could not be shown again to admins. Guessing is limited by expiry (1-30 days, default 7), revoke, a per-IP limit (30/min) and a per-user cap on failed lookups (10 per 15 min). The code is never logged, tagged in a metric, echoed in a message or part of a request hash. | Decided (B11) |
| A71 | `GET /invites/{code}` and `POST /invites/{code}/join` need a signed-in user but **no group authorization** (the code is the capability). The preview shows only group name, type, the inviter's member name, the active member count, the unclaimed members (id + name), `requiresApproval`, expiry and the caller's state (NONE, PENDING_APPROVAL, ALREADY_MEMBER): no balances, no expense counts, no accounts. Unknown code 404; expired or used up 410 `INVITE_EXPIRED`; revoked 410 `INVITE_REVOKED` (revoked wins). New codes `INVITE_EXPIRED`, `INVITE_REVOKED`, `ALREADY_MEMBER`, `MEMBER_ALREADY_CLAIMED`. | Decided (B11) |
| A72 | Join is one transaction under the lock order idempotency lock, invite row (`FOR UPDATE`), group row. Claiming a ghost is a conditional UPDATE (`user_id IS NULL`), so of parallel claims exactly one wins; `(group_id, user_id)` and the member-name unique indexes are the last defense (the former maps to 409 `ALREADY_MEMBER`). `use_count` only grows on JOINED/APPROVED and `CHECK use_count <= max_uses` backs it. Replays answer with the stored result (also after the invite expired or was revoked). | Decided (B11) |
| A73 | Invites that require approval answer `202 PENDING_APPROVAL`; asking twice is the same request (one open request per user and invite, partial unique index). Approving re-runs the join atomically: a ghost claimed or a name taken meanwhile is 409 and the request stays PENDING so it can be rejected; approving past `max_uses` is 410 `INVITE_EXPIRED`. Pending requests stay decidable after revoke or expiry. | Decided (B11) |
| A74 | A request already decided the other way answers `409 VERSION_CONFLICT` ("already decided"); repeating the same decision returns the stored result (200). No new code before B13. | Decided (B11) |
| A75 | Unlink (`POST /groups/{gid}/members/{mid}/unlink`, Owner/Admin): the account is detached, the member, its history and balance stay, the person loses access at once and the member is claimable again; the role is reset to MEMBER. The owner's member is protected (409 `OWNER_MEMBER_PROTECTED`), only the owner may unlink an admin (403 otherwise), unlinking a member without an account is a 204 no-op. | Decided (B11) |
| A76 | New permissions `MANAGE_INVITES`, `APPROVE_JOINS`, `UNLINK_MEMBER` (Owner, Admin). B11 emits no events or notifications (B15 adds them through one recorder). `INVITE_*` per-IP limiting reuses the auth limiter class with its own prefix; the per-user cap is an in-memory component (one instance, resets on restart, same accepted limits). Known limit: a reverse proxy or Spring Security DEBUG logging that records request paths would show codes. | Decided (B11) |
| A77 | Member transitions (B12), every cell tested in `MemberLifecycleIT`. `PATCH /members/{mid}`: each present field is authorized on its own (`displayName`: MANAGE_MEMBERS = Owner/Admin; `role`: CHANGE_ROLE = Owner; `status`: MANAGE_MEMBER_STATUS = Owner/Admin), all checks run before the first write (a refused field means nothing is applied). Precedence 404, 403, then 409/422. Owner: demote ADMIN->MEMBER, promote MEMBER->ADMIN, remove (status LEFT) an Admin or Member, reactivate a LEFT member: 200. Admin: remove/reactivate a MEMBER: 200; any role change, or any change to another Admin: 403 `FORBIDDEN`. Anyone acting on the Owner's member (role or status): 409 `OWNER_MEMBER_PROTECTED` (the Owner's own PATCH too; Admin gets 403 first for role changes since the permission is missing). `role=OWNER`, unknown role/status, an empty body: 422 `VALIDATION_ERROR`. A member without an account has no role or status (422; ghosts are renamed or deleted as in Phase 1); a LEFT member cannot get a role (422). Self: Admin or Member `PATCH status=LEFT` on themselves is 422 (use `/leave`); a Member's PATCH of role/status/name is 403. The hierarchy rule (only the Owner acts on an Admin) is one method of `GroupAccessService` (also used by unlink, A75). Leaving or being removed resets the role to MEMBER (least privilege on return). Leaving with PENDING settlements or an unsettled balance is allowed: the balance stays, a warning is the client's concern. | Decided (B12) |
| A78 | LEFT semantics. A LEFT member keeps its row, its account link and its history (V14 `CHECK status <> 'LEFT' OR user_id IS NOT NULL`). Strangers and LEFT callers get the identical 404 (A65) and the group disappears from their `GET /groups`; the member stays in `GroupDto.members` (with `status`), history, balances and suggested transfers. New records may not use a LEFT member: `422 MEMBER_INACTIVE` in expense create, preview and update (payers, EQUAL participants, EXACT shares, ITEMIZED assignees; an EQUAL expense without participants means the ACTIVE members) and in settlement create (both parties). On expense update a LEFT member who is already in the stored expense (payer, share or assignee) may stay, no LEFT member can be added. Unlinking a LEFT member turns the row into an ACTIVE claimable ghost. Consequence, accepted: the balance of a LEFT member cannot be settled until an Admin reactivates them (settlements are new records). | Decided (B12) |
| A79 | Rejoin: a LEFT person redeems an invite (claim target or new name is ignored); their own LEFT row is reactivated (`ACTIVE`, `left_at` cleared, role MEMBER, `joined_at` = now) instead of `ALREADY_MEMBER` or a second row (`ux_members_group_user` stays intact). With an approval-required invite the request points at their own row and reactivation happens on approval. A reactivation by an Admin (A77) does not touch `joined_at`. | Decided (B12) |
| A80 | PATCH mass-assignment boundary: the request record has exactly `displayName`, `role`, `status` (the wire name stays `displayName`, as in Phase 1; the spec's `name` was shorthand, and renaming the operation id `renameMember` is avoided so the generated client stays compatible). `user_id`, `sort_order`, `joined_at`, `left_at` and the group are never client-settable; unknown JSON fields are ignored. | Decided (B12) |
| A81 | `POST /groups/{gid}/leave` (any ACTIVE member; the Owner holds the permission but gets `409 OWNER_MUST_TRANSFER`, also when alone) and `POST /groups/{gid}/transfer-ownership {toMemberId}` (Owner only; 204). Transfer takes the group row lock (`requireForUpdate`), validates the target (ACTIVE and linked: LEFT is 422 `MEMBER_INACTIVE`, a ghost or yourself 422 `VALIDATION_ERROR`, an unknown or foreign id 404), then runs two conditional UPDATEs in one transaction: first the old owner becomes ADMIN, then the target OWNER. The unique index `ux_members_group_owner` is non-deferrable and checked per statement, so this order means there is never more than one OWNER; no deferrable constraint is needed. Of two parallel transfers the lock lets one win and the second caller is by then an Admin (403). Both endpoints are state transitions, not creates: no `Idempotency-Key`; a repeated leave is 404, a repeated transfer 403. No `group_events` yet (B15). | Decided (B12) |
| A82 | Group delete (A23) additionally refuses (409 `GROUP_NOT_EMPTY`) a group that has any linked member besides the owner, ACTIVE or LEFT, so leaving members never make a group deletable. Groups with only ghost members and no ledger data stay deletable as in Phase 1. New permissions: `CHANGE_ROLE`, `TRANSFER_OWNERSHIP` (Owner), `LEAVE_GROUP` (all roles), `MANAGE_MEMBER_STATUS` (Owner, Admin). New codes: `MEMBER_INACTIVE` (422), `OWNER_MUST_TRANSFER` (409). | Decided (B12) |
| A83 | **Balance rule (B13).** Nets, suggested transfers, `yourNetMinor` and the group summary count settlements with `status = 'CONFIRMED'` only; PENDING and DISPUTED are informational and CANCELLED never counts. The predicate lives in ONE constant (`SettlementLedgerSql.COUNTS_IN_BALANCE`) used by `BalanceTotalsQuery` and `YourNetQuery` (pinned by `BalanceRuleFilterTest`); the engine input and `BalanceCalculator` do not change, so `Σ nets = 0` is still checked by the engine and no engine fixture vector changes. Each `transfers[]` item gains `pendingMinor` (sum of PENDING between that exact from/to pair), `hasDispute` (any DISPUTED between that pair) and `openSettlementIds` (PENDING and DISPUTED ids, oldest first), computed by ONE grouped statement (`PendingPairsQuery`) in the same snapshot; the suggested `amountMinor` is never reduced by them and the client never subtracts them itself. A pending/disputed pair without a matching suggested transfer is not shown in balances; clients find it with `GET /settlements?status=PENDING&status=DISPUTED`. | Decided (B13) |
| A84 | **State machine (B13).** One table in `SettlementTransitions` (`from, action -> to, allowed actors`): PENDING+confirm -> CONFIRMED (receiver, or Owner/Admin who is not the payer), PENDING+dispute -> DISPUTED (receiver only), PENDING+cancel -> CANCELLED (payer, or Owner/Admin), DISPUTED+confirm -> CONFIRMED (receiver, or Owner/Admin who is not the payer), DISPUTED+cancel -> CANCELLED (payer, or Owner/Admin). The payer never confirms their own payment, not even as Admin/Owner. Order of checks: not a member -> 404; caller can never do this action -> 403 `FORBIDDEN`; already in the target state -> no-op, 200 with the current view (no second timestamp); no table row -> `409 INVALID_STATE_TRANSITION` (new code); otherwise transition. Concurrency: a conditional `UPDATE ... WHERE id AND group_id AND status = <seen state>`; 0 rows -> reload and re-decide (the loser gets the idempotent view or 409), so confirm racing cancel has exactly one winner (`SettlementConcurrencyIT`). No group-row lock on transitions. | Decided (B13) |
| A85 | **Who creates what (B13).** The status is the server's decision, never the client's. Caller is the payer: receiver has an account -> PENDING; receiver is a ghost -> CONFIRMED + `recorded_by_admin` for Owner/Admin, 403 for a Member (nobody could confirm). Caller is the receiver -> CONFIRMED, `recorded_by_admin = false` (this is also how cash received from a ghost is recorded). Caller is neither -> CONFIRMED + `recorded_by_admin = true` for Owner/Admin, 403 for a Member. `created_by_member_id` is the caller's member. New permission `MANAGE_SETTLEMENTS` (Owner, Admin) replaces `DELETE_OWN_SETTLEMENT` / `DELETE_ANY_SETTLEMENT`, which are removed with the delete (A87). Checks run after validation and the membership check (422 before 403), because the role needed depends on the named members. | Decided (B13) |
| A86 | **V15 (V14 was taken by B12).** `settlements` gains `status`, `declared_at`, `confirmed_at`, `disputed_at`, `cancelled_at`, `recorded_by_admin`, `created_by_member_id`. Backfill: live Phase 1 rows -> CONFIRMED (`confirmed_at = declared_at = created_at`), Phase 1 soft-deleted rows -> CANCELLED (`cancelled_at = deleted_at`; balances already ignored them and the history is kept), every row `recorded_by_admin = true`, `created_by_member_id` from the member linked to the creator. CHECKs: status in the four values; `(status = CONFIRMED) = (confirmed_at IS NOT NULL)`; `(status = CANCELLED) = (cancelled_at IS NOT NULL)`; DISPUTED needs `disputed_at`; PENDING has neither confirmed nor disputed timestamp; legacy `deleted_at` only on CANCELLED rows (the column is no longer written). Balances before and after are identical (`SettlementStatusMigrationIT`). | Decided (B13) |
| A87 | **Phase 1 delete removed.** `DELETE /groups/{gid}/settlements/{sid}` is removed from the controller, `OPERATION_IDS`, `docs/openapi.json` and spec 8.2; `cancel` replaces it and CANCELLED rows stay in the history. A45 is amended accordingly (no soft delete of settlements any more; `GET /settlements` lists every status, cancelled included, default page 20, max 100, optional repeatable `status` filter, 422 for an unknown status). A46 now means any settlement of any status. A47 is amended by A83 (the new transfer fields). Client note: `mobile` must regenerate `qesma_api` (operation `deleteSettlement` disappears; `confirmSettlement`, `disputeSettlement`, `cancelSettlement` appear; `SettlementView` and `TransferView` gain fields) and the Phase 1 delete-payment UI (FL7, `balances_repository.dart`) is replaced by cancel in FL13. | Decided (B13) |
| A88 | `POST /groups/{gid}/settlements/{sid}/confirm|dispute|cancel`: no body, no `Idempotency-Key` (state transitions, idempotent by state like A81), 200 `SettlementView`; a settlement id of another group or an unknown id is 404. `SettlementView` gains `status`, `recordedByAdmin`, `createdByMemberId` (null for legacy rows without a linked creator), `declaredAt`, `confirmedAt`, `disputedAt`, `cancelledAt` (null for states not reached). The stored create response (A44) is the original snapshot. | Decided (B13) |
| A89 | Out of B13: notifications and events (B15), payment-proof images, transaction references, arbitration of disputes (resolution is manual by confirm or cancel). The seed (`local & seed`) adds one PENDING and one DISPUTED settlement from عاصم to محمد; they do not change the documented nets. | Decided (B13) |
| A90 | **Payment handle validation (B14).** Two optional handles per user, one value per type, `PUT /me/payment-handles` replaces both and a null, absent or blank field removes that one. Wallet: Arabic-Indic (U+0660-0669) and Extended Arabic-Indic (U+06F0-06F9) digits are mapped to ASCII, spaces, NBSP, tabs and dashes are dropped, a leading `+20` or `0020` becomes `0`; the result must match `01[0125][0-9]{8}` and is stored as those 11 digits. InstaPay: trimmed, ASCII only (checked before lower-casing, because U+212A lower-cases to `k`), 3..60 characters, exactly one `@`, matches `[a-z0-9._-]+@[a-z0-9.-]+`, stored lower case (addresses are case-insensitive). Anything else is `422 VALIDATION_ERROR` whose message names the field (`wallet` / `instapay`) and never contains the value; a non-blank value that becomes empty after stripping (for example `---`) is rejected, it does not mean "remove". The same shapes are CHECK constraints in V16, so a malformed row cannot exist even if the service is bypassed. | Decided (B14) |
| A91 | **Visibility of payment handles (B14), the single rule.** `PaymentHandleQuery` (one SQL statement, batched over all receivers) returns a member's handles only when the viewer is an ACTIVE member of that group AND the handle owner is an ACTIVE, linked member of the same group; the service has already required the viewer to be a member, the rule is repeated in SQL so the query alone can never over-share. Delivery: **only** `GET /groups/{gid}/balances` -> `transfers[].receiverHandles {instapay, wallet}` (the field is always present, null when not visible) and `GET /me/payment-handles` (the owner). A viewer gets the receiver's handles on the transfers they pay (`fromMemberId` = their member), and on every transfer when they hold the new permission `VIEW_ALL_PAYMENT_HANDLES` (Owner, Admin: they record payments on behalf of others, A85, and resolve disputes). Everyone else, the receiver included (they use `/me`), gets null; so does a ghost, LEFT or unlinked receiver, or one without handles. **Deviation from PHASE2_SPEC section 7 ("transfer/member DTOs"):** handles are NOT on `MemberDto`, because `GroupDto.members` embeds it and handles must never be in `GroupDto`; the minimal exposure is the transfer the viewer pays. Never in group lists, activity, notifications, invite previews, errors or logs (`PaymentHandleExposureIT`, `PaymentHandleLogsIT`). The statement count is constant: one handles statement for 1 or 20 transfers, none for a viewer who pays nothing (`PaymentHandleQueryCountIT`). | Decided (B14) |
| A92 | **Storage and privacy of payment handles (B14).** Plain text in `payment_handles (user_id, type, value)` with `UNIQUE (user_id, type)`; application-level encryption is not added (the values are shown to co-members anyway and a key would be new infrastructure; disk encryption is a deployment concern). The records `PaymentHandlesView` and `UpdatePaymentHandlesRequest` redact themselves in `toString` (A51 style); log lines carry the user id and the type that changed, never a value. `PaymentHandleService.deleteAllFor(userId)` exists for account deletion (B17 must call it). Personal data under PDPL No. 151/2020: **open item, lawyer review** of storage, retention and the co-member display before release. | Decided (B14); lawyer review open |
| A93 | **Endpoints (B14).** `GET /me/payment-handles` and `PUT /me/payment-handles` (`{instapay, wallet}`, 200 with the same shape), operation ids `getPaymentHandles` / `updatePaymentHandles`. PUT is a full replace, naturally idempotent, so no `Idempotency-Key` (it is not a create, spec 8.3). Two concurrent PUTs of one user are serialised by a `SELECT ... FOR UPDATE` on the `users` row, so the result is one request's pair, never a mix. **No rate limit:** the endpoints are authenticated, touch only the caller's own row, cost a constant number of statements and are no oracle about anybody else. | Decided (B14) |
| A94 | **V16 (V15 was taken by B13) and client note (B14).** `payment_handles (id, user_id FK, type, value, created_at, updated_at)` with `UNIQUE (user_id, type)`, `CHECK type IN ('INSTAPAY','WALLET')` and the two shape CHECKs of A90; new table only. `BalanceView.TransferView` gains `receiverHandles` (nullable `PaymentHandlesView`). `mobile` must regenerate `qesma_api` (new operations `getPaymentHandles`, `updatePaymentHandles`, new schema `PaymentHandlesView`, new `TransferView.receiverHandles`); the UI (FL13/FL14) only displays and copies, it never starts a transfer. | Decided (B14) |
| A95 | **Atomic emission of events and notifications (B15).** One `GroupEventRecorder` (service package, `@Transactional(propagation = MANDATORY)`) is the single write point; only services call it, always inside the business transaction, after every idempotent-replay early return and only for a real change (the settlement transition's `rows == 1` branch, the member branches that change state, a join request row that was actually inserted). It flushes the `EntityManager` first (JdbcTemplate does not see Hibernate's pending changes), then issues exactly two statements whatever the number of recipients: `INSERT group_events`, and one `INSERT INTO notifications ... SELECT gen_random_uuid(), m.user_id, ... FROM members m WHERE ...` that resolves the recipients and writes every row at once (`gen_random_uuid()` is built into PostgreSQL 16). No Hibernate batching is needed, so `hibernate.order_inserts` is not added. A recorder failure rolls back the business write (atomicity over availability: it is our own database). B16 adds its mute filter as a `NOT EXISTS` in that same statement. Counters `qesma.events{type}` and `qesma.notifications{type}`; nothing logs a payload, name or title. | Decided (B15) |
| A96 | **Schema (B15) and deviation from PHASE2_SPEC section 3.** `notifications (id, user_id, event_id, created_at, read_at)` references the event instead of copying `type`, `payload` and `group_id`: one payload, nothing to drift, the group comes from the event. `group_events.group_id` is `ON DELETE CASCADE` (an empty group may be hard-deleted, A23/A82; events are derived data, not ledger), `actor_member_id` is `ON DELETE SET NULL` (a ghost can be hard-deleted), `notifications.event_id` is `ON DELETE CASCADE` (purge, group delete), `notifications.user_id` references `users` without cascade (B17 purges explicitly). `UNIQUE (event_id, user_id)` is the one-notification-per-recipient guard and also serves the cascade lookup; `ix_group_events_feed (group_id, created_at DESC, id DESC)`, `ix_group_events_created (created_at)` (purge), `ix_group_events_actor` (FK), `ix_notifications_user (user_id, created_at DESC, id DESC)`, partial `ix_notifications_unread (user_id) WHERE read_at IS NULL`. `CHECK` on the type list (widened by B16 for `REMINDER`), on `jsonb_typeof(payload) = 'object'` and on `read_at >= created_at`. New tables only, forward-only. **V17** (V16 was taken by B14); B16's migration becomes V18. | Decided (B15) |
| A97 | **Payload (B15).** One record `EventPayload` (`@JsonInclude(NON_NULL)`) is both what is stored and the typed `payload` of the responses: `expenseId, settlementId, memberId, requestId, inviteId, fromMemberId, toMemberId` (uuid), `version` (int), `totalMinor, amountMinor` (int64 minor units), `role, previousRole` (enum). It has no free-text field, so a name or a title cannot be stored by construction (PHASE2_SPEC section 3); `EventPayloadPrivacyIT` checks every type. | Decided (B15) |
| A98 | **Event catalogue and recipients (B15).** Types: `EXPENSE_ADDED` (payers, shares and item assignees), `EXPENSE_EDITED` (old set union new set), `EXPENSE_DELETED` (previous set), `SETTLEMENT_PENDING` (the receiver), `SETTLEMENT_CONFIRMED` (recorded as confirmed, or confirmed later: both parties), `SETTLEMENT_DISPUTED` (both parties and Owner/Admins), `SETTLEMENT_CANCELLED` (both parties), `INVITE_ACCEPTED` (claim, new member or A79 rejoin; the invite's creator and Owner/Admins; actor = the joined member), `JOIN_REQUESTED` (Owner/Admins; no actor; only when a request row is inserted), `MEMBER_JOINED` (approval; the joined member and Owner/Admins; actor = approver), `MEMBER_LEFT` (leave, or removal by an admin; Owner/Admins), `ROLE_CHANGED` (the affected member), `OWNERSHIP_TRANSFERRED` (the new owner), and two types **added by B15** because PHASE2_SPEC rule 2.4 says every role/status change is an event: `MEMBER_REACTIVATED` (the affected member) and `MEMBER_UNLINKED` (feed only: the account has no access any more). Recipients are always ACTIVE members with an account (`user_id IS NOT NULL`), minus the actor's own member, each account once (one member per account per group); LEFT members and ghosts never get a row. Not events: rejecting a join request, ghost add/rename/delete, invite create/revoke, group edit, a rename. `REMINDER` is B16. | Decided (B15) |
| A99 | **Edit recipients (B15).** The previous participants are the live child rows read before the replace (`memberIdsOf`, which equal the previous revision's snapshot), so no revision JSON is parsed: a member removed by the edit and a member added by it each get one notification. | Decided (B15) |
| A100 | **Read model (B15).** Feed item `{id, type, actorMemberId, createdAt, payload, subject}`; notification item adds `groupId, groupName, actorName, readAt` (its `id` is the notification id). `subject` is the expense's current title for `EXPENSE_*` (soft-deleted expenses included, their history stays readable), the member's `display_name` (of `payload.memberId`) for member events, else null; names are resolved at read time so renames and account deletion stay consistent. In the notification center `subject` and `actorName` are resolved only while the caller still has an ACTIVE member in that group (a user who left does not learn later renames); `groupName` always. Each page is ONE SQL statement (LEFT JOINs to `expenses`, `members`, `expense_groups`); `ActivityQueryCountIT`, `ActivityQueryPlanIT`. | Decided (B15) |
| A101 | **Pagination (B15).** Keyset on `(created_at, id)` descending; `limit` 1..50 (default 20, else `422 VALIDATION_ERROR`; a non-numeric value is the standard 400); `before` is an opaque base64url cursor of `createdAtMicros:id` (timestamps are written truncated to microseconds so they round-trip exactly; a malformed cursor is `422 VALIDATION_ERROR`, never echoed). The first page uses `'infinity'` and the maximum uuid as the cursor so one SQL text serves every page and the composite index is used. Response `{items, nextBefore}` (`nextBefore` null on the last page): concrete records `ActivityPage` / `NotificationPage`, not the offset `PageResponse`. | Decided (B15) |
| A102 | **Visibility (B15).** The feed: any ACTIVE member reads the whole group history (not only what happened after `joined_at`); a stranger and a LEFT member get `404` (identical to an unknown group), through `GroupAccessService`. The notification center is strictly per user: every statement filters `user_id = caller`, never a client-supplied user; notifications stay readable after the user left the group (A100 limits what is resolved). | Decided (B15) |
| A103 | **Mark read, unread count and retention (B15).** `POST /notifications/read` body `{ids: [<=100]}` xor `{all: true}` (else `422`): `UPDATE ... WHERE user_id = caller AND read_at IS NULL [AND id = any(?)]`; unknown or foreign ids match nothing, so the answer is identical for both; returns `{marked, unreadCount}` where `marked` counts only rows that changed now. Not a create, so no `Idempotency-Key` (idempotent by state). `GET /notifications/unread-count` returns `{count}`. Operation ids `listGroupActivity`, `listNotifications`, `getUnreadNotificationCount`, `markNotificationsRead`. Retention: `ActivityPurgeJob` deletes events older than `qesma.activity.retention` (180d; their notifications cascade) in chunks of 5000 (by id subquery, looping until fewer than a chunk is deleted), fixed delay `qesma.activity.purge-interval` (PT6H), initial delay PT10M, logging `event=activity.purge deletedEvents millis`; a failed run is harmless and retried. `mobile` must regenerate `qesma_api` (four new operations; new schemas `ActivityPage`, `ActivityItem`, `NotificationPage`, `NotificationItem`, `EventPayload`, `UnreadCount`, `MarkReadResult`, request `MarkReadRequest`). | Decided (B15) |
| A104 | **Preferences semantics (B16).** Global `enabled` (default true) and per-group `muted` (default false); no row means the default. Mute/disable applies to EVERY event type, including `REMINDER` and `SETTLEMENT_DISPUTED` (the user's choice wins; disputes stay visible in balances `hasDispute` and in the feed). UI copy (FL15): "Muted: you will not get notifications from this group, including reminders and disputes. Activity still shows everything." Applied at write time only: notifications that already exist are KEPT when muting and unmuting does NOT backfill. The feed (`group_events`) is never filtered. A LEFT user's mute row stays and applies again if they rejoin. | Decided (B16) |
| A105 | **Preferences storage (B16, V18).** `notification_prefs(id, user_id, group_id NULL = global, muted, updated_at)`; two partial unique indexes (`(user_id) WHERE group_id IS NULL`, `(user_id, group_id) WHERE group_id IS NOT NULL`) because a plain UNIQUE treats NULLs as distinct; idempotent upsert with `ON CONFLICT (...) WHERE ... DO UPDATE`. Global `enabled=false` is stored as `muted=true` on the NULL-group row. `group_id` FK cascades (an empty group may be deleted); `user_id` has no cascade (B17 purges explicitly). The filter is one `NOT EXISTS` added to the single `INSERT ... SELECT` of `NotificationStore.insertFor`, so the statement count per event is unchanged. | Decided (B16) |
| A106 | **Preferences endpoints (B16).** `PUT /me/notification-prefs {enabled}` -> `{enabled}`; `PUT /groups/{gid}/notification-prefs {muted}` -> `{muted}` (any ACTIVE member, `READ_GROUP`; a stranger or LEFT member gets 404). PUT sets a value, so repeating it is harmless: no `Idempotency-Key`. No separate GET: `UserDto.notificationsEnabled` (GET/PATCH /me and both sign-in responses) and `GroupDto.muted` (GET /groups/{gid}, create and update). A null or missing field is `422 VALIDATION_ERROR`. Operation ids `updateNotificationPrefs`, `updateGroupNotificationPrefs`. | Decided (B16) |
| A107 | **Remind rules (B16).** `POST /groups/{gid}/transfers/remind {fromMemberId, toMemberId}` + `Idempotency-Key`, 201 `ReminderView {fromMemberId, toMemberId, amountMinor, remindedAt, canRemindAt}`. Check order: 404 non-member -> 403 if the caller's member is not `toMemberId` and the role lacks `REMIND_ANY` (Owner, Admin) -> 422 `VALIDATION_ERROR` for missing ids, from == to, or the caller being the debtor -> (idempotency replay) -> 422 `MEMBER_NOT_IN_GROUP` unknown member -> 422 `MEMBER_INACTIVE` debtor LEFT -> 422 `VALIDATION_ERROR` debtor is a ghost ("this member has no account to remind"; the client can hide the button from `MemberDto.hasAccount`) -> 422 `VALIDATION_ERROR` there is no suggested transfer from -> to NOW (wrong direction included) -> 429 limits -> write. `amountMinor` is that suggested transfer's amount, computed by the same `BalanceCalculator` + `Simplifier` path as GET balances (CONFIRMED settlements only, A83); the client sends no amount. Operation id `remindTransfer`. | Decided (B16) |
| A108 | **Rate limit (B16).** One reminder per (group, debtor) per rolling 24 h (`qesma.remind.window`), whoever the creditor is. Source of truth: `remind_log`, written in the same transaction as the event; race safety: the group row lock (`requireForUpdate`, the lock expense and settlement creates take), so of two parallel reminders for one pair the second sees the committed row and gets `429 REMIND_RATE_LIMITED`. An idempotent replay returns the stored 201 and consumes no slot; a 429 is not stored, so the same key succeeds after the window. A muted or disabled debtor still gets 201 (the slot is consumed, no notification row): the mute is never revealed to the sender. | Decided (B16) |
| A109 | **canRemindAt (B16).** Every `BalanceView.TransferView` carries `canRemindAt`: the last reminder of that debtor in the group plus the window if that is in the future, else null (may remind now). ONE grouped `remind_log` statement per balances call (constant, whatever the number of transfers). It reflects the pair window only, not the per-account cap or whether the viewer may remind: the client decides that from role, `hasAccount` and `status`. | Decided (B16) |
| A110 | **Per-account cap (B16).** At most 20 reminders per rolling 24 h per sending account across all groups (`qesma.remind.daily-cap-per-user`). The pair limit already bounds one group; 20 covers a heavy legitimate organiser (one trip with ~15 debtors plus a few groups) while stopping fan-out spam through many throwaway groups. Same `429 REMIND_RATE_LIMITED`, `nextAllowedAt` = oldest reminder in the window + 24 h. It is a soft abuse ceiling: concurrent reminders of one account in DIFFERENT groups may exceed it by the number in flight (no cross-group lock; acceptable for spam control, it is not a money rule). `remind_log` rows older than max(window, 7 days) are purged by `ActivityPurgeJob`. | Decided (B16) |
| A111 | **REMINDER event (B16).** Payload `{fromMemberId, toMemberId, amountMinor}` (ids and the server amount, no free text); actor = the caller's member; recipients = the debtor only (`Recipients.members({from})`), the mute/disable filter applies; it appears in the group feed (balances are visible to every member anyway). Notification `subject` is null. `ck_group_events_type` is replaced in V18 to add `REMINDER`. | Decided (B16) |
| A112 | **Error contract (B16).** `ErrorCode.REMIND_RATE_LIMITED` (429). `ApiException` gains optional extension properties which `GlobalExceptionHandler` copies into the `ProblemDetail`; the OpenAPI `Problem` schema gains the optional `nextAllowedAt` (date-time, only with `REMIND_RATE_LIMITED`). No `Retry-After` header: the body is the contract. Metrics `qesma.reminders{result=sent|replayed|rate_limited_pair|rate_limited_user}`; logs `remind.sent groupId fromMemberId toMemberId` (ids only), `notification_prefs.updated`. `mobile` must regenerate `qesma_api` (three new operations, `canRemindAt`, `notificationsEnabled`, `muted`, `nextAllowedAt`, `REMIND_RATE_LIMITED`). | Decided (B16) |
| A113 | **Conflict contract (B17, Part A).** A stale `If-Match` on `PUT`/`DELETE` expense and `PATCH` group returns `409 VERSION_CONFLICT` with two extra problem members: `currentVersion` (int) and `current` (an `ExpenseView` for expenses, a `GroupDto` for the group: exactly what `GET` returns to that caller). The body is built only after the 404 (non-member) and 403 (role) checks, so a conflict never shows anything the caller could not GET; a stranger still gets the plain 404, a member without the permission the plain 403. The race path (`ObjectOptimisticLockingFailureException`) and the other `VERSION_CONFLICT` uses (approve/reject already decided, members changed) stay a plain 409: both members are optional. A soft-deleted expense is a 404, so it has no `current`. OpenAPI: a dedicated `VersionConflictProblem` schema (`allOf` Problem + `currentVersion` + `current`) is referenced only from those three 409 responses; the generic `Problem` and the Dart client's error type are unchanged. `current` is a plain object (no `oneOf`, which generators handle badly); its description names the type per operation. The group `GroupDto` is built in `GroupController` (the service layer must not depend on api). | Decided (B17) |
| A114 | **Account deletion: data inventory (B17, Part B).** `DELETE /me`. Per personal-data location: `users` row **anonymised** (display_name `Deleted user`, `auth_subject` = `deleted:<random uuid>` so the original address/username/Google subject is free and no sign-in can match the tombstone (it contains `:`), `email` and `email_verified_at` NULL, `deleted_at` set; `ck_users_deleted_anonymised` enforces the shape; ledger tables keep their FK to the row); **purged** (rows deleted): `user_passwords`, `email_tokens`, `refresh_tokens`, `payment_handles`, `notification_prefs`, `notifications`, `remind_log` (sent_by), `idempotency_keys` (stored responses hold names/amounts), `join_requests` of the user (free-text names), `device_tokens` (B18: not built yet; B18 must delete them in this transaction); **kept**: `members.display_name` (the member's own name is group history), `members` rows themselves (see A116), `expenses.created_by_user_id`, `expense_revisions.changed_by_user_id`, `settlements.created_by_user_id`, `expense_groups.owner_user_id` (opaque ids of the anonymised row), `group_events` (actor is a member id, payloads hold ids/amounts only, names are resolved from `members` at read time), free text inside the ledger (expense titles/notes, settlement notes). | Decided (B17) |
| A115 | **Request, re-authentication, sessions (B17).** Body `{confirm: "DELETE"}` (exact, else 422); a password account must also send `password`, checked like change-password (lockout counter commits; wrong = 422 `VALIDATION_ERROR`, never 401). Rationale: a stolen 15-minute access token must not be able to erase an account; Google accounts have no password, the token is their proof. 204. All refresh-token rows are deleted in the same transaction. The access token (stateless, 15 min) is refused at once: the JWT validator checks `users.deleted_at` (one primary-key probe per request) and answers the generic 401; `UserService.get/updateDisplayName` refuse too. No rate limiter on `DELETE /me` beyond the password lockout. | Decided (B17) |
| A116 | **Members of the account (B17).** Every member linked to the account keeps its id, name and history and becomes an ordinary unclaimed member (`user_id` NULL, role MEMBER, status ACTIVE: V12/V14 forbid NULL on OWNER/LEFT rows, same as unlink, A75/A78). It is therefore claimable by an invite like any ghost, and `hasAccount` is false; no extra `deleted` flag/column (decided against: it would need a second code path in every claim list for no data-protection gain, the name is the member's own history). **No other member's balance and no ledger row changes** (member ids are untouched; `AccountDeletionIT` compares balances/expenses JSON before and after). | Decided (B17) |
| A117 | **Ownership (B17).** An Owner whose group has ledger history (including soft-deleted/cancelled rows) or another ACTIVE linked member gets `409 OWNER_MUST_TRANSFER` with `groups: [{id, name}]` (all offending groups at once); nothing changes. A sole Owner of a group *with* history and nobody else active is blocked with the same code (never an ownerless, unreachable group); they must first add or reactivate someone and transfer. An owned group with no ledger data and no other ACTIVE linked member is deleted with its ghosts and any LEFT members (they have no history to keep; unlike the manual delete, A23, which keeps a group people joined, the owner here has no other way out), its invites and join requests included. Owner groups are locked in id order after the user row. | Decided (B17) |
| A118 | **Latent bug fixed (B17).** `GroupService.delete` did not delete `group_invites`/`join_requests` (no cascade), so deleting a group that ever had an invite failed with an FK violation. Both are now removed first (`removeEmptyGroup`, shared with account deletion). | Decided (B17) |
| A119 | **Concurrency (B17).** Lock order everywhere: credential row, user row, token rows, groups (id order). Account deletion takes the credential row, then the user row `FOR UPDATE`; sign-in and refresh take the user row `FOR SHARE` (`UserRepository.lockActive`) before issuing or rotating a token, so a sign-in racing the deletion either finishes first (its token is purged) or finds the account deleted (401): no session row survives. A repeated or parallel deletion finds `deleted_at` set: 401 (exactly one 204). A password sign-in that loses its credential row to the deletion is an ordinary failed sign-in (401), not a 500. The deletion itself is one transaction (`TransactionTemplate`, because the password check must commit its failure counter before, like change-password): all or nothing. | Decided (B17) |
| A120 | **Retention note and open items (B17).** After deletion we keep: the anonymised `users` row (random id, `Deleted user`, no email/subject), the ledger and its history (other people's financial records), member names, and group events. Backups age out with the normal retention. **Open items:** (1) **lawyer review of the retention approach** under PDPL No. 151/2020 (member names, ledger free text, an owner member's name copied from the profile, backups); (2) **Google Play account-deletion requirement** (in-app deletion exists with this milestone; Play also requires a public web page/URL where deletion can be requested without the app, **out of scope here**: list for release); (3) `device_tokens` purge belongs to B18. No email is sent for a deletion (no mail channel for password accounts, ADR-008). | Decided (B17); lawyer review and Play web URL open |
| A121 | **Standalone release (SA0, ADR-011).** The first public release is a standalone, local-first Android app for one organizer: no deployed server, $0 running cost. The Java backend is frozen at the git tag `server-phase-ready`. The app serves the `/api/v1` contract in-process from SQLite (`LocalBackend` as an `HttpClientAdapter`) with a Dart port of the engine; Java stays the reference and the shared `fixtures/` keep both equal. Full detail: `docs/STANDALONE_SPEC.md`. | Decided (SA0) |
| A122 | **App modes (SA0).** `QESMA_MODE=local\|server` (default `server` for debug and tests, `local` for the release). Hidden in local mode: sign-in, invites, join requests, role management, leave/transfer, settlement confirm/dispute/pending chips, remind, notifications, account deletion. Stays: the "you" member = member #1 (B9) and the OWNER role in every group. | Decided (SA0) |
| A123 | **Local backend equals the server contract (SA0).** Same endpoints, DTOs, `FieldRules` and `ExpenseValidator` limits (group 60, member 40, title/item 100, lists 100, bps 0..10000, dates 2000..2100, amount <= 10^12), error codes and Problem JSON, ETag/If-Match with the B17 conflict body, and Idempotency-Key semantics of 8.3 (24 h retention, purge at app start, key and business write in one transaction). Pinned by the SA3 conformance suite. | Decided (SA0) |
| A124 | **Endpoints served locally (SA0).** The operations the repositories really call: me, own handles, groups, members (add/rename/delete), expenses (preview, CRUD, revisions), balances, settlements (create, list, cancel). Server-only endpoints answer `404 NOT_FOUND`; `PATCH member` with role or status answers `422`. List in STANDALONE_SPEC 4. | Decided (SA0) |
| A125 | **Local settlements are CONFIRMED (SA0).** A settlement created in local mode is CONFIRMED immediately (consistent with A85: the caller is the Owner and the other members are ghosts). Cancel (A87) stays; confirm and dispute are not served. The balance rule A83 ("CONFIRMED only") is unchanged. | Decided (SA0) |
| A126 | **Local data rules (SA0).** UUID TEXT ids, INTEGER money and bps, soft delete and immutable revisions, balances computed never stored, schema invariants as CHECK/UNIQUE/FK (`PRAGMA foreign_keys=ON`), member-name uniqueness on a normalized `name_key` (SQLite `lower()` is ASCII-only), forward-only drift migrations, ids and JSON shapes kept compatible with the server for a later upload. | Decided (SA0) |
| A127 | **Backup (SA0).** Versioned JSON export (`qesma-backup-v1.json`), replace-all import after confirmation, validated before writing (versions, integrity, limits, recompute check: nets sum to 0 and shares sum to totals), one transaction, nothing changes on failure; a newer format is refused. | Decided (SA0) |
| A128 | **Android auto-backup replaces `allowBackup="false"` (SA0).** FL2 disabled backup because a Keystore-wrapped token cannot be restored; local mode has no token, and a restored database is the point. Backup rules include only the drift database file and exclude caches and secure storage. SA5 changes the manifest, the `source_guards_test` test and the ADR-006 addendum in one commit. | Decided (SA0) |
| A129 | **Categories (SA0).** Fixed enum FOOD, TRANSPORT, FUEL, ACCOMMODATION, GROCERIES, SHOPPING, ENTERTAINMENT, BILLS, OTHER; default OTHER; no user-defined categories at launch. Replaces the list in PROJECT_PHASES 3.3. Added to the contract by BSA1 (`expenses.category`, filter `?category=`, revision snapshot). | Decided (SA0) |
| A130 | **My share formula (SA0).** Per calendar month x category over non-deleted expenses in all groups, latest revision only: consumed = sum of the "you" member's `owed`; paid up front = sum of the "you" payer amounts. Settlements are excluded. Month = the calendar month of `expenseDate` (already a local date, no timezone shift; Africa/Cairo only defines "this month" on screen). | Decided (SA0) |
| A131 | **My share per currency (SA0, owner).** The table is built per `currencyCode` with no conversion: one section per currency that has data, EGP first. | Decided (SA0) |
| A132 | **Recap figures (SA0).** Total spent, expense count, top payer (largest sum of payer amounts; tie -> lower sortOrder), biggest expense (largest total; tie -> earlier date, then earlier creation). | Decided (SA0) |
| A133 | **Recap category percentages (SA0, owner).** Basis points by LRM that sum to exactly 10000 (with an LRM tie-break by the category enum order as `sortOrder`); a group with no expenses has no recap. | Decided (SA0) |
| A134 | **Recap privacy (SA0).** Member names appear in a shared recap only after the user confirms sharing. | Decided (SA0) |
| A135 | **Pool model (SA0).** Group setting `treasurerMemberId` (nullable); a deposit is a settlement member -> treasurer with `kind = POOL_DEPOSIT` (default `PAYMENT`); a deposit to anyone but the treasurer is rejected; a pool expense has a single payer who is the treasurer and `paidFromPool = true`, valid only with a treasurer. Contract added by BSA1. | Decided (SA0) |
| A136 | **Pool meter and balances (SA0).** Meter = sum of CONFIRMED deposits - sum of totals of non-deleted pool expenses; may be negative (the treasurer fronted cash); never stored (`GroupDto.poolBalanceMinor`, null without a treasurer). Unequal deposits are allowed; leftover and overdraft settle through the normal balances and suggested transfers (a settlement's kind never changes a net); only received deposits are recorded; the treasurer's own share is like anyone's. | Decided (SA0) |
| A137 | **Treasurer change lock (SA0).** Changing or clearing the treasurer is allowed only while no deposit and no pool expense exists, counting cancelled and soft-deleted rows. The error code is chosen in BSA1 (ErrorCode, OpenAPI enum, `ApiContractCoverageIT`). | Decided (SA0); code to be named in BSA1 |
| A138 | **No self-deposit (SA0, owner).** The treasurer cannot deposit to themselves (`from <> to` stays); their own cash lowers the meter or makes it negative. | Decided (SA0) |
| A139 | **Fuel formula (SA0).** `fuel = round_half_up(km_tenths x l100_tenths x pricePerLitreMinor / 10000)` with BigInt intermediates; total = fuel + sum of tolls (<= 10^12); consumption 1.0-30.0 L/100 km; split equally by LRM among the chosen riders, ties by sortOrder, driver in or out as chosen. | Decided (SA0) |
| A140 | **Multi-stop ride (SA0).** Leg fare = LRM of the total fare with weights = leg distance in tenths of km (all-zero weights -> equal, 7.1.5); each leg is split equally (LRM) among the riders on board, ties by sortOrder; a rider's share is the sum over their legs. | Decided (SA0) |
| A141 | **Leg without riders (SA0, owner).** Rejected with `VALIDATION_ERROR`; the user fixes the stops. | Decided (SA0) |
| A142 | **Calculator output (SA0).** An EXACT expense draft (category FUEL or TRANSPORT, driver as default payer) that the user reviews; never auto-saved. The fuel price is user-edited with a "last updated" date; no hardcoded official price and no network fetch. | Decided (SA0) |
| A143 | **Reminder tones (SA0).** Soft / firm / funny ARB templates (Egyptian Arabic, English) with placeholders name, amount, group and an optional own InstaPay handle; editable preview; `https://wa.me/?text=` (no phone numbers stored); never auto-sent; last tone remembered locally. The copy needs the owner's approval in SA9. | Decided (SA0) |
| A144 | **Receipt OCR (SA0).** Firebase AI Logic (Gemini Developer API, free tier, Spark plan, no billing account) with App Check (Play Integrity); consent screen before the first scan; structured JSON with amounts as strings parsed by `Money.parse`/`Bps.parse`; result opens the itemized editor as an unsaved draft; mismatch banner from the editor's preview; the image is never stored, logged or uploaded elsewhere; failures fall back to manual entry. | Decided (SA0) |
| A145 | **OCR daily cap (SA0).** 20 scans per device per calendar day (Africa/Cairo), counted locally. | Decided (SA0); the number is checked against the free-tier quota in SA12 |
| A146 | **Free-tier data use (SA0).** The consent text says the image is sent to Google and, on the free tier, may be used to improve Google products. | To verify (SA12, against the current Gemini API terms) |
| A147 | **Voice entry, update 1 (SA0).** `speech_to_text` with ar-EG (fallback ar), on-device when available, title and amount only, from a pure number-words parser; the transcript is confirmed by the user; never saves by itself. | Decided (SA0) |
| A148 | **Local settings storage (SA0).** Small settings (last tone, fuel prices, OCR consent and counter, backup reminder) live in the drift database; `shared_preferences` stays banned. | Decided (SA0) |
| A149 | **Engine access (SA0).** `package:qesma_engine` is imported only under `lib/local/**`; `lib/features/**` reaches it through local repositories (calculator, insights) and never computes splits, balances, the meter, My share or the recap. | Decided (SA0) |
| A150 | **Local-only computations (SA0).** My share and the recap are local computations, not fake HTTP endpoints; they are hidden in server mode until the server phase adds endpoints for them. | Decided (SA0) |
| A151 | **Local timestamps (SA2).** Every local timestamp column is `INTEGER` UTC epoch **milliseconds** (not ISO-8601 text, not drift's default `DateTime` storage, which keeps seconds). Reasons: sortable and comparable as numbers, no timezone or format variants, cheap CHECKs, and the 24-hour idempotency purge is one integer comparison. The local backend (SA3) converts to ISO-8601 UTC for the contract. Dates stay `TEXT 'YYYY-MM-DD'` with `CHECK (date(x) IS x)`. | Decided (SA2) |
| A152 | **Member name key (SA2, owner).** `members.name_key` = `memberNameKey(displayName)` (`lib/local/db/name_key.dart`): trim, collapse every whitespace run to one space, Unicode lower case; Arabic letters, hamza forms and diacritics are kept as typed. `UNIQUE (group_id, name_key)` replaces the server's `lower(display_name)`. Stricter than the server only in whitespace collapsing, so an upload never creates a server duplicate. `MembersDao` always derives the key itself. | Decided (SA2) |
| A153 | **Local user mapping (SA2).** The server's `users` row becomes the single `local_profile` row (one-row table via `singleton UNIQUE CHECK (singleton = 1)`); every `*_user_id` column (`owner_user_id`, `members.user_id`, `created_by_user_id`, `changed_by_user_id`, `payment_handles.user_id`) references it, so the V12/V14 CHECKs and partial unique indexes port unchanged and an upload maps one id. `local_meta` is a one-row table (schema version at creation, last export time and format) written on create. | Decided (SA2) |
| A154 | **Postgres regex CHECKs ported to GLOB (SA2).** Wallet `^01[0125][0-9]{8}$` and InstaPay `^[a-z0-9._-]+@[a-z0-9.-]+$` (3..60) are written with `GLOB` and `length()`, so the database file needs no custom SQL function and opens in any SQLite tool; currency `^[A-Z]{3}$` likewise. Tested with accept/reject pairs. | Decided (SA2) |
| A155 | **STRICT tables and append-only revisions (SA2).** Every local table is `STRICT` (a REAL or TEXT cannot enter an INTEGER money column). `expense_revisions` has a `BEFORE UPDATE` trigger that aborts; there is deliberately no DELETE trigger, so the SA5 replace-all import can wipe the ledger. `RevisionsDao` has no update/delete (source test). Idempotency keys are UUIDs (`CHECK length = 36`), scope `(key)`. | Decided (SA2) |
| A156 | **Settlement `deleted_at` not ported (SA2).** The legacy column is never written since B13 (A87) and only constrained legacy rows; the local table keeps the V15 status columns and CHECKs and drops `deleted_at` and `ck_settlements_legacy_deleted`. | Decided (SA2) |
| A157 | **Local database file (SA2).** `<getApplicationDocumentsDirectory()>/qesma_local.sqlite` (Android `<data dir>/app_flutter/`), opened on a background isolate, WAL, `foreign_keys = ON` on every connection. SA5's backup rules must include this file and either checkpoint the WAL before backup or include the `-wal` file. `schemaVersion` 1; snapshots in `mobile/drift_schemas/local/`; forward-only step migrations from `drift_dev make-migrations`. | Decided (SA2) |
