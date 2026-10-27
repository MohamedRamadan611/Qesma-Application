# Stitch AI — UI/UX Prompts for "Qesma" (working title)

## How to use
1. Create **one Stitch project** for the app (Mobile / Android).
2. Paste **Prompt 0** first to establish the design system. Review it, adjust colors/fonts if you like.
3. Then paste **Prompts 1–11** one at a time (Phase 1 screens). Each prompt covers one group of related screens. Every prompt repeats a short **STYLE line** so the screens stay consistent even if Stitch treats each prompt independently.
4. Iterate on each result with short follow-ups ("make the total bar sticky", "increase the touch targets", "show the empty state").
5. Prompts 12–14 are for **Phase 2** (collaboration). Use them later.
6. The UI text is **Arabic** (Egyptian-friendly wording, written inside the prompts). The prompts themselves are in English.

> If Stitch limits prompt length, shorten the descriptions but keep the STYLE line and the sample data.

## Shared sample data (use in every prompt)
Group: **"رحلة دهب"** (Dahab trip), type: trip, currency EGP (ج.م). Members in order: **محمد، عاصم، محسن، يوسف، كريم**.
Expenses:
- **بنزين** 600.00 ج.م — paid by محمد — split equally among all 5 (120.00 each).
- **فندق** 3,000.00 ج.م — paid by عاصم 2,000.00 + محمد 1,000.00 — split equally among all 5 (600.00 each).
- **عشاء مأكولات بحرية** 561.79 ج.م (restaurant bill) — paid by محمد 300.00 + محسن 261.79 — items: بيتزا 200.00 (محمد، عاصم), باستا 150.00 (محسن), مشروبات 90.00 (محمد، عاصم، محسن); service 12%; tax 14%. Per person: محمد 165.99, عاصم 165.98, محسن 229.82.
Net balances after those expenses: محمد **+1,014.01**, عاصم **+1,114.02**, محسن **−688.03**, يوسف **−720.00**, كريم **−720.00**.
Suggested transfers: يوسف → عاصم 720.00 · كريم → محمد 720.00 · محسن → عاصم 394.02 · محسن → محمد 294.01.

---

## Prompt 0 — Design system & component sheet

```
Design the visual system for a mobile app (Android, 360×800 base, Material 3 sensibility but with its own personality) called "قسمة" (Qesma): a group expense-splitting app for friends sharing trips, shared housing and outings in Egypt. The app only RECORDS who paid what and who owes whom; it never moves money.

Language & direction: Arabic first, full RTL layout (mirror all icons that imply direction, e.g. back arrows, chevrons). Use Egyptian-friendly, short, friendly microcopy. Use Western digits (0–9) for amounts. Currency label "ج.م" after the amount.

Tone: friendly, trustworthy, clean, a little playful — like a helpful friend who is good with money. NOT a cold banking app, NOT childish.

Color (light theme first):
- Primary: deep teal #0F766E (buttons, active tab, FAB). Primary container: soft teal #CCFBF1.
- Surface/background: #F8FAFB with white cards; border #E2E8F0; text #0F172A, secondary text #475569.
- "Owed to you / positive": green #15803D on light green #DCFCE7.
- "You owe / negative": orange-red #C2410C on light #FFEDD5. (Never rely on color alone: also use +/− signs and labels.)
- Warning/mismatch: amber #B45309 on #FEF3C7. Error: #B91C1C.
Typography: Cairo (or IBM Plex Sans Arabic) — headline 22/700, title 18/600, body 15/400, caption 13/400, numbers in a medium weight with tabular figures for amounts.
Shape & spacing: 16px corner radius on cards, 12px on inputs/chips, 28px on bottom sheets; 8px spacing grid; minimum touch target 48px.
Elevation: very light; prefer borders + subtle shadows.

Produce a component sheet showing: primary/secondary/text buttons, FAB with label "إضافة مصروف", text fields (default, focused, error, with currency suffix), amount input (large number), chips (member chip with colored avatar initial, selectable chip, assignee chip), segmented control, toggle row with optional percentage field, top app bar, tab bar (3 tabs), list tiles (group, expense, member, transfer), balance pill (positive/negative/zero), bottom sheet, dialog (confirm delete), snackbar, empty-state illustration style (simple, friendly line illustrations), skeleton loading, and an avatar set of 5 members with distinct pastel colors.
```

