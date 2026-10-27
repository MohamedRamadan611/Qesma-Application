# Stitch-native UX/UI Test & Fix Prompts — "Qesma" (قسمة)

Paste these **directly into Stitch** (the design agent / prompt box) with the right screens selected. Every prompt asks Stitch to **review → apply fixes → summarize what changed**, because Stitch is an editor, not a report generator.

---

## 0. How to use inside Stitch

1. **Protect your originals.** Duplicate the screens you are about to change (or ask for *variants*). Compare before/after and keep the better one.
2. **Select the screens first** (multi-select), then paste a prompt. Stitch can edit several screens at once, which keeps flows consistent and saves your daily generation quota.
3. **Order matters:** S0 (design system) → S1–S10 (principles, applied to all screens) → G1–G11 (group-specific critiques) → X (stress tests) → F (flow + heat-map + prototype tests) → V (variants) → R (final readiness).
4. **Generate missing states in small batches** (multi-screen generation is limited to a handful of screens per request).
5. After each prompt, **read the summary**. If Stitch changed content or flow you didn't want, undo and re-run with "Do not change content or flow".
6. Stitch's AI-generated heat maps are **predictions, not real user data**; prototype click-throughs help count taps, but **only real users prove ease of use** — finish with 5 real people (see section F4).
7. Features vary by Stitch version; if an option (variants, heat map, prototype, design system) is named differently in your UI, use the closest equivalent.

**Shared sample data** (keep consistent across edits): group "رحلة دهب"; members محمد، عاصم، محسن، يوسف، كريم; balances محمد +1,014.01 · عاصم +1,114.02 · محسن −688.03 · يوسف −720.00 · كريم −720.00; restaurant bill 561.79 ج.م (service 12%, tax 14%).

**Style line** (already part of your design): Arabic-first RTL, Android 360×800, teal #0F766E, green #15803D = له (owed), orange-red #C2410C = عليه (owes), amber #B45309 warning, Cairo font, 16px card radius, 8px grid.

---

## S0 — Lock the design system (do this first)

Select **all screens** → set/modify the project design system, then paste:

```text
Update the project's design system with these exact tokens and apply it to ALL selected screens:
Colors: primary #0F766E; primary container #CCFBF1; background #F8FAFB; surface #FFFFFF; border #E2E8F0; text #0F172A; secondary text #475569; positive #15803D on #DCFCE7; negative #C2410C on #FFEDD5; warning #B45309 on #FEF3C7; error #B91C1C.
Typography: Cairo; headline 22/700, title 18/600, body 15/400, caption 13/400; amounts in medium weight with tabular figures.
Shape/spacing: cards 16px, inputs and chips 12px, bottom sheets 28px top corners; 8px spacing grid; screen side padding 16px; minimum touch target 48dp.
Then scan every selected screen and fix any component that deviates (buttons, inputs, chips, cards, tabs, FAB, bottom sheets, dialogs, list tiles, avatars). Do not change content or flow. At the end, list the 5 most common deviations you fixed.
```

---

## S1–S10 — Principle prompts (apply to all or to a whole screen group)

### S1 — Visual hierarchy & spacing
```text
Review the selected screens for visual hierarchy and spacing, then fix them.
- One clear focal point per screen; the primary action must be the most prominent element.
- Group related items in cards; use whitespace instead of heavy dividers; remove decorative noise.
- All spacing in multiples of 8px; consistent 16px side padding; consistent card padding.
- Align amounts in a clean column with tabular figures so numbers are easy to compare.
- Secondary information (captions, hints) must be visibly lower in emphasis than primary information.
Do not change content or flow. Finish with a 5-line summary of what you changed.
```

