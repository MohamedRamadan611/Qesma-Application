import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/features_for_mode.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../balances/presentation/balances_tab.dart';
import '../../balances/presentation/receiver_card.dart';
import '../../expenses/application/expenses_list_controller.dart';
import '../../expenses/presentation/expenses_tab.dart';
import '../../invites/presentation/invite_sheet.dart';
import '../../pool/presentation/pool_card.dart';
import '../../receipt_scan/application/receipt_scan_providers.dart';
import '../../receipt_scan/presentation/scan_flow.dart';
import '../application/group_detail_controller.dart';
import '../application/group_permissions.dart';
import '../data/group_type.dart';
import 'group_summary_card.dart';
import 'group_ui.dart';
import '../../../core/format/date_format.dart';
import 'members_tab.dart';

/// Group home shell (P3-01): header with name, type, member count and total spent, and the
/// three tabs in the design's order (Expenses, Balances, Members: first on the right in
/// Arabic).
class GroupHomeScreen extends ConsumerStatefulWidget {
  const GroupHomeScreen({super.key, required this.gid, this.initialTab});

  final String gid;
  final String? initialTab;

  @override
  ConsumerState<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends ConsumerState<GroupHomeScreen> {
  static const _tabNames = ['expenses', 'balances', 'members'];
  late int _tab = _tabNames.indexOf(widget.initialTab ?? '').clamp(0, 2);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(groupDetailControllerProvider(widget.gid));
    final group = detail.group;
    // Holds the expenses list for as long as this screen lives, so its filters and loaded pages
    // survive switching tabs and opening an expense (the list is auto-dispose).
    ref.listen(expensesListControllerProvider(widget.gid), (_, _) {});

    if (group == null) {
      final Widget body = detail.failure == null
          ? const SkeletonList(itemCount: 3)
          : detail.gone
          ? EmptyState(
              icon: Icons.search_off,
              title: l10n.groupOpenFailedGone,
              actionLabel: l10n.groupBackToList,
              onAction: () => context.go(Routes.home),
            )
          : detail.failure is ApiNoConnection || detail.failure is ApiTimeout
          ? NoInternetState(
              onRetry: ref
                  .read(groupDetailControllerProvider(widget.gid).notifier)
                  .load,
            )
          : ErrorState(
              onRetry: ref
                  .read(groupDetailControllerProvider(widget.gid).notifier)
                  .load,
              message: errorCopyFor(l10n, detail.failure!).message,
              requestId: detail.failure!.problem?.requestId,
            );
      return AppScaffold(
        title: l10n.groupsTitle,
        showBack: true,
        onBack: () => context.go(Routes.home),
        body: body,
      );
    }

    final type = GroupType.fromWire(group.type);
    final tabs = [
      AppTabItem(label: l10n.groupTabExpenses, icon: Icons.receipt_long),
      AppTabItem(
        label: l10n.groupTabBalances,
        icon: Icons.account_balance_wallet_outlined,
      ),
      AppTabItem(label: l10n.groupTabMembers, icon: Icons.group_outlined),
    ];

    final Widget tabBody = switch (_tab) {
      0 => ExpensesTab(group: group),
      2 => MembersTab(group: group),
      _ => BalancesTab(group: group),
    };

    return AppScaffold(
      title: group.name,
      subtitle: l10n.groupHeaderSubtitle(
        memberCountText(l10n, group.members.length),
        moneyDisplay(l10n, group.totalSpentMinor),
      ),
      titleTag: AppTag(label: type.label(l10n), tone: AppTagTone.info),
      showBack: true,
      onBack: () => context.go(Routes.home),
      // Only an owner or an admin edits the group (the server still decides; a plain member would get 403).
      actions: [
        if (ref.watch(modeFeaturesProvider).recap)
          IconButton(
            icon: const Icon(Icons.photo),
            tooltip: l10n.recapTitle,
            onPressed: () => context.push(Routes.recap(group.id)),
          ),
        // Owner and Admin invite people (the server still decides; a plain member would get 403).
        if (ref.watch(groupPermissionsProvider(widget.gid)).canManageInvites)
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.inviteAction,
            onPressed: () => showInviteSheet(context, gid: group.id, groupName: group.name),
          ),
        if (ref.watch(groupPermissionsProvider(widget.gid)).canEditGroup)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.groupEditTitle,
            onPressed: () => context.push(Routes.editGroup(group.id)),
          ),
      ],
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              // SA11: in local mode the button offers the calculator next to a plain expense.
              onPressed: ref.watch(modeFeaturesProvider).calculator || ref.watch(receiptScanVisibleProvider)
                  ? () => _showAddMenu(context, group.id)
                  : () => context.push(Routes.addExpense(group.id)),
              icon: const Icon(Icons.add),
              label: Text(l10n.expensesAdd),
            )
          : null,
      // The header (summary, pool, tabs) scrolls away with the list instead of staying fixed.
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
        children: [
          // Payments waiting for this person to confirm (FL13), visible on every tab.
          IncomingPaymentsBanner(gid: group.id),
          // The "total shared" card: total spent, member count, the caller's position and the settlement status.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, 0, QesmaSpacing.margin, QesmaSpacing.sm),
            child: GroupSummaryCard(
              title: l10n.summaryGroupTotal,
              totalSpentMinor: group.totalSpentMinor,
              countLabel: memberCountText(l10n, group.members.length),
              netMinor: group.yourNetMinor,
              statusLabel: group.yourNetMinor == 0 ? l10n.summaryAllSettled : l10n.summaryOpen,
              settled: group.yourNetMinor == 0,
              footnote: group.lastExpenseAt == null ? l10n.groupNoActivity : l10n.groupLastActivity(ltrIsolate(isoDate(group.lastExpenseAt!))),
            ),
          ),
          // SA10: the pool card, only when the group has a treasurer.
          if (ref.watch(modeFeaturesProvider).pool && group.treasurerMemberId != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, 0, QesmaSpacing.margin, QesmaSpacing.sm),
              child: PoolCard(group: group),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              QesmaSpacing.margin,
              0,
              QesmaSpacing.margin,
              QesmaSpacing.sm,
            ),
            child: AppSegmentedTabs(
              items: tabs,
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
        ],
            ),
          ),
        ],
        body: tabBody,
      ),
    );
  }

  /// SA11: add a plain expense, or open the Khorouga calculator (which prefills one).
  void _showAddMenu(BuildContext context, String gid) {
    final l10n = AppLocalizations.of(context);
    showAppBottomSheet<void>(
      context,
      title: l10n.expensesAdd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(l10n.calcMenuAddExpense),
            subtitle: Text(l10n.calcMenuAddExpenseHint),
            onTap: () {
              Navigator.of(context).pop();
              context.push(Routes.addExpense(gid));
            },
          ),
          if (ref.read(modeFeaturesProvider).calculator)
            ListTile(
              leading: const Icon(Icons.local_gas_station_outlined),
              title: Text(l10n.calcMenuCalculator),
              subtitle: Text(l10n.calcMenuCalculatorHint),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.calculator(gid));
              },
            ),
          // SA12: a photo of the receipt becomes an unsaved itemized bill.
          if (ref.read(receiptScanVisibleProvider))
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.scanReceiptAction),
              subtitle: Text(l10n.scanReceiptHint),
              onTap: () {
                Navigator.of(context).pop();
                _scanReceipt(gid);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _scanReceipt(String gid) async {
    final result = await runReceiptScan(context, ref);
    if (!mounted) return;
    switch (result) {
      case ScanFlowDraft(:final draft):
        await context.push(Routes.addExpense(gid), extra: draft);
      case ScanFlowManual():
        await context.push(Routes.addExpense(gid));
      case ScanFlowCancelled():
        break;
    }
  }
}