---

## Prompt 1 — Splash, welcome & sign-in

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design 3 screens for "قسمة":
1) Splash: centered logo mark (simple coin-split/two overlapping circles motif in teal) and the name "قسمة" with tagline "قسّموا المصاريف من غير خناقات".
2) Welcome (single screen, no carousel): friendly illustration of friends on a trip; headline "سجّلوا مصاريف الرحلة في مكان واحد"; three short value lines with icons — "مين دفع إيه ولمين" / "الحساب بيتعمل أوتوماتيك" / "تعرفوا مين يدفع لمين في الآخر". Primary button "ابدأ".
3) Sign-in: "سجّل دخولك" with one prominent button "الدخول بحساب جوجل" (Google logo), small text under it "التطبيق بيسجّل الحسابات بس — مبيتعاملش مع فلوسك". Footer links: "الشروط والأحكام" و"سياسة الخصوصية". Include a loading state on the button and an error snackbar state "حصلت مشكلة في الدخول، جرّب تاني".
```

---

## Prompt 2 — Groups list, create & edit group

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the groups flow for "قسمة":
1) Groups list screen titled "مجموعاتي". Show populated state with 3 group cards: "رحلة دهب" (icon: palm/beach, type chip "رحلة", 5 أعضاء, إجمالي المصاريف 3,761.79 ج.م, last activity "آخر مصروف: النهاردة"), "شقة المعادي" (type chip "سكن", 3 أعضاء, 4,200.00 ج.م), "خروجة الخميس" (type chip "خروجة", 4 أعضاء, 850.00 ج.م). Top bar has the profile avatar. Extended FAB: "+ مجموعة جديدة". Also design the EMPTY state: friendly illustration and text "لسه مفيش مجموعات — ابدأ بمجموعة جديدة", primary button "إنشاء مجموعة".
2) Create group screen (full screen, not a sheet): fields — group name (placeholder "مثلاً: رحلة دهب"), type selector as 4 big selectable cards "رحلة", "سكن", "خروجة", "أخرى" (each with an icon), currency selector defaulting to "جنيه مصري (ج.م)". Primary button "إنشاء المجموعة". Show validation error state for empty name: "اكتب اسم المجموعة".
3) Edit group: same form prefilled, with a destructive text button at the bottom "حذف المجموعة" and a confirmation dialog. Also show the dialog state explaining deletion is only possible when the group has no expenses: "مينفعش تحذف مجموعة فيها مصاريف".
```

---

## Prompt 3 — Group home shell & Expenses tab

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the Group Home for the group "رحلة دهب" with a top app bar (back, group name, overflow menu: "تعديل المجموعة") and three tabs: "المصاريف" (active), "الأرصدة", "الأعضاء".

Above the tab content show a compact summary card: "إجمالي المصاريف 3,761.79 ج.م" and "5 أعضاء · 3 مصاريف".

Expenses tab: list grouped by date headers ("النهاردة", "إمبارح", "12 أكتوبر"). Each expense tile shows: category-neutral icon, title, "دفع: محمد" (or "دفع: عاصم + محمد" for multiple payers), the total amount, and a small caption of how it was split ("على الكل", "على 3 أعضاء", "فاتورة مطعم"). Use the three sample expenses: "عشاء مأكولات بحرية" 561.79 (paid by محمد + محسن, caption "فاتورة مطعم"), "فندق" 3,000.00 (paid by عاصم + محمد, "على الكل"), "بنزين" 600.00 (paid by محمد, "على الكل"). Show an "تم التعديل" small badge on one tile. Extended FAB "إضافة مصروف".
Also design: the EMPTY expenses state ("لسه مفيش مصاريف — سجّل أول مصروف") and a loading skeleton state.
```

---

## Prompt 4 — Members tab & add/edit member

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the "الأعضاء" (Members) tab of the group "رحلة دهب" and its related sheets.
1) Members tab: list of 5 members with colored initial avatars: محمد، عاصم، محسن، يوسف، كريم. Each tile shows the name and a balance pill (محمد +1,014.01 green, عاصم +1,114.02 green, محسن −688.03 orange-red, يوسف −720.00 orange-red, كريم −720.00 orange-red). Add a small hint under the list: "الأعضاء بيتضافوا بالاسم بس — مش لازم يكون عندهم حساب". Button "+ إضافة عضو".
2) Add member bottom sheet: single text field "اسم العضو", primary button "إضافة", error state "الاسم ده موجود بالفعل في المجموعة".
3) Member options bottom sheet (tap a member): "تعديل الاسم", "حذف العضو".
4) Rename sheet.
5) Delete member: confirmation dialog for a member with no transactions, and a BLOCKED state for a member with transactions: "مينفعش تحذف عضو عليه مصاريف أو مدفوعات".
```

