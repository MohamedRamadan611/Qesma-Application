import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_command_builder.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import '../application/expense_preview_controller.dart';
import 'expense_blocks.dart';
import 'expense_ui.dart';
import 'status_banner.dart';

/// The restaurant-bill editor (P8-01), shown inside the add/edit form when the "Restaurant bill"
/// tab is selected: items with assignees, service and tax (each its own switch, rate and amount),
/// the tax base, a signed adjustment, then the per-person breakdown and the payers banner.
///
/// Every amount drawn here that the user did not type (subtotal, service, tax, per-person parts,
/// total, "payers match") is the server's, from the preview, and only while that preview is the
/// answer for the bill as it is now. Nothing is calculated here and nothing is added up.
class ItemizedEditor extends ConsumerWidget {
  const ItemizedEditor({super.key, required this.formKey, required this.form, required this.members, required this.nameOf});

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;
  final String Function(String) nameOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final memberIds = controller.memberIds;
    final splitCommand = buildItemizedPreview(form, memberIds: memberIds);
    final splitKey = splitCommand == null ? null : commandKey(splitCommand);
    final preview = ref.watch(expensePreviewControllerProvider((gid: formKey.gid, slot: PreviewSlot.split)));
    final current = preview.isCurrentFor(splitKey) ? preview.preview : null;

    final matchCommand = buildItemizedPreview(form, memberIds: memberIds, withPayers: true);
    final matchKey = matchCommand == null ? null : commandKey(matchCommand);
    final match = ref.watch(expensePreviewControllerProvider((gid: formKey.gid, slot: PreviewSlot.match)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ItemsCard(formKey: formKey, form: form, members: members, subtotalMinor: current?.subtotalMinor),
        const SizedBox(height: QesmaSpacing.md),
        _ChargesCard(formKey: formKey, form: form, current: current),
        const SizedBox(height: QesmaSpacing.md),
        _BreakdownCard(
          formKey: formKey,
          form: form,
          preview: preview,
          splitKey: splitKey,
          current: current,
          match: match,
          matchKey: matchKey,
          nameOf: nameOf,
          yourMemberId: members.where((m) => m.isYou).firstOrNull?.id,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------------------------

class _ItemsCard extends ConsumerWidget {
  const _ItemsCard({required this.formKey, required this.form, required this.members, required this.subtotalMinor});

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final List<MemberDto> members;
  final int? subtotalMinor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final items = form.itemized.items;
    final atLimit = items.length >= kMaxItems;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: const Icon(Icons.receipt_long_outlined, color: QesmaColors.primary)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(child: Semantics(header: true, child: Text(l10n.expenseItemizedItemsTitle, style: theme.textTheme.titleMedium))),
              Text(
                countPhrase(items.length, one: l10n.expenseItemsCountOne, two: l10n.expenseItemsCountTwo, few: l10n.expenseItemsCount, many: l10n.expenseItemsCountMany),
                style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textHelper),
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.md),
          for (var i = 0; i < items.length; i++) ...[
            _ItemCard(
              key: ValueKey(items[i].id),
              index: i + 1,
              item: items[i],
              members: members,
              onName: (v) => controller.setItemName(items[i].id, v),
              onAmount: (v) => controller.setItemAmount(items[i].id, v),
              onToggle: (memberId) => controller.toggleAssignee(items[i].id, memberId),
              onRemove: () => controller.removeItem(items[i].id),
            ),
            const SizedBox(height: QesmaSpacing.sm + 4),
          ],
          AppButton(
            label: l10n.expenseItemizedAdd,
            icon: Icons.add_circle_outline,
            variant: AppButtonVariant.secondary,
            onPressed: atLimit ? null : controller.addItem,
          ),
          if (atLimit)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.sm),
              child: Semantics(liveRegion: true, child: Text(l10n.expenseItemizedLimit, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary))),
            ),
          if (subtotalMinor != null) ...[
            const SizedBox(height: QesmaSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(color: QesmaColors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
              child: Padding(
                padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.expenseSubtotal, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary))),
                    MoneyText(subtotalMinor!, size: MoneySize.medium),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One item: name, price, who shared it. The two fields keep their own controllers (the user is
/// the only one who changes their text while the card is on screen).
class _ItemCard extends StatefulWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.members,
    required this.onName,
    required this.onAmount,
    required this.onToggle,
    required this.onRemove,
  });

