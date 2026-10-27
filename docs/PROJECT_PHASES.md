# Qesma (working title) — Full Project Specification by Phase
## Phases 0–5 · v0.1

> Companion to `PROJECT_SPEC.md`, which contains the **line-by-line Phase 1 spec** (data model, engine rules, API, test vectors).
> This file defines **the whole project**: what each phase delivers, what it adds to the data model and API, rules, acceptance criteria, risks, and the gates between phases.
> Working title "Qesma" (قسمة) is a placeholder.

---

## 0. How to use this document

- Each phase is a **shippable slice**. Do not start phase N+1 until the **gate** at the end of phase N is passed (or consciously waived).
- Items marked **(decide)** are open decisions. Do not guess; ask or follow the Decision Log in `PROJECT_SPEC.md`.
- Estimates assume 10–12 hours/week by a solo developer and include learning Flutter. They are rough and must be revisited after Phase 0.
- Effort labels: S (< 1 week), M (1–3 weeks), L (3+ weeks).

### 0.1 Principles that apply to every phase
1. The app **never holds, moves, or processes money**. It only records. "Settle up" shows information; payment happens outside the app.
2. Money = integer minor units; percentages = integer basis points. No floating point.
3. The backend is the source of truth for calculations. Balances are **computed** from the ledger, never stored.
4. Nothing is hard-deleted from the ledger. Edits create revisions; deletes are soft.
5. All create endpoints are idempotent.
6. Personal data (names, phone/email, financial records, later payment handles and receipt images) is regulated by Egypt's Personal Data Protection Law No. 151 of 2020. Collect the minimum, and have a lawyer review before public release.
7. Everything happens **inside the app**. No WhatsApp/chat integration. Invitations use a link/code shared through the OS share sheet; reminders use push notifications.
8. Arabic (Egyptian, RTL) first; English second. EGP default.

### 0.2 Phase map

| Phase | Name | Users involved | Effort | Ships to |
|---|---|---|---|---|
| 0 | Validation & Design | 10 interviewees | 2 weeks (parallel) | Prototype only |
| 1 | Organizer Mode | 1 organizer per group | 9–11 weeks | Internal / friends testing |
| 2 | Collaboration | Whole group on their own phones | 6–8 weeks | Closed beta |
| 3 | Trip power features & release | Public | 5–6 weeks | Google Play |
| 4 | Offline & multi-currency | Travelers abroad | 4–6 weeks | Update |
| 5 | Monetization & growth | Paying users | Ongoing | Updates |

### 0.3 Feature → phase matrix (quick reference)

| Area | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|---|---|---|---|---|---|
| Auth | Google sign-in | Email/password (optional), account deletion | — | — | — |
| Groups | Create, list, edit, delete-if-empty | Roles, ownership transfer | Archive, close/reopen trip | — | Sub-groups |
| Members | Ghost members, rename, remove-if-no-txns | Invite, link to account, LEFT status, roles | — | — | — |
| Expense split | Equal (all/selected), Exact, **Itemized + optional service/tax** | — | Percent, Shares | — | — |
| Payers | **Multiple payers** | — | — | — | — |
| Expense extras | Edit/soft-delete + revisions | Activity feed, conflict UI | Refunds, categories, duplicate warning | Multi-currency | Receipt scan, dispute, recurring (housing) |
| Balances | Net + simplified transfers | — | Detailed pairwise view, trip summary | Base-currency balances | — |
| Settlement | Organizer records payments | Two-sided confirm, partial, disputed, payment handles | Final statement image | — | PDF/CSV export |
| Notifications | — | Push + "Remind" + in-app center | — | — | — |
| Platform | Idempotency, versioning | Version-conflict UX | Crash reporting, release | Offline queue | Paywall, iOS |

---

## Phase 0 — Validation & Design (≈ 2 weeks, runs alongside the start of Phase 1)

**Goal:** confirm real people have this problem and will use an Arabic, in-app solution; produce the UI design.

**Deliverables**
- 10 interviews (people who traveled or shared a flat in the last year). Questions: how do you split costs now; when did it last cause friction; have you tried Splitwise/Tricount and why did you stop; who chases payments; do you split restaurant bills by item; do service charge/tax matter; would you pay (and how much) to avoid chasing money.
- Competitor check: Google Play and App Store (Arabic apps and Egypt reviews), Facebook groups (shared housing, university trips). Re-check current Splitwise/Tricount/Kittysplit pricing and limits.
- UI/UX design for Phase 1 screens (see `STITCH_PROMPTS.md`) and a clickable prototype.
- Real restaurant receipts (collect 5–10) to verify how service charge and tax are actually laid out (this decides Decision A1 in `PROJECT_SPEC.md`).

