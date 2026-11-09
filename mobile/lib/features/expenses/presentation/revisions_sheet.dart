import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/format/date_format.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_detail_controller.dart';
import 'expense_ui.dart';

/// The edit history of one expense (newest first). Read-only: each row is the saved
/// snapshot's total and payers, with its version, kind of change and time.
Future<void> showRevisionsSheet(BuildContext context, {required ExpenseKey expenseKey, required String Function(String) nameOf}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<void>(
    context,
    title: l10n.expenseHistory,
    child: _RevisionsBody(expenseKey: expenseKey, nameOf: nameOf),
  );
}

class _RevisionsBody extends ConsumerWidget {
  const _RevisionsBody({required this.expenseKey, required this.nameOf});

  final ExpenseKey expenseKey;
  final String Function(String) nameOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final revisions = ref.watch(expenseRevisionsProvider(expenseKey));
    return revisions.when(
      loading: () => Semantics(
        label: l10n.commonLoading,
        liveRegion: true,
        child: const ExcludeSemantics(
          child: SkeletonPulse(
            child: Column(
              children: [
                SkeletonBlock(height: 64, radius: 12),
                SizedBox(height: QesmaSpacing.sm),
                SkeletonBlock(height: 64, radius: 12),
              ],
            ),
          ),
        ),
      ),
      error: (error, _) {
        final failure = error is ApiFailure ? error : const ApiUnexpected();
        return Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(errorCopyFor(l10n, failure).message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: QesmaSpacing.md),
              AppButton(label: l10n.commonRetry, onPressed: () => ref.invalidate(expenseRevisionsProvider(expenseKey))),
            ],
          ),
        );
      },
      data: (list) => list.isEmpty
          ? Text(l10n.expenseHistoryEmpty, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final revision in list.reversed) ...[
            _RevisionRow(revision: revision, nameOf: nameOf),
            const SizedBox(height: QesmaSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RevisionRow extends StatelessWidget {
  const _RevisionRow({required this.revision, required this.nameOf});

  final ExpenseRevisionView revision;
  final String Function(String) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (kind, tone) = switch (revision.changeType) {
      'CREATE' => (l10n.expenseChangeCreate, AppTagTone.success),
      'UPDATE' => (l10n.expenseChangeUpdate, AppTagTone.info),
      'DELETE' => (l10n.expenseChangeDelete, AppTagTone.warning),
      _ => (null, AppTagTone.neutral),
    };
    final snapshot = revision.snapshot;
    final nameOfPayers = payersText(l10n, snapshot, nameOf);
    return MergeSemantics(
      child: AppCard(
      color: QesmaColors.tint,
      padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.expenseHistoryVersion('${revision.version}'), style: theme.textTheme.titleMedium),
              if (kind != null) AppTag(label: kind, tone: tone),
              Text(ltrIsolate(isoDateTime(revision.changedAt)), style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textHelper)),
            ],
          ),
          const SizedBox(height: QesmaSpacing.xs),
          Semantics(
            label: l10n.expenseHistoryTotal(moneySpoken(l10n, snapshot.totalMinor)),
            child: ExcludeSemantics(child: Text(l10n.expenseHistoryTotal(moneyDisplay(l10n, snapshot.totalMinor)), style: theme.textTheme.bodyMedium)),
          ),
          Semantics(
            label: payersSpoken(l10n, snapshot, nameOf),
            child: ExcludeSemantics(child: Text(nameOfPayers, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary))),
          ),
        ],
      ),
    ),
    );
  }
}
