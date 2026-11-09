import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/presentation/group_dialogs.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/expense_detail_controller.dart';
import '../application/expenses_list_controller.dart';
import '../data/split_type.dart';
import 'expense_blocks.dart';
import 'expense_ui.dart';
import 'revisions_sheet.dart';

/// Expense details (P7-01): header, payers, items and charges (itemized), everyone's share,
/// edit, history and delete. Every number is what the server sent; nothing is recomputed.
class ExpenseDetailsScreen extends ConsumerWidget {
  const ExpenseDetailsScreen({super.key, required this.gid, required this.eid});

  final String gid;
  final String eid;

  ExpenseKey get _key => (gid: gid, eid: eid);

  void _back(BuildContext context) => goBackOr(context, Routes.group(gid));

  Future<void> _delete(BuildContext context, WidgetRef ref, ExpenseView expense) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.expenseDeleteConfirmTitle,
      message: l10n.expenseDeleteConfirmBody(expense.title),
      confirmLabel: l10n.expenseDelete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final controller = ref.read(expenseDetailControllerProvider(_key).notifier);
    final (outcome, failure) = await controller.delete();
    if (!context.mounted) return;
    switch (outcome) {
      case DeleteOutcome.deleted:
        showAppSnackBar(context, l10n.expenseDeleted);
        _back(context);
      case DeleteOutcome.alreadyGone:
        showAppSnackBar(context, l10n.expenseAlreadyDeleted);
        _back(context);
      case DeleteOutcome.failed:
        if (failure == null) return;
        if (codeOf(failure) == ApiErrorCode.versionConflict) {
          // Someone edited it meanwhile: offer the latest version before anything is deleted.
          final reload = await showConfirmDialog(
            context,
            title: l10n.expenseConflictTitle,
            message: l10n.expenseConflictBody,
            confirmLabel: l10n.groupConflictReload,
          );
          if (reload) {
            final reloadFailure = await controller.load();
            // A failed reload must not look like success: the stale copy (and its version) is still on screen.
            if (reloadFailure != null && context.mounted) showFailureSnack(context, reloadFailure);
          }
        } else {
          showFailureSnack(context, failure);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(expenseDetailControllerProvider(_key));
    final group = ref.watch(groupDetailControllerProvider(gid)).group;
    final nameOf = memberNameResolver(group, l10n);
    final expense = detail.expense;

    Widget body;
    if (expense == null) {
      if (detail.failure == null) {
        body = const SkeletonList(itemCount: 3);
      } else if (detail.gone) {
        body = EmptyState(
          icon: Icons.search_off,
          title: l10n.expenseGoneTitle,
          actionLabel: l10n.expenseBackToList,
          onAction: () {
            if (ref.read(expensesListControllerProvider(gid).exists)) ref.read(expensesListControllerProvider(gid).notifier).refresh();
            _back(context);
          },
        );
      } else {
        final failure = detail.failure!;
        final retry = ref.read(expenseDetailControllerProvider(_key).notifier).load;
        body = failure is ApiNoConnection || failure is ApiTimeout
            ? NoInternetState(onRetry: retry)
            : ErrorState(onRetry: retry, message: errorCopyFor(l10n, failure).message, requestId: failure.problem?.requestId);
      }
    } else {
      body = _Content(
        expense: expense,
        group: group,
        nameOf: nameOf,
        busy: detail.busy,
        onEdit: () => context.push(Routes.editExpense(gid, eid)),
        onHistory: () => showRevisionsSheet(context, expenseKey: _key, nameOf: nameOf),
        onDelete: () => _delete(context, ref, expense),
      );
    }

    return AppScaffold(title: l10n.expenseDetailsTitle, showBack: true, onBack: () => _back(context), body: body);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.expense,
    required this.group,
    required this.nameOf,
    required this.busy,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
  });

  final ExpenseView expense;
  final GroupDto? group;
  final String Function(String) nameOf;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final split = SplitType.fromWire(expense.splitType);
    final yourMemberId = group?.yourMemberId;
    final hasItems = (expense.items?.isNotEmpty ?? false);
    const gap = SizedBox(height: QesmaSpacing.md);

    return ListView(
      padding: const EdgeInsets.all(QesmaSpacing.margin),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: QesmaColors.primaryContainer, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                    child: Icon(split?.icon ?? Icons.receipt_long, color: QesmaColors.onPrimaryContainer),
                  ),
                  const SizedBox(width: QesmaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(expense.title, style: theme.textTheme.titleLarge)),
                        if (group != null) Text(group!.name, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QesmaSpacing.md),
              Text(l10n.expenseDetailsTotal, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary)),
              MoneyText(expense.totalMinor, size: MoneySize.large),
              const SizedBox(height: QesmaSpacing.sm),
              Wrap(
                spacing: QesmaSpacing.sm,
                runSpacing: QesmaSpacing.xs,
                children: [
                  Semantics(
                    label: spokenDate(context, expense.expenseDate),
                    child: ExcludeSemantics(child: AppTag(label: dateText(expense.expenseDate), icon: Icons.calendar_today_outlined)),
                  ),
                  if (split != null) AppTag(label: split.label(l10n), tone: split == SplitType.itemized ? AppTagTone.warning : AppTagTone.primary),
                  if (expense.version > 1) AppTag(label: l10n.expenseEditedBadge('${expense.version}'), tone: AppTagTone.info, icon: Icons.history),
                ],
              ),
            ],
          ),
        ),
        gap,
        PayersBlock(expense: expense, nameOf: nameOf, yourMemberId: yourMemberId),
        if (hasItems) ...[gap, ItemsAndChargesBlock(expense: expense, nameOf: nameOf)],
        gap,
        BreakdownBlock(expense: expense, nameOf: nameOf, yourMemberId: yourMemberId),
        const SizedBox(height: QesmaSpacing.lg),
        AppButton(
          label: split == SplitType.itemized ? l10n.expenseEditItemized : l10n.expenseEdit,
          icon: Icons.edit_outlined,
          onPressed: busy ? null : onEdit,
        ),
        const SizedBox(height: QesmaSpacing.sm),
        AppButton(label: l10n.expenseHistory, icon: Icons.history, variant: AppButtonVariant.secondary, onPressed: onHistory),
        const SizedBox(height: QesmaSpacing.sm),
        AppButton(
          label: l10n.expenseDelete,
          icon: Icons.delete_outline,
          variant: AppButtonVariant.destructive,
          loading: busy,
          onPressed: busy ? null : onDelete,
        ),
      ],
    );
  }
}