### S2 — Accessibility & readability
```text
Audit the selected screens for accessibility and fix every issue:
- Text contrast at least 4.5:1 (body) and 3:1 (large text, icons, input borders). Check gray secondary text on tinted backgrounds (teal, green, orange, amber) and fix any that fail.
- Minimum text size: 14 for body, 12 for captions. No important information in captions.
- Touch targets at least 48×48dp with at least 8dp between adjacent targets (especially member chips, toggles, icon buttons).
- Never rely on color alone: owed/owes must also use words ("له" / "عليه"), +/− signs, and an icon. Warning and error states need an icon plus text.
- Icon-only buttons get a visible text label or are replaced by labeled buttons.
- Layouts must survive 130% and 200% text size without clipping: use wrapping and flexible containers.
Summarize in a short table: element → problem → fix.
```

### S3 — RTL & Arabic quality
```text
Review the selected screens as an Arabic RTL product and fix problems:
- Everything is truly mirrored (layout order, tab order, navigation: the back arrow points right, chevrons point left); no left-to-right layouts that were merely translated.
- Text is right-aligned; Arabic uses generous line height (about 1.5) and no letter spacing or italics.
- Amounts use Western digits; the currency label "ج.م" follows the number in reading order; "+" and "−" signs stay attached to the number and never flip to the wrong side.
- Mixed content (Arabic names with Latin letters like "Ahmed (أحمد)", digits, currency) renders in the correct order.
- Numeric columns and tables stay readable in RTL; long Arabic names wrap or ellipsize gracefully without breaking the layout.
Do not change content or flow. List what you corrected.
```

### S4 — State completeness (run on 3–5 screens at a time)
```text
For the selected screen(s), create the missing states as separate screens placed next to the original, keeping the same design system:
empty state with a friendly illustration and one clear action; loading skeleton; inline validation error; disabled primary button with a visible reason; keyboard-open state where the primary action remains visible; long-content state (long Arabic names, many items); success/confirmation feedback (snackbar).
Do not redesign the original screen. Name each new screen with its state, e.g. "Add expense — keyboard open".
```

### S5 — Microcopy & terminology (use this glossary)
```text
Rewrite all visible UI text on the selected screens for clarity and consistency, using Egyptian-friendly Arabic that is short, friendly and not overly formal.
Use this glossary consistently on every screen:
- expense = مصروف; who paid = مين دفع؟; split = التقسيم; members = الأعضاء; balances = الأرصدة;
- is owed money = له (e.g. "له 1,014.01 ج.م"); owes money = عليه (e.g. "عليه 688.03 ج.م"); settled = متسوّي ✔;
- who pays whom = مين يدفع لمين؛ record a payment = سجّل دفعة.
Important: do NOT use "ليه" for "is owed" because in Egyptian Arabic it reads as "why". Use "له".
Rules: buttons start with a verb or a clear noun ("حفظ", "تسجيل الدفعة"); error messages say what went wrong AND how to fix it; avoid gendered commands where a neutral noun phrase works (e.g. "اختيار الأعضاء" instead of "اختار"); no jargon; keep each label under ~25 characters where possible.
Return a table of old text → new text for the 15 weakest strings.
```

### S6 — Money clarity & trust (most important)
```text
Improve how the selected screens communicate money so a first-time user always understands and trusts the numbers.
- Balances: show "له" (green, with +) or "عليه" (orange-red, with −) as words, not color only. Zero shows "متسوّي ✔".
- Transfers read as sentences: "يوسف يدفع لعاصم 720.00 ج.م" with an arrow between the two avatars, so they are not mistaken for payments already made. Add a small caption: "ده اقتراح للتسوية — التطبيق بيحسب بس ومبيحوّلش فلوس".
- Add a small "إزاي اتحسبت؟" link near each balance and transfer that opens a bottom sheet listing the expenses behind the number.
- Show reconciliation lines wherever totals appear (payers total equals expense total; sum of shares equals total; sum of balances = 0).
- When rounding happens, show a one-line explanation ("القرش الزيادة بيتوزع تلقائيًا").
- Anything the user typed vs anything the app calculated must look different (e.g. calculated values in a muted style with a small "محسوب" tag).
Apply the changes without adding new screens except the "إزاي اتحسبت؟" bottom sheet. Summarize changes.
```

