import '../../expenses/application/expense_draft.dart';
import '../../expenses/application/expense_form_state.dart';
import 'parsed_receipt.dart';

/// ParsedReceipt -> the unsaved itemized draft the editor opens with (SA12, SA17). Every item starts with nobody
/// assigned (the user assigns members) and carries its quantity and unit price; an item the user must look at is
/// marked as touched so its error shows at once. The discount, service and tax follow what was printed, in amount or
/// percent form. The tax base keeps the editor's default. The shop name and the category are passed on as
/// suggestions: the form decides whether the title and the category are still free to take them.
ScanDraft scanDraftFrom(ParsedReceipt receipt) => ScanDraft(
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
        taxOn: receipt.taxOn,
        taxMode: receipt.taxAmountText.isNotEmpty ? ChargeMode.amount : ChargeMode.percent,
        taxPercentText: receipt.taxPercentText,
        taxAmountText: receipt.taxAmountText,
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
