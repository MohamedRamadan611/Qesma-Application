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
    final negative = meter < 0;
    return AppCard(
      onTap: () => context.push(Routes.pool(group.id)),
      padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
      child: Semantics(
        button: true,
        label: l10n.poolOpenDetails,
        child: Row(
          children: [
            Icon(negative ? Icons.warning_amber_rounded : Icons.savings_outlined, color: negative ? context.colors.error : context.colors.primary),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.poolSectionTitle, style: theme.textTheme.titleSmall),
                  Text(
                    l10n.poolTreasurerIs(fsIsolate(treasurer)),
                    style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: QesmaSpacing.sm),
            // A negative meter is said in words on the pool screen; here the amount plus the warning icon is enough.
            MoneyText(meter, size: MoneySize.small),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: l10n.poolAddDeposit,
              onPressed: () => showDepositSheet(context, gid: group.id, treasurerId: treasurerId),
            ),
          ],
        ),
      ),
    );
  }
}
