import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/format/date_format.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/group_type.dart';
import 'group_ui.dart';
import '../../../core/theme/palette.dart';

/// One row of the groups list (P2-01): type icon, name, type tag, last activity, total spent,
/// member count and the "you are owed / you owe / settled" chip from the server's `yourNetMinor`.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});

  final GroupSummaryDto group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final type = GroupType.fromWire(group.type);
    final activity = group.lastExpenseAt == null ? l10n.groupNoActivity : l10n.groupLastActivity(ltrIsolate(isoDate(group.lastExpenseAt!)));
    final members = memberCountText(l10n, group.memberCount);

    final balanceSpoken = group.yourNetMinor > 0
        ? l10n.balanceOwedSpoken(moneySpoken(l10n, group.yourNetMinor))
        : group.yourNetMinor < 0
            ? l10n.balanceOwesSpoken(moneySpoken(l10n, group.yourNetMinor, signedSpoken: false))
            : l10n.balanceSettledSpoken;

    return AppCard(
      onTap: onTap,
      semanticLabel: l10n.groupCardSpoken(group.name, type.label(l10n), members, moneySpoken(l10n, group.totalSpentMinor), balanceSpoken),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                child: Icon(type.icon, color: context.colors.onPrimaryContainer),
              ),
              const SizedBox(width: QesmaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: QesmaSpacing.xs),
                    Wrap(
                      spacing: QesmaSpacing.sm,
                      runSpacing: QesmaSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppTag(label: type.label(l10n), tone: AppTagTone.info),
                        Text(activity, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.md - 4),
          DecoratedBox(
            decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: QesmaSpacing.sm,
                      children: [
                        Text('${l10n.groupTotalSpent}:', style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                        MoneyText(group.totalSpentMinor, size: MoneySize.small),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: QesmaSpacing.sm + 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: QesmaSpacing.sm,
            spacing: QesmaSpacing.sm,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                ExcludeSemantics(child: Icon(Icons.group_outlined, size: 18, color: context.colors.textSecondary)),
                const SizedBox(width: QesmaSpacing.xs),
                Text(members, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ]),
              BalanceStatusChip(group.yourNetMinor),
            ],
          ),
        ],
      ),
    );
  }
}
