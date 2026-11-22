import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import '../application/expense_preview_controller.dart';
import '../../../core/theme/palette.dart';

/// The split part of the form (P5-01): the four tabs and the member list.
///
/// - **Everyone / Selected:** every number per member is the server's (`members[].owedMinor` of
///   the preview). While the preview is loading, failed or older than the input, the amounts are
///   not shown as if they were current.
/// - **Exact:** boxes the user edits; they start from the server's equal split.
/// - **Restaurant bill:** opens the FL6 stub; the form keeps its mode.
class SplitSection extends ConsumerWidget {
  const SplitSection({super.key, required this.formKey, required this.form, required this.members, required this.previewKey});

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;

  /// Canonical text of the command the form would preview now (null in Exact mode or while incomplete).
  final String? previewKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final view = ref.watch(expenseFormControllerProvider(formKey));
    final preview = ref.watch(expensePreviewControllerProvider((gid: formKey.gid, slot: PreviewSlot.split)));
    final mode = form.splitMode;

    final current = preview.isCurrentFor(previewKey) ? preview.preview : null;
    final owedByMember = {for (final s in current?.members ?? const <ShareView>[]) s.memberId: s.owedMinor};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SplitMethodRow(
            mode: mode,
            onChosen: controller.setSplitMode,
          ),
          const SizedBox(height: QesmaSpacing.md),
          if (mode == SplitMode.all || mode == SplitMode.selected) _PreviewStatus(form: form, state: preview, current: current != null, previewKey: previewKey, formKey: formKey),
          if (mode == SplitMode.exact) ...[
            Row(
              children: [
                Expanded(child: Text(l10n.expenseFormExactHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary))),
                const SizedBox(width: QesmaSpacing.sm),
                AppButton(
                  label: l10n.expenseFormSpreadEqually,
                  icon: Icons.balance,
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  loading: view.prefilling,
                  onPressed: form.totalMinor == null || view.prefilling ? null : controller.prefillExact,
                ),
              ],
            ),
            if (view.prefillFailed)
              Padding(
                padding: const EdgeInsets.only(top: QesmaSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: Semantics(liveRegion: true, child: Text(l10n.expenseFormShareFailed, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)))),
                    TextButton(onPressed: controller.prefillExact, child: Text(l10n.commonRetry)),
                  ],
                ),
              ),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          if (mode != SplitMode.itemized)
            for (final member in members)
            Padding(
              padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
              child: _MemberRow(
                member: member,
                mode: mode,
                checked: mode == SplitMode.all || form.selectedIds.contains(member.id),
                owedMinor: owedByMember[member.id],
                previewCurrent: current != null,
                exactText: form.exactTexts[member.id] ?? '',
                onToggle: () => controller.toggleMember(member.id),
                onExactChanged: (text) => controller.setExactText(member.id, text),
              ),
            ),
        ],
      ),
    );
  }
}

/// The split method as one row (the redesign): the title, the chosen method with its one-line explanation, and a
/// chevron; a tap opens a sheet with the four methods. Choosing one closes the sheet.
class SplitMethodRow extends StatelessWidget {
  const SplitMethodRow({super.key, required this.mode, required this.onChosen});

  final SplitMode mode;
  final ValueChanged<SplitMode> onChosen;

  static String labelOf(AppLocalizations l10n, SplitMode mode) => switch (mode) {
        SplitMode.all => l10n.expenseFormSplitAll,
        SplitMode.selected => l10n.expenseFormSplitSelected,
        SplitMode.exact => l10n.expenseSplitExact,
        SplitMode.itemized => l10n.expenseSplitItemized,
      };

  static String subtitleOf(AppLocalizations l10n, SplitMode mode) => switch (mode) {
        SplitMode.all => l10n.expenseFormSplitSubtitleAll,
        SplitMode.selected => l10n.expenseFormSplitSubtitleSelected,
        SplitMode.exact => l10n.expenseFormSplitSubtitleExact,
        SplitMode.itemized => l10n.expenseFormSplitSubtitleItemized,
      };

  static IconData iconOf(SplitMode mode) => switch (mode) {
        SplitMode.all => Icons.groups_outlined,
        SplitMode.selected => Icons.group_outlined,
        SplitMode.exact => Icons.pin_outlined,
        SplitMode.itemized => Icons.receipt_long,
      };