**Gate 0 → 1 (suggested):** at least 3 people say they would use it for their next trip/outing and at least 1 would pay. If not, stop or pivot before writing backend code. (Thresholds are suggestions; confirm yourself.)

---

## Phase 1 — Organizer Mode (≈ 9–11 weeks)

**Goal:** one person (the organizer) runs the whole group from their phone: creates the group, adds members by name, records every expense (including multi-payer and restaurant bills), and sees correct balances and who pays whom. Prove the **core calculation** before any multi-user complexity.

**Full detail:** see `PROJECT_SPEC.md` (sections 3–11). Summary:

**In scope**
- Google sign-in; profile; Arabic RTL.
- Groups (TRIP / HOUSING / OUTING / OTHER) and ghost members.
- Expenses: title, date, **one or more payers with amounts**, and one of three split types:
  - **EQUAL** among all members or a selected subset (participants are snapshotted).
  - **EXACT** amounts per member.
  - **ITEMIZED restaurant bill**: items assigned to one or more members; **service charge optional** (own %), **tax optional** (own %), any combination (service only / tax only / both / neither); optional signed adjustment; both are allocated proportionally with the largest-remainder rule.
- Edit and soft-delete with revisions; idempotent creates; optimistic concurrency.
- Balances: net per member and simplified transfers; organizer records settlements (partial allowed).
- Housing use case in Phase 1: rent, electricity, internet, etc. are entered manually as ordinary expenses inside a HOUSING group (recurring automation arrives in Phase 5).

**Added to Slice 1 at the founder's request**
1. Multiple payers.
2. Restaurant bill with optional service charge and optional tax, each with its own percentage.

**Gate 1 → 2 (suggested):** at least 3 real trips/outings recorded end-to-end by someone other than you; the app's final balances match a manual check; no calculation bug found in the last week of use; you personally want to keep using it.

---

## Phase 2 — Collaboration (≈ 6–8 weeks)

**Goal:** turn the single-organizer tool into a real multi-user product where each person uses their own phone, adds their own expenses, and confirms payments. This is where the app becomes sticky.

### 2.1 Invitations
- Admin generates an **invite link** and a short **invite code** (share via OS share sheet; no WhatsApp integration).
- Invite properties: expiry (default 7 days, **(decide)**), revocable, optional max uses, optional "require admin approval".
- Android App Links (deep link) opens the app on the join screen; code entry is the fallback; if the app is not installed the link goes to the Play Store page (a simple landing page is acceptable).
- Joining requires sign-in.

### 2.2 Link member to account
- On joining, the user either **claims an existing ghost member** ("I am Asem") or **creates a new member**. Admin can unlink/relink.
- Rules: one account ↔ at most one member per group; a ghost member can be claimed once; all history stays attached to the member, not the account.

### 2.3 Roles and permissions
- Roles: `OWNER`, `ADMIN`, `MEMBER`.
- Matrix (default, **(decide)** after beta feedback):

| Action | Owner | Admin | Member |
|---|---|---|---|
| Add expense / settlement | ✔ | ✔ | ✔ |
| Edit/delete own expense | ✔ | ✔ | ✔ |
| Edit/delete others' expense | ✔ | ✔ | ✖ |
| Add/rename/remove members | ✔ | ✔ | ✖ |
| Manage invites | ✔ | ✔ | ✖ |
| Promote/demote admin | ✔ | ✖ | ✖ |
| Delete/close group | ✔ | close only | ✖ |
| Transfer ownership | ✔ | ✖ | ✖ |

- Implement as one central authorization component (replace Phase 1 owner-only checks).
- Anyone affected by an edit to an expense they participate in gets a notification (see 2.7).

### 2.4 Member lifecycle
- Member status: `ACTIVE` | `LEFT`. A member can leave any time (owner must transfer ownership first). A `LEFT` member stays in history and keeps their balance, cannot be added to new expenses; admin can reactivate.
- "Remove" in Phase 1 (only when no transactions) remains for ghost members with no history.

### 2.5 Settlement v2 (two-sided confirmation)
- Statuses: `PENDING` (payer tapped "I paid") → `CONFIRMED` (receiver tapped "Received") or `DISPUTED` (receiver tapped "Not received").
- Payer can cancel a `PENDING` settlement. Partial amounts allowed. Admin can record on behalf of two members (auto-`CONFIRMED`, flagged `recorded_by_admin`).
- **Balance rule (decide):** nets count only `CONFIRMED` settlements; `PENDING` ones are shown as an informational badge beside the transfer. Validate this with beta users.
- A `DISPUTED` settlement is visible to admins and both parties; resolution is manual (receiver confirms or payer cancels). The app does not arbitrate.

