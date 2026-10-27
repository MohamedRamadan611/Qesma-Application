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
- Sign in with Google. Basic profile (display name). Sign out. Arabic RTL UI.

**Groups & members**
- Create group (name, type: TRIP/HOUSING/OUTING/OTHER, currency code, default EGP). List groups. Edit name. Delete group only if it has no expenses/settlements.
- Add members by name (ghost members), any time. Rename member. Remove member only if they have no transactions.

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
  user_id uuid REFERENCES users(id),      -- null = ghost member (all members are ghost members in Phase 1)
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

---

## 8. API (REST, JSON, `/api/v1`)

### 8.1 Conventions
- Auth: `Authorization: Bearer <access JWT>`. All endpoints except `/auth/*` require it.
- Authorization (Phase 1): a user can only access groups they own. Accessing another user's group returns **404** (not 403).
- Money: integer minor units + group `currencyCode`. Dates: ISO-8601.
- Errors: RFC 7807 `application/problem+json` with a stable `code` field.
- Pagination: `?page=&size=` for lists; expenses sorted by `expenseDate desc, createdAt desc`.
- Optimistic concurrency: `ETag`/`If-Match` carrying the entity `version`.

### 8.2 Endpoints
```
POST   /auth/google                 { idToken } -> { accessToken, refreshToken, user }
POST   /auth/refresh                { refreshToken } -> { accessToken, refreshToken }
POST   /auth/logout                 { refreshToken }
GET    /me
PATCH  /me                          { displayName }

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

GET    /groups/{gid}/balances           -> { nets: [{memberId, netMinor}], transfers: [{fromMemberId, toMemberId, amountMinor}] }
POST   /groups/{gid}/settlements        { fromMemberId, toMemberId, amountMinor, settledOn, note? } (Idempotency-Key required)
GET    /groups/{gid}/settlements
DELETE /groups/{gid}/settlements/{sid}
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
`VALIDATION_ERROR`, `PAYERS_TOTAL_MISMATCH`, `SPLIT_TOTAL_MISMATCH`, `MEMBER_NOT_IN_GROUP`, `MEMBER_HAS_TRANSACTIONS`, `DUPLICATE_MEMBER_NAME`, `VERSION_CONFLICT`, `IDEMPOTENCY_KEY_REUSED`, `GROUP_NOT_EMPTY`, `NOT_FOUND`, `UNAUTHORIZED`.

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
12. **Settings Hub**: language (ar/en), default currency, navigation to Edit Profile and Account Settings, sign out.
13. **Edit profile**: display name, avatar picker, phone number, read-only Google account info.
14. **Account settings**: linked Google account status, payment handles (InstaPay/wallet handle), data export, sign out from all devices, delete account.

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
- Members will later gain `status` (ACTIVE/LEFT) and invitations; keep member queries going through a service so this is additive.
- Roles/permissions will replace owner-only checks; centralize authorization in one place now.
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
| A4 | Phase 1 supports **Google Sign-In only**. Email/password (which needs password reset emails) is deferred to Phase 2. | Decided |
| A5 | Debt simplification uses a deterministic greedy algorithm, not a guaranteed-minimum solver. | Decided |
| A6 | Phase 1 is online-only; offline queue is Phase 4. | Decided |
| A7 | Backend is authoritative for all calculations; the app uses the `preview` endpoint. | Decided |
| A8 | A payer may be a non-participant; a participant may owe without paying. | Decided |
| A9 | Tie-breaks for rounding use `sort_order` (member creation order). | Decided |
| A10 | Pricing, paywall and monetization are Phase 5 hypotheses to be tested with real users, not decided. | Open |
