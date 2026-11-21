import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import 'status_banner.dart';

/// Discount, delivery, service and tax rows (each a switch, a `% | EGP` toggle (not for delivery, an amount only), a
/// value box and the preview's amount), the tax base when both service and tax are on, and the adjustment with the
/// automatic-adjustment note (SA16, A171-A174, A180).
class ChargesCard extends ConsumerWidget {
  const ChargesCard({super.key, required this.formKey, required this.form, required this.current, this.discountTooLarge = false});

  final ExpenseFormKey formKey;
  final ExpenseFormState form;
  final ExpensePreview? current;

  /// The server refused a bill whose inputs are all readable while a discount is on: the discount is the usual cause
  /// (it must stay below the items total). Said without numbers, because the client never adds up the items.
  final bool discountTooLarge;

  /// The server's delivery part per person as a hint: one amount, or "from - to" when the parts differ by a piaster.
  String? _deliveryHint(AppLocalizations l10n) {
    final parts = [for (final m in current?.members ?? const <ShareView>[]) if ((m.deliveryMinor ?? 0) > 0) m.deliveryMinor!];
    if (parts.isEmpty) return null;
    parts.sort();
    return parts.first == parts.last
        ? l10n.expenseItzDeliveryHint(moneyDisplay(l10n, parts.first))
        : l10n.expenseItzDeliveryHintRange(moneyDisplay(l10n, parts.first), moneyDisplay(l10n, parts.last));
  }

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
          Semantics(header: true, child: Text(l10n.expenseItzChargesTitle, style: theme.textTheme.titleMedium)),
          const SizedBox(height: QesmaSpacing.md),
          ChargeRow(
            title: l10n.expenseItzDiscountLabel,
            icon: Icons.sell_outlined,
            on: d.discountOn,
            mode: d.discountMode,
            text: d.discountMode == ChargeMode.percent ? d.discountPercentText : d.discountAmountText,
            valid: d.discountValid,
            errorText: d.discountMode == ChargeMode.percent ? l10n.expenseItzDiscountPercentInvalid : l10n.expenseItzDiscountNeedsAmount,
            amountMinor: current?.discountMinor,
            serverError: discountTooLarge && d.discountOn && d.discountValid ? l10n.expenseItzDiscountTooLarge : null,
            negative: true,
            onToggle: controller.setDiscountOn,
            onMode: (mode) => controller.setChargeMode(ChargeKind.discount, mode),
            onText: (text) => controller.setChargeText(ChargeKind.discount, text),
          ),
          const Divider(height: QesmaSpacing.lg),
          ChargeRow(
            title: l10n.expenseServiceLabel,
            icon: Icons.room_service_outlined,
            on: d.serviceOn,
            mode: d.serviceMode,
            text: d.serviceMode == ChargeMode.percent ? d.servicePercentText : d.serviceAmountText,
            valid: d.serviceValid,
            errorText: d.serviceMode == ChargeMode.percent ? l10n.expenseItemizedPercentInvalid : l10n.expenseItzChargeAmountInvalid,
            amountMinor: current?.serviceMinor,
            onToggle: controller.setServiceOn,
            onMode: (mode) => controller.setChargeMode(ChargeKind.service, mode),
            onText: (text) => controller.setChargeText(ChargeKind.service, text),
          ),
          const Divider(height: QesmaSpacing.lg),
          ChargeRow(
            title: l10n.expenseItzDeliveryLabel,
            icon: Icons.delivery_dining_outlined,
            on: d.deliveryOn,
            mode: ChargeMode.amount,
            amountOnly: true,
            text: d.deliveryAmountText,
            valid: d.deliveryValid,
            errorText: l10n.expenseItzChargeAmountInvalid,
            amountMinor: current?.deliveryMinor,
            hint: _deliveryHint(l10n),
            onToggle: controller.setDeliveryOn,
            onMode: (_) {},
            onText: controller.setDeliveryAmount,
          ),
          const Divider(height: QesmaSpacing.lg),
          ChargeRow(
            title: l10n.expenseTaxLabel,
            icon: Icons.percent,
            on: d.taxOn,
            mode: d.taxMode,
            text: d.taxMode == ChargeMode.percent ? d.taxPercentText : d.taxAmountText,
            valid: d.taxValid,
            errorText: d.taxMode == ChargeMode.percent ? l10n.expenseItemizedPercentInvalid : l10n.expenseItzChargeAmountInvalid,
            amountMinor: current?.taxMinor,
            onToggle: controller.setTaxOn,
            onMode: (mode) => controller.setChargeMode(ChargeKind.tax, mode),
            onText: (text) => controller.setChargeText(ChargeKind.tax, text),
          ),
          // The base only matters when there is a service charge for the tax to be applied on top of.
          if (d.taxOn && d.serviceOn) ...[
            const SizedBox(height: QesmaSpacing.sm + 4),
            Text(l10n.expenseItemizedTaxBaseTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: QesmaSpacing.xs),
            Wrap(
              spacing: QesmaSpacing.sm,
              runSpacing: QesmaSpacing.xs,
              children: [
                AppChoiceChip(label: l10n.expenseItemizedTaxBaseSubtotal, selected: d.taxBase == TaxBase.subtotal, onSelected: (_) => controller.setTaxBase(TaxBase.subtotal)),
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
          if (d.adjustmentAuto && form.autoAdjustedPiasters != null) ...[
            const SizedBox(height: QesmaSpacing.sm),
            StatusBanner(icon: Icons.auto_fix_high, text: l10n.expenseItzAutoAdjusted(ltrIsolate('${form.autoAdjustedPiasters}')), tone: BannerTone.neutral),
          ],
        ],
      ),
    );
  }
}

