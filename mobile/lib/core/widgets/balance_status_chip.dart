import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/balance_colors.dart';
import '../theme/qesma_text.dart';
import '../theme/tokens.dart';
import 'money_text.dart';

/// A member's balance as a person would say it ("Owes 80 pounds"): word and amount in words, no digits-only numbers.
String balanceSpoken(AppLocalizations l10n, int netMinor) => netMinor > 0
    ? l10n.balanceOwedSpoken(moneySpoken(l10n, netMinor))
    : netMinor < 0
        ? l10n.balanceOwesSpoken(moneySpoken(l10n, netMinor, signedSpoken: false))
        : l10n.balanceSettledSpoken;

/// A member's net balance as a pill: word + signed amount (owed "له +100.00", owes
/// "عليه −80.00", settled "خالص 0.00"). Colour is never the only signal.
class BalanceStatusChip extends StatelessWidget {
  const BalanceStatusChip(this.netMinor, {super.key});

  /// Net balance in piasters: positive = owed, negative = owes, zero = settled.
  final int netMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.balanceColors;
    final (word, fg, bg, spoken) = netMinor > 0
        ? (l10n.balanceOwed, colors.owed, colors.owedBg, l10n.balanceOwedSpoken(moneySpoken(l10n, netMinor)))
        : netMinor < 0
            ? (
                l10n.balanceOwes,
                colors.owes,
                colors.owesBg,
                l10n.balanceOwesSpoken(moneySpoken(l10n, netMinor, signedSpoken: false)),
              )
            : (l10n.balanceSettled, colors.settled, colors.settledBg, l10n.balanceSettledSpoken);
    final amount = moneyDisplay(l10n, netMinor, signed: true);
    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.pill)),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              '$word $amount',
              style: QesmaText.amountInline().copyWith(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