  final int index;
  final ItemDraft item;
  final List<MemberDto> members;
  final ValueChanged<String> onName;
  final ValueChanged<String> onAmount;
  final ValueChanged<String> onToggle;
  final VoidCallback onRemove;

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _name = TextEditingController(text: widget.item.name);
  late final TextEditingController _amount = TextEditingController(text: widget.item.amountText);

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final item = widget.item;
    final memberIds = [for (final m in widget.members) m.id];
    final shown = item.touched;
    final noAssignee = item.assigneesAmong(memberIds).isEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: QesmaColors.tint,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        border: Border.all(color: QesmaColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Semantics(header: true, child: Text(l10n.expenseItemizedItemHeading('${widget.index}'), style: theme.textTheme.titleSmall))),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.expenseItemizedRemoveSpoken('${widget.index}'),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            AppTextField(
              controller: _name,
              label: l10n.expenseItemizedNameLabel,
              hint: l10n.expenseItemizedNameHint,
              maxLength: kItemNameMax,
              showClear: false,
              errorText: shown && !item.nameValid ? l10n.expenseItemizedNameRequired : null,
              textInputAction: TextInputAction.next,
              onChanged: widget.onName,
            ),
            const SizedBox(height: QesmaSpacing.sm + 4),
            AppTextField(
              controller: _amount,
              label: l10n.expenseItemizedAmountLabel,
              hint: l10n.expenseFormAmountHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [amountInputFormatter],
              showClear: false,
              errorText: shown && item.amountMinor == null ? l10n.expenseItemizedAmountInvalid : null,
              onChanged: widget.onAmount,
            ),
            const SizedBox(height: QesmaSpacing.sm + 4),
            Text(l10n.expenseItemizedAssigneesLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: QesmaSpacing.xs),
            Wrap(
              spacing: QesmaSpacing.sm,
              runSpacing: QesmaSpacing.xs,
              children: [
                for (final member in widget.members)
                  AppChoiceChip(
                    label: member.displayName,
                    selected: item.assigneeIds.contains(member.id),
                    onSelected: (_) => widget.onToggle(member.id),
                  ),
              ],
            ),
            if (shown && noAssignee)
              Padding(
                padding: const EdgeInsets.only(top: QesmaSpacing.xs),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      const ExcludeSemantics(child: Icon(Icons.error_outline, color: QesmaColors.error, size: 18)),
                      const SizedBox(width: QesmaSpacing.xs),
                      Expanded(child: Text(l10n.expenseItemizedNoAssignee, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.error))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Service, tax, adjustment
// ---------------------------------------------------------------------------------------------

class _ChargesCard extends ConsumerWidget {
  const _ChargesCard({required this.formKey, required this.form, required this.current});

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final ExpensePreview? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(expenseFormControllerProvider(formKey).notifier);
    final d = form.itemized;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.expenseItemizedChargesTitle, style: theme.textTheme.titleMedium)),
          const SizedBox(height: QesmaSpacing.md),
          _ChargeRow(
            title: l10n.expenseServiceLabel,
            icon: Icons.room_service_outlined,
            on: d.serviceOn,
            percentText: d.servicePercentText,
            valid: d.serviceValid,
            amountMinor: current?.serviceMinor,
            onToggle: controller.setServiceOn,
            onPercent: controller.setServicePercent,
          ),
          const Divider(height: QesmaSpacing.lg),
          _ChargeRow(
            title: l10n.expenseTaxLabel,
            icon: Icons.percent,
            on: d.taxOn,
            percentText: d.taxPercentText,
            valid: d.taxValid,
            amountMinor: current?.taxMinor,
            onToggle: controller.setTaxOn,
            onPercent: controller.setTaxPercent,
          ),
          if (d.taxOn) ...[
            const SizedBox(height: QesmaSpacing.sm + 4),
            Text(l10n.expenseItemizedTaxBaseTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: QesmaSpacing.xs),
            Wrap(
              spacing: QesmaSpacing.sm,
              runSpacing: QesmaSpacing.xs,
              children: [
                AppChoiceChip(
                  label: l10n.expenseItemizedTaxBaseSubtotal,
                  selected: d.taxBase == TaxBase.subtotal,
                  onSelected: (_) => controller.setTaxBase(TaxBase.subtotal),
                ),
                AppChoiceChip(
                  label: l10n.expenseItemizedTaxBaseWithService,
                  selected: d.taxBase == TaxBase.subtotalPlusService,
                  onSelected: (_) => controller.setTaxBase(TaxBase.subtotalPlusService),
                ),
              ],
            ),
          ],
          const Divider(height: QesmaSpacing.lg),
          _AdjustmentRow(form: form, controller: controller),
        ],
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({
    required this.title,
    required this.icon,
    required this.on,
    required this.percentText,
    required this.valid,
    required this.amountMinor,
    required this.onToggle,
    required this.onPercent,
  });

  final String title;
  final IconData icon;
  final bool on;
  final String percentText;
  final bool valid;

  /// The server's amount for this charge (null until the preview for the current bill arrives).
  final int? amountMinor;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final percentBox = AmountBox(
      text: percentText,
      hint: l10n.expenseItemizedPercentHint,
      semanticLabel: '$title: ${l10n.expenseItemizedPercentLabel}',
      onChanged: onPercent,
      hasError: on && !valid,
      width: stacked ? 200 : 120,
    );
    final amount = valid && amountMinor != null ? MoneyText(amountMinor!, size: MoneySize.small, signed: true) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(QesmaRadii.control),
            onTap: () => onToggle(!on),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTouch),
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(icon, color: QesmaColors.primary)),
                  const SizedBox(width: QesmaSpacing.sm),
                  Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
                  Switch(value: on, onChanged: onToggle),
                ],
              ),
            ),
          ),
        ),
        if (on) ...[
          const SizedBox(height: QesmaSpacing.sm),
          if (stacked) ...[
            Row(children: [Text(l10n.expenseItemizedPercentLabel, style: theme.textTheme.labelLarge)]),
            const SizedBox(height: QesmaSpacing.xs),
            percentBox,
            if (amount != null) Padding(padding: const EdgeInsets.only(top: QesmaSpacing.sm), child: Align(alignment: AlignmentDirectional.centerEnd, child: amount)),
          ] else
            Row(
              children: [
                Text(l10n.expenseItemizedPercentLabel, style: theme.textTheme.labelLarge),
                const SizedBox(width: QesmaSpacing.sm),
                percentBox,
                const Spacer(),
                ?amount,
              ],
            ),
          if (!valid)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.xs),
              child: Semantics(liveRegion: true, child: Text(l10n.expenseItemizedPercentInvalid, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.error))),
            ),
        ],
      ],
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({required this.form, required this.controller});

  final ExpenseFormState form;
  final ExpenseFormController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = form.itemized;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.expenseItemizedAdjustmentTitle, style: theme.textTheme.titleMedium)),
        Text(l10n.expenseItemizedAdjustmentHint, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary)),
        const SizedBox(height: QesmaSpacing.sm),
        Row(
          children: [
            IconButton.outlined(
              icon: const Icon(Icons.remove),
              tooltip: l10n.expenseItemizedAdjustmentMinus,
              onPressed: d.adjustmentValid ? () => controller.stepAdjustment(-1) : null,
            ),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(
              child: AmountBox(
                text: d.adjustmentText,
                semanticLabel: l10n.expenseItemizedAdjustmentTitle,
                signed: true,
                expand: true,
                hasError: !d.adjustmentValid,
                onChanged: controller.setAdjustment,
              ),
            ),
            const SizedBox(width: QesmaSpacing.sm),
            IconButton.outlined(
              icon: const Icon(Icons.add),
              tooltip: l10n.expenseItemizedAdjustmentPlus,
              onPressed: d.adjustmentValid ? () => controller.stepAdjustment(1) : null,
            ),
          ],
        ),
        if (!d.adjustmentValid)
          Padding(
            padding: const EdgeInsets.only(top: QesmaSpacing.xs),
            child: Semantics(liveRegion: true, child: Text(l10n.expenseItemizedAdjustmentInvalid, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.error))),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Per-person breakdown, total and the payers banner
