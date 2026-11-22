# Qesma — Standalone release spec (local-first Android app)

Status: **Decided (SA0, 2026-11-17)**. Owner decisions are recorded here and in the Decision Log of `PROJECT_SPEC.md` (A121 onward). Decision: ADR-011. Dependencies: ADR-012. Prompt index: `prompts/STANDALONE_PROMPTS.md`.

`PROJECT_SPEC.md` stays authoritative for every money rule (section 7), error code (8.5) and Phase 1/2 behaviour. This file adds what is different or new in the standalone app. Where they disagree about a standalone topic, this file wins and the change is recorded in the Decision Log. All invariants of `AGENTS.md` still hold, read as described in section 3.

---

## 1. Scope

The first public release is a **standalone Android app for one organizer**: no deployed server, **$0 running cost**. The Java backend is frozen (not deleted) at the git tag `server-phase-ready` and returns in the server phase.

| Slice | Content | Prompts |
|---|---|---|
| **Launch (1.0.0)** | Phase 1 core (groups, ghost members, equal / exact / itemized, multi-payer, revisions, balances, simplified transfers, payments); categories; My share; trip recap image; reminder tones (WhatsApp); pool & treasurer (أمين الصندوق); Khorouga fuel / ride calculator; receipt OCR; backup | SA1–SA13, BSA1 |
| **Update 1** | Voice entry | SA14 |
| **Server phase** (not written yet) | To-buy checklist (members claim items); multi-user features (invites, join, roles management, settlement confirm/dispute, remind, notifications, activity, push B18/FL17, FL15, FL16, B19/FL18); "upload my local data" import endpoint and the `RemoteRepository` switch; server endpoints for My share and recap | later |

Out of the standalone release (not built): accounts and sign-in, any server call except the OCR request (section 13) and, in update 1, the speech service (section 14), analytics, crash reporting, ads, iOS, web, multi-currency conversion, percent/shares splits, refunds, user-defined categories, offline queue (the app is offline by design), exports other than the backup (section 6).

## 2. App modes

`--dart-define=QESMA_MODE=local|server` selects the mode at build time.

- **`server`**: today's app, unchanged. Default for debug builds and tests (existing tests keep running against the fake servers).
- **`local`**: the release mode. `main.dart` plugs `LocalBackend` (an `HttpClientAdapter`) into `httpAdapterProvider`; the same repositories, DTOs and generated client run unchanged against SQLite. `API_BASE_URL` is needed only in server mode.

**Hidden in local mode** (absent from the widget tree, not disabled; one place decides, SA4): sign-in, sign-out, registration, password and session screens, session-expired dialog, token storage; invites, join, join requests, link/unlink; role chips and role management; leave group and transfer ownership; settlement confirm / dispute / pending chips and the receiver card; server Remind (FL14) and its rate limit; notifications, activity feed and notification settings; account deletion. A `/join/<code>` link is ignored (SA4 decides the page; the words "coming soon" stay banned by the guard).

**Stays:** the **"you" member = member #1** of every group, created with the group (B9, A53), renamable, not removable; **OWNER role** for that member in every group; ghost members; groups, expenses, balances, payments (cancel), revisions; own payment handle (used only by reminder tones, section 12); language and theme.

## 3. Local backend rules

The local backend is the authority in local mode (ADR-011): invariants 3 and 4 hold *inside the app*. Money rules live only in `packages/qesma_engine` and in `lib/local/service/`; screens compute nothing.

