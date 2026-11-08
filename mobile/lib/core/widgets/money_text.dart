import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../money/money.dart';
import '../theme/balance_colors.dart';
import '../theme/qesma_text.dart';
import 'bidi.dart';

/// Visible text of an amount: "1,061.79 ج.م" (ar) / "1,061.79 EGP" (en), signed on request.
/// Western digits, non-breaking space before the currency (DESIGN.md numeral rules).
String moneyDisplay(AppLocalizations l10n, int minor, {bool signed = false}) =>
    '${ltrIsolate(Money.formatNumber(minor, signed: signed))}$nbsp${l10n.moneyCurrency}';

/// Spoken form: "80 جنيه", "80 جنيه و50 قرش", "سالب 80 جنيه". Words, not symbols.
/// [signedSpoken] says "minus" for negatives; balance chips pass false because
/// "owes" already carries the direction.
String moneySpoken(AppLocalizations l10n, int minor, {bool signedSpoken = true}) {
  final p = Money.parts(minor);
  final amount = p.piasters == 0
      ? l10n.moneySpokenPounds('${p.pounds}')
      : p.pounds == 0
          ? l10n.moneySpokenPiasters('${p.piasters}')
          : l10n.moneySpokenPoundsPiasters('${p.pounds}', '${p.piasters}');
  return signedSpoken && minor < 0 ? l10n.moneySpokenNegative(amount) : amount;
}

enum MoneySize { large, medium, small, inline }

/// An amount in integer piasters. Never takes a double.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    super.key,
    this.signed = false,
    this.size = MoneySize.small,
    this.color,
    this.colorBySign = false,
    this.textAlign,
  });

  final int minor;

  /// Show "+" for positive amounts (negatives always show the minus sign).
  final bool signed;
  final MoneySize size;
  final Color? color;

  /// Colour by balance state (owed/owes/settled). Always paired with the sign, never alone.
  final bool colorBySign;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = switch (size) {
      MoneySize.large => QesmaText.amountLarge(),
      MoneySize.medium => QesmaText.amountMedium(),
      MoneySize.small => QesmaText.amountSmall(),
      MoneySize.inline => QesmaText.amountInline(),
    };
    final colors = context.balanceColors;
    final resolved = color ??
        (colorBySign
            ? (minor > 0 ? colors.owed : (minor < 0 ? colors.owes : colors.settled))
            : null);
    return Semantics(
      label: moneySpoken(l10n, minor),
      child: ExcludeSemantics(
        child: Text(
          moneyDisplay(l10n, minor, signed: signed),
          style: resolved == null ? style : style.copyWith(color: resolved),
          textAlign: textAlign,
        ),
      ),
    );
  }
}
