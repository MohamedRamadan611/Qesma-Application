import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/format/clock.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_filters.dart';
import '../application/expense_grouping.dart';
import '../application/expenses_list_controller.dart';
import 'expense_card.dart';
import 'expense_filters.dart';
import 'expense_ui.dart';
import '../../../core/theme/palette.dart';

/// The Expenses tab of the group home (P3-01): filters, then the list grouped by date,
/// newest first, 20 per page with infinite scroll and pull to refresh.
/// The "add expense" button belongs to the group home (it floats over every tab-0 state).
class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key, required this.group});

  final GroupDto group;

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  final _scroll = ScrollController();

  String get _gid => widget.group.id;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Within about three cards of the end.
    if (_scroll.position.extentAfter < 500) _loadMore();
  }

  /// Scrolling loads the next page; after a failure the "try again" row (not a scroll event) retries.
  Future<void> _loadMore({bool retry = false}) => ref.read(expensesListControllerProvider(_gid).notifier).loadMore(retry: retry);

  Future<void> _refresh() async {
    final failure = await ref.read(expensesListControllerProvider(_gid).notifier).refresh();
    if (failure != null && mounted) showAppSnackBar(context, AppLocalizations.of(context).expensesRefreshFailed);
  }

  Future<void> _pickDates(ExpenseFilters current) async {
    final choice = await showDateFilterSheet(context, from: current.from, to: current.to);
    if (choice == null || !mounted) return;
    await ref
        .read(expensesListControllerProvider(_gid).notifier)
        .applyFilters(ExpenseFilters(from: choice.from, to: choice.to, memberId: current.memberId));
  }

  Future<void> _pickMember(ExpenseFilters current) async {
    final choice = await showMemberFilterSheet(context, members: widget.group.members.toList(), selectedId: current.memberId);
    if (choice == null || !mounted) return;
    await ref
        .read(expensesListControllerProvider(_gid).notifier)
        .applyFilters(ExpenseFilters(from: current.from, to: current.to, memberId: choice.isEmpty ? null : choice));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(expensesListControllerProvider(_gid));
    final controller = ref.read(expensesListControllerProvider(_gid).notifier);
    final nameOf = memberNameResolver(widget.group, l10n);

    Widget body;
    switch (state.status) {
      case ExpensesStatus.loading:
        body = const SkeletonList();
      case ExpensesStatus.failed:
        final failure = state.failure!;
        body = failure is ApiNoConnection || failure is ApiTimeout
            ? NoInternetState(onRetry: controller.load)
            : ErrorState(
                onRetry: controller.load,
                message: errorCopyFor(l10n, failure).message,
                requestId: failure.problem?.requestId,
              );
      case ExpensesStatus.ready:
        body = state.items.isEmpty ? _empty(l10n, state) : _list(state, nameOf);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.xs, QesmaSpacing.margin, 0),
          child: ExpenseFilterBar(
            filters: state.filters,
            nameOf: nameOf,
            onDate: () => _pickDates(state.filters),
            onMember: () => _pickMember(state.filters),
            onClearDate: () => controller.applyFilters(ExpenseFilters(memberId: state.filters.memberId)),
            onClearMember: () => controller.applyFilters(ExpenseFilters(from: state.filters.from, to: state.filters.to)),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n, ExpensesListState state) {
    final filtered = state.filters.isActive;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: box.maxHeight,
            child: EmptyState(
              icon: filtered ? Icons.filter_alt_off_outlined : Icons.receipt_long_outlined,
              title: filtered ? l10n.expensesNoMatchTitle : l10n.expensesEmptyTitle,
              message: filtered ? l10n.expensesNoMatchBody : l10n.expensesEmptyBody,
              actionLabel: filtered ? l10n.expensesClearFilters : null,
              onAction: filtered ? ref.read(expensesListControllerProvider(_gid).notifier).clearFilters : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(ExpensesListState state, String Function(String) nameOf) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = ref.read(clockProvider)();
    // Date headers and cards in one flat list; the grouping runs over everything loaded.
    final rows = <Object>[
      for (final day in groupByDate(state.items)) ...[day.date, ...day.items],
    ];
    return RefreshIndicator(
      onRefresh: _refresh,
      // Pull to refresh is a gesture; screen-reader users get the same thing as a named action.
      child: Semantics(
        customSemanticsActions: {CustomSemanticsAction(label: l10n.expensesRefresh): _refresh},
        child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, 96),
        itemCount: rows.length + (state.loadingMore || state.loadMoreFailed ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= rows.length) {
            if (state.loadMoreFailed) {
              return Padding(
                padding: const EdgeInsets.all(QesmaSpacing.md),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    children: [
                      Text(l10n.expensesLoadMoreFailed, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: QesmaSpacing.sm),
                      AppButton(
                        label: l10n.commonRetry,
                        icon: Icons.refresh,
                        variant: AppButtonVariant.secondary,
                        expand: false,
                        onPressed: () => _loadMore(retry: true),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(QesmaSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final row = rows[index];
          if (row is Date) {
            // Seen as "Today — 2026-10-18"; said as a date a person would say.
            return Semantics(
              header: true,
              label: dayHeaderSpoken(context, row, now),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: QesmaSpacing.md, bottom: QesmaSpacing.sm),
                  child: Text(dayHeaderText(l10n, row, now), style: theme.textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
                ),
              ),
            );
          }
          final expense = row as ExpenseView;
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: QesmaSpacing.md - 4),
            child: ExpenseCard(
              expense: expense,
              nameOf: nameOf,
              yourMemberId: widget.group.yourMemberId,
              onTap: () => context.push(Routes.expense(_gid, expense.id)),
            ),
          );
        },
        ),
      ),
    );
  }
}