### 2.6 Payment handles
- Optional per-user fields: InstaPay address and mobile-wallet number. Shown only to members of shared groups, on the settle-up screen with a **Copy** button.
- The app only displays them; it never initiates a transfer. Treat as sensitive: minimal storage, access limited to group members, lawyer review, easy removal.

### 2.7 Notifications (push via FCM + in-app center)
- Events: added to an expense; an expense I'm in was edited/deleted; settlement pending/confirmed/disputed; invitation accepted; member joined/left.
- **Remind** button on a transfer: sends a push to the debtor; rate-limited (e.g. once per 24 h per debtor per group, **(decide)**).
- Per-group notification mute and a global toggle. Device-token management, token cleanup on logout.

### 2.8 Activity feed
- Per-group chronological feed built from revisions and events ("Mohamed added *Hotel* — 3,000 EGP", "Asem edited *Fuel*").

### 2.9 Concurrency UX
- On `VERSION_CONFLICT`, show a conflict screen: "This expense changed while you were editing" with the latest values and a choice to re-apply the user's edit or discard.

### 2.10 Account management
- **Account deletion** (required before public release; verify current Google Play requirements): personal data removed; the user's member records become "Deleted user" and the ledger remains intact so other members' balances are unaffected. Lawyer review of the retention approach.
- **Email/password sign-in (optional, decide):** needs email verification and password reset, which require an email-sending service. Add only if users without Google accounts are a real need.

### 2.11 Data model additions
```
members:       + role (OWNER|ADMIN|MEMBER), status (ACTIVE|LEFT), joined_at, left_at   (user_id now used)
group_invites: id, group_id, code, token_hash, created_by, expires_at, max_uses, use_count, requires_approval, revoked_at
join_requests: id, invite_id, user_id, status (PENDING|APPROVED|REJECTED), created_at
settlements:   + status (PENDING|CONFIRMED|DISPUTED|CANCELLED), declared_at, confirmed_at, disputed_at, recorded_by_admin boolean
payment_handles: id, user_id, type (INSTAPAY|WALLET), value, created_at
device_tokens: id, user_id, token, platform, last_seen_at
notifications: id, user_id, group_id, type, payload jsonb, read_at, created_at
notification_prefs: user_id, group_id, muted boolean
group_events:  id, group_id, actor_member_id, type, payload jsonb, created_at   (activity feed)
```

### 2.12 API additions (illustrative)
```
POST   /groups/{gid}/invites                 GET /groups/{gid}/invites      DELETE /groups/{gid}/invites/{iid}
POST   /invites/{code}/join                  (claim ghost member or create new)
POST   /groups/{gid}/members/{mid}/link      POST /groups/{gid}/members/{mid}/unlink
PATCH  /groups/{gid}/members/{mid}           (role, status)
POST   /groups/{gid}/transfer-ownership
POST   /groups/{gid}/settlements/{sid}/confirm | /dispute | /cancel
GET/PUT /me/payment-handles
POST   /groups/{gid}/transfers/remind        { fromMemberId, toMemberId }
GET    /notifications        POST /notifications/read        PUT /groups/{gid}/notification-prefs
POST   /devices              DELETE /devices/{id}
GET    /groups/{gid}/activity
DELETE /me                   (account deletion)
```

### 2.13 Acceptance criteria
1. Two phones: A creates a group and invites B by link; B claims a ghost member; both see the same data within a few seconds of a change (pull-to-refresh or push-triggered refresh is acceptable; real-time sockets are **not** required).
2. Role permissions enforced server-side for every endpoint (test matrix).
3. Full settlement lifecycle works: pending → confirmed; pending → disputed → cancelled.
4. Push received for each event type; mute works; Remind is rate-limited.
5. Deleting an account leaves all other members' balances unchanged.

### 2.14 Risks
Invite-link leakage (expiry, revoke, approval option); notification spam (per-group mute, rate limits); confusion over pending vs confirmed balances (clear UI copy); payment-handle privacy.

**Gate 2 → 3 (suggested):** at least 10 groups with 2+ real accounts each used it for a real trip/outing; users came back for a second group; no data-integrity incidents.

---

## Phase 3 — Trip power features & public release (≈ 5–6 weeks)

**Goal:** make trips pleasant and ship publicly.