1. **Same contract:** the same endpoints, DTOs (generated `qesma_api` serializers), status codes, `Location`/`ETag`/`Idempotency-Replayed` headers, and Problem JSON (`application/problem+json`, stable `code` from spec 8.5 and A15) as the Java backend. Unexpected errors become `500 INTERNAL_ERROR` without stack traces; nothing is swallowed; logs carry ids only (invariant 10).
2. **Same limits:** `FieldRules` (group name 60, member name 40, page size default 20 / max 100, group types TRIP/HOUSING/OUTING/OTHER, ISO currency shape `[A-Z]{3}`, default EGP) and `ExpenseValidator` (title 100, item name 100, at most 100 payers / participants / shares / items, bps 0..10000, `expenseDate` between 2000-01-01 and 2100-12-31) and `Limits.MAX_AMOUNT_MINOR` = 10^12 piasters per amount. The local port is pinned to these values by the conformance suite (SA3).
3. **ETag / If-Match:** `version` carried as in spec 7.9; a stale `If-Match` returns `409 VERSION_CONFLICT` with `currentVersion` and the latest state (B17 shape, A113).
4. **Idempotency-Key (spec 8.3):** the key write and the business write share one drift transaction. Same key + same body → the stored response with `Idempotency-Replayed`; same key + different body → `422 IDEMPOTENCY_KEY_REUSED`. Keys are kept 24 hours and purged at app start. There is one local user, so the key scope is `(key)`.
5. **Settlements** created in local mode are **CONFIRMED immediately** (the caller is the Owner and everyone else is a ghost: A85). The Phase 2 balance rule "CONFIRMED only" (A83) is unchanged. A cancel (A87) stays available, because it is the only way to undo a payment; confirm and dispute are not served.
6. **Identity:** one `local_profile`; `GET /me` reads it; `PATCH /me` renames it (1–60 characters).
7. **Engine:** all splits, preview, balances and suggested transfers come from `qesma_engine`, which must reproduce the Java engine on every vector in `fixtures/` (parity rule, ADR-011).
8. **Atomicity:** every write is one drift transaction together with its revision and idempotency record.

## 4. Endpoints served in local mode (derived from the repositories in `lib/features/*/data`)

**Served:** `GET/PATCH /me`; `GET/PUT /me/payment-handles`; `POST/GET /groups`; `GET/PATCH/DELETE /groups/{gid}`; `POST/PATCH/DELETE /groups/{gid}/members[/{mid}]`; `POST /groups/{gid}/expenses/preview`; `POST/GET /groups/{gid}/expenses`; `GET/PUT/DELETE /groups/{gid}/expenses/{eid}`; `GET …/revisions`; `GET /groups/{gid}/balances`; `POST/GET /groups/{gid}/settlements`; `POST …/settlements/{sid}/cancel`.

**Answered with `404 NOT_FOUND`** (and never reachable from the UI): `/auth/*`, `/me/password`, `DELETE /me`, invites, join, join requests, unlink, leave, transfer-ownership, settlement confirm and dispute, `/transfers/remind`, notifications, activity, notification prefs. `PATCH member` with `role` or `status` → `422 VALIDATION_ERROR`.

**Contract additions** (BSA1, mirrored locally by SA6/SA10): `expense.category`, `expense.paidFromPool`, `settlement.kind`, `group.treasurerMemberId`, `group.poolBalanceMinor`, list filter `?category=`.

## 5. Data rules

1. Ids are UUID v4 as TEXT; money and bps are INTEGER (piasters, basis points); dates `YYYY-MM-DD`; timestamps are UTC epoch milliseconds as INTEGER (SA2, A151). Schema details: A152-A157 and `mobile/lib/local/db/schema.drift`.
2. **Soft delete and revisions:** the ledger is never hard-deleted; every edit and delete writes an immutable revision snapshot (JSON). Groups and members follow the Phase 1 rules (A23). **Balances are computed, never stored** — and so are the pool meter, My share and the recap.
3. **Invariants live in the schema** as SQLite CHECK / UNIQUE / FK / NOT NULL (the Postgres CHECKs of spec 6 are ported one by one; `PRAGMA foreign_keys = ON`, WAL). Member-name uniqueness is on a normalized `name_key` filled by one Dart function (SQLite `lower()` is ASCII-only).
4. **Forward-only migrations** (drift step migrations, exported schema snapshots, generated migration tests). Never edit a shipped step.
5. **Server compatibility:** ids, field names and JSON shapes match the server contract so that a later "upload my local data" import needs no conversion. Server-only tables (users, tokens, invites, events, notifications, remind log) are not created locally; `local_profile` and `local_meta` are new.
6. Small local settings (last reminder tone, saved fuel prices, OCR consent and daily counter, backup reminder state) are stored in the drift DB. `shared_preferences` stays banned (A148).

## 6. Backup

Without a server the phone holds the only copy, so backup is a **launch requirement**.

