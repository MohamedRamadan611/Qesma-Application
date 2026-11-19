import '../../expenses/application/expense_draft.dart';
import '../../expenses/application/expense_form_state.dart';
import 'parsed_receipt.dart';

/// ParsedReceipt -> the unsaved itemized draft the editor opens with (SA12). Every item starts with nobody assigned
/// (the user assigns members), a flagged item is marked as touched so its error shows at once, the service / tax
/// switches follow what was printed, and the tax base keeps the editor's default.
ScanDraft scanDraftFrom(ParsedReceipt receipt) => ScanDraft(
      itemized: ItemizedDraft(
        items: [
          for (var i = 0; i < receipt.items.length; i++)
            ItemDraft(
              id: 'scan-$i',
              name: receipt.items[i].name,
              amountText: receipt.items[i].amountText,
              touched: receipt.items[i].flagged,
            ),
        ],
        serviceOn: receipt.serviceOn,
        servicePercentText: receipt.servicePercentText,
        taxOn: receipt.taxOn,
        taxPercentText: receipt.taxPercentText,
      ),
      printedTotalMinor: receipt.printedTotalMinor,
      notes: {
        if (receipt.hasFlaggedItems) ScanNote.flaggedItems,
        if (receipt.chargeNeedsPercent) ScanNote.needsPercent,
        if (receipt.truncated) ScanNote.truncated,
      },
    );
