import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../groups/application/group_detail_controller.dart';
import '../application/incoming_settlements.dart';
import '../application/settlement_actions_controller.dart';
import '../application/settlement_rules.dart';
import 'settlement_action_runner.dart';
import 'settlement_status_chip.dart';

/// P13-02: "Yousef says he paid you 720.00" with "Received" and "Not received yet" for one PENDING payment addressed
/// to the signed-in person. Names and amount are the server's; the buttons only call the confirm / dispute actions.
class ReceiverCard extends ConsumerWidget {
  const ReceiverCard({super.key, required this.gid, required this.settlement, required this.nameOf});

  final String gid;
  final SettlementView settlement;
  final String Function(String memberId) nameOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final from = nameOf(settlement.fromMemberId);
    final amount = settlement.amountMinor;
    final active = ref.watch(settlementActionsControllerProvider(gid));
    final busy = active.busy;
    final mine = active.busyId == settlement.id;

    Future<void> act(SettlementAction action) =>
        runSettlementAction(context, ref, gid: gid, settlement: settlement, action: action, nameOf: nameOf);

    return AppCard(
      onTap: () => context.push(Routes.settlement(gid, settlement.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MemberAvatar(memberId: settlement.fromMemberId, name: from, size: 40),
              const SizedBox(width: QesmaSpacing.sm + 4),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.receiverCardTitle(fsIsolate(from), moneyDisplay(l10n, amount)), style: theme.textTheme.titleSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.sm),
          const Align(alignment: AlignmentDirectional.centerStart, child: SettlementStatusChip(SettlementStatus.pending)),
          const SizedBox(height: QesmaSpacing.sm),
          Text(l10n.receiverCardBody, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.md),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: l10n.receiverConfirmSpoken(moneySpoken(l10n, amount), from),
            onTap: busy ? null : () => act(SettlementAction.confirm),
            child: AppButton(
              label: l10n.receiverConfirm,
              icon: Icons.check,
              loading: mine && active.busyAction == SettlementAction.confirm,
              onPressed: busy ? null : () => act(SettlementAction.confirm),
            ),
          ),
          const SizedBox(height: QesmaSpacing.sm),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: l10n.receiverDisputeSpoken(moneySpoken(l10n, amount), from),
            onTap: busy ? null : () => act(SettlementAction.dispute),
            child: AppButton(
              label: l10n.receiverDispute,
              icon: Icons.close,
              variant: AppButtonVariant.secondary,
              loading: mine && active.busyAction == SettlementAction.dispute,
              onPressed: busy ? null : () => act(SettlementAction.dispute),
            ),
          ),
        ],
      ),
    );
  }
}

/// The payments waiting for the signed-in person as a section of the Balances tab. Nothing while there are none or while
/// the list is loading or failed (the balances tab has its own states).
class IncomingPaymentsSection extends ConsumerWidget {
  const IncomingPaymentsSection({super.key, required this.group});

  final GroupDto group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(incomingPaymentsProvider(group.id)).value ?? const <SettlementView>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final nameOf = memberNameResolver(group, l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: QesmaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
            child: Semantics(header: true, child: Text(l10n.incomingTitle, style: Theme.of(context).textTheme.titleMedium)),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: QesmaSpacing.sm + 4),
            ReceiverCard(gid: group.id, settlement: items[i], nameOf: nameOf),
          ],
        ],
      ),
    );
  }
}

/// Group-home banner "A payment is waiting for you to confirm", visible on every tab. Opens the receiver cards in a sheet.
class IncomingPaymentsBanner extends ConsumerWidget {
  const IncomingPaymentsBanner({super.key, required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(incomingPaymentsProvider(gid)).value ?? const <SettlementView>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final text = items.length == 1 ? l10n.incomingBannerOne : l10n.incomingBannerMany('${items.length}');
    final warning = context.colors.warning;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, 0, QesmaSpacing.margin, QesmaSpacing.sm),
      child: Semantics(
        button: true,
        container: true,
        excludeSemantics: true,
        label: text,
        onTap: () => showIncomingPaymentsSheet(context, gid),
        child: Material(
          color: context.colors.warningContainer,
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          child: InkWell(
            borderRadius: BorderRadius.circular(QesmaRadii.control),
            onTap: () => showIncomingPaymentsSheet(context, gid),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: warning, size: 20),
                    const SizedBox(width: QesmaSpacing.sm),
                    Expanded(child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: warning))),
                    Icon(Icons.chevron_left, color: warning),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showIncomingPaymentsSheet(BuildContext context, String gid) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (_) => _IncomingSheet(gid: gid),
  );
}

class _IncomingSheet extends ConsumerWidget {
  const _IncomingSheet({required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupDetailControllerProvider(gid)).group;
    final incoming = ref.watch(incomingPaymentsProvider(gid));
    final items = incoming.value ?? const <SettlementView>[];
    final nameOf = memberNameResolver(group, l10n);
    // Everything answered: close by itself, the banner is gone as well.
    if (items.isEmpty && incoming.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }
    return AppBottomSheet(
      title: l10n.incomingTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: QesmaSpacing.sm + 4),
            ReceiverCard(gid: gid, settlement: items[i], nameOf: nameOf),
          ],
        ],
      ),
    );
  }
}