### S7 — Ergonomics (one-handed, in a hurry)
```text
Optimize the selected screens for one-handed use on a 360×800 phone while the user is in a rush (restaurant, car, hotel lobby):
- Primary actions in the bottom third; use a sticky bottom action bar that stays visible above the keyboard.
- Use bottom sheets for short tasks instead of full screens.
- Amount fields open the numeric keypad; sensible autofocus; smart defaults (today's date, last payer, all members selected).
- Member chips and toggles are big enough and spaced for thumb taps; avoid actions only reachable in the top corners.
- Reduce the number of taps for the default path to the minimum.
Show the final tap count for the default "add an equal expense" path in your summary.
```

### S8 — Error prevention & recovery
```text
Strengthen error prevention and recovery on the selected screens:
- Inline, specific validation messages next to the field that failed (Arabic, with how to fix).
- Primary buttons disabled only with a visible reason beneath them.
- Mismatch indicators (remaining / over total) are impossible to miss and use icon + text + color.
- Destructive actions (delete expense, delete member, delete group, sign out) use a calm confirmation dialog that explains the consequence; after deletion show an undo snackbar.
- Show a preview of per-person amounts before saving an expense.
- Add a "discard changes?" dialog when closing a form with unsaved input.
Apply the changes and list each protection you added.
```

### S9 — Consistency & navigation
```text
Check the selected screens for consistency and navigation logic, then fix:
- Same pattern for the same task everywhere (adding something, picking members, confirming, deleting).
- Consistent app-bar structure (back, title, actions), consistent FAB and button hierarchy (one primary per screen, secondary and destructive clearly different).
- Same naming for the same concept on every screen.
- Consistent choice between bottom sheet and full screen (sheets for short tasks, full screens for long forms).
- Back behavior is predictable and the user always knows where they are (group name visible inside the group).
List inconsistencies found and fixed.
```

### S10 — Cognitive load & progressive disclosure
```text
Reduce cognitive load on the selected screens:
- Show only what is needed for the default path; move advanced options under an expandable "خيارات أكتر" section.
- Limit visible decisions per screen to what the user really needs to decide now.
- Prefer recognition over recall (chips and pickers instead of typing, sensible defaults).
- Use plain language and short helper text only where users commonly hesitate.
- Make the first-time experience guided but skippable.
Explain in 5 lines what you hid, simplified, or merged, and why. Do not remove any required Phase 1 capability.
```

---

## G1–G11 — Group-specific critique-and-fix prompts

Use this wrapper for each group, replacing `[GROUP]` and `[QUESTIONS]` with the text below:

```text
Act as a senior UX reviewer. For the selected screens ([GROUP]): first list the 5 most serious usability problems in one line each (screen, element, problem, severity 1–4). Then fix them directly on the screens (create a variant instead of overwriting if the change is big). Answer these questions explicitly: [QUESTIONS]. Finish with "Open decisions for the founder" (max 3 bullets).
```

| Group | Questions to paste |
|---|---|
| **G1 Splash / Welcome / Sign-in** | Does the value show in under 5 seconds? Is "the app never touches your money" reassuring without scaring? Is it clear what happens after tapping Google sign-in? |
| **G2 Groups list / Create / Edit group** | Is the first action obvious for a new user? Do group cards show the most useful 3 facts first (name, total, last activity)? Is the group-type selector worth its friction? |
| **G3 Group home + Expenses tab** | Can each expense be understood in one glance (who paid, split type)? Is the summary card useful or noise? Does the FAB collide with the keyboard or tabs? |
| **G4 Members** | Can several members be added in a row without reopening the sheet? Is it clear members don't need accounts? Do balance pills duplicate the Balances tab (remove if so)? |
| **G5 Add expense** | How many decisions does the default path require? Are "who paid" and "split among whom" clearly separate and in logical order? Does the live per-person amount build trust? Is the 3-way split selector clear? |
| **G6 Multi-payer sheet** | Is the remaining/over indicator unmissable? Is the disabled "تم" button state explained? Is a bottom sheet the right pattern, or should it be a full screen? |
| **G7 Itemized restaurant bill** | Can a first-time user understand item assignment and how shared items split? Are the independent service and tax toggles obvious (service only / tax only / both / neither)? Does the per-person table fit 360dp in RTL without cramping? Is "تم" reachable with the keyboard open? What can be simplified? |
| **G8 Expense details** | Does it explain "why this amount" for every person? Is the history readable and calm? Are the delete and conflict dialogs clear? |
| **G9 Balances + Record payment** | Will users read له/عليه correctly? Are suggested transfers understood as suggestions rather than completed payments? Is "سجّل دفعة" clearly different from "pay"? Is partial payment intuitive? |
| **G10 Settings / Edit Profile / Account** | Can a user edit their display name and avatar with minimal friction? Is the Google-linked email clearly read-only? Are payment handles (InstaPay and wallet) clearly explained as visible only to group members? Is account deletion properly secured with two-step confirmation? |
| **G11 System states & coach marks** | Are no-internet and error states helpful, friendly, and non-blaming? Are the coach marks worth the interruption? Is the session-expired flow clear? |

