import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/pool_summary_provider.dart';
import '../../../local/insights/pool_summary_repository.dart';
import '../../balances/application/record_payment_state.dart';
import '../../balances/presentation/record_payment_sheet.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/presentation/group_ui.dart';
import 'pool_meter.dart';

/// The pool (SA10, STANDALONE_SPEC 10): the meter (deposited, spent from the pool, what is left), the treasurer and
/// the deposits, newest first. "What is left" is `GroupDto.poolBalanceMinor`; the two parts come from the local
/// read-model. Nothing here adds or subtracts money.
class PoolScreen extends ConsumerWidget {
  const PoolScreen({super.key, required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupDetailControllerProvider(gid)).group;
    final summary = ref.watch(poolSummaryProvider(gid));
    final Widget body;
    if (group == null || group.treasurerMemberId == null) {
      body = const SkeletonList(itemCount: 3);
    } else {
      body = _PoolBody(group: group, summary: summary.value);
    }
    return AppScaffold(
      title: l10n.poolSectionTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.group(gid)),
      body: body,
    );
  }
}

class _PoolBody extends StatelessWidget {
  const _PoolBody({required this.group, required this.summary});

  final GroupDto group;
  final PoolSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nameOf = memberNameResolver(group, l10n);
    final treasurerId = group.treasurerMemberId!;
    final s = summary;
    return ListView(
      padding: const EdgeInsets.all(QesmaSpacing.margin),
      children: [
        Text(l10n.poolTreasurerIs(fsIsolate(nameOf(treasurerId))), style: theme.textTheme.titleSmall),
        const SizedBox(height: QesmaSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (s != null) ...[
                PoolMeterRow(label: l10n.poolDeposited, minor: s.depositedMinor),
                PoolMeterRow(label: l10n.poolSpent, minor: s.spentMinor),
                const Divider(height: QesmaSpacing.lg),
              ],
              PoolRemaining(meterMinor: group.poolBalanceMinor ?? 0),
            ],
          ),
        ),
        const SizedBox(height: QesmaSpacing.md),
        AppButton(
          label: l10n.poolAddDeposit,
          icon: Icons.add,
          onPressed: () => showDepositSheet(context, gid: group.id, treasurerId: treasurerId),
        ),
        const SizedBox(height: QesmaSpacing.lg),
        Semantics(header: true, child: Text(l10n.poolDepositsTitle, style: theme.textTheme.titleMedium)),
        const SizedBox(height: QesmaSpacing.sm),
        if (s == null)
          const SkeletonList(itemCount: 2)
        else if (s.deposits.isEmpty)
          EmptyState(icon: Icons.savings_outlined, title: l10n.poolDepositsEmpty, message: l10n.poolDepositsEmptyBody)
        else
          for (final d in s.deposits) ...[
            _DepositRow(deposit: d, name: nameOf(d.fromMemberId), onEdit: d.cancelled ? null : () => showRecordPaymentSheet(context, gid: group.id, seed: PaymentSeed(fromId: d.fromMemberId, toId: treasurerId, amountMinor: d.amountMinor, poolDeposit: true, replacesId: d.id, settledOn: d.settledOn, note: d.note))),
            const SizedBox(height: QesmaSpacing.sm),
          ],
      ],
    );
  }
}

class _DepositRow extends StatelessWidget {
  const _DepositRow({required this.deposit, required this.name, this.onEdit});

  final PoolDeposit deposit;
  final String name;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
      child: Row(
        children: [
          MemberAvatar(memberId: deposit.fromMemberId, name: name, size: 36),
          const SizedBox(width: QesmaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall),
                Text(ltrIsolate(deposit.settledOn), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                if (deposit.note != null)
                  Text(deposit.note!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (deposit.cancelled) ...[
                  const SizedBox(height: QesmaSpacing.xs),
                  AppTag(label: AppLocalizations.of(context).settlementChipCancelled, icon: Icons.cancel_outlined),
                ],
              ],
            ),
          ),
          const SizedBox(width: QesmaSpacing.sm),
          MoneyText(deposit.amountMinor),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppLocalizations.of(context).poolEditDeposit,
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
