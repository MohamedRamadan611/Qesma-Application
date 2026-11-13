import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/qesma_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/expense_blocks.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../application/settlement_rules.dart';
import '../application/settlements_controller.dart';
import 'settlement_status_chip.dart';
import '../../../core/theme/palette.dart';

/// Every payment, newest first (the server's order), each with its status chip; a tap opens its detail (where the
/// actions by role live). Cancelled payments stay in the list.
class SettlementHistory extends StatelessWidget {
  const SettlementHistory({
    super.key,
    required this.state,
    required this.nameOf,
    required this.onOpen,
    required this.onLoadMore,
    required this.onRetry,
  });

  final SettlementsState state;
  final String Function(String memberId) nameOf;
  final void Function(SettlementView payment) onOpen;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final Widget body;
    switch (state.status) {
      case SettlementsStatus.loading:
        body = const Center(child: Padding(padding: EdgeInsets.all(QesmaSpacing.md), child: CircularProgressIndicator()));
      case SettlementsStatus.failed:
        body = Semantics(
          liveRegion: true,
          child: Column(
            children: [
              Text(errorCopyFor(l10n, state.failure!).message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: QesmaSpacing.sm),
              AppButton(label: l10n.commonRetry, icon: Icons.refresh, variant: AppButtonVariant.secondary, expand: false, onPressed: onRetry),
            ],
          ),
        );
      case SettlementsStatus.ready:
        body = state.items.isEmpty
            ? Text(l10n.balancesHistoryEmpty, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final payment in state.items)
                    _PaymentRow(
                      payment: payment,
                      nameOf: nameOf,
                      onOpen: () => onOpen(payment),
                    ),
                  if (state.loadingMore)
                    const Padding(padding: EdgeInsets.all(QesmaSpacing.md), child: Center(child: CircularProgressIndicator()))
                  else if (state.loadMoreFailed)
                    Semantics(
                      liveRegion: true,
                      child: Column(
                        children: [
                          Text(l10n.balancesLoadMoreFailed, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: QesmaSpacing.sm),
                          AppButton(label: l10n.commonRetry, icon: Icons.refresh, variant: AppButtonVariant.secondary, expand: false, onPressed: onLoadMore),
                        ],
                      ),
                    )
                  else if (state.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: QesmaSpacing.sm),
                      child: AppButton(label: l10n.balancesLoadMore, variant: AppButtonVariant.secondary, onPressed: onLoadMore),
                    ),
                ],
              );
    }
    return SectionCard(
      title: l10n.balancesHistoryTitle,
      icon: Icons.history,
      count: state.status == SettlementsStatus.ready ? ltrIsolate('${state.total}') : null,
      child: body,
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.nameOf, required this.onOpen});

  final SettlementView payment;
  final String Function(String) nameOf;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final from = nameOf(payment.fromMemberId);
    final to = nameOf(payment.toMemberId);
    final status = payment.statusKind;
    final note = payment.note;
    final hasNote = note != null && note.isNotEmpty;
    var spoken = l10n.balancesPaymentSpoken(from, moneySpoken(l10n, payment.amountMinor), to, spokenDate(context, payment.settledOn));
    if (hasNote) spoken = l10n.balancesPaymentNoteSpoken(spoken, note);
    spoken = l10n.balancesPaymentNoteSpoken(spoken, l10n.settlementChipSpoken(settlementStatusLabel(l10n, status)));
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: spoken,
      onTap: onOpen,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.balancesPaymentTitle(fsIsolate(from), fsIsolate(to)), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        moneyDisplay(l10n, payment.amountMinor),
                        style: QesmaText.amountSmall().copyWith(
                          color: status == SettlementStatus.cancelled ? context.colors.textHelper : context.colors.primary,
                          decoration: status == SettlementStatus.cancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasNote ? '${dateText(payment.settledOn)} · $note' : dateText(payment.settledOn),
                        style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper),
                      ),
                      const SizedBox(height: QesmaSpacing.xs),
                      SettlementStatusChip(status),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: context.colors.textHelper),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