---

## X — Stress tests (duplicate screens first, then paste)

### X1 — Long content
```text
Duplicate the selected screens and fill the copies with stress content, keeping the design system:
- Member name: "عبد الرحمن محمد عبد العزيز السيد" and a mixed-script name "Ahmed (أحمد)".
- Group name of 40 characters; expense title of 60 characters; an itemized bill with an item named with 35 characters.
Show how the layout copes (wrap, ellipsize, resize). Fix any overflow, clipped text, or broken alignment in BOTH the copies and the originals, then summarize the fixes.
```

### X2 — Large scale
```text
Duplicate the selected screens and populate the copies with: 12 members; 20 items in a restaurant bill; an item shared by 7 people; amounts like 0.01, 999.99 and 1,250,000.50; a member with a balance of exactly 0.00; a group where everyone is settled.
Check scanning speed and readability. Fix: long lists (sticky headers, search or grouping where helpful), number formatting with thousands separators, chip rows that wrap, and the per-person breakdown table when there are many rows. Summarize.
```

### X3 — Text scale and small screens
```text
Create variants of the selected screens simulating 200% text size and a 320dp-wide phone. Identify what breaks (clipped buttons, overlapping text, unreachable primary actions, truncated amounts) and fix the ORIGINAL screens so they adapt (wrapping, flexible heights, stacked layouts instead of side-by-side where needed). Summarize the changes.
```

### X4 — Failure situations
```text
Create screens for these situations in the existing style, each with a calm, non-blaming message and one clear next action: no internet while saving an expense (the form data is preserved, button "حاول تاني"); slow network (skeleton plus "لسه بنحمّل..."); session expired (sign in again, nothing lost); a conflict where an expense was edited while the user was editing; trying to delete a member with transactions.
```

---

## F — Flow tests, heat maps and prototype tests

### F1 — Build the prototype
```text
Create an interactive prototype connecting these screens with hotspots so I can click through the main flows: Welcome → Sign-in → Groups list → Create group → Group home → Members (add member sheet) → Add expense (equal) → Add expense (multi-payer sheet) → Add expense (restaurant bill editor) → Expense details → Balances → Record payment → back to Balances showing the updated state. Use the existing screens; do not redesign. List any missing screen needed to complete a flow.
```

### F2 — Tap-count tests (you click, you count, optionally with a stopwatch)

Targets are suggestions to validate, not facts.

| Task | Target |
|---|---|
| T1 First launch → sign in → create the first group | ≤ 4 screens |
| T2 Add 5 members | ≤ 2 taps per extra member after the first |
| T3 Add a simple equal expense (default payer, everyone) | ≤ 3 taps + typing |
| T4 Equal expense among 3 of 5 members paid by someone else | ≤ 6 taps |
| T5 Multi-payer expense (hotel, 2 payers) | ≤ 8 taps |
| T6 Restaurant bill (3 items, service only, then both) | no help needed; numbers understood |
| T7 See that an expense was edited and what changed | ≤ 3 taps |
| T8 Find who owes me / what I owe | ≤ 2 taps from group home |
| T9 Record a partial payment, then complete it | ≤ 5 taps each |
| T10 Recover from a mistaken delete | obvious recovery path |

