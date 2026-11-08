import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../application/groups_list_controller.dart';
import 'group_card.dart';

/// Home of the signed-in app: the paged list of groups (P2-01).
/// The overflow menu with "sign out" is TEMPORARY until the profile screen exists (FL8).
class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  final _scroll = ScrollController();

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
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _loadMore() async {
    final failure = await ref.read(groupsListControllerProvider.notifier).loadMore();
    if (failure != null && mounted) showAppSnackBar(context, AppLocalizations.of(context).groupsLoadMoreFailed);
  }

  Future<void> _refresh() async {
    final failure = await ref.read(groupsListControllerProvider.notifier).refresh();
    if (failure != null && mounted) showAppSnackBar(context, AppLocalizations.of(context).groupsRefreshFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(groupsListControllerProvider);
    final controller = ref.read(groupsListControllerProvider.notifier);

    Widget body;
    switch (state.status) {
      case GroupsStatus.loading:
        body = const SkeletonList();
      case GroupsStatus.failed:
        final failure = state.failure!;
        body = failure is ApiNoConnection || failure is ApiTimeout
            ? NoInternetState(onRetry: controller.load)
            : ErrorState(
                onRetry: controller.load,
                message: errorCopyFor(l10n, failure).message,
                requestId: failure.problem?.requestId,
              );
      case GroupsStatus.ready:
        body = state.items.isEmpty
            ? RefreshIndicator(
                onRefresh: _refresh,
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: box.maxHeight,
                      child: EmptyState(
                        icon: Icons.group_outlined,
                        title: l10n.groupsEmptyTitle,
                        message: l10n.groupsEmptyBody,
                        actionLabel: l10n.groupsNew,
                        onAction: () => context.push(Routes.newGroup),
                      ),
                    ),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, 96),
                  itemCount: state.items.length + 1 + (state.loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: QesmaSpacing.md - 4),
                  itemBuilder: (context, index) {
                    if (index == 0) return _NetHeader(totalMinor: state.netTotalMinor);
                    if (index > state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(QesmaSpacing.md),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final group = state.items[index - 1];
                    return GroupCard(group: group, onTap: () => context.push(Routes.group(group.id)));
                  },
                ),
              );
    }

    return AppScaffold(
      title: l10n.groupsTitle,
      showBack: false,
      actions: [
        PopupMenuButton<String>(
          tooltip: l10n.groupsMore,
          icon: const Icon(Icons.more_vert),
          onSelected: (_) => ref.read(authControllerProvider.notifier).signOut(),
          itemBuilder: (_) => [PopupMenuItem<String>(value: 'signout', child: Text(l10n.homeSignOut))],
        ),
      ],
      floatingActionButton: state.status == GroupsStatus.ready && state.items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newGroup),
              icon: const Icon(Icons.add),
              label: Text(l10n.groupsNew),
            )
          : null,
      body: body,
    );
  }
}

/// Net across all groups: only shown when the controller says it is valid (all pages
/// loaded, one currency). The number is a sum of server-sent values.
class _NetHeader extends StatelessWidget {
  const _NetHeader({required this.totalMinor});

  final int? totalMinor;

  @override
  Widget build(BuildContext context) {
    final total = totalMinor;
    if (total == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return AppCard(
      color: QesmaColors.tint,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: QesmaSpacing.sm,
        runSpacing: QesmaSpacing.sm,
        children: [
          Text(l10n.groupsNetTotal, style: Theme.of(context).textTheme.titleMedium),
          BalanceStatusChip(total),
        ],
      ),
    );
  }
}
