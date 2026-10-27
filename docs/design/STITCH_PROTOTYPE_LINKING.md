# Stitch Prototype Linking — "Qesma" (قسمة) Phase 1

Goal: connect **all existing screens and states** into one clickable prototype so you can view every action, count taps, and show it to real users.

---

## 0. Read this first (honest limits)

- Stitch prototypes are **screen-to-screen links (hotspots)**. Nothing is calculated: balances, counts and lists do not change when you click. Each "result" is just another pre-designed screen.
- I could not verify that every Stitch version can wire hotspots **from a text prompt**. Try the prompts below; if Stitch ignores or half-does them, use the same lines as a **manual wiring checklist** in Stitch's prototype mode (select a screen → Prototype → draw a hotspot on the element → choose the destination).
- **Do not let Stitch regenerate or restyle screens while linking.** Every prompt says so. Duplicate the project (or the screens) first if you're nervous.
- States that are not reachable through normal clicking (loading, errors, validation, conflict) are reachable through a **test-only "Prototype Index" screen** (prompt L9).
- Overlays (bottom sheets, dialogs) are separate screens in Stitch, so each overlay needs a link **in** (from its parent) and a link **out** (close/cancel back to the parent).

## 1. Naming convention (do this before linking)

Rename every screen to its ID so prompts and your notes match. If your names differ, run L1 and let Stitch map them.

| ID | Screen / state | ID | Screen / state |
|---|---|---|---|
| P1-01 | Splash | P6-01 | Multi-payer — initial |
| P1-02 | Welcome | P6-02 | Multi-payer — partial (amber) |
| P1-03 | Sign-in | P6-03 | Multi-payer — matched (green) |
| P1-04 | Sign-in — loading | P6-04 | Multi-payer — over total (red) |
| P1-05 | Sign-in — error | P7-01 | Itemized — service OFF, tax OFF |
| P2-01 | Groups list — empty | P7-02 | Itemized — service ON only |
| P2-02 | Groups list — populated | P7-03 | Itemized — tax ON only |
| P2-03 | Create group | P7-04 | Itemized — service ON + tax ON |
| P2-04 | Create group — validation error | P7-05 | Itemized — item with nobody assigned (error) |
| P2-05 | Edit group | P7-06 | Itemized — keyboard open |
| P2-06 | Delete group — confirm dialog | P7-07 | Itemized — payers mismatch |
| P2-07 | Delete group — blocked dialog | P8-01 | Expense details — itemized |
| P3-01 | Group home — Expenses (populated) | P8-02 | Expense details — equal |
| P3-02 | Group home — Expenses (empty) | P8-03 | Expense details — history expanded |
| P3-03 | Group home — Expenses (loading skeleton) | P8-04 | Delete expense — dialog |
| P4-01 | Members tab | P8-05 | Expense — deleted view |
| P4-02 | Add member sheet | P8-06 | Edit conflict dialog |
| P4-03 | Add member — duplicate error | P9-01 | Balances tab |
| P4-04 | Member options sheet | P9-02 | Record payment sheet |
| P4-05 | Rename member sheet | P9-03 | Balances — after partial payment |
| P4-06 | Delete member — confirm | P9-04 | Balances — all settled |
| P4-07 | Delete member — blocked | P9-05 | Payment deleted — undo snackbar |
| P5-01 | Add expense — equal (all) | P10-01 | Settings / Profile Hub |
| P5-02 | Add expense — equal (subset) | P10-02 | Edit profile |
| P5-03 | Add expense — exact amounts | P10-03 | Edit profile — avatar picker sheet |
| P5-04 | Add expense — restaurant mode entry | P10-04 | Edit profile — unsaved changes dialog |
| P5-05 | Add expense — validation errors | P10-05 | Account settings |
| P5-06 | Add expense — saving | P10-06 | Delete account — confirmation dialog |
| | | P10-07 | Sign-out dialog |
| | | P11-01 | No internet |
| | | P11-02 | Generic error |
| | | P11-03 | Loading skeleton (generic) |
| | | P11-04 | Session expired dialog |
| | | P11-05 | Coach marks |

Plus the test-only screen **IX-00 Prototype Index** (created in L9).