---

## Prompt 5 — Add expense (basic) & split selector

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the "إضافة مصروف" (Add expense) screen, optimized for fast entry with one hand. Full-screen with close (X) and a sticky bottom bar containing the primary button "حفظ".
Fields in order:
- Large amount input at the top "المبلغ" with "ج.م" suffix, autofocus with numeric keypad.
- Title "اسم المصروف" (placeholder "مثلاً: بنزين").
- Date row "التاريخ" defaulting to today.
- "مين دفع؟" row: shows a single member chip (default محمد) with a link "أكتر من شخص؟" that opens the multi-payer editor (separate prompt).
- "اتقسم على مين؟" segmented control with 3 options: "بالتساوي" · "مبالغ محددة" · "فاتورة مطعم". (Equal is default.)
  • Equal mode: a chip group of all 5 members, all selected by default, plus a quick "الكل" toggle and a live line "كل واحد هيدفع 120.00 ج.م". Allow deselecting members; show "3 من 5 أعضاء" and updated per-person amount "200.00 ج.م" (for 600 among 3).
  • Exact mode: a list of the 5 members each with an amount field, and a running indicator "المتبقي: 0.00 ج.م" that turns amber when not zero ("لسه فاضل 50.00 ج.م") and green when matched.
  • Restaurant-bill mode: shows a card "فاتورة مطعم" with a button "افتح تفاصيل الفاتورة" (opens the itemized editor, separate prompt).
Include states: validation errors ("اكتب المبلغ", "اختار شخص واحد على الأقل"), the equal-split rounding hint "القرش الزيادة بيتوزع تلقائيًا" (small caption, shown for 100.00 among 3 → 33.34 / 33.33 / 33.33), and a saving/loading state.
```

---

## Prompt 6 — Multiple payers editor

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the "مين دفع؟" (Who paid?) multi-payer editor as a full-height bottom sheet over the Add Expense screen, for the expense "فندق" total 3,000.00 ج.م.
Content:
- Header: "مين دفع؟" and the total chip "الإجمالي 3,000.00 ج.م".
- A list of all 5 members with checkboxes; selected members reveal an amount field. Selected: عاصم 2,000.00 and محمد 1,000.00.
- A sticky status card: "تم توزيع 3,000.00 من 3,000.00" with a green check when matched; amber state "لسه فاضل 500.00 ج.م" when not matched; red state "المبالغ أكتر من الإجمالي بـ 200.00 ج.م".
- A helper action "قسّم بالتساوي على اللي دفعوا".
- Primary button "تم" (disabled until amounts match the total).
Show 3 states: initial (single payer selected, full amount prefilled), partially filled with amber warning, and matched with green confirmation.
```

---

## Prompt 7 — Itemized restaurant bill editor (key screen)

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the "فاتورة مطعم" (Restaurant bill) editor — the most important screen. A single scrollable screen with a sticky bottom summary bar showing "الإجمالي 561.79 ج.م" and the primary button "تم".

Sections:
1) Items list. Each item is a card: item name, price field, and assignee chips (member avatars; tap to toggle who shared this item; if several are selected show "بيتقسم بينهم بالتساوي"). Sample items: "بيتزا" 200.00 → محمد، عاصم · "باستا" 150.00 → محسن · "مشروبات" 90.00 → محمد، عاصم، محسن. Button "+ إضافة صنف". Swipe to delete an item. A quick action "الكل" to assign an item to everyone.
2) Charges card with TWO INDEPENDENT optional toggle rows:
   - Toggle "خدمة" with a percentage field "12 %" (editable) — shows the calculated amount "52.80 ج.م" when on.
   - Toggle "ضريبة" with a percentage field "14 %" (editable) — shows "68.99 ج.م" when on, plus a small selector "تتحسب على: المجموع + الخدمة / المجموع فقط".
   Show clearly that the user can enable service only, tax only, both, or neither. Caption: "النِّسب دي مقترحة وتقدر تعدّلها حسب الفاتورة".
   - Optional row "تعديل (تقريب / بقشيش)" with a signed amount field.