/// One charge: the switch row, then (when on) the `% | EGP` toggle, the value box and the server's amount.
class ChargeRow extends StatelessWidget {
  const ChargeRow({
    super.key,
    required this.title,
    required this.icon,
    required this.on,
    required this.mode,
    required this.text,
    required this.valid,
    required this.errorText,
    required this.amountMinor,
    required this.onToggle,
    required this.onMode,
    required this.onText,
    this.negative = false,
    this.amountOnly = false,
    this.hint,
    this.serverError,
  });

  final String title;
  final IconData icon;
  final bool on;
  final ChargeMode mode;
  final String text;
  final bool valid;
  final String errorText;

  /// The server's amount for this charge (null until the preview for the current bill arrives).
  final int? amountMinor;

  /// A discount is shown with a minus sign in front of the server's (positive) amount.
  final bool negative;

  /// The delivery row: no `% | EGP` toggle, the box is always an amount (A180).
  final bool amountOnly;

  /// A helper line under the value box (the delivery's per-person part, from the preview).
  final String? hint;

  /// An error the server's answer implies for this row (shown with an icon and words, like the typed-value error).
  final String? serverError;
  final ValueChanged<bool> onToggle;
  final ValueChanged<ChargeMode> onMode;
  final ValueChanged<String> onText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final box = AmountBox(
      text: text,
      hint: mode == ChargeMode.percent ? l10n.expenseItemizedPercentHint : l10n.expenseItzAmountHint,
      semanticLabel: '$title: ${mode == ChargeMode.percent ? l10n.expenseItemizedPercentLabel : l10n.expenseItzAmountLabel}',
      onChanged: onText,
      hasError: on && !valid,
      width: stacked ? 200 : 120,
    );
    final toggle = amountOnly ? null : _ModeToggle(title: title, mode: mode, onMode: onMode);
    final amount = on && valid && amountMinor != null
        ? (negative ? Text('${Money.minus}${moneyDisplay(l10n, amountMinor!)}', style: theme.textTheme.titleSmall) : MoneyText(amountMinor!, size: MoneySize.small, signed: true))
        : null;

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
                  ExcludeSemantics(child: Icon(icon, color: context.colors.primary)),
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
            if (toggle != null) ...[Align(alignment: AlignmentDirectional.centerStart, child: toggle), const SizedBox(height: QesmaSpacing.sm)],
            box,
            if (amount != null) Padding(padding: const EdgeInsets.only(top: QesmaSpacing.sm), child: Align(alignment: AlignmentDirectional.centerEnd, child: amount)),
          ] else
            // A wrap: on a narrow screen the server's amount drops under the toggle and the box instead of overflowing.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: QesmaSpacing.sm,
              runSpacing: QesmaSpacing.sm,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [?toggle, if (toggle != null) const SizedBox(width: QesmaSpacing.sm), box]),
                ?amount,
              ],
            ),
          if (hint != null && valid)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.xs),
              child: Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
            ),
          if (serverError != null && valid)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.xs),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                    const SizedBox(width: QesmaSpacing.xs),
                    Expanded(child: Text(serverError!, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
                  ],
                ),
              ),
            ),
          if (!valid)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.xs),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                    const SizedBox(width: QesmaSpacing.xs),
                    Expanded(child: Text(errorText, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// `% | EGP`.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.title, required this.mode, required this.onMode});

  final String title;
  final ChargeMode mode;
  final ValueChanged<ChargeMode> onMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.expenseItzModeSpoken(title),
      child: SegmentedButton<ChargeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ChargeMode.percent, label: Text(l10n.expenseItzModePercent, semanticsLabel: l10n.expenseItzModePercentSpoken)),
          ButtonSegment(value: ChargeMode.amount, label: Text(l10n.expenseItzModeAmount, semanticsLabel: l10n.expenseItzModeAmountSpoken)),
        ],
        selected: {mode},
        onSelectionChanged: (value) => onMode(value.first),
        style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, kMinTouch)), padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12))),
      ),
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
        Text(l10n.expenseItemizedAdjustmentHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
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
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(Icons.error_outline, color: context.colors.error, size: 18)),
                  const SizedBox(width: QesmaSpacing.xs),
                  Expanded(child: Text(l10n.expenseItemizedAdjustmentInvalid, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
