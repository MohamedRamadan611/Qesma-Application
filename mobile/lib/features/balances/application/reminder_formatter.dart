import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/active_currency.dart';
import '../../../core/money/money.dart';
import '../domain/reminder_tone.dart';

/// Which of the sender's payment methods the reminder mentions at its end.
enum ReminderPayMethod { instapay, wallet }

/// Formats WhatsApp reminder messages from localized ARB templates (SA9, STANDALONE_SPEC 12).
abstract final class ReminderFormatter {
  /// Formats the amount using Western digits and the localized currency symbol.
  static String formatAmount(AppLocalizations l10n, int amountMinor) =>
      '${Money.formatNumber(amountMinor)} ${ActiveCurrency.label(l10n)}';

  /// Formats the template with filled placeholders for the given [tone].
  static String formatMessage({
    required AppLocalizations l10n,
    required ReminderTone tone,
    required String debtorName,
    required int amountMinor,
    required String groupName,
    String? instapayHandle,
    bool includeInstapay = false,
    String? walletHandle,
    ReminderPayMethod method = ReminderPayMethod.instapay,
  }) {
    final amountStr = formatAmount(l10n, amountMinor);
    final handle = (method == ReminderPayMethod.wallet ? walletHandle : instapayHandle)?.trim();
    final handleLine = (includeInstapay && handle != null && handle.isNotEmpty)
        ? (method == ReminderPayMethod.wallet
            ? l10n.reminderWalletLine(handle)
            : l10n.reminderInstapayLine(handle))
        : '';

    return switch (tone) {
      ReminderTone.soft => l10n.reminderToneSoft(debtorName, groupName, amountStr, handleLine),
      ReminderTone.firm => l10n.reminderToneFirm(debtorName, groupName, amountStr, handleLine),
      ReminderTone.funny => l10n.reminderToneFunny(debtorName, groupName, amountStr, handleLine),
    };
  }

  /// Builds a `https://wa.me/?text=<urlencoded>` URI ready for `url_launcher`.
  static Uri buildWhatsAppUri(String message) =>
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
}
