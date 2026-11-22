import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/format/date_format.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/group_detail_controller.dart';
import '../application/groups_list_controller.dart';
import '../application/group_permissions.dart';
import '../data/group_type.dart';
import 'group_dialogs.dart';
import 'group_ui.dart';
import '../../../core/features_for_mode.dart';
import '../../../core/theme/palette.dart';
import '../../../local/errors.dart';
import '../../../local/insights/archive_provider.dart';
import '../../../local/insights/pool_summary_provider.dart';
import '../../balances/presentation/member_picker_sheet.dart';
import '../../expenses/presentation/expense_ui.dart';
import 'group_type_dropdown.dart';

/// Edit group (P2-03): name and type via `PATCH` with `If-Match`; delete with confirm.
/// No photo, no admin label, no status card.
class EditGroupScreen extends ConsumerStatefulWidget {
  const EditGroupScreen({super.key, required this.gid});

  final String gid;

  @override
  ConsumerState<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends ConsumerState<EditGroupScreen> {
  final _name = TextEditingController();
  GroupType _type = GroupType.other;

  /// SA10: the chosen treasurer (null = none yet). Only sent when it differs from the group's.
  String? _treasurerId;
  bool _filled = false;

  /// The user changed the form: reloads (after a conflict) must not overwrite it.
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    // Re-read on open so the version for `If-Match` is current and a deleted group is noticed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(groupDetailControllerProvider(widget.gid).notifier).load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Fills the form once, from the first copy of the group. Later reloads never overwrite
  /// what the user typed (after a conflict they re-apply their edit).
  void _sync(GroupDto group) {
    if (_touched) return;
    if (_name.text != group.name) _name.text = group.name;
    _type = GroupType.fromWire(group.type);
    _treasurerId = group.treasurerMemberId;
  }

  void _fillOnce(GroupDto group) {
    if (_filled) return;
    _filled = true;
    _name.text = group.name;
    _type = GroupType.fromWire(group.type);
    _treasurerId = group.treasurerMemberId;
  }

  Future<void> _pickTreasurer(GroupDto group) async {
    final active = group.members.where((m) => m.status == 'ACTIVE').toList();
    final id = await showMemberPicker(context, members: active, selectedId: _treasurerId, excludeId: null);
    if (id != null && mounted) {
      setState(() {
        _treasurerId = id;
        _touched = true;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(groupDetailControllerProvider(widget.gid).notifier);
    final current = ref.read(groupDetailControllerProvider(widget.gid)).group?.treasurerMemberId;
    final failure = await controller.save(
      name: _name.text.trim(),
      type: _type.wire,
      treasurerMemberId: _treasurerId != current ? _treasurerId : null,
    );
    if (!mounted) return;
    if (failure == null) {
      goBackOr(context, Routes.group(widget.gid));
      return;
    }
    switch (codeOf(failure)) {
      case ApiErrorCode.versionConflict:
        if (await showConflictDialog(context)) await controller.load();
      case ApiErrorCode.notFound:
        showAppSnackBar(context, l10n.groupOpenFailedGone);
        context.go(Routes.home);
      case ApiErrorCode.invalidStateTransition:
        // A137: the pool was used meanwhile; the treasurer is locked. Put the saved one back.
        showAppSnackBar(context, l10n.poolTreasurerLocked);
        setState(() => _treasurerId = ref.read(groupDetailControllerProvider(widget.gid)).group?.treasurerMemberId);
      default:
        showFailureSnack(context, failure);
    }
  }

  /// A184: archive a settled group (local mode). It leaves the list and is deleted after the retention period.
  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context);
    final group = ref.read(groupDetailControllerProvider(widget.gid)).group;
    if (group == null) return;
    final days = await ref.read(archiveRetentionProvider.future);
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.archiveConfirmTitle,
      message: l10n.archiveConfirmBody(group.name, '$days'),
      confirmLabel: l10n.archiveAction,
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(archiveServiceProvider).archive(widget.gid);
    } on LocalApiException {
      if (mounted) await showBlockedDialog(context, title: l10n.archiveBlockedTitle, message: l10n.archiveBlocked);
      return;
    }
    if (!mounted) return;
    // Leave first, refresh after: invalidating while this screen is still mounted made the archived group's screens
    // rebuild against a group that is gone (a blank white frame) before the navigation finished.
    final container = ProviderScope.containerOf(context, listen: false);
    context.go(Routes.home);
    messenger.showSnackBar(SnackBar(content: Text(l10n.archiveDone)));
    container.invalidate(archivedGroupsProvider);
    container.invalidate(groupsListControllerProvider);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final detail = ref.read(groupDetailControllerProvider(widget.gid));
    final group = detail.group;
    if (group == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.groupDeleteConfirmTitle,
      message: l10n.groupDeleteConfirmBody(group.name),
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final failure = await ref.read(groupDetailControllerProvider(widget.gid).notifier).delete();
    if (!mounted) return;
    if (failure == null) {
      context.go(Routes.home);
      return;
    }
    switch (codeOf(failure)) {
      case ApiErrorCode.groupNotEmpty:
        await showBlockedFor(context, failure, extra: l10n.groupBlockedTotal(moneyDisplay(l10n, group.totalSpentMinor)));
      case ApiErrorCode.notFound:
        context.go(Routes.home);
      default:
        showFailureSnack(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final detail = ref.watch(groupDetailControllerProvider(widget.gid));
    ref.listen(groupDetailControllerProvider(widget.gid), (_, next) {
      final g = next.group;
      if (g != null) _sync(g);
    });
    final group = detail.group;
    if (group != null) _fillOnce(group);
    final poolOn = ref.watch(modeFeaturesProvider).pool;
    // A137: locked once the pool was used (the server's 409 stays the authority).
    final poolLocked = poolOn && (ref.watch(poolSummaryProvider(widget.gid)).value?.locked ?? false);

    Widget body;
    if (group == null || detail.gone) {
      body = detail.failure == null
          ? const SkeletonList(itemCount: 2)
          : detail.gone
              ? EmptyState(
                  icon: Icons.search_off,
                  title: l10n.groupOpenFailedGone,
                  actionLabel: l10n.groupBackToList,
                  onAction: () => context.go(Routes.home),
                )
              : ErrorState(
                  onRetry: ref.read(groupDetailControllerProvider(widget.gid).notifier).load,
                  message: errorCopyFor(l10n, detail.failure!).message,
                  requestId: detail.failure!.problem?.requestId,
                );
    } else {
      body = ListView(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        children: [
          AppTag(label: l10n.groupCreatedOn(ltrIsolate(isoDate(group.createdAt)))),
          const SizedBox(height: QesmaSpacing.md),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => AppTextField(
              controller: _name,
              label: l10n.groupNameLabel,
              maxLength: 60,
              enabled: !detail.busy,
              onChanged: (_) => _touched = true,
            ),
          ),
          const SizedBox(height: QesmaSpacing.lg),
          Text(l10n.groupTypeLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: QesmaSpacing.sm),
          GroupTypeDropdown(
            value: _type,
            onChanged: detail.busy
                ? null
                : (type) => setState(() {
                      _type = type;
                      _touched = true;
                    }),
          ),
          if (poolOn) ...[
            const SizedBox(height: QesmaSpacing.lg),
            _PoolSection(
              group: group,
              treasurerId: _treasurerId,
              locked: poolLocked,
              onPick: detail.busy || poolLocked ? null : () => _pickTreasurer(group),
            ),
          ],
          const SizedBox(height: QesmaSpacing.lg),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) {
              final changed =
                  _name.text.trim() != group.name || _type.wire != group.type || _treasurerId != group.treasurerMemberId;
              return AppButton(
                label: l10n.groupSaveChanges,
                icon: Icons.check,
                loading: detail.busy,
                onPressed: changed && _name.text.trim().isNotEmpty && !detail.busy ? _save : null,
              );
            },
          ),
          const SizedBox(height: QesmaSpacing.sm),
          if (ref.watch(modeFeaturesProvider).archive && ref.watch(groupPermissionsProvider(widget.gid)).canDeleteGroup) ...[
            AppButton(
              label: l10n.archiveAction,
              icon: Icons.inventory_2_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: detail.busy ? null : _archive,
            ),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          if (ref.watch(groupPermissionsProvider(widget.gid)).canDeleteGroup)   // only the owner deletes a group
            AppButton(
              label: l10n.groupDelete,
              icon: Icons.delete_outline,
              variant: AppButtonVariant.secondary,
              onPressed: detail.busy ? null : _delete,
            ),
        ],
      );
    }

    return AppScaffold(
      title: l10n.groupEditTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.group(widget.gid)),
      body: body,
    );
  }
}

/// SA10: the "Pool" section (STANDALONE_SPEC 10): pick the treasurer among the active members. Locked after the first
/// deposit or pool expense (A137), with the reason in words. There is no "clear" (the contract cannot express it).
class _PoolSection extends StatelessWidget {
  const _PoolSection({required this.group, required this.treasurerId, required this.locked, required this.onPick});