1. **Export:** `qesma-backup-v1.json` with `formatVersion`, `schemaVersion`, `exportedAt`, app version and every table needed to rebuild the ledger (groups, members, expenses with children, revisions, settlements, profile, own handles). Ids are preserved; idempotency keys are not exported. The file contains names and amounts; the share text says so.
2. **Import:** replace-all after an explicit confirmation (merge is out of scope). Validation **before** anything is written: format/schema version, referential integrity, limits, and a **recompute check**: balances recomputed by the engine sum to 0 and each expense's shares sum to its total. One transaction; on any failure nothing changes. A newer `formatVersion` is refused with a clear message.
3. **Android auto-backup** includes the drift database file and excludes caches and secure storage. This **replaces** the FL2 `android:allowBackup="false"` rule (A128); SA5 changes the manifest, the guard and the ADR-006 addendum together.
4. A dismissible reminder banner after 10 new expenses or 14 days since the last export (SA5, A165); dismiss snoozes it 7 days.
5. SA5 details: file format and limits A162, import A163, auto-backup and WAL A164, reminder and schema 2 A165. Profile hub (local mode): "Export backup" (confirm, then the share sheet) and "Restore from backup" (file picker, validation, counts and a destructive confirm); the export share text and the privacy policy say the file contains names and amounts.

## 7. Categories

Fixed enum, in this order: `FOOD, TRANSPORT, FUEL, ACCOMMODATION, GROCERIES, SHOPPING, ENTERTAINMENT, BILLS, OTHER`. Default `OTHER`. No user-defined categories at launch. Category is part of the revision snapshot, an expense list filter (`?category=`), and has an icon plus text label (never colour alone). The Phase 3 list in `PROJECT_PHASES` 3.3 is replaced by this one.

## 8. My share

For one calendar month and one category, across **all groups**, over non-deleted expenses, latest revision only:

- **Consumed** = Σ of the **"you" member's `owed`**.
- **Paid up front** = Σ of the "you" member's payer amounts.
- Settlements (payments, deposits) are **excluded**. A group without a "you" member contributes nothing.
- Month = the calendar month of `expenseDate` (it is already a local date; no timezone shift is applied; Africa/Cairo only decides what "this month" means on the screen).
- **Per currency:** the table is built per `currencyCode` with no conversion; one section per currency that has data, EGP first (A131). Most users see only EGP.
- Output order is deterministic (month descending, category enum order). Percentages are basis points from the engine (LRM, sum exactly 10000, ties by category enum order); the widget computes nothing.
- Local-only computation (`qesma_engine` `insights/my_share.dart`, reached through a local repository, not a fake HTTP endpoint); hidden in server mode (A150).

## 9. Trip recap

For one group, non-deleted expenses:

- **Total spent**, expense count, date range, per-member paid totals.
- **Top payer** = largest sum of payer amounts; tie → lower `sortOrder`.
- **Biggest expense** = largest `totalMinor`; tie → earlier `expenseDate`, then earlier `createdAt`.
- **Category split**: totals per category and percentages in **basis points by LRM that sum to exactly 10000**; the LRM tie-break uses the category enum order as `sortOrder` (A133). A group with no expenses has no recap.
- Shared as an image (WhatsApp) and as text (who pays whom, from `GET balances`). **Member names appear only after the user confirms sharing** (confirm dialog). Every image carries the app name; the footer holds the Play link after SA13. Computed locally; no network.

## 10. Pool & treasurer (أمين الصندوق)

An internal ledger of a pooled kitty. The app records it and **never holds money** (invariant 2).

1. Group setting `treasurerMemberId` (nullable; an ACTIVE member of the same group).
2. A **deposit** is a settlement **member → treasurer** with `kind = POOL_DEPOSIT` (the settlement default kind is `PAYMENT`). A deposit **to anyone but the treasurer is rejected**. The treasurer cannot deposit to themselves: `from <> to` stays (A138); the treasurer's own cash simply lowers the meter or makes it negative.
3. A **pool expense** is an expense whose **single payer is the treasurer** and `paidFromPool = true`. It is valid only when the group has a treasurer; otherwise `422 VALIDATION_ERROR`.
4. **Meter** = Σ CONFIRMED deposits − Σ totals of non-deleted pool expenses. It **may go negative** (the treasurer fronted cash; shown with text, not colour only). Never stored: `GroupDto.poolBalanceMinor`, null when there is no treasurer, computed in one query.
5. Unequal deposits are allowed. Leftover and overdraft **settle through the normal balances and suggested transfers** (the kind does not change any net: tested). Only **received** deposits are recorded. The treasurer's own share of an expense is calculated like anyone's.
6. **Changing the treasurer** (including clearing it; clearing has no request in the contract, so it is not offered: A167) is allowed only while **no deposit and no pool expense exists**, counting cancelled and soft-deleted rows (the ledger is never hard-deleted). The error code is chosen in BSA1 and added to `ErrorCode`, the OpenAPI enum and `ApiContractCoverageIT`.
7. Authorization: the same roles that edit the group / record settlements; no new permission.