---

## L1 — Mapping check (run first; changes nothing)

```text
Look at all screens in this project. Do NOT change, regenerate or restyle anything. Produce a table that maps each existing screen to one of these IDs: P1-01 Splash; P1-02 Welcome; P1-03 Sign-in; P1-04 Sign-in loading; P1-05 Sign-in error; P2-01 Groups list empty; P2-02 Groups list populated; P2-03 Create group; P2-04 Create group validation error; P2-05 Edit group; P2-06 Delete group confirm dialog; P2-07 Delete group blocked dialog; P3-01 Group home Expenses populated; P3-02 Group home Expenses empty; P3-03 Group home Expenses loading skeleton; P4-01 Members tab; P4-02 Add member sheet; P4-03 Add member duplicate error; P4-04 Member options sheet; P4-05 Rename sheet; P4-06 Delete member confirm; P4-07 Delete member blocked; P5-01 Add expense equal all; P5-02 Add expense equal subset; P5-03 Add expense exact; P5-04 Add expense restaurant mode entry; P5-05 Add expense validation errors; P5-06 Add expense saving; P6-01 to P6-04 Multi-payer initial / partial / matched / over; P7-01 Itemized service off tax off; P7-02 service only; P7-03 tax only; P7-04 service and tax; P7-05 item unassigned error; P7-06 keyboard open; P7-07 payers mismatch; P8-01 Expense details itemized; P8-02 Expense details equal; P8-03 History expanded; P8-04 Delete expense dialog; P8-05 Deleted view; P8-06 Conflict dialog; P9-01 Balances; P9-02 Record payment sheet; P9-03 Balances after partial payment; P9-04 All settled; P9-05 Payment deleted undo; P10-01 Settings / Profile Hub; P10-02 Edit profile; P10-03 Avatar picker sheet; P10-04 Edit profile unsaved changes dialog; P10-05 Account settings; P10-06 Delete account dialog; P10-07 Sign-out dialog; P11-01 No internet; P11-02 Generic error; P11-03 Loading skeleton; P11-04 Session expired; P11-05 Coach marks.
Rename each matched screen to "ID – name". List separately: (a) screens that exist but match no ID, (b) IDs with no screen. Do not create the missing screens.
```

---

## Global rules (included in every wiring prompt below)

- Use only existing screens; do not redesign, regenerate or move elements.
- **Navigation** (screen → screen): forward motion mirrored for RTL; the top-app-bar back arrow returns to the parent listed in the link map.
- **Bottom sheets**: slide up from the bottom; closing returns to the parent.
- **Dialogs**: fade in; "إلغاء" returns to the parent.
- Tabs (Expenses / Balances / Members) link to each other without a back stack.
- If an element has no destination in the map, leave it unlinked.

---

## L2 — Flow A: Onboarding & sign-in

```text
Create prototype links for the onboarding flow. Use only existing screens; do not change, regenerate or restyle any screen. Forward navigation is mirrored for RTL; back arrows return to the previous screen.
- P1-01 Splash: tap anywhere (or auto-advance after 1.5 seconds if supported) → P1-02.
- P1-02 Welcome: button "ابدأ" → P1-03.
- P1-03 Sign-in: button "الدخول بحساب جوجل" → P2-01 (new user, empty groups list). Back → P1-02.
- P1-04 and P1-05 (loading and error states) have no incoming links; they are reached from the Prototype Index. On P1-05, button "حاول تاني" → P1-03.
Report any element that should link but couldn't.
```

## L3 — Flow B: Groups

```text
Create prototype links for the groups flow. Use only existing screens; do not change anything visually.
- P2-01 Groups list (empty): button "إنشاء مجموعة" → P2-03; profile avatar (top bar) → P10-01.
- P2-02 Groups list (populated): group card "رحلة دهب" → P3-01; the other two cards ("شقة المعادي", "خروجة الخميس") → P3-01 as well; button "+ مجموعة جديدة" → P2-03; profile avatar → P10-01.
- P2-03 Create group: button "إنشاء المجموعة" → P3-02 (new group with no expenses); close/back → P2-01.
- P2-04 Create group validation error: reached from the Index only; the fix path "إنشاء المجموعة" → P3-02.
- P2-05 Edit group: button "حذف المجموعة" → P2-07 (blocked because the group has expenses); back → P3-01.
- P2-06 Delete group confirm dialog: reached from the Index only; "إلغاء" → P2-05; "حذف" → P2-02.
- P2-07 Delete group blocked dialog: button "حسنًا" → P2-05.
Report any element that should link but couldn't.
```