### 3.1 More split types
- **PERCENT:** per-member percentages in bps; Σ must equal 10000.
- **SHARES:** per-member weights (positive, up to 2 decimals, stored as integer hundredths: 1.5 shares = 150); allocate with the largest-remainder rule. Useful for couples (2 shares) and kids (0.5).

### 3.2 Refunds
- Expense `kind = REFUND`, optionally linked to the original expense. Model: "received by" member(s) (cash returned to them) and "credited to" participants. Balance contribution is the reverse of a normal expense, so `Σ net == 0` is preserved. Property tests must cover refunds.

### 3.3 Categories
- Fixed set to start: food, transport, fuel, accommodation, activities, shopping, other (icons + Arabic labels). Filter and group by category.

### 3.4 Trip summary
- Total spent; per member: paid, owed, net; by category; by day; average per member. Shareable as an image rendered on the client.

### 3.5 Detailed balances view
- Toggle between **Simplified** (default) and **Detailed** (pairwise: who owes whom, per original expenses, netted pairwise). Same totals; different presentation.

### 3.6 Close / reopen trip and final statement
- Group status `OPEN | CLOSED`. `CLOSED` blocks new expenses but still allows settlements. Admin can reopen. Archive hides groups from the main list.
- **Final statement** (image) with totals, per-person net, and recorded settlements. (PDF export is Phase 5.)

### 3.7 Duplicate-expense warning
- On create: if an expense exists with the same total within ±1 day and the same payer or a similar title, show a non-blocking warning.

### 3.8 Release readiness
- Privacy policy and Terms (Arabic + English), Play Store listing (Arabic first), Data Safety form, signed release builds, staged rollout.
- Crash reporting (e.g. Firebase Crashlytics) and minimal, privacy-respecting analytics (screens and key events only, no financial values).
- Onboarding walkthrough (3 short screens), in-app "Send feedback" link, support contact.
- Backup **restore drill** (prove backups can be restored), basic load test, rate limiting review.
- Lawyer review of privacy policy, data retention, and account deletion.

### 3.9 Data model additions
```
expenses:      + kind (EXPENSE|REFUND), original_expense_id, category
expense_splits:+ percent_bps, shares_hundredths   (as inputs; owed_minor remains the resolved result)
expense_groups:+ status (OPEN|CLOSED), archived_at
```

### 3.10 Acceptance criteria
1. New split types and refunds pass new test vectors (add to the shared fixtures file) and the property tests (`Σ owed == total`, `Σ net == 0`).
2. A closed trip rejects new expenses and accepts settlements.
3. The app is published to Google Play (at least closed testing → production staged rollout).
4. Restore drill documented and successful.

**Gate 3 → 4 (suggested):** live on Play; first external (non-friend) groups completed; collect evidence on how often users have no internet while traveling (this decides Phase 4 priority).

---

## Phase 4 — Offline & multi-currency (≈ 4–6 weeks)

**Goal:** make the app dependable while traveling abroad.

### 4.1 Offline-first reads
- Local database (e.g. drift/SQLite) caches groups, members, expenses, settlements, balances for the user's groups.

### 4.2 Pending-operation queue
- Create/edit/delete expense and create settlement can be done offline. Each operation is stored with its `Idempotency-Key`, `baseVersion`, and timestamp, shown as "pending sync", and replayed on reconnect with retry/backoff.
- Conflict rules: creates never conflict (idempotent); edits/deletes use the version check — on conflict show the Phase 2 conflict UI; the server wins by default.
- **Engine parity (decide):** offline previews and offline balance display require the split/balance engine on the device. Port the engine to Dart and validate it with the **same shared JSON test fixtures** (all vectors from Phase 1+3) so both implementations are proven identical. The server remains authoritative and recomputes on sync; if a result differs, the server's result wins and the UI shows the update.

### 4.3 Multi-currency
- Group has a **base currency**. Per group, the organizer sets **exchange rates** (currency → base) manually, with an optional per-expense override. Live-rate lookup is optional and only if a free, compliant source is found (**verify terms/cost**).
- An expense has `currency_code`, `original_amount_minor`, `rate` (decimal stored as scaled integer, e.g. 1e6), and `amount_in_base_minor = round_half_up(original × rate)`. All balances and settlements are in the base currency.
- Itemized and multi-payer expenses in a foreign currency: compute allocation in the original currency, then convert each member's amount using the largest-remainder rule so the converted parts sum exactly to the converted total.
- Card/ATM fees are recorded as ordinary expenses.

