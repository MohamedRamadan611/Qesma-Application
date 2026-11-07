# Mobile reference map: screens, API, scope (read this before any `fl*` prompt)

This file is shared context for the Flutter prompts (`.claude/commands/fl*.md`). It reconciles three sources that do not fully agree: the screen images (`docs/design/screens/`), the Phase 1 spec (`docs/PROJECT_SPEC.md` sections 3 and 9) and the real API (`docs/openapi.json`). When they disagree, **the API and spec win; the design is never "made to work" with fake data.**

## 1. Rules that apply to every mobile prompt
1. **Phase 1 only.** Build what the spec lists and the backend supports. Anything else in a design is **omitted** (not disabled, not faked, not "coming soon"). Section 4 lists what is hidden.
2. **No money arithmetic in Dart** beyond what the spec explicitly allows. Allowed: summing amounts the user typed (payer "remaining" indicator, exact-share "remaining" indicator) and counting. Everything else (splits, rounding, service, tax, totals, balances, suggested transfers, "equal" prefills, "half"/percent shortcuts) comes from the backend: `POST /groups/{gid}/expenses/preview` and `GET /groups/{gid}/balances`. To prefill "equal" amounts, call preview with the EQUAL split and copy `members[].owedMinor`.
3. **Money is `int` piasters.** Never `double`/`num`/`Decimal` for amounts. Parse user input ("1,000.50", Arabic-Indic digits) with string logic into piasters; format with Western digits (0-9) and the suffix `ج.م` (Decision A3). Maximum amount 10^12 piasters.
4. **Percentages are integer basis points** (`bps`): parse "12" -> 1200, "12.5" -> 1250 by string logic (max 2 decimals, 0..100.00).
5. **The API client is generated** from `docs/openapi.json` (`docs/mobile-client.md`); never hand-write or edit API models. If the contract is wrong, fix the backend and regenerate.
6. **Idempotency:** every create (`POST` expenses, settlements) carries a UUID `Idempotency-Key` generated once per user action and reused for retries of the same request body; a changed body gets a new key. Groups and members have no key (Decision A24): disable the button while in flight and re-read the list after an ambiguous failure.
7. **Optimistic concurrency:** edits and deletes of expenses and group edits send `If-Match: "<version>"` taken from the last read; `409 VERSION_CONFLICT` -> conflict dialog -> reload.
8. **Arabic first, full RTL**, ARB files (ar primary, en secondary), Android first, online only (clear error + retry when offline).
9. **Never log** tokens, emails, names or titles. Tokens live in secure storage only.

## 2. Screen files: naming warning
The two files below are **swapped** relative to `docs/design/STITCH_PROTOTYPE_LINKING.md`. Open by content, not by number:
- `P7-01-Itemized restaurant.png` shows the **expense details** page (read-only view of a saved restaurant bill).
- `P8-01-Expense-Details.png` shows the **itemized bill editor** (items, service/tax toggles, per-person breakdown, save).
Do not rename the files without telling the owner; the prompts below use the real file names.

## 3. Screen -> prompt -> endpoints