## L4 — Flow C: Group home & members

```text
Create prototype links for the group home and members. Use only existing screens; do not change anything visually.
- P3-01 Group home (populated): tab "الأرصدة" → P9-01; tab "الأعضاء" → P4-01; extended FAB "إضافة مصروف" → P5-01; expense tile "عشاء مأكولات بحرية" → P8-01; expense tiles "فندق" and "بنزين" → P8-02; overflow menu "تعديل المجموعة" → P2-05; back → P2-02.
- P3-02 Group home (empty): FAB or primary empty-state action → P5-01; tab "الأرصدة" → P9-01; tab "الأعضاء" → P4-01; back → P2-02.
- P3-03 Loading skeleton: reached from the Index only; no outgoing links except back → P2-02.
- P4-01 Members tab: tab "المصاريف" → P3-01; tab "الأرصدة" → P9-01; button "+ إضافة عضو" → P4-02; each member tile → P4-04; back → P2-02.
- P4-02 Add member sheet: button "إضافة" → P4-01; close → P4-01.
- P4-03 Add member duplicate error: Index only; close → P4-01.
- P4-04 Member options sheet: "تعديل الاسم" → P4-05; "حذف العضو" → P4-06; tap outside → P4-01.
- P4-05 Rename sheet: button "حفظ" → P4-01; close → P4-01.
- P4-06 Delete member confirm: "إلغاء" → P4-01; "حذف" → P4-01.
- P4-07 Delete member blocked: Index only; button "حسنًا" → P4-01.
Report any element that should link but couldn't.
```

## L5 — Flow D: Add expense, multi-payer, itemized bill

```text
Create prototype links for adding expenses. Use only existing screens; do not change anything visually.
Add expense:
- P5-01 (equal, all): close (X) → P3-01; button "حفظ" → P3-01; link "أكتر من شخص؟" → P6-01; segmented control "مبالغ محددة" → P5-03; segmented control "فاتورة مطعم" → P5-04; tapping a member chip to deselect → P5-02.
- P5-02 (equal, subset): "الكل" toggle → P5-01; segmented "مبالغ محددة" → P5-03; segmented "فاتورة مطعم" → P5-04; "حفظ" → P3-01; close → P3-01.
- P5-03 (exact): segmented "بالتساوي" → P5-01; segmented "فاتورة مطعم" → P5-04; "حفظ" → P3-01; close → P3-01.
- P5-04 (restaurant mode entry): button "افتح تفاصيل الفاتورة" → P7-01; segmented "بالتساوي" → P5-01; segmented "مبالغ محددة" → P5-03; "حفظ" → P3-01; close → P3-01.
- P5-05 (validation errors) and P5-06 (saving): Index only; P5-05 "حفظ" after fixing → P3-01; P5-06 has no outgoing link.
Multi-payer:
- P6-01 (initial): selecting a second payer → P6-02; "قسّم بالتساوي على اللي دفعوا" → P6-03; close → P5-01.
- P6-02 (partial, amber): "قسّم بالتساوي على اللي دفعوا" → P6-03; entering an amount that exceeds the total → P6-04; close → P5-01.
- P6-03 (matched, green): button "تم" → P5-01.
- P6-04 (over total, red): "قسّم بالتساوي على اللي دفعوا" → P6-03; close → P5-01.
Itemized bill (each toggle shows a different combination):
- P7-01 (service off, tax off): toggle "خدمة" → P7-02; toggle "ضريبة" → P7-03; button "تم" → P5-04; back → P5-04.
- P7-02 (service only): toggle "خدمة" (off) → P7-01; toggle "ضريبة" (on) → P7-04; "تم" → P5-04.
- P7-03 (tax only): toggle "ضريبة" (off) → P7-01; toggle "خدمة" (on) → P7-04; "تم" → P5-04.
- P7-04 (service + tax): toggle "خدمة" (off) → P7-03; toggle "ضريبة" (off) → P7-02; link "غيّر الدافعين" → P6-01; button "+ إضافة صنف" → P7-05; tapping a price field → P7-06; "تم" → P5-04; back → P5-04.
- P7-05 (item unassigned error): assigning a member chip to the item → P7-04.
- P7-06 (keyboard open): "تم" → P7-04.
- P7-07 (payers mismatch): Index only; link "غيّر الدافعين" → P6-01.
Report any element that should link but couldn't.
```

