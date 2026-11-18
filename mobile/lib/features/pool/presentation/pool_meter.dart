import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// What is left in the pool: `GroupDto.poolBalanceMinor` exactly as the backend computed it (A136, never stored,
/// never recomputed here). A negative meter means the treasurer fronted their own cash: it is said in words with a
/// warning icon ("the treasurer covered X"), never by colour alone.
class PoolRemaining extends StatelessWidget {
  const PoolRemaining({super.key, required this.meterMinor, this.size = MoneySize.medium});

  final int meterMinor;
  final MoneySize size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (meterMinor < 0) {
      final covered = l10n.poolCovered(moneyDisplay(l10n, Money.magnitude(meterMinor)));
      return Semantics(
        container: true,
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: context.colors.error, semanticLabel: null),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(covered, style: theme.textTheme.titleSmall?.copyWith(color: context.colors.error)),
                  const SizedBox(height: QesmaSpacing.xs),
                  Text(l10n.poolCoveredHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.poolRemaining, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              if (meterMinor == 0)
                Text(l10n.poolEmptyMeter, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
            ],
          ),
        ),
        const SizedBox(width: QesmaSpacing.sm),
        MoneyText(meterMinor, size: size),
      ],
    );
  }
}

/// One line of the breakdown: a label and an amount as the read-model sent it.
class PoolMeterRow extends StatelessWidget {
  const PoolMeterRow({super.key, required this.label, required this.minor});

  final String label;
  final int minor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: QesmaSpacing.sm),
          MoneyText(minor),
        ],
      ),
    );
  }
}
