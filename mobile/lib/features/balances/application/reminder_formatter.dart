import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../domain/reminder_tone.dart';

/// Formats WhatsApp reminder messages from localized ARB templates (SA9, STANDALONE_SPEC 12).
abstract final class ReminderFormatter {
  /// Formats the amount using Western digits and the localized currency symbol.
  static String formatAmount(AppLocalizations l10n, int amountMinor) =>
      '${Money.formatNumber(amountMinor)} ${l10n.moneyCurrency}';

  /// Formats the template with filled placeholders for the given [tone].
  static String formatMessage({
    required AppLocalizations l10n,
    required ReminderTone tone,
    required String debtorName,
    required int amountMinor,
    required String groupName,
    String? instapayHandle,
    bool includeInstapay = false,
  }) {
    final amountStr = formatAmount(l10n, amountMinor);
    final handleLine = (includeInstapay && instapayHandle != null && instapayHandle.trim().isNotEmpty)
        ? l10n.reminderInstapayLine(instapayHandle.trim())
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
