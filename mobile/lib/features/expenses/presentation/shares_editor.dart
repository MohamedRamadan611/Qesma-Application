import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import '../application/shares_field_errors.dart';
import 'expense_ui.dart';
import 'itemized_items_card.dart' show QuantityStepper;
import 'member_picker_sheet.dart';

/// The shares split of the form (SA19): units per person, an optional billing period and, per person, the days they
/// were present. Every amount, unit and presence range shown as a RESULT is the preview's (`ShareView`); the editor
/// shows no day count and does no money or date arithmetic. While the preview is not for the form as it is, the
/// amounts are a skeleton, never old numbers.
class SharesEditor extends ConsumerWidget {
  const SharesEditor({
    super.key,
    required this.formKey,
    required this.form,
    required this.members,
    required this.previewShares,
    required this.errors,
  });

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;

  /// The preview's share per person, only while the preview is the answer for exactly this form (empty otherwise).
  final Map<String, ShareView> previewShares;
  final SharesFieldErrors errors;

  Future<void> _editPeople(BuildContext context, ExpenseFormController controller) async {
    final l10n = AppLocalizations.of(context);
    final pick = await showMemberPicker(
      context,
      title: l10n.sharesPickerTitle,
      members: members,
      selected: {for (final r in form.shares.rows) r.memberId},
    );
    if (pick is PickedEqual) controller.setShareMembers(pick.ids);
  }

  Future<void> _periodSwitched(BuildContext context, ExpenseFormController controller, bool on) async {
    if (!on) {
      controller.clearPeriod();
      return;
    }
    // Turning the period on asks for the dates at once; closing the picker leaves it off (no default range is made up).
    await _pickPeriod(context, controller);
  }

  Future<void> _pickPeriod(BuildContext context, ExpenseFormController controller) async {
    final l10n = AppLocalizations.of(context);
    final draft = form.shares;
    final from = draft.periodFrom, to = draft.periodTo;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: kFirstExpenseDate.toDateTime(),
      lastDate: kLastExpenseDate.toDateTime(),
      initialDateRange: draft.periodOn && from != null && to != null ? DateTimeRange(start: from.toDateTime(), end: to.toDateTime()) : null,
      helpText: l10n.sharesPeriodTitle,
    );
    if (picked != null) controller.setPeriod(picked.start.toDate(), picked.end.toDate());
  }

  Future<void> _pickPresence(BuildContext context, ExpenseFormController controller, ShareRowDraft row) async {
    final l10n = AppLocalizations.of(context);
    final periodFrom = form.shares.periodFrom, periodTo = form.shares.periodTo;
    if (periodFrom == null || periodTo == null) return;
    final from = row.presentFrom, to = row.presentTo;
    final picked = await showDateRangePicker(
      context: context,
      // Bounded to the billing period, so a presence range is always inside it.
      firstDate: periodFrom.toDateTime(),
      lastDate: periodTo.toDateTime(),
      initialDateRange: DateTimeRange(
        start: (from ?? periodFrom).toDateTime(),
        end: (to ?? periodTo).toDateTime(),
      ),
      helpText: l10n.sharesDaysPresent,
    );
    if (picked != null) controller.setPresence(row.memberId, picked.start.toDate(), picked.end.toDate());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final draft = form.shares;
    final previewCurrent = previewShares.isNotEmpty;
    final byId = {for (final m in members) m.id: m};
    final rows = draft.rowsAmong([for (final m in members) m.id]);
    final from = draft.periodFrom, to = draft.periodTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sharesHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        const SizedBox(height: QesmaSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            Text(l10n.sharesPeopleTitle, style: theme.textTheme.titleMedium),
            AppButton(
              label: l10n.sharesEditPeople,
              icon: Icons.group_outlined,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: () => _editPeople(context, controller),
            ),
          ],
        ),
        const SizedBox(height: QesmaSpacing.sm),
        if (rows.isEmpty)
          Semantics(liveRegion: true, child: Text(l10n.sharesNeedPeople, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error)))
        else
          for (final row in rows)
            if (byId[row.memberId] case final member?)
              Padding(
                padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
                child: _ShareRow(
                  member: member,
                  row: row,
                  share: previewShares[row.memberId],
                  previewCurrent: previewCurrent,
                  periodOn: draft.periodOn,
                  error: errors.byMember[row.memberId],
                  onStep: (delta) => controller.stepShareUnits(row.memberId, delta),
                  onPickPresence: () => _pickPresence(context, controller, row),
                  onResetPresence: () => controller.resetPresence(row.memberId),
                ),
              ),
        const SizedBox(height: QesmaSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouch),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.sharesPeriodTitle, style: theme.textTheme.titleMedium),
            subtitle: Text(l10n.sharesPeriodSubtitle, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
            value: draft.periodOn,
            onChanged: (on) => _periodSwitched(context, controller, on),
          ),
        ),
        if (draft.periodOn && from != null && to != null)
          Semantics(
            button: true,
            label: '${l10n.sharesPeriodChange}: ${dateRangeSpoken(context, from, to)}',
            excludeSemantics: true,
            onTap: () => _pickPeriod(context, controller),
            child: _RangeButton(
              icon: Icons.date_range_outlined,
              text: dateRangeText(l10n, from, to),
              onTap: () => _pickPeriod(context, controller),
            ),
          ),
        if (errors.period)
          Padding(
            padding: const EdgeInsets.only(top: QesmaSpacing.xs),
            child: _FieldError(text: l10n.sharesErrPeriod),
          ),
      ],
    );
  }
}

