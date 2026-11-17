import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/money_text.dart';

/// Formatter for the text balance summary ("who pays whom" from balances).
abstract final class TripRecapFormatter {
  static String formatTextSummary({
    required AppLocalizations l10n,
    required String groupName,
    required int totalSpentMinor,
    required int expenseCount,
    required List<TransferView> transfers,
    required String Function(String memberId) nameOf,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(l10n.recapTextSummaryHeader(groupName));
    buffer.writeln(l10n.recapTextSummaryTotal(
      moneyDisplay(l10n, totalSpentMinor),
      l10n.recapExpensesCount(expenseCount),
    ));
    buffer.writeln();

    if (transfers.isEmpty) {
      buffer.writeln(l10n.recapTextSummaryAllSettled);
    } else {
      buffer.writeln(l10n.recapTextSummaryTransfersHeader);
      for (final t in transfers) {
        final from = nameOf(t.fromMemberId);
        final to = nameOf(t.toMemberId);
        final amt = moneyDisplay(l10n, t.amountMinor);
        buffer.writeln(l10n.recapTextSummaryTransferLine(from, to, amt));
      }
    }

    buffer.writeln();
    buffer.write(l10n.recapTextSummaryFooter);
    return buffer.toString();
  }
}