3) "حصة كل شخص" card: live per-person breakdown table — columns: الاسم · الأصناف · الخدمة · الضريبة · الإجمالي. Rows: محمد 130.00 / 15.60 / 20.39 / 165.99 · عاصم 130.00 / 15.60 / 20.38 / 165.98 · محسن 180.00 / 21.60 / 28.22 / 229.82. A totals row: 440.00 / 52.80 / 68.99 / 561.79.
4) A line comparing the total with what payers entered: "الدافعين: 561.79 من 561.79 ✔" (and an amber state when they differ, with a link "غيّر الدافعين").
Design these states: all-toggles-off (totals only equal to subtotal), service-only, tax-only, both, an item with no one assigned (error: "اختار مين شارك في الصنف ده"), and a keyboard-open state with the sticky bar visible.
```

---

## Prompt 8 — Expense details, edit history & delete

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the Expense Details screen for "عشاء مأكولات بحرية" 561.79 ج.م, with top bar actions: edit (pencil) and overflow menu (حذف).
Sections:
- Header card: title, date, big total, chip "فاتورة مطعم", and a small "تم التعديل" badge.
- "مين دفع": two rows — محمد 300.00, محسن 261.79.
- "الأصناف": the 3 items with assignee avatars and prices; then rows for "الخدمة 12% — 52.80" and "الضريبة 14% — 68.99".
- "حصة كل شخص": rows with names and amounts (165.99 / 165.98 / 229.82).
- "سجل التعديلات" (collapsible): timeline entries such as "تم الإنشاء — محمد — النهاردة 9:40 م", "تم تعديل الخدمة من 10% إلى 12% — محمد — النهاردة 9:52 م". Each entry can expand to show the previous values.
States: delete confirmation dialog "تحذف المصروف ده؟ الأرصدة هتتحدّث وهيفضل في السجل"; a deleted-expense view (greyed, with the text "المصروف ده اتحذف" and the history still visible); a conflict dialog "المصروف ده اتعدّل وإنت بتعدّل فيه" with buttons "اعرض النسخة الأحدث" / "تجاهل تعديلاتي".
Also show a simple variant of this screen for an EQUAL expense ("بنزين" 600.00, paid by محمد, split among all 5 at 120.00 each).
```

---

## Prompt 9 — Balances tab, suggested transfers & record payment

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the "الأرصدة" (Balances) tab of the group "رحلة دهب".
Section 1 — "الصافي لكل شخص": list of 5 members with avatar, name, and a balance pill with an explicit label: محمد "ليه 1,014.01" (green), عاصم "ليه 1,114.02" (green), محسن "عليه 688.03" (orange-red), يوسف "عليه 720.00" (orange-red), كريم "عليه 720.00" (orange-red). Optionally a thin horizontal bar to visualise size. Add a sum check caption "المجموع = 0" in small grey text.
Section 2 — "مين يدفع لمين" (simplified transfers): 4 cards, each shows two avatars with an arrow and the amount, and a secondary button "سجّل دفعة":
 • يوسف ← عاصم 720.00 ج.م
 • كريم ← محمد 720.00 ج.م
 • محسن ← عاصم 394.02 ج.م
 • محسن ← محمد 294.01 ج.م