  Future<void> _choose(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppBottomSheet<SplitMode>(
      context,
      title: l10n.expenseFormSplitTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final m in SplitMode.values) _MethodTile(mode: m, selected: m == mode)],
      ),
    );
    if (picked != null && picked != mode) onChosen(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '${l10n.expenseFormSplitTitle}: ${labelOf(l10n, mode)}, ${subtitleOf(l10n, mode)}',
      onTap: () => _choose(context),
      child: ExcludeSemantics(
        child: Material(
          color: context.colors.primaryContainer.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(QesmaRadii.control),
            side: BorderSide(color: context.colors.primary, width: 1.5),
          ),
          child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: () => _choose(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch + 8),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
            child: Row(
              children: [
                Icon(iconOf(mode), color: context.colors.primary),
                const SizedBox(width: QesmaSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.expenseFormSplitTitle, style: theme.textTheme.labelLarge?.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
                      Text(labelOf(l10n, mode), style: theme.textTheme.titleMedium),
                      Text(subtitleOf(l10n, mode), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: QesmaSpacing.sm),
                Icon(Icons.chevron_right, color: context.colors.primary),
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

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.mode, required this.selected});

  final SplitMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${SplitMethodRow.labelOf(l10n, mode)}, ${SplitMethodRow.subtitleOf(l10n, mode)}',
      onTap: () => Navigator.of(context).pop(mode),
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: () => Navigator.of(context).pop(mode),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch + 8),
            child: Row(
              children: [
                Icon(SplitMethodRow.iconOf(mode), color: selected ? context.colors.primary : context.colors.textSecondary),
                const SizedBox(width: QesmaSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(SplitMethodRow.labelOf(l10n, mode), style: theme.textTheme.titleMedium),
                      Text(SplitMethodRow.subtitleOf(l10n, mode), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check, color: context.colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewStatus extends ConsumerWidget {
  const _PreviewStatus({required this.form, required this.state, required this.current, required this.previewKey, required this.formKey});

  final ExpenseFormState form;
  final PreviewState state;
  final bool current;
  final String? previewKey;
  final ExpenseFormKey formKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (form.totalMinor == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
        child: Text(l10n.expenseFormShareNeedAmount, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
      );
    }
    if (current || previewKey == null) return const SizedBox.shrink();
    if (state.status == PreviewStatus.failed && state.key == previewKey) {
      return Padding(
        padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
        child: Row(
          children: [
            Expanded(child: Semantics(liveRegion: true, child: Text(l10n.expenseFormShareFailed, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)))),
            TextButton(
              onPressed: () => ref.read(expensePreviewControllerProvider((gid: formKey.gid, slot: PreviewSlot.split)).notifier).retry(),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Text(l10n.expenseFormShareLoading, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.mode,
    required this.checked,
    required this.owedMinor,
    required this.previewCurrent,
    required this.exactText,
    required this.onToggle,
    required this.onExactChanged,
  });

  final MemberDto member;
  final SplitMode mode;
  final bool checked;
  final int? owedMinor;
  final bool previewCurrent;
  final String exactText;
  final VoidCallback onToggle;
  final ValueChanged<String> onExactChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isExact = mode == SplitMode.exact;
    // The amount box sits under the name when text is large, and always in Exact mode, where a
    // name next to a box would be squeezed ("Moha-med").
    final stacked = isExact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final togglable = mode != SplitMode.all;

    Widget amount;
    if (isExact) {
      amount = checked
          ? AmountBox(text: exactText, semanticLabel: l10n.expenseFormExactAmountLabel(member.displayName), onChanged: onExactChanged, width: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 200 : 160)
          : const SizedBox.shrink();
    } else if (!checked) {
      amount = Text('—', style: theme.textTheme.titleMedium?.copyWith(color: context.colors.textHelper));
    } else if (previewCurrent && owedMinor != null) {
      amount = MoneyText(owedMinor!, size: MoneySize.small);
    } else {
      amount = const SkeletonBlock(width: 72, height: 18);
    }

    final spoken = !checked
        ? l10n.expenseFormMemberUnchecked(member.displayName)
        : (!isExact && previewCurrent && owedMinor != null)
            ? l10n.expenseFormMemberSpoken(member.displayName, moneySpoken(l10n, owedMinor!))
            : member.displayName;

    final top = Row(
      children: [
        if (togglable) ...[
          // In Exact mode the row holds a text box, so the checkbox is its own accessible control.
          isExact
              ? Semantics(
                  label: member.displayName,
                  checked: checked,
                  child: SizedBox(
                    width: kMinTouch,
                    height: kMinTouch,
                    child: Checkbox(value: checked, onChanged: (_) => onToggle()),
                  ),
                )
              : ExcludeSemantics(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(value: checked, onChanged: (_) => onToggle(), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ),
          const SizedBox(width: QesmaSpacing.sm),
        ],
        MemberAvatar(memberId: member.id, name: member.displayName, size: 36),
        const SizedBox(width: QesmaSpacing.sm + 4),
        Expanded(
          child: Wrap(
            spacing: QesmaSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(member.displayName, style: theme.textTheme.titleMedium),
              if (member.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
            ],
          ),
        ),
        if (!stacked) ...[const SizedBox(width: QesmaSpacing.sm), amount],
      ],
    );
    final row = stacked
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [top, const SizedBox(height: QesmaSpacing.sm), Align(alignment: AlignmentDirectional.centerEnd, child: amount)])
        : top;

    final decorated = DecoratedBox(
      decoration: BoxDecoration(color: checked ? context.colors.tint : context.colors.card, borderRadius: BorderRadius.circular(QesmaRadii.control), border: Border.all(color: context.colors.hairline)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouch),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm), child: row),
      ),
    );

    // Exact rows contain a text box, so they cannot be one tappable node; the others are one stop
    // with a check state and a tap action (the whole row toggles).
    if (isExact) {
      return Semantics(container: true, child: InkWell(borderRadius: BorderRadius.circular(QesmaRadii.control), onTap: null, child: decorated));
    }
    if (!togglable) return Semantics(container: true, label: spoken, child: ExcludeSemantics(child: decorated));
    return Semantics(
      container: true,
      checked: checked,
      label: spoken,
      onTap: onToggle,
      child: ExcludeSemantics(
        child: InkWell(borderRadius: BorderRadius.circular(QesmaRadii.control), onTap: onToggle, child: decorated),
      ),
    );
  }
}