## L6 — Flow E: Expense details

```text
Create prototype links for expense details. Use only existing screens; do not change anything visually.
- P8-01 (itemized details): back → P3-01; edit (pencil) → P7-04; overflow menu "حذف" → P8-04; "سجل التعديلات" header → P8-03.
- P8-02 (equal details): back → P3-01; edit (pencil) → P5-01; overflow menu "حذف" → P8-04.
- P8-03 (history expanded): collapse "سجل التعديلات" → P8-01; back → P3-01.
- P8-04 (delete dialog): "إلغاء" → P8-01; "حذف" → P3-01.
- P8-05 (deleted view): Index only; back → P3-01.
- P8-06 (conflict dialog): Index only; "اعرض النسخة الأحدث" → P8-01; "تجاهل تعديلاتي" → P3-01.
Report any element that should link but couldn't.
```

## L7 — Flow F: Balances & payments

```text
Create prototype links for balances and payments. Use only existing screens; do not change anything visually.
- P9-01 (Balances tab): tab "المصاريف" → P3-01; tab "الأعضاء" → P4-01; button "سجّل دفعة" on each suggested transfer card → P9-02; back → P2-02.
- P9-02 (record payment sheet): button "تسجيل" → P9-03; close → P9-01.
- P9-03 (after partial payment): button "سجّل دفعة" on the remaining transfer → P9-02; a button or link that settles the remainder (if present) → P9-04; delete icon on a recorded payment → P9-05; tabs as in P9-01.
- P9-04 (all settled): tab "المصاريف" → P3-01; tab "الأعضاء" → P4-01.
- P9-05 (undo snackbar): snackbar action "تراجع" → P9-03.
Report any element that should link but couldn't.
```

## L8 — Flow G: Settings, Edit Profile & Account Settings

```text
Create prototype links for settings, profile editing, and account settings. Use only existing screens; do not change anything visually.
- P10-01 (Settings / Profile Hub): profile card or button "تعديل الملف الشخصي" → P10-02; row "إعدادات الحساب" → P10-05; button "تسجيل الخروج" → P10-07; back → P2-02.
- P10-02 (Edit profile): action "حفظ" → P10-01; camera badge on avatar → P10-03; back (with unsaved changes) → P10-04; back (no changes) → P10-01.
- P10-03 (Avatar picker sheet): option tap or close → P10-02.
- P10-04 (Edit profile unsaved changes dialog): "استمرار التعديل" → P10-02; "تجاهل" → P10-01.
- P10-05 (Account settings): button "حذف الحساب نهائيًا" → P10-06; back → P10-01.
- P10-06 (Delete account dialog): "إلغاء" → P10-05; "تأكيد حذف الحساب" → P1-03.
- P10-07 (Sign-out dialog): "إلغاء" → P10-01; "تسجيل الخروج" → P1-03.

System states (P11):
- P11-01 (no internet): button "حاول تاني" → P2-02.
- P11-02 (generic error): button back or retry → P2-02.
- P11-03 (loading skeleton): no links.
- P11-04 (session expired): button to sign in → P1-03.
- P11-05 (coach marks): "تخطي" or the last tip's button → P3-02.
These system screens have no incoming links; they are opened from the Prototype Index.
Report any element that should link but couldn't.
```

---

## L9 — Prototype Index (test-only launchpad for unreachable states)