Header helper text: "ده أقل عدد تحويلات تقريبًا — التطبيق بيحسب بس، ومبيحوّلش فلوس".
Section 3 — "الدفعات المسجّلة": a collapsible list of recorded payments (empty state "لسه مفيش دفعات متسجّلة").
Design the "سجّل دفعة" bottom sheet: from (member picker, prefilled يوسف), to (prefilled عاصم), amount (prefilled 720.00, editable for partial payments), date, optional note, primary button "تسجيل". Show a partial-payment result state (e.g. 300.00 recorded → the transfer card updates to "باقي 420.00"), a fully-settled state ("كله متسوّى ✔" with a friendly illustration), and a state where a delete action appears on a recorded payment with an undo snackbar.
```

---

## Prompt 10 — Settings, Edit Profile & Account Settings

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the settings, profile editing, and account management suite for "قسمة":
1) Settings / Profile Hub (screen titled "الإعدادات" with back arrow):
   - Profile header card: user avatar (teal circle with white initials "م.ر" or photo), display name "محمد رمضان", email "mohamed@example.com", and a secondary text/outline button "تعديل الملف الشخصي" (opens Edit Profile).
   - "الحساب" section card: row "إعدادات الحساب" with a chevron (opens Account Settings).
   - "التفضيلات" section card: row "لغة التطبيق" with value "العربية" (opens language modal "العربية" / "English"); row "العملة الافتراضية" with value "جنيه مصري (ج.م)".
   - "عن التطبيق" section card: links "الشروط والأحكام", "سياسة الخصوصية", and app version "قسمة 1.0.0 (تجريبي)".
   - Destructive text button at the bottom: "تسجيل الخروج" with sign-out confirmation dialog.

2) Edit Profile screen (opened from "تعديل الملف الشخصي", full screen with back arrow and top bar action "حفظ"):
   - Centered large circular avatar (96×96) with an edit badge/camera icon button ("تغيير الصورة الشخصية").
   - Field 1: "الاسم المعروض" with value "محمد رمضان" and helper caption "الاسم ده هيظهر لأصحابك في المجموعات والمصاريف". Show inline error state for empty name: "اكتب اسمك عشان أصحابك يعرفوك".
   - Field 2: "البريد الإلكتروني" read-only field with Google icon and subtle chip "مرتبط بحساب جوجل".
   - Field 3: "رقم الموبايل" with Egyptian prefix "+20" and placeholder "01X XXXX XXXX" (optional, with caption "اختياري — لتسهيل إضافتك للمجموعات").
   - Bottom sheet for avatar: "التقاط صورة", "اختيار من المعرض", "استخدام الحرف الأول بالألوان", "إزالة الصورة".
   - Dialog state: unsaved changes warning "تجاهل التعديلات؟" with buttons "استمرار التعديل" / "تجاهل".
   - Success state: snackbar "تم حفظ التعديلات بنجاح".

3) Account Settings screen (opened from "إعدادات الحساب", full screen with back arrow and title "إعدادات الحساب"):
   - "بيانات الحساب": Google account card showing email "mohamed@example.com", status chip "متصل ✔", and "آخر دخول: النهاردة".
   - "بيانات الدفع والتسوية": card with note "البيانات دي بتظهر لأعضاء مجموعاتك بس عشان يسهل عليهم يحولولك فلوسك — التطبيق مبيحوّلش فلوس":
     • Field "عنوان إنستا باي (InstaPay)": placeholder "asem@instapay".
     • Field "رقم المحفظة الذكية (Smart Wallet)": placeholder "010XXXXXXXX".
   - "البيانات والخصوصية": row "تصدير ملخص حساباتي" (export CSV) and row "الأجهزة النشطة".
   - "المنطقة الخطرة" (red tinted card):
     • Button "تسجيل الخروج من كل الأجهزة".
     • Destructive button "حذف الحساب نهائيًا" that opens a two-step confirmation dialog explaining that account deletion permanently deletes groups owned by the user, unlinks balances, and cannot be undone: "هل أنت متأكد من حذف حسابك نهائيًا؟" with actions "إلغاء" and destructive "تأكيد حذف الحساب".
```

---