### 4.4 Data model additions
```
expense_groups: (base currency = currency_code)
group_rates:    id, group_id, currency_code, rate_scaled bigint, set_by, set_at
expenses:       + currency_code, original_amount_minor, rate_scaled, (total_minor now = amount in base)
```

### 4.5 Acceptance criteria
1. Airplane-mode scenario: create a group's worth of expenses (all split types) offline; reconnect; no duplicates; balances match the server.
2. Dart engine passes the same fixtures as the Java engine (CI check for both).
3. Multi-currency vectors pass (add fixtures with rounding cases).

### 4.6 Risks
Duplicated engine logic (mitigated by shared fixtures); sync conflicts on edits; user confusion about which rate applies (always show the rate used).

**Gate 4 → 5 (suggested):** retention signal (e.g. users creating a second group); at least a few groups that ran across more than one trip.

---

## Phase 5 — Monetization & growth (ongoing)

**Goal:** earn money without harming the free experience. Everything here is a **hypothesis to validate**; do not build a paywall before users show willingness to pay.

### 5.1 Validate willingness to pay first
- Run small experiments with existing users before engineering: ask directly, offer a manual "pro" for a few groups, compare responses.
- Pricing options to **test** (ranges only; Egyptian consumers are price-sensitive, and free competitors exist): a one-time fee per group (roughly 20–60 EGP), or a household/monthly plan (roughly 15–40 EGP/month). Do not treat these as decided.
- Check how payment actually works for Egyptian users on Google Play (Play Billing rules and available local payment methods) and Apple's rules for iOS; **verify current policies and fees**.

### 5.2 Candidate paid features (pick by evidence)
- PDF/CSV export of statements; unlimited history and groups.
- **Receipt scanning with AI** (low cost per scan, but receipt images are personal data: require explicit consent, minimal retention, lawyer review; keep optional).
- **Recurring bills for HOUSING groups** (rent, electricity, internet auto-created each month from templates) — makes usage monthly rather than occasional. Consider pulling this earlier if Phase 0 interviews show housing is the main use case.
- **Shared kitty** (internal accounting of a pooled amount; no real money handled).
- **Sub-groups** (e.g. a family counted as one unit inside a bigger group).
- Receipt photo attachments; custom categories.
- Expense **dispute** button (mark an expense as disputed and notify its creator and admins).

### 5.3 Growth
- Invite loop: shareable trip summary/statement image that carries an app link.
- Optional read-only web view of a group summary for people without the app (privacy controls required).
- Arabic app-store optimization; community channels (university trip groups, shared-housing groups); a simple landing page.

### 5.4 Platform expansion
- iOS (only after Android proves demand; verify Apple Developer fees and review rules).
- Dark theme.

### 5.5 Long-term direction (not committed)
- A broader "shared money" app that also covers gam3eya (rotating savings groups) and family installments, reusing this core (members, ledger, reminders). Do this only after the expense-splitting product works and has users.

### 5.6 Acceptance
Each feature ships behind a clear success metric chosen in advance (e.g. conversion to paid ≥ X% of active groups; export feature used by ≥ Y% of closed trips). Remove or rework features that miss their metric.

---

## 6. Cross-phase technical debt guardrails

- Keep a single `fixtures/` folder of JSON test vectors (inputs and expected outputs) used by both the Java engine tests and, from Phase 4, the Dart engine tests.
- Keep `currency_code` on the group from day one; never assume EGP in code.
- Keep authorization centralized from day one so roles (Phase 2) are additive.
- Every migration is forward-only and reviewed; test migrations against a copy of production-like data before releases.
- Maintain the Decision Log in `PROJECT_SPEC.md`; add an entry whenever a rule changes.

## 7. Risk register (project level)

| Risk | Impact | Mitigation |
|---|---|---|
| Free competitors good enough (Tricount etc.) | Low adoption/revenue | Local edge (Arabic, EGP, in-app flow, restaurant service/tax); validate in Phase 0 and each gate |
| Willingness to pay is low | No income | Treat as a validation project; keep costs near zero; consider Phase 5 experiments early |
| Calculation bug destroys trust | Churn | Pure engine + shared fixtures + property tests; revisions for traceability |
| Legal/privacy (Law 151/2020) | Fines, takedown | Minimal data, lawyer review before release, account deletion |
| Solo developer bandwidth (10–12 h/week) | Delays | Strict phase gates; defer non-essential features; reconsider time allocation against foreign-client freelance work at each gate |
| Offline complexity | Bugs, delays | Phase 4 only after demand evidence; shared fixtures |