```text
Create ONE new screen called "IX-00 Prototype Index (test only)" in the app's visual style (Arabic RTL, teal #0F766E, Cairo). It is not part of the real app. Show a scrollable list grouped by flow with section headers: "الدخول" (P1), "المجموعات" (P2), "المصاريف والأعضاء" (P3–P4), "إضافة مصروف" (P5–P7), "التفاصيل والأرصدة" (P8–P9), "الإعدادات والملف الشخصي" (P10), "حالات النظام" (P11). Each row is the screen ID and name, and links to that screen. Include every screen listed in the mapping table (P1-01 through P11-05).
Then, on every screen that has NO incoming link from the real flow (P1-04, P1-05, P2-04, P2-06, P3-03, P4-03, P4-07, P5-05, P5-06, P7-07, P8-05, P8-06, P10-03, P10-04, P10-06, P11-01, P11-02, P11-03, P11-04, P11-05), add an invisible 48×48 hotspot in the top-end corner that links back to IX-00. Do not change anything else visually.
Set IX-00 as an optional alternative start screen for the prototype (the main start screen remains P1-01).
```

## L10 — Link QA (run after wiring)

```text
Audit the prototype links without changing any design. Report as a table:
1. Tappable-looking elements (buttons, tiles, tabs, toggles, chips, FABs, back arrows, close icons) that have no destination but should have one.
2. Screens with no incoming link that are not listed as "Index only".
3. Links that go to a screen different from the link map I gave you in this conversation.
4. Overlays (sheets, dialogs) with no way to close or cancel.
5. Dead ends (a screen with no way forward or back) and loops that trap the user.
6. Inconsistencies in transitions (sheets should slide up, dialogs fade, tabs switch without a back stack).
Then fix items 1–5 using the link map, and list anything you could not fix.
```

---

## 2. Click-through test (Golden Path) — do this after wiring

Open the prototype at **P1-01** and verify each step lands on the expected screen. Count taps (excluding typing).

| # | Action | Expected screen |
|---|---|---|
| 1 | Tap splash | P1-02 Welcome |
| 2 | "ابدأ" | P1-03 Sign-in |
| 3 | "الدخول بحساب جوجل" | P2-01 Groups (empty) |
| 4 | "إنشاء مجموعة" | P2-03 Create group |
| 5 | "إنشاء المجموعة" | P3-02 Group home (empty) |
| 6 | Tab "الأعضاء" | P4-01 Members |
| 7 | "+ إضافة عضو" → "إضافة" | P4-02 → P4-01 |
| 8 | Tab "المصاريف" → FAB "إضافة مصروف" | P3-02 → P5-01 |
| 9 | "حفظ" (simple equal expense) | P3-01 |
| 10 | FAB → "أكتر من شخص؟" → "قسّم بالتساوي…" → "تم" | P5-01 → P6-01 → P6-03 → P5-01 |
| 11 | "فاتورة مطعم" → "افتح تفاصيل الفاتورة" | P5-04 → P7-01 |
| 12 | Toggle "خدمة", then "ضريبة" | P7-02 → P7-04 |
| 13 | "تم" → "حفظ" | P5-04 → P3-01 |
| 14 | Tap "عشاء مأكولات بحرية" | P8-01 |
| 15 | "سجل التعديلات", back | P8-03 → P3-01 |
| 16 | Tab "الأرصدة" | P9-01 |
| 17 | "سجّل دفعة" → "تسجيل" | P9-02 → P9-03 |
| 18 | Settle the remainder (if present) | P9-04 |
| 19 | Avatar → "تعديل الملف الشخصي" → "حفظ" → "تسجيل الخروج" → confirm | P10-01 → P10-02 → P10-01 → P10-07 → P1-03 |

Then repeat the **branch tests**: all four itemized combinations (P7-01 ↔ P7-02 ↔ P7-03 ↔ P7-04), all three split modes (P5-01 / P5-03 / P5-04), delete flow (P8-04), and every state from the Index.

Compare your tap counts with the targets in `STITCH_UX_TEST_PROMPTS.md` (section F2). If a task is too long, use the "task takes too many steps" prompt there.

## 3. Sharing the prototype
Open it on a real Android phone (or share the preview link if Stitch provides one) and run the 5-person test from `STITCH_UX_TEST_PROMPTS.md` (section F4). Remember: the prototype is static, so tell testers that numbers don't update when they tap.