If a task misses its target, paste:
```text
This task takes too many steps: [task, current taps, target]. Redesign the involved screens to reduce steps and confusion (smart defaults, merged steps, progressive disclosure, a quick-add path). Create a variant, show the new tap count, and explain the trade-offs.
```

### F3 — Heat-map check (on 5–6 key screens)
Generate Stitch's predicted heat map for: Add expense, Itemized editor, Balances, Group home, Welcome, Record payment. Read it like this:
- Is the **primary action** (حفظ / تم / سجّل دفعة) among the top attention areas?
- On Balances, does attention go to the **transfers** and the له/عليه words, not decoration?
- On Itemized editor, does the **amount and total** draw attention, not secondary hints?
- Is anything important in a "cold" zone?

If attention is wrong, paste:
```text
The predicted attention on [screen] is wrong: [what attracts attention vs what should]. Adjust hierarchy (size, contrast, position, whitespace) so the primary action and key numbers draw the most attention, and reduce emphasis on [elements]. Do not change content or flow.
```

### F4 — Real-user test (mandatory, ~2 weeks, near-zero cost)
Share the prototype link (or open it on a real mid-range Android phone) with **5 people** who traveled or shared a flat recently. Give them scenarios, not instructions: *"You're in Dahab with 4 friends. Dinner was 561.79 with service and tax; two of you paid. Record it and tell me who owes whom."* Observe silently, record where they hesitate, tap wrong, or ask questions. Ask: "Do you trust these numbers? Why?" and "What does 'له' / 'عليه' mean to you?" Score each task: success / success with hints / fail. Fix every problem that 3 of 5 people hit, then retest.

---

## V — Variant experiments (choose with evidence)

Select the screen and paste. Keep the originals; compare side by side; test with 5 people or a 5-second preference test.

### V1 — Add expense
```text
Create 3 variants of "Add expense": A) current single screen; B) two steps (step 1: amount, title, payer; step 2: split); C) quick-add: only amount and title with defaults (today, last payer, everyone) and a "خيارات أكتر" section for payers, split type and date. Keep the same design system. Label the variants and write one line on who each suits best.
```
Decision rule: choose the variant with the fewest taps for the default case that **real users complete without hints**.

### V2 — Itemized bill editor
```text
Create 3 variants of the restaurant bill editor: A) item cards with assignee chips (current); B) compact rows with inline price and avatar stack; C) a list of items where tapping an item opens a bottom sheet to set price and assignees. Keep service and tax as independent optional toggles with percentage fields in every variant, and keep the per-person breakdown. Label them.
```

### V3 — Balances
```text
Create 3 variants of the Balances tab: A) net per person first, then suggested transfers (current); B) suggested transfers first ("مين يدفع لمين"), then net per person; C) a single merged list where each person's row expands to show who they pay or receive from. Make "له/عليه" unmistakable in all.
```

### V4 — Welcome / first run
```text
Create 2 variants of the first-run experience: A) welcome screen with illustration and three value lines; B) skip the welcome and go straight to sign-in, then show a short guided empty state on the Groups screen. Label them.
```

---

## R — Final readiness

```text
Update the project's design system and DESIGN.md so they match the final screens: tokens, component rules, spacing, states, RTL rules, accessibility rules, and the glossary (له/عليه/متسوّي ✔/سجّل دفعة/مين يدفع لمين). Then list any screen or state that is still missing or inconsistent. Do not change the screens.
```

**Ready for Flutter when:**
- [ ] All states from G1–G10 exist (empty, loading, error, validation, keyboard-open, long-content).
- [ ] S0–S10 done on every screen; the glossary is applied everywhere (no "ليه" for "owed").
- [ ] X1–X4 pass (long names, 12 members, 200% text, failure states).
- [ ] Prototype tap counts meet targets (or the misses are accepted knowingly).
- [ ] Heat maps look right on the key screens.
- [ ] 5 real users completed the main tasks; problems hit by 3 of 5 are fixed.
- [ ] Design system and DESIGN.md exported/saved with the final screens.