| Screen file | What it shows | Prompt | Endpoints | Build (Phase 1) | Omit |
|:--|:--|:--|:--|:--|:--|
| `P1-01-splash.png` | Splash | fl2 | `GET /me` (session restore) | logo, restore session | - |
| `P1-02-Welcome.png` | Onboarding value props + "start" | fl2 | - | static welcome, terms/privacy links (placeholder URLs until legal pages exist) | - |
| `P1-03-Sign-in.png` | Google sign-in | fl2 | `POST /auth/google` | Google button, loading, errors by code | "explore as a guest" (no guest mode) |
| `P11-04-Session-Expired.png` | Session-expired dialog | fl2 | `POST /auth/refresh` | dialog + Google sign-in again | "continue as guest" |
| `P2-01-Group-List.png` | Groups list | fl3 | `GET /groups` | cards: name, type chip, last activity (`lastExpenseAt`), total spent, member count, "you are owed/owe" from `yourNetMinor` (after B9); FAB new group; empty state | cross-group header numbers unless all groups share one currency (then only "net" = sum of `yourNetMinor`); "monthly spend", "11 friends", quick settings, bell, cover photos, member avatar stacks, "ready to settle / pay now" chips, bottom tabs "Activity" and "Expenses" (Phase 2/3) |
| `P2-02-Create-Group.png` | Create group | fl3 | `POST /groups` | name (max 60), type chips (TRIP/HOUSING/OUTING/OTHER), currency shown fixed EGP | cover photo, "add members from contacts" (no contacts access in Phase 1), name counter says /40: backend limit is 60 |
| `P2-03-Edit-Group.png`, `P2-03-Validate-Group.png` | Edit group, validation state | fl3 | `GET/PATCH/DELETE /groups/{gid}`, members | rename, type, delete group (blocked dialog on `GROUP_NOT_EMPTY`), created date | photo, "admin" role label, "toggle status" card |
| `P3-01-Group-Home & Expenses-Tab.png` | Group home, Expenses tab | fl3 (shell), fl4 (list) | `GET /groups/{gid}`, `GET .../expenses` | header (name, type, member count, total spent), tabs (Expenses/Balances/Members), list grouped by date, title, total, "your share", payer text, split-type chip, participant count, filters (date range, member), FAB | location text under the date, category icons, "settlement status" and "approx. share per person" in the header, promo tip card |
| `P4-Add-Member.png` | Add member sheet (+ duplicate error) | fl3 | `POST /groups/{gid}/members` | name (max 40), `DUPLICATE_MEMBER_NAME` inline | colour picker (no backend field) |
| (no file) | Members tab, member options, rename, delete confirm/blocked | fl3 | `PATCH/DELETE .../members/{mid}` | derive from DESIGN.md + the add-member sheet | member photos, roles |
| `P5-01-Add Expense.png` | Add expense (equal / selected / exact) | fl5 | `POST .../expenses/preview`, `POST/PUT .../expenses` | title (max 100), amount, date, paid-by summary, split tabs (all, selected, exact amounts), per-member amounts from preview, "remaining" banner | receipt photo, emoji in the title field, per-member notes ("shared in the trip") |
| `P6-01-Paid by.png` | Multi-payer sheet | fl5 | preview | payers with amounts, running "remaining", `payersTotalMatches`, "split among selected payers" (use preview) | "main payer / participant" captions that are not data |
| `P8-01-Expense-Details.png` (**itemized editor**) | Restaurant bill editor | fl6 | preview, `POST/PUT .../expenses` | items (name, amount, assignee chips), service toggle + %, tax toggle + % + base (SUBTOTAL / SUBTOTAL_PLUS_SERVICE), adjustment, per-person breakdown, totals, payers match banner | scan-the-receipt, item icons/emoji and descriptions |
| `P7-01-Itemized restaurant.png` (**expense details**) | Expense details | fl4 | `GET .../expenses/{eid}`, `GET .../revisions`, `DELETE` | payers, items with assignees, subtotal/service/tax/adjustment, per-person breakdown, "edited (version N)" badge, history, edit, delete with confirm | payment method per payer, item icons, "delete permanently" wording (it is a soft delete: say "delete") |
| `P9-01-Balance-Tab.png` | Balances tab | fl7 | `GET .../balances`, `GET .../settlements` | nets with sign + colour + text, "you" badge (after B9), suggested transfers with "Record payment", settlement history with delete, "N transfers needed" / "all settled" from the transfers count | per-member activity captions ("paid for the hotel"), undo snackbar (no restore endpoint) |
| `P9-02-Pay.png` | Record payment sheet | fl7 | `POST .../settlements` | from, to, amount (prefilled from the transfer), date, note (max 200) | payment-method chips, "half amount" shortcut, "immediate effect" panel (client arithmetic) |
| `P10-01-Profile-Hub.png` | Profile hub | fl8 | `GET /me`, `GET /groups` | name, email, group count, language, terms/privacy, app version, sign out | role badge, "account settings"/"alerts" rows, default-currency row, avatar |
| `P10-02-Edit-Profile.png` | Edit profile | fl8 | `PATCH /me` | display name (max 60, required) | photo, phone, "preview states" helper |
| `P10-03-Account-Settings.png` | Account settings | fl8 | - | connected Google email (read only), sign out | InstaPay/wallet handles (Phase 2), export (out of scope), active devices, sign out everywhere, **delete account** (required before public release, not in the Phase 1 backend: record as an open item) |
| `P11-01-No-Internet.png`, `P11-02-Generic-Error.png`, `P11-03-Loading-pattern.png` | Offline, generic error, skeleton | fl1, fl8 | - | shared widgets used everywhere | - |
| `P11-05-Coach-Marks.png` | 3-step first-run tour | fl8 (optional, last) | - | only if time allows | - |
| `P12-*`, `P13-*`, `P14-*` | Invites, transfer status/disputes/remind, activity, notifications | **none** | - | **Phase 2: do not build** | everything |

## 4. Missing designs (derive from `docs/design/DESIGN.md`, the nearest screen and the ux-copy skill; list them in each plan)
Empty states, loading skeletons per screen, delete-group confirm/blocked, delete-member confirm/blocked, delete-expense confirm, edit-conflict dialog, expense history sheet, members tab, all-settled balances, dark theme (light only in Phase 1).

