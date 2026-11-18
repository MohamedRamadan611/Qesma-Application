import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../balances/presentation/record_payment_sheet.dart';
import '../../expenses/presentation/expense_ui.dart';
import 'pool_meter.dart';

/// The compact pool card on the group home (SA10): who holds the pool, what is left (`poolBalanceMinor`) and
/// "Add deposit". Tapping it opens the pool screen with the breakdown and the deposits. Shown only when the group has
/// a treasurer (the caller decides).
class PoolCard extends StatelessWidget {
  const PoolCard({super.key, required this.group});

  final GroupDto group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final treasurerId = group.treasurerMemberId!;
    final meter = group.poolBalanceMinor ?? 0;
    final treasurer = memberNameResolver(group, l10n)(treasurerId);
    return AppCard(
      onTap: () => context.push(Routes.pool(group.id)),
      padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: l10n.poolOpenDetails,
            child: Row(
              children: [
                Icon(Icons.savings_outlined, color: context.colors.primary),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.poolSectionTitle, style: theme.textTheme.titleSmall),
                      Text(
                        l10n.poolTreasurerIs(fsIsolate(treasurer)),
                        style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.colors.textHelper),
              ],
            ),
          ),
          const SizedBox(height: QesmaSpacing.sm),
          PoolRemaining(meterMinor: meter, size: MoneySize.small),
          const SizedBox(height: QesmaSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              label: l10n.poolAddDeposit,
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: () => showDepositSheet(context, gid: group.id, treasurerId: treasurerId),
            ),
          ),
        ],
      ),
    );
  }
}
