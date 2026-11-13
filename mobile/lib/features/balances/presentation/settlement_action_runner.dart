import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/widgets.dart';
import '../application/settlement_actions_controller.dart';
import '../application/settlement_rules.dart';

/// Runs one confirm / dispute / cancel from a button: asks first where the step is a hard one (dispute, cancel), sends it,
/// then says what came of it in one snackbar. Everything is re-read by the controller; the screens just redraw.
/// Returns what the server came to (null when the person backed out of the question).
Future<SettlementActionOutcome?> runSettlementAction(
  BuildContext context,
  WidgetRef ref, {
  required String gid,
  required SettlementView settlement,
  required SettlementAction action,
  required String Function(String memberId) nameOf,
}) async {
  final l10n = AppLocalizations.of(context);
  if (action == SettlementAction.dispute) {
    final ok = await showConfirmDialog(
      context,
      title: l10n.disputeDialogTitle,
      message: l10n.disputeDialogBody(fsIsolate(nameOf(settlement.fromMemberId))),
      confirmLabel: l10n.disputeDialogConfirm,
      cancelLabel: l10n.cancelDialogKeep,
      destructive: true,
    );
    if (!ok || !context.mounted) return null;
  } else if (action == SettlementAction.cancel) {
    final ok = await showConfirmDialog(
      context,
      title: l10n.cancelDialogTitle,
      message: l10n.cancelDialogBody,
      confirmLabel: l10n.cancelDialogConfirm,
      cancelLabel: l10n.cancelDialogKeep,
      destructive: true,
    );
    if (!ok || !context.mounted) return null;
  }
  final result = await ref.read(settlementActionsControllerProvider(gid).notifier).perform(settlement.id, action);
  if (!context.mounted) return result.outcome;
  final text = switch (result.outcome) {
    SettlementActionOutcome.done => switch (action) {
        SettlementAction.confirm => l10n.settlementConfirmedSnack,
        SettlementAction.dispute => l10n.settlementDisputedSnack,
        SettlementAction.cancel => l10n.settlementCancelledSnack,
      },
    SettlementActionOutcome.stateChanged => l10n.settlementStateChanged,
    SettlementActionOutcome.gone => l10n.settlementGone,
    SettlementActionOutcome.failed => result.failure == null ? null : errorCopyFor(l10n, result.failure!).message,
  };
  if (text != null) showAppSnackBar(context, text);
  return result.outcome;
}