## 5. Backend limits the UI must respect
Group name 60 code points · member name 40 · expense title 100 · item name 100 · settlement note 200 · display name 60 · up to 100 payers/participants/shares/items and 100 assignees per item · amounts 1..10^12 piasters (adjustment ±10^12) · `expenseDate` / `settledOn` 2000-01-01..2100-12-31 · page size max 100 (default 20) · request body max 64 KB · auth endpoints 10 requests/minute/IP · access token 15 minutes, refresh token 30 days (rotates on every refresh; **reusing an old refresh token ends the whole session**) · idempotency keys kept 24 hours.

## 6. Endpoints (24, from `docs/openapi.json`)
| Operation | Success | Notes |
|:--|:--|:--|
| `POST /auth/google` `{idToken}` | 200 `AuthResponse` | rate limited; 503 `AUTH_PROVIDER_UNAVAILABLE` |
| `POST /auth/refresh` `{refreshToken}` | 200 `TokenResponse` | single-flight in the client; persist the new token before retrying anything |
| `POST /auth/logout` `{refreshToken}` | 204 | best effort |
| `GET /me`, `PATCH /me` `{displayName}` | 200 `UserDto` | |
| `GET /groups?page&size`, `POST /groups` | 200 `PageResponseGroupSummaryDto` / **201** `GroupDto` | create: no key |
| `GET /groups/{gid}`, `PATCH` (If-Match), `DELETE` | 200 `GroupDto` (+`ETag`) / 204 | 409 `GROUP_NOT_EMPTY` |
| `POST /groups/{gid}/members`, `PATCH .../{mid}`, `DELETE .../{mid}` | **201** `MemberDto` / 200 / 204 | 409 `DUPLICATE_MEMBER_NAME`, `MEMBER_HAS_TRANSACTIONS` |
| `GET /groups/{gid}/expenses?page&size&fromDate&toDate&memberId` | 200 `PageResponseExpenseView` | newest first |
| `POST /groups/{gid}/expenses/preview` `ExpenseCommand` | 200 `ExpensePreview` | no key, nothing saved; payers may be empty |
| `POST /groups/{gid}/expenses` (Idempotency-Key) | 201 `ExpenseView` (+`ETag`, `Idempotency-Replayed`) | |
| `GET/PUT/DELETE /groups/{gid}/expenses/{eid}` (PUT/DELETE: If-Match) | 200 / 200 / **204** | edit sends the explicit participant list |
| `GET /groups/{gid}/expenses/{eid}/revisions` | 200 `ExpenseRevisionView[]` | oldest first |
| `GET /groups/{gid}/balances` | 200 `BalanceView` | positive net = is owed |
| `GET/POST /groups/{gid}/settlements` (POST: Idempotency-Key), `DELETE .../{sid}` | 200 / 201 / **204** | |

> Since B9 the OpenAPI declares the real success statuses (201 for creates, 204 for deletes); regenerate the client after B9 (`docs/mobile-client.md`).

## 7. Error code -> UX
| Code | Meaning | UX |
|:--|:--|:--|
| `VALIDATION_ERROR` (422/400/413/428) | bad input | inline under the field when it can be attributed, else a short generic message; 428/413 are client bugs: generic + log `requestId` |
| `PAYERS_TOTAL_MISMATCH` | payers do not add up | red banner on the payers sheet, save disabled |
| `SPLIT_TOTAL_MISMATCH` | exact shares do not add up | banner on the split section |
| `MEMBER_NOT_IN_GROUP` | stale members | reload the group, keep the form |
| `IDEMPOTENCY_KEY_REUSED` | client bug | new key once, retry once, else generic |
| `DUPLICATE_MEMBER_NAME` | name taken | inline in the add/rename sheet |
| `MEMBER_HAS_TRANSACTIONS` | cannot delete | blocked dialog |
| `GROUP_NOT_EMPTY` | cannot delete group | blocked dialog |
| `OWNER_MEMBER_PROTECTED` | the group creator's own member cannot be deleted (B9) | do not offer delete for the member with `isYou`; if it happens, a short explanatory dialog (rename is allowed) |
| `VERSION_CONFLICT` | edited elsewhere | conflict dialog: reload latest, keep the user's input, let them re-apply |
| `NOT_FOUND` | gone or not yours | "no longer available", go back, refresh |
| `UNAUTHORIZED` | token problem | refresh flow; if it fails: session-expired dialog |
| `RATE_LIMITED` | too many sign-ins | wait message |
| `AUTH_PROVIDER_UNAVAILABLE` | Google keys unreachable | "try again in a moment" |
| `INTERNAL_ERROR` | server bug | generic error with the `requestId` |