## 11. Khorouga calculator (حاسبة البنزين وأوبر)

Pure functions in `qesma_engine`; integer / BigInt math only; no network, no maps. The result **prefills an EXACT expense** the user reviews (category FUEL or TRANSPORT, the driver as the default payer). The calculator never saves anything itself.

**Fuel trip.** Inputs: distance in **tenths of km**, consumption in **tenths of L/100 km** (1.0–30.0), price per litre in piasters, tolls in piasters (a list), riders (memberId, sortOrder), driver in or out of the riders.

- `fuelMinor = round_half_up(km_tenths × l100_tenths × pricePerLitreMinor / 10000)` (BigInt intermediates, 7.1).
- `total = fuelMinor + Σ tolls` (≤ 10^12).
- Split **equally by LRM** among the chosen riders, ties by `sortOrder`; the driver counts only if chosen.
- The fuel price is **user-editable** with a "last updated" date; no network fetch (A142). Update (2026-11-22, owner): the app bundles a small list of reference prices (official Egyptian pump prices with their date) offered as a tappable suggestion; the user decides, can edit it, and it is refreshed with each release.

**Multi-stop ride.** Ordered stops form legs; each leg has a distance in tenths of km; each rider has a boarding and a leaving stop; the total fare is in piasters.

1. Leg fare = **LRM of the total fare with weights = leg distance in tenths** (all-zero weights → equal, 7.1.5).
2. Each leg's fare is split **equally (LRM)** among the riders on board in that leg, ties by `sortOrder`.
3. A rider's share = the sum over their legs.
4. **A leg with no riders on board is rejected** (`VALIDATION_ERROR`; the user fixes the stops) (A141).

Decimal inputs (km, L/100 km) are parsed by string logic like `Money.parse`, never `double`; Arabic-Indic digits and the comma are accepted; at most one decimal.

**SA11 details (A168):** fuel types 80 / 92 / 95 / diesel; saved prices live in `fuel_prices` (local schema 6) and are not part of the backup; `,` is a decimal point in km and L/100 km fields (no grouping); limits and fixture rules are in A168.

## 12. Reminder tones

