import 'package:flutter/material.dart';

import 'tokens.dart';

/// Colours of the three balance states (owed / owes / settled) as a theme extension.
///
/// Colour is only a hint: every use pairs it with a sign and a word (SCREEN_MAP a11y rule).
@immutable
class BalanceColors extends ThemeExtension<BalanceColors> {
  const BalanceColors({
    this.owed = QesmaColors.owed,
    this.owedBg = QesmaColors.owedBg,
    this.owes = QesmaColors.owes,
    this.owesBg = QesmaColors.owesBg,
    this.settled = QesmaColors.settled,
    this.settledBg = QesmaColors.settledBg,
  });

  final Color owed;
  final Color owedBg;
  final Color owes;
  final Color owesBg;
  final Color settled;
  final Color settledBg;

  @override
  BalanceColors copyWith({
    Color? owed,
    Color? owedBg,
    Color? owes,
    Color? owesBg,
    Color? settled,
    Color? settledBg,
  }) =>
      BalanceColors(
        owed: owed ?? this.owed,
        owedBg: owedBg ?? this.owedBg,
        owes: owes ?? this.owes,
        owesBg: owesBg ?? this.owesBg,
        settled: settled ?? this.settled,
        settledBg: settledBg ?? this.settledBg,
      );

  @override
  BalanceColors lerp(ThemeExtension<BalanceColors>? other, double t) {
    if (other is! BalanceColors) return this;
    return BalanceColors(
      owed: Color.lerp(owed, other.owed, t)!,
      owedBg: Color.lerp(owedBg, other.owedBg, t)!,
      owes: Color.lerp(owes, other.owes, t)!,
      owesBg: Color.lerp(owesBg, other.owesBg, t)!,
      settled: Color.lerp(settled, other.settled, t)!,
      settledBg: Color.lerp(settledBg, other.settledBg, t)!,
    );
  }
}

extension BalanceColorsX on BuildContext {
  BalanceColors get balanceColors => Theme.of(this).extension<BalanceColors>() ?? const BalanceColors();
}
