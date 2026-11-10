import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/qesma_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/expense_blocks.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/balances_controller.dart';
import '../application/record_payment_state.dart';
import '../application/settlements_controller.dart';
import 'member_net_row.dart';
import 'record_payment_sheet.dart';
import 'settlement_history.dart';
import 'transfer_card.dart';
import '../../../core/theme/palette.dart';

/// The Balances tab of the group home (P9-01): the group's total, how many transfers settle it up,
/// the server's suggested transfers, each member's net balance and the payment history.
///
/// Everything shown is what the server said. "N transfers needed" is the number of suggested
/// transfers and "all settled" is "there are none"; nothing is added up, divided or compared here.
class BalancesTab extends ConsumerStatefulWidget {
  const BalancesTab({super.key, required this.group});

  final GroupDto group;

  @override
  ConsumerState<BalancesTab> createState() => _BalancesTabState();
}

class _BalancesTabState extends ConsumerState<BalancesTab> {
  final _scroll = ScrollController();

  String get _gid => widget.group.id;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final failure = await ref.read(balancesControllerProvider(_gid).notifier).refresh();
    await ref.read(settlementsControllerProvider(_gid).notifier).refresh();
    if (failure != null && mounted) showAppSnackBar(context, AppLocalizations.of(context).balancesRefreshFailed);
  }

  Future<void> _record(PaymentSeed seed) async {
    final recorded = await showRecordPaymentSheet(context, gid: _gid, seed: seed);
    if (recorded && mounted) showAppSnackBar(context, AppLocalizations.of(context).paymentRecorded);
  }

  Future<void> _delete(SettlementView payment, String Function(String) nameOf) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.balancesDeleteTitle,
      message: l10n.balancesDeleteBody,
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final (outcome, failure) = await ref.read(settlementsControllerProvider(_gid).notifier).delete(payment.id);
    if (!mounted) return;
    final text = switch (outcome) {
      SettlementDeleteOutcome.deleted => l10n.balancesDeleted,
      SettlementDeleteOutcome.alreadyGone => l10n.balancesDeleteGone,
      SettlementDeleteOutcome.failed => failure == null ? null : errorCopyFor(l10n, failure).message,
    };
    if (text != null) showAppSnackBar(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(balancesControllerProvider(_gid));
    final controller = ref.read(balancesControllerProvider(_gid).notifier);

    switch (state.status) {
      case BalancesStatus.loading:
        return const SkeletonList();
      case BalancesStatus.failed:
        final failure = state.failure!;
        return failure is ApiNoConnection || failure is ApiTimeout
            ? NoInternetState(onRetry: controller.load)
            : ErrorState(onRetry: controller.load, message: errorCopyFor(l10n, failure).message, requestId: failure.problem?.requestId);
      case BalancesStatus.ready:
        return _ready(state.balances!);
    }
  }

  Widget _ready(BalanceView balances) {
    final l10n = AppLocalizations.of(context);
    final group = widget.group;
    final nameOf = memberNameResolver(group, l10n);
    final settlements = ref.watch(settlementsControllerProvider(_gid));
    final members = {for (final m in group.members) m.id: m};
    final transfers = balances.transfers.toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Semantics(
        customSemanticsActions: {CustomSemanticsAction(label: l10n.balancesRefresh): _refresh},
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
          children: [
            _StatusCard(totalSpentMinor: group.totalSpentMinor, transferCount: transfers.length),
            const SizedBox(height: QesmaSpacing.md),
            if (transfers.isEmpty)
              _AllSettled()
            else
              SectionCard(
                title: l10n.balancesSuggestedTitle,
                icon: Icons.swap_horiz,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < transfers.length; i++) ...[
                      if (i > 0) const SizedBox(height: QesmaSpacing.sm + 4),
                      TransferCard(
                        transfer: transfers[i],
                        nameOf: nameOf,
                        onRecord: () => _record(PaymentSeed(fromId: transfers[i].fromMemberId, toId: transfers[i].toMemberId, amountMinor: transfers[i].amountMinor)),
                      ),
                    ],
                  ],
                ),
              ),
            if (group.members.length >= 2) ...[
              const SizedBox(height: QesmaSpacing.md),
              AppButton(label: l10n.balancesRecordAnother, icon: Icons.add, variant: AppButtonVariant.secondary, onPressed: () => _record(const PaymentSeed())),
            ],
            const SizedBox(height: QesmaSpacing.md),
            SectionCard(
              title: l10n.balancesNetsTitle,
              icon: Icons.balance,
              count: memberCountText(l10n, balances.nets.length),
              child: Column(
                children: [
                  for (final net in balances.nets)
                    MemberNetRow(
                      memberId: net.memberId,
                      name: nameOf(net.memberId),
                      netMinor: net.netMinor,
                      isYou: members[net.memberId]?.isYou ?? false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: QesmaSpacing.md),
            SettlementHistory(
              state: settlements,
              nameOf: nameOf,
              onDelete: (payment) => _delete(payment, nameOf),
              onLoadMore: () => ref.read(settlementsControllerProvider(_gid).notifier).loadMore(retry: true),
              onRetry: ref.read(settlementsControllerProvider(_gid).notifier).load,
            ),
          ],
        ),
      ),
    );
  }
}

/// Total spent and the "N transfers needed" line. The count is the number of suggested transfers.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.totalSpentMinor, required this.transferCount});

  final int totalSpentMinor;
  final int transferCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = transferCount == 0
        ? l10n.balancesAllSettledTitle
        : countPhrase(transferCount, one: l10n.balancesNeedOne, two: l10n.balancesNeedTwo, few: l10n.balancesNeed, many: l10n.balancesNeedMany);
    return MergeSemantics(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(QesmaRadii.hero), boxShadow: QesmaShadows.card),
          child: Padding(
            padding: const EdgeInsets.all(QesmaSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.balancesTotalSpent, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.onPrimary)),
                const SizedBox(height: QesmaSpacing.xs),
                Text(moneyDisplay(l10n, totalSpentMinor), style: QesmaText.amountLarge().copyWith(color: context.colors.onPrimary)),
                const SizedBox(height: QesmaSpacing.sm + 4),
                Row(
                  children: [
                    ExcludeSemantics(child: Icon(Icons.swap_horiz, color: context.colors.onPrimary, size: 20)),
                    const SizedBox(width: QesmaSpacing.sm),
                    Expanded(child: Text(status, style: theme.textTheme.titleSmall?.copyWith(color: context.colors.onPrimary))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllSettled extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.colors.successContainer, borderRadius: BorderRadius.circular(QesmaRadii.card)),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.md),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(Icons.check_circle, color: context.colors.success)),
              const SizedBox(width: QesmaSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.balancesAllSettledTitle, style: theme.textTheme.titleSmall?.copyWith(color: context.colors.success)),
                    Text(l10n.balancesAllSettledBody, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.success)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