Chasing money should be kind. Three tones — **soft, firm, funny** — as ARB templates (Egyptian Arabic primary, English) with placeholders `{name}`, `{amount}`, `{group}` and an optional `{handle}` line (the user's own InstaPay address, added by a toggle only if the profile has one). The owner approves the copy; the funny tone never shames or insults.

- Opens `https://wa.me/?text=<urlencoded>` through `url_launcher` (no phone number stored or used); falls back to the system share sheet if WhatsApp is missing.
- Preview text is **editable**; **never auto-sent**; the last tone is remembered in the local DB; no server rate limit in local mode. Server-mode Remind (FL14) is unchanged.

## 13. Receipt OCR

A 20-item restaurant bill is unusable by hand. The AI only **proposes**; the user confirms every number.

- **Backend:** Firebase AI Logic with the Gemini Developer API on the **free tier** (Spark plan, **no billing account**) and **App Check** with Play Integrity (debug provider for dev builds). No API key in the app or the repo.
- **Consent:** a one-time screen before the first scan stating that the **image is sent to Google** and, on the free tier, **may be used to improve Google products** (to verify against the current terms in SA12, A146), how to avoid it (type manually), stored locally and revocable in the profile.
- **Capture:** camera or gallery, downscaled and compressed before upload, EXIF/location stripped. **The image is never stored, logged or uploaded anywhere else**; nothing is written outside the temp directory.
- **Output:** (extended by 18.4) structured JSON schema (`items[{name, amount}]`, `subtotal`, `servicePercent`, `serviceAmount`, `taxPercent`, `taxAmount`, `total`, `currency`) with **every amount as a string**, parsed by `Money.parse` / `Bps.parse`. Items that fail to parse are kept with an empty amount and flagged. The model's arithmetic is never trusted.
- **Result:** opens the itemized editor as an **unsaved draft** (never auto-saved); a banner when items + charges differ from the printed total (taken from the editor's existing preview, not client math).
- **Limits:** a per-device cap of **20 scans per calendar day** (Africa/Cairo), counted locally (A145; the number is checked against the free-tier quota in SA12).
- **Failure modes** — offline, timeout, quota exhausted, App Check / permission denied, unreadable photo, invalid JSON — each shows its own Arabic message and a "type manually" action; repeated permission errors hide the feature.

## 14. Voice entry (update 1)

`speech_to_text` with locale `ar-EG` (fallback `ar`), **on-device when available** (otherwise the user is told audio goes to Google's speech service; privacy policy updated). It fills **title and amount only**, from a pure number-words parser (Western and Arabic-Indic digits, Egyptian number words, "ونص"/"وربع", "جنيه"/"ج"); ambiguous input yields no amount and the user types it. The transcript is shown and **confirmed by the user**; the form is never saved by voice.

## 15. Guard change list (text only; each SA prompt applies its part)

**`scope_guard_test.dart`** (per-feature keys, like the Phase 2 ones; a feature's prompt enables its key in the same commit as its screens):

| Key | Prompt | Unlocks |
|---|---|---|
| `backup` | SA5 | `export`, `import`, `backup`, `restore`; Icons.download, Icons.upload, Icons.file_download |
| `categories` | SA6 | category words (none banned today) |
| `myShare` | SA7 | the phrase `monthly spend`; a route for My share |
| `recap` | SA8 | Icons.photo / Icons.share for the image share; route `'/recap` |
| `reminders` + `whatsapp` | SA9 | the existing `reminders` key plus the word `whatsapp` |
| `pool` | SA10 | `أمين الصندوق`, `الصندوق`, `إيداع`, `treasurer`, `deposit`, `pool` |
| `calculator` | SA11 | calculator words (fuel, tolls, ride); route `'/calculator` |
| `receiptScan` | SA12 | `receipt`, `scan`, `إيصال`; Icons.camera, Icons.receipt, Icons.document_scanner, Icons.photo |
| `voice` | SA14 | `voice`, `microphone`; Icons.mic |

SA4 adds a **per-mode allow-list**: in local mode the server-only features (`invites`, `settlements` pending/dispute copy, server `reminders`, `notifications`, `accountDeletion`, sign-in copy) must be unreachable. The `_permanent*` lists keep `guest`, `contacts`, `coupon`, `premium`, `subscribe`, `ads`, `coming soon`, `قريبا`, `pay now`, `ready to settle`, `cover photo`; `receipt`, `scan`, `export`, `إيصال`, `monthly spend` and the camera/photo/receipt/scanner/download/upload icons move out of the permanent lists into the keys above.

**`source_guards_test.dart`:**
1. The pubspec ban narrows to allow **exactly** `firebase_core`, `firebase_ai` and `firebase_app_check`; `analytics`, `crashlytics`, `sentry`, `amplitude`, `mixpanel`, `shared_preferences`, `connectivity_plus`, `package_info_plus` stay banned (SA2 and SA12 apply their part).
2. Path exemptions: `lib/local/db/` (persistence, no money math; SA2) and `lib/local/service/` (money math only through `qesma_engine` calls and plain sums of stored amounts; SA3) are exempt from the arithmetic/rounding guard; `double`/`num` stay banned there. `packages/qesma_engine/` is not under `lib/` and has its own purity test (SA1).
3. New guard: `package:qesma_engine` is imported only under `lib/local/**` (A149); `lib/features/**` never computes splits, balances, meter, My share or recap.
4. The `allowBackup="false"` test is replaced by a backup-rules test (SA5, A128).
5. The "balances arithmetic" and "no hard-coded strings" guards stay as they are.

**`members_guard_test.dart`:** no change planned; SA4 verifies that role chips are absent in local mode.

## 16. Amendments to existing documents

| Document | Change |
|---|---|
| `PROJECT_SPEC.md` 3.2, 12 | The standalone release overrides the "out of scope" list for its features (pointer added) |
| `PROJECT_PHASES.md` 0.1-7 | "No WhatsApp integration" now means: no API and no auto-send; user-edited share / `wa.me` text is allowed |
| `PROJECT_PHASES.md` 3.3, 3.4, 5.2 | Categories, trip summary (recap) and receipt scan moved to the standalone release; 3.8 crash reporting is deferred (no crash SDK at launch) |
| `PROJECT_PHASES.md` 4.2 | "Engine parity (decide)" is decided by ADR-011 |
| ADR-006 / FL2 | `allowBackup="false"` is replaced by backup rules (A128) |
| `AGENTS.md` rule 11, routing; `mobile/AGENTS.md`; `SCREEN_MAP.md` rules 1, 2, 8 | Standalone scope, `qesma_engine` and `lib/local/` routing, local backend as the only other place with money math, local mode is offline by design |
| Spec 11 privacy ("no receipt images") | Receipt images are processed by Google only with consent and are never stored (section 13) |

## 17. Ownership (nothing unowned)

| Feature | Spec section | Decision Log | Prompt(s) |
|---|---|---|---|
| Modes, hidden features | 2 | A121, A122 | SA4 |
| Dart engine | 3 | A121 | SA1 |
| Local database | 5 | A126, A148 | SA2 |
| Local backend | 3, 4 | A123–A125, A149 | SA3 |
| Backup | 6 | A127, A128 | SA5 |
| Categories | 7 | A129 | BSA1, SA6 |
| My share | 8 | A130, A131, A150 | SA7 |
| Trip recap | 9 | A132–A134, A150 | SA8 |
| Reminder tones | 12 | A143 | SA9 |
| Pool & treasurer | 10 | A135–A138, A167 | BSA1, SA10 |
| Khorouga calculator | 11 | A139–A142 | SA11 |
| Receipt OCR | 13 | A144–A146 | SA12 |
| Voice entry | 14 | A147 | SA14 |
| Itemized v2 (discount, quantity, charges as amounts, editor UX, OCR v2) | 18 | A171–A176 | BSA2, SA15, SA16, SA17 |
| Release, privacy | all | — | SA13 |

## 18. Itemized bill v2: discount, quantity, charges as amounts (BSA2, SA15–SA17)

Owner decisions of 2026-11-20 (A171–A176). Section 7.4 of `PROJECT_SPEC.md` is extended as follows. Bills without the new fields compute exactly as before: V5–V8 do not change.

### 18.1 Input (additions)
- **Item:** `quantity` is an integer 1..999 (default 1). `unitAmountMinor` is greater than 0. The line amount `amountMinor = quantity × unitAmountMinor` is computed in the engine with exact multiplication and is subject to the A43 cap. A request sends **either** `amountMinor` (legacy; it means quantity 1) **or** `unitAmountMinor` with an optional `quantity`, never both. Responses always carry `quantity`, `unitAmountMinor` and `amountMinor`.
- **Discount** (optional) is one discount on the whole bill. It is `{ bps }` (1..9,999) **or** `{ amountMinor }` (≥ 1), never both.
- **Service** is `{ bps }` (as before) **or** `{ amountMinor }` (≥ 1).
- **Tax** is `{ bps, base }` (as before) **or** `{ amountMinor, base }`. In the amount form, `base` sets only the allocation weights.
- **Delivery** (A180, V22 / schema 9) is an optional `deliveryMinor`: an integer from 0 to the A43 cap (absent or 0 = none). It is an **amount only**, never a percentage. A negative value or one above the cap is `VALIDATION_ERROR`. It is allowed on ITEMIZED expenses only. Responses carry `deliveryMinor` on the charges, on the preview and on every share of an itemized expense (0 when there is none).

### 18.2 Algorithm (replaces 7.4 steps 2–5)
1. **Item shares:** unchanged. Each line is split equally among its assignees with LRM. This gives `itemsMinor[m]` and `subtotal`.
2. **Discount:**
   - `discountTotal = round_half_up(subtotal × bps / 10000)` or the given amount.
   - It must satisfy `0 < discountTotal < subtotal`, otherwise `VALIDATION_ERROR`.
   - Allocate it by LRM with weights `itemsMinor[m]`, which gives `discountMinor[m]`.
   - `netMinor[m] = itemsMinor[m] − discountMinor[m]` and `netSubtotal = subtotal − discountTotal`.
   - With no discount, net equals items.
3. **Service:** `serviceTotal = round_half_up(netSubtotal × bps / 10000)` or the amount, allocated by LRM with weights `netMinor[m]`.
4. **Tax:**
   - The base is `netSubtotal`, or `netSubtotal + serviceTotal`.
   - `taxTotal = round_half_up(base × bps / 10000)` or the amount.
   - It is allocated by LRM with weights `netMinor[m]`, or `netMinor[m] + serviceMinor[m]`.
5. **Delivery (A180):** outside the discount, service and tax (it is part of no base and gets none of them). `deliveryMinor` is split **equally** (weight 1 each) among the members who have **at least one item**, meaning they are assigned to any line, even when their share of it is 0. LRM gives any leftover piasters to the lowest `sort_order` first. Members with no item get 0 delivery. With no delivery every part is 0.
6. **Adjustment:** allocated by LRM with weights `netMinor[m]`. A12 (no negative share) is unchanged.
7. `owed[m] = netMinor[m] + serviceMinor[m] + taxMinor[m] + deliveryMinor[m] + adjustmentMinor[m]`, and `total = netSubtotal + serviceTotal + taxTotal + delivery + adjustment`, which must be > 0. Members who owe 0 are dropped (step 6). The breakdown adds `discountMinor` per member and `deliveryMinor` per member, and the result adds `discountMinor` and `deliveryMinor` (the totals).

### 18.3 Printed-total tolerance (client only, A174)
This applies when a scanned receipt gave a printed total, the user has not edited the adjustment, and `|printed − previewTotal| ≤ 100` piasters (1 EGP). The editor then sets `adjustmentMinor = printed − previewTotal`, previews again, and shows the match with a note.
- The engine and the payers rule do not change (Σ payers == total exactly, 7.5).
- If the engine rejects the adjustment (A12), the mismatch banner stays.

### 18.4 Receipt OCR additions (SA17; extends section 13)
- **Schema additions:**
  - per item, `quantity` and `unitPrice`;
  - `discountAmount`, `discountPercent`, `merchantName`;
  - `category`, one of the section 7 values or null.
  - All amounts stay strings, and the model is told never to calculate.
- **Mapping:**
  - `merchantName` fills the **title** only while it is empty.
  - `category` fills the category only while the user has not chosen one.
  - A printed line total with a quantity but no unit price is flagged for the user to confirm. The client never divides.
  - An unparseable quantity is flagged, and the item opens as quantity 1.
  - A quantity above 1 without a unit price opens as quantity 1 with the line total; a printed percentage wins over a printed amount (A179).

### 18.5 Editor UX (SA16; design P8-01 revised)
- **Assignment modes:** "حسب الصنف" (one card per item) and "حسب الشخص" (choose a person, then tick that person's items).
- **Compact item card:** name, quantity stepper, unit price and a ⋮ menu (Duplicate, Delete with undo); then a summary chip for the assignees.
- **Member chips:** groups of ≤ 5 members get inline chips. Bigger groups get a summary chip that opens a member picker sheet (search above 8 members, all/none toggle).
- **Charge rows:** the discount, service and tax rows each have a `% | ج.م` toggle.
- **Breakdown:** each person shows one row (name and total), which expands to show the details.
- **Validation:** required fields are marked. Save stays enabled; tapping it with an error scrolls to the first error and shows how many fields are missing.
- **Money math:** every computed number still comes from the preview endpoint. The client does no money math (`SCREEN_MAP.md` rule).

**Redesign (A181, design "Add Expense – Redesigned Screen", UI only except delivery):**
- **Form shell:** the date and the category share one row (the category is a button that opens its nine chips in a sheet); the payer is one row with a "تغيير" button; the split method is one row (title, chosen method, one-line explanation, chevron) that opens a sheet with the four methods. At text scale above 1.3 the rows stack.
- **By item (accordion):** one item card is open at a time and the others are one-line rows (name, "× quantity · who", the typed price, a chevron, an error icon when something is missing). A new item opens; the first item is open when the form opens. The open card has the name and ⋮ menu (Duplicate, Delete with undo), the unit price and the quantity stepper side by side, one "مين شارك؟" button (always the summary chip that opens the member picker, whatever the group size) and the typed line (`quantity × price` as typed, never multiplied by the client).
- **Member picker:** an item with quantity above 1 and more than one member has a "بالتساوي | حسب الكمية" toggle. By quantity each person gets a number of units: "وزّعت x من n" (a count, with icon and words), a stepper per person, "مسح الكل", and Done is enabled only when the units add up to the quantity. Done splits the item into one item per person as in A172 (the separate unit-split sheet is gone). Equal mode is the usual checklist.
- **By person:** one card per member who has items (avatar, name, item count, the preview's total), one card open at a time. The open card lists their items (each removable from that person), "نسخ صنف موجود" chips for the items they are not on, and an inline "إضافة صنف لـ X" form (name, price, quantity). Members with no items are folded under "أعضاء من غير أصناف (n)". An item nobody has is flagged with icon and words.
- **Charges card:** discount, delivery (amount only: no `% | ج.م` toggle), service and tax, in that order after the discount; delivery shows the preview's per-person part ("بتتقسم بالتساوي على اللي معاهم أصناف: X لكل واحد", or "من X لـ Y" when parts differ by a piaster). A preview refused with `VALIDATION_ERROR` while every field is readable and a discount is on shows "الخصم لازم يكون أقل من إجمالي الأصناف." on the discount row, **without numbers** (the client does not add up the items).
- **Validation:** after Save on an incomplete bill a summary card at the top lists every problem in screen order (title, payer, each item's name, price, quantity and members, each charge); a tap goes to it and opens that item. The count line next to Save stays, and the page still scrolls to the first problem. Errors always have an icon and words.
- **Scan notices** (SA12/SA17) can be closed.

### 18.6 Test vectors
Vectors V9, V10, V12 and V13 use the V5 items: members A, B, C in `sort_order`; Pizza 200.00 (A, B), Pasta 150.00 (C), Drinks 90.00 (A, B, C); so items are A 130.00, B 130.00, C 180.00 and the subtotal is 440.00.

| # | Input | Expected |
|---|---|---|
| V9 | Discount 10%, service 12%, tax 14% on `SUBTOTAL_PLUS_SERVICE` | Discount 44.00 → A 13.00, B 13.00, C 18.00; net 396.00. Service 47.52 → 14.04 / 14.04 / 19.44. Tax round_half_up(443.52 × 14%) = 62.09; floors 18.34 / 18.34 / 25.40; the extra piaster goes to A on a tie → 18.35 / 18.34 / 25.40. Owed **A 149.39, B 149.38, C 206.84**, total **505.61** |
| V10 | Discount 50.00 (amount); no service, no tax | Discount 14.77 / 14.77 / 20.46 (the remainder goes to C, .45 > .27). Owed **A 115.23, B 115.23, C 159.54**, total **390.00** |
| V11 | Members A, B. Pepsi quantity 3 × 15.25 (A, B); Shawarma quantity 1 × 85.00 (A) | Pepsi line 45.75 → A 22.88, B 22.87. Owed **A 107.88, B 22.87**, total **130.75** |
| V12 | Service 50.00 (amount); no tax | Service 14.77 / 14.77 / 20.46. Owed **A 144.77, B 144.77, C 200.46**, total **490.00** |
| V13 | Service 12%, tax 60.00 (amount) on `SUBTOTAL_PLUS_SERVICE` | Service 15.60 / 15.60 / 21.60. Tax weights 145.60 / 145.60 / 201.60; floors 17.72 / 17.72 / 24.54; the 2 piasters left go to A and B → 17.73 / 17.73 / 24.54. Owed **A 163.33, B 163.33, C 226.14**, total **552.80** |
| V14 | Members A, B. One item 100.00 (A, B); discount 99.99 (amount) | Discount 50.00 / 49.99 (A wins the tie). Net A 0.00, B 0.01. **A is dropped** (owes 0). Owed **B 0.01**, total **0.01** |
| V15 | As V14 but discount 100.00, or 100% | `VALIDATION_ERROR` (discount must be less than the subtotal) |
| V16 | An item with both `amountMinor` and `unitAmountMinor`, or quantity 0 or 1000 | `VALIDATION_ERROR` |
| V17 | Members A, B, C, D. Pizza 200.00 (A, B), Pasta 90.00 (C); delivery 10.00 | Delivery 3.34 / 3.33 / 3.33 for A, B, C (D has no item, owes nothing). Owed **A 103.34, B 103.33, C 93.33**, total **300.00** |
| V18 | V9 (discount 10%, service 12%, tax 14%) plus delivery 10.00 | Every V9 part is unchanged; delivery 3.34 / 3.33 / 3.33. Owed **A 152.73, B 152.71, C 210.17**, total **515.61** |
| V19 | Members A, B, C. Burger 60.00 (A), Salad 30.00 (B); delivery 10.00; adjustment −5.00 | Delivery 5.00 / 5.00 (C has no item). Adjustment −5.00 by net 60:30 → −3.33 / −1.67. Owed **A 61.67, B 33.33**, total **95.00** |
| V20 | Delivery −0.01, or 10,000,000,000.01 | `VALIDATION_ERROR` |
