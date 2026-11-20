# SA16 device check list: itemized editor UX

For the owner, on the phone (standalone / local mode build). About 15 minutes. Tick each line; write what you saw next to any line that fails.

Set up once: a group of 15 members (add them by name: "عضو 1" to "عضو 15"), and a second group of 4 members.

## 1. A receipt with a discount and a quantity (group of 4)
- [ ] Add expense, tab "فاتورة مفصلة". The editor shows: items card, discount/service/tax card, per-person card, one "حفظ الفاتورة" button at the bottom.
- [ ] Item 1: "بيبسي", unit price 15.25, press + twice. The quantity box shows 3 and the card shows "3 × 15.25 ج.م" (not 45.75; the app does not multiply).
- [ ] Item 2: "شاورما", price 85, keep only one person ticked.
- [ ] Turn on "الخصم", choose `%`, type 10. A minus amount appears next to it and the total changes.
- [ ] Switch the discount to `ج.م`, type 50: the total changes again. Switch back to `%`: your 10 is still there.
- [ ] Turn on "رسوم الخدمة" and `ج.م`, type 20. Turn on the tax: the "الضريبة تُحسب على" chips appear only now (not with service off).
- [ ] Open a person's row in the breakdown: it shows items, discount (with a minus), service and tax. Close it again.
- [ ] Save. The details page shows "3 × 15.25", the discount line, and the service as an amount (no % tag).
- [ ] Edit the saved bill: quantity, price, discount and the `ج.م` service open exactly as saved.

## 2. Split units between people
- [ ] On the Pepsi item press ⋮ then "وزّع الوحدات على الأشخاص". Give person A 2 and person B 1: the banner says all units are given out.
- [ ] After "تقسيم" there are two items: "بيبسي" × 2 for A and "بيبسي" × 1 for B.

## 3. Delete and undo
- [ ] ⋮ then "حذف الصنف": the item disappears and a bar offers "تراجع". Tap it: the item is back in the same place.
- [ ] ⋮ then "تكرار الصنف": a copy appears right under it.

## 4. A 15-member group
- [ ] Item cards stay short: one summary chip with up to 3 avatars and "الكل" (or "+N"), not 15 chips.
- [ ] Tap the chip: a sheet opens with a search box, "الكل" / "لا أحد", rows you can hit easily, and a "تم (n)" button that stays at the bottom while you scroll.
- [ ] Type part of a name: the list filters. Choose "لا أحد", tick two people: the button says "تم (2)". Tap it: the chip updates.
- [ ] An item with nobody shows a red icon and "اختار عضو واحد على الأقل".
- [ ] Switch to "حسب الشخص": choose a person from the list (their running total is shown next to them), tick items. An item nobody has is flagged. "كل الأصناف" and "ولا صنف" work.
- [ ] The paid-by sheet ("تعديل الدافعين") also has a search box with this many members.

## 5. Missing fields
- [ ] New bill, type nothing, tap "حفظ الفاتورة": nothing is saved, the bottom bar says how many fields are missing (with an icon), and the page scrolls to the first problem.
- [ ] Fill the first item only, scroll to the bottom, tap Save again: the count drops and the page goes back up to the next missing field.
- [ ] Check that every problem has an icon and words, not only a red colour.

## 6. Receipt scan and the printed total (local mode with scan)
- [ ] Scan a receipt whose printed total is within 1 EGP of what the app works out: the app sets the adjustment itself, shows "تم ضبط فرق X قرش تلقائيًا لمطابقة إجمالي الإيصال" and the green "الإجمالي زي إجمالي الإيصال".
- [ ] Type your own number in the adjustment box: the note goes away and the app never changes your number again.
- [ ] A receipt that is more than 1 EGP off keeps the red mismatch message and does not adjust anything.

## 7. Text size 2.0
Phone settings: font size and display size at the largest. Open the same bill.
- [ ] Nothing is cut off or overlapping on the item card, the charge rows, the member sheet and the bottom bar.
- [ ] The stepper buttons, the ⋮ menu, the chips and the rows are all easy to hit with a thumb.
- [ ] The bottom bar (count, total, Save) is still fully visible.

## 8. Screen reader (TalkBack), 5 minutes
- [ ] The quantity stepper reads "الكمية 3" and can be changed with the swipe up/down gesture.
- [ ] The ⋮ button reads "خيارات الصنف 1". The charge `% | ج.م` toggle says percentage or amount in words.
- [ ] The missing-fields count is announced when you tap Save.

Not part of this list: receipt reading of quantity, unit price, discount and merchant (that is SA17).
