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
import '../application/group_permissions.dart';
import '../data/group_type.dart';
import 'group_dialogs.dart';
import 'group_ui.dart';

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
  }

  void _fillOnce(String name, String type) {
    if (_filled) return;
    _filled = true;
    _name.text = name;
    _type = GroupType.fromWire(type);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(groupDetailControllerProvider(widget.gid).notifier);
    final failure = await controller.save(name: _name.text.trim(), type: _type.wire);
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
      default:
        showFailureSnack(context, failure);
    }
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
    if (group != null) _fillOnce(group.name, group.type);

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
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.sm,
            children: [
              for (final type in GroupType.values)
                AppChoiceChip(
                  label: type.label(l10n),
                  icon: type.icon,
                  selected: _type == type,
                  onSelected: detail.busy
                      ? null
                      : (_) => setState(() {
                            _type = type;
                            _touched = true;
                          }),
                ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.lg),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) {
              final changed = _name.text.trim() != group.name || _type.wire != group.type;
              return AppButton(
                label: l10n.groupSaveChanges,
                icon: Icons.check,
                loading: detail.busy,
                onPressed: changed && _name.text.trim().isNotEmpty && !detail.busy ? _save : null,
              );
            },
          ),
          const SizedBox(height: QesmaSpacing.sm),
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