// ---------------------------------------------------------------------------------------------

class _BreakdownCard extends ConsumerWidget {
  const _BreakdownCard({
    required this.formKey,
    required this.form,
    required this.preview,
    required this.splitKey,
    required this.current,
    required this.match,
    required this.matchKey,
    required this.nameOf,
    required this.yourMemberId,
  });

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final PreviewState preview;
  final String? splitKey;
  final ExpensePreview? current;
  final PreviewState match;
  final String? matchKey;
  final String Function(String) nameOf;
  final String? yourMemberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget body;
    if (splitKey == null) {
      body = Text(l10n.expenseItemizedIncomplete, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary));
    } else if (current != null) {
      final shares = current!.members.toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareRows(shares: shares, nameOf: nameOf, yourMemberId: yourMemberId),
          DecoratedBox(
            decoration: BoxDecoration(color: QesmaColors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Row(
                children: [
                  Expanded(child: Text(l10n.expenseBillTotal, style: theme.textTheme.titleMedium)),
                  MoneyText(current!.totalMinor, size: MoneySize.medium),
                ],
              ),
            ),
          ),
          if (matchKey != null) ...[const SizedBox(height: QesmaSpacing.sm), _MatchBanner(state: match, key_: matchKey!)],
        ],
      );
    } else if (preview.status == PreviewStatus.failed && preview.key == splitKey) {
      body = Row(
        children: [
          Expanded(child: Semantics(liveRegion: true, child: Text(l10n.expenseItemizedFailed, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.error)))),
          TextButton(
            onPressed: () => ref.read(expensePreviewControllerProvider((gid: formKey.gid, slot: PreviewSlot.split)).notifier).retry(),
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    } else {
      body = Semantics(
        liveRegion: true,
        child: Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(child: Text(l10n.expenseItemizedLoading, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary))),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.expenseBreakdownTitle, style: theme.textTheme.titleMedium)),
          const SizedBox(height: QesmaSpacing.md),
          body,
        ],
      ),
    );
  }
}

/// "The payers match the bill", from the server's `payersTotalMatches` for the payers as they are now.
class _MatchBanner extends StatelessWidget {
  const _MatchBanner({required this.state, required this.key_});

  final PreviewState state;
  final String key_;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!state.isCurrentFor(key_)) {
      return StatusBanner(icon: Icons.hourglass_empty, text: l10n.expenseItemizedPayersChecking, tone: BannerTone.neutral);
    }
    return state.preview!.payersTotalMatches
        ? StatusBanner(icon: Icons.check_circle_outline, text: l10n.expenseItemizedPayersMatch, tone: BannerTone.success)
        : StatusBanner(icon: Icons.error_outline, text: l10n.expenseItemizedPayersMismatch, tone: BannerTone.error);
  }
}
