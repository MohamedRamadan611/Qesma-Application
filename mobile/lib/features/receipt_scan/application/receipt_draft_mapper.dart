import '../../../core/money/money.dart';
import '../../expenses/application/expense_draft.dart';
import '../../expenses/application/expense_form_state.dart';
import 'parsed_receipt.dart';

/// Do the item prices already include VAT? Items − discount + service + delivery are compared with the printed grand
/// total (integers, piasters; a rounding gap of 1 piaster is allowed, e.g. 250.01 + 35.00 vs 285.00). Equal => the
/// prices include VAT (VAT off); different => VAT is added on top (VAT on). null when it cannot be decided: no
/// printed total or an unreadable amount.
bool? _itemsIncludeVat(ParsedReceipt r) {
  final total = r.printedTotalMinor;
  if (total == null || r.items.isEmpty) return null;
  var sum = 0;
  for (final item in r.items) {
    final unit = Money.parse(item.amountText);
    if (unit == null) return null;
    sum += unit * item.quantity;
  }
  var discount = 0;
  if (r.discountAmountText.isNotEmpty) {
    discount = Money.parse(r.discountAmountText) ?? -1;
  } else if (r.discountPercentText.isNotEmpty) {
    final bps = Bps.parse(r.discountPercentText);
    discount = bps == null ? -1 : (sum * bps + 5000) ~/ 10000;
  }
  if (discount < 0) return null;
  final base = sum - discount;
  var service = 0;
  if (r.serviceOn) {
    if (r.serviceAmountText.isNotEmpty) {
      service = Money.parse(r.serviceAmountText) ?? -1;
    } else {
      final bps = Bps.parse(r.servicePercentText);
      service = bps == null ? -1 : (base * bps + 5000) ~/ 10000;
    }
    if (service < 0) return null;
  }
  final delivery = r.deliveryAmountText.isEmpty ? 0 : (Money.parse(r.deliveryAmountText) ?? -1);
  if (delivery < 0) return null;
  return (base + service + delivery - total).abs() <= 1;
}

/// ParsedReceipt -> the unsaved itemized draft the editor opens with (SA12, SA17). Every item starts with nobody
/// assigned and carries its quantity and unit price. VAT on/off is decided by [_itemsIncludeVat] when possible.
ScanDraft scanDraftFrom(ParsedReceipt receipt) {
  final includesVat = _itemsIncludeVat(receipt);
  final taxOn = includesVat == null ? receipt.taxOn : !includesVat;
  return _scanDraft(receipt, taxOn);
}

ScanDraft _scanDraft(ParsedReceipt receipt, bool taxOn) => ScanDraft(
      itemized: ItemizedDraft(
        items: [
          for (var i = 0; i < receipt.items.length; i++)
            ItemDraft(
              id: 'scan-$i',
              name: receipt.items[i].name,
              amountText: receipt.items[i].amountText,
              quantity: receipt.items[i].quantity,
              touched: receipt.items[i].flagged,
            ),
        ],
        discountOn: receipt.discountOn,
        discountMode: receipt.discountAmountText.isNotEmpty ? ChargeMode.amount : ChargeMode.percent,
        discountPercentText: receipt.discountPercentText,
        discountAmountText: receipt.discountAmountText,
        serviceOn: receipt.serviceOn,
        serviceMode: receipt.serviceAmountText.isNotEmpty ? ChargeMode.amount : ChargeMode.percent,
        servicePercentText: receipt.servicePercentText,
        serviceAmountText: receipt.serviceAmountText,
        taxOn: taxOn,
        taxMode: receipt.taxAmountText.isNotEmpty ? ChargeMode.amount : ChargeMode.percent,
        taxPercentText: taxOn && receipt.taxPercentText.isEmpty && receipt.taxAmountText.isEmpty ? kDefaultTaxPercent : receipt.taxPercentText,
        taxAmountText: receipt.taxAmountText,
        taxBase: receipt.taxOnSubtotalOnly ? TaxBase.subtotal : TaxBase.subtotalPlusService,
        deliveryOn: receipt.deliveryAmountText.isNotEmpty,
        deliveryAmountText: receipt.deliveryAmountText,
      ),
      printedTotalMinor: receipt.printedTotalMinor,
      merchantName: receipt.merchantName,
      category: receipt.category,
      notes: {
        if (receipt.hasFlaggedItems) ScanNote.flaggedItems,
        if (receipt.hasQuantityToCheck) ScanNote.quantityCheck,
        if (receipt.hasUnitPriceToCheck) ScanNote.unitPriceCheck,
        if (receipt.discountOn) ScanNote.discountFound,
        if (receipt.discountBothPrinted) ScanNote.discountPercentKept,
        if (receipt.discountDropped) ScanNote.discountDropped,
        if (receipt.truncated) ScanNote.truncated,
      },
    );