/// A bordered full-width button showing a date range (the period or a person's presence).
class _RangeButton extends StatelessWidget {
  const _RangeButton({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: context.colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QesmaRadii.control), side: BorderSide(color: context.colors.buttonBorder, width: 1.5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
            child: Row(
              children: [
                Icon(icon, color: context.colors.primary),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
                Icon(Icons.edit_outlined, size: 18, color: context.colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The person's days present: "Full period" or the range they picked; a tap opens the range picker.
class _PresenceChip extends StatelessWidget {
  const _PresenceChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.card,
      shape: StadiumBorder(side: BorderSide(color: context.colors.buttonBorder, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_outlined, size: 18, color: context.colors.primary),
                const SizedBox(width: QesmaSpacing.xs + 2),
                Flexible(child: Text(text, style: Theme.of(context).textTheme.labelLarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: context.colors.error),
          const SizedBox(width: QesmaSpacing.xs),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.error))),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.member,
    required this.row,
    required this.share,
    required this.previewCurrent,
    required this.periodOn,
    required this.error,
    required this.onStep,
    required this.onPickPresence,
    required this.onResetPresence,
  });

  final MemberDto member;
  final ShareRowDraft row;
  final ShareView? share;
  final bool previewCurrent;
  final bool periodOn;
  final SharesErrorKind? error;
  final ValueChanged<int> onStep;
  final VoidCallback onPickPresence;
  final VoidCallback onResetPresence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final owed = share?.owedMinor;
    final Widget amount = previewCurrent && owed != null ? MoneyText(owed, size: MoneySize.small) : const SkeletonBlock(width: 72, height: 18);

    final spoken = previewCurrent && owed != null
        ? l10n.sharesRowSpoken(member.displayName, unitsSpoken(l10n, row.units), moneySpoken(l10n, owed))
        : l10n.sharesRowSpokenNoAmount(member.displayName, unitsSpoken(l10n, row.units));

    // What the server took for this person (units and presence range), straight from the preview.
    final seen = share;
    final tookParts = [
      if (previewCurrent && seen != null && seen.shareUnits != null) unitsText(l10n, seen.shareUnits!),
      if (previewCurrent && seen != null && periodOn) ?presenceLineOf(l10n, seen),
    ];

    final header = Row(
      children: [
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

    final presence = periodOn
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Semantics(
                  button: true,
                  label: '${l10n.sharesPresenceFor(member.displayName)}: ${row.hasPresence ? l10n.sharesDaysPresentLine(dateRangeSpoken(context, row.presentFrom!, row.presentTo!)) : l10n.sharesFullPeriod}',
                  excludeSemantics: true,
                  onTap: onPickPresence,
                  child: _PresenceChip(
                    text: row.hasPresence ? dateRangeText(l10n, row.presentFrom!, row.presentTo!) : l10n.sharesFullPeriod,
                    onTap: onPickPresence,
                  ),
                ),
              ),
              if (row.hasPresence)
                IconButton(
                  tooltip: l10n.sharesPresenceReset,
                  icon: const Icon(Icons.restart_alt),
                  onPressed: onResetPresence,
                  constraints: const BoxConstraints(minWidth: kMinTouch, minHeight: kMinTouch),
                ),
            ],
          )
        : null;

    final stepper = QuantityStepper(
      quantity: row.units,
      name: member.displayName,
      min: kMinShareUnits,
      max: kMaxShareUnits,
      label: l10n.sharesStepperLabel,
      decreaseTooltip: l10n.sharesStepperMinus,
      increaseTooltip: l10n.sharesStepperPlus,
      threeDigits: true,
      onStep: onStep,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.tint,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        border: Border.all(color: error == null ? context.colors.hairline : context.colors.error, width: error == null ? 1 : 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(container: true, label: spoken, child: ExcludeSemantics(child: header)),
            if (stacked) ...[const SizedBox(height: QesmaSpacing.xs), Align(alignment: AlignmentDirectional.centerStart, child: amount)],
            const SizedBox(height: QesmaSpacing.sm),
            Wrap(
              spacing: QesmaSpacing.sm,
              runSpacing: QesmaSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [stepper, ?presence],
            ),
            if (tookParts.isNotEmpty) ...[
              const SizedBox(height: QesmaSpacing.xs),
              Text(tookParts.join(' · '), style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
            ],
            if (error != null) ...[
              const SizedBox(height: QesmaSpacing.xs),
              _FieldError(text: error == SharesErrorKind.units ? l10n.sharesErrUnits : l10n.sharesErrPresence),
            ],
          ],
        ),
      ),
    );
  }
}