## Prompt 11 — System states, errors & onboarding coach marks

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design reusable system states and onboarding guidance for "قسمة":
1) No-internet screen (full-screen): friendly illustration of an unplugged cable or desert dune, headline "مفيش اتصال بالإنترنت", friendly body "التطبيق محتاج إنترنت عشان يحفظ ويسجّل المصاريف — اتأكد من شبكة الواي فاي أو باقة الموبايل", and primary button "حاول تاني".
2) Generic error screen (full-screen): friendly line illustration, headline "حصل خطأ غير متوقع", body "حاولنا ننفّذ طلبك بس حصلت مشكلة تقنية بسيطة", button "تحديث الصفحة" and text button "الرجوع للرئيسية".
3) Inline & component loading patterns: pull-to-refresh indicator (custom teal spinner), skeleton loading cards for group list and expense list tiles (subtle shimmer #F1F5F9).
4) Session expired dialog: modal dialog with headline "انتهت الجلسة", body "مر وقت طويل من غير نشاط، سجّل دخولك تاني عشان تكمل بأمان", primary button "تسجيل الدخول" (navigates to Google Sign-in).
5) First-use coach marks: sequence of 3 friendly floating tooltip cards on the Group Home screen:
   - Tooltip 1 pointing to FAB: "ابدأ من هنا وسجّل أول مصروف للرحلة".
   - Tooltip 2 pointing to tab 'الأرصدة': "هنا هتشوف مين عليه فلوس ومين ليه في ثواني".
   - Tooltip 3 pointing to tab 'الأعضاء': "ضيف أصحابك بالاسم بس ومن غير ما يحتاجوا يسجلوا حساب".
   Each tooltip has a "التالي" (Next) or "فهمت" (Got it) action and a "تخطي" (Skip) text button.
```

---

# Phase 2 prompts (use later, after Phase 1 is built and validated)

## Prompt 12 — Invite & join flow

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the collaboration entry flow for "قسمة":
1) Invite sheet in the group "رحلة دهب": a short invite code "DHB-4821" in a large copyable box, a link, buttons "مشاركة الرابط" (opens the system share sheet) and "نسخ الكود", settings "ينتهي بعد 7 أيام", "يحتاج موافقة الأدمن" toggle, and "إلغاء الدعوة" text button.
2) Join screen (opened from the link or by entering a code): group name, who invited you, member count, and the question "إنت مين من الأعضاء؟" with a list of unclaimed member names (محسن، يوسف، كريم) as radio cards plus "أنا عضو جديد". Primary button "انضم". States: expired invite, revoked invite, "في انتظار موافقة الأدمن".
3) Members tab updates: badges "متصل بحساب" vs "اسم فقط", role chips "مالك" / "أدمن", and a member options sheet with "ترقية لأدمن", "فصل الحساب", "عضو غادر".
```

## Prompt 13 — Settlement confirmation, payment handles & reminders

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design the two-sided settlement flow:
1) Transfer card for the current user (يوسف owes عاصم 720.00): shows عاصم's payment details with copy buttons — "إنستا باي: asem@instapay" and "محفظة: 010XXXXXXXX" — plus a clear note "التطبيق مبيحوّلش فلوس — حوّل من تطبيق البنك أو المحفظة وبعدين اضغط دفعت". Buttons "دفعت" (primary) and "نسخ البيانات".
2) Receiver view: notification-style card "يوسف بيقول إنه دفعلك 720.00 ج.م" with buttons "استلمت ✔" and "لسه مااستلمتش".
3) Status chips on transfers: "في انتظار التأكيد" (amber), "مؤكّد" (green), "فيه خلاف" (red) and a disputed-detail screen visible to both parties and admins with actions "تأكيد" / "إلغاء الدفعة".
4) "ذكّره" (Remind) button on a transfer you are owed, with a disabled/rate-limited state "اتبعت تذكير النهاردة".
5) Profile section "بيانات الدفع" to add/edit InstaPay address and wallet number with a privacy note "بتظهر لأعضاء مجموعاتك بس".
```

## Prompt 14 — Notifications center & activity feed

```
STYLE: Arabic-first RTL Android 360×800, teal #0F766E primary, Cairo font, 16px radius cards, green=owed to you (#15803D), orange-red=you owe (#C2410C), Western digits, currency "ج.م". Friendly, trustworthy, clean.

Design:
1) Notifications cetnter: list with unread indicators — "محمد ضافك في مصروف: فندق (600.00 ج.م)", "عاصم عدّل مصروف: بنزين", "يوسف بيقول إنه دفعلك 720.00 ج.م", "اتقبلت دعوتك: كريم انضم للمجموعة". Group-by day, mark-all-read action, empty state.
2) Group activity feed (a 4th tab or a screen from the group menu "النشاط"): a vertical timeline with avatars, concise Arabic sentences ("محمد أضاف: عشاء مأكولات بحرية — 561.79 ج.م"), relative times, and tap-through to the related expense.
3) Notification settings: global toggle, per-group mute switches, and a short explanation of when reminders are sent.
```