  final GroupDto group;
  final String? treasurerId;
  final bool locked;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final id = treasurerId;
    final name = id == null ? l10n.poolTreasurerNone : memberNameResolver(group, l10n)(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.poolSectionTitle, style: theme.textTheme.titleMedium)),
        const SizedBox(height: QesmaSpacing.xs),
        Text(l10n.poolSectionHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        const SizedBox(height: QesmaSpacing.sm),
        Semantics(
          button: onPick != null,
          enabled: onPick != null,
          excludeSemantics: true,
          label: '${l10n.poolTreasurerLabel}: $name',
          hint: onPick == null ? null : l10n.poolTreasurerChoose,
          onTap: onPick,
          child: AppCard(
            onTap: onPick,
            padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
            child: Row(
              children: [
                if (id != null) ...[MemberAvatar(memberId: id, name: name, size: 36), const SizedBox(width: QesmaSpacing.sm)]
                else ...[Icon(Icons.savings_outlined, color: context.colors.textHelper), const SizedBox(width: QesmaSpacing.sm)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.poolTreasurerLabel, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                      Text(name, style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
                Icon(locked ? Icons.lock_outline : Icons.expand_more, color: context.colors.textHelper),
              ],
            ),
          ),
        ),
        if (locked) ...[
          const SizedBox(height: QesmaSpacing.xs),
          Text(l10n.poolTreasurerLocked, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        ],
      ],
    );
  }
}
