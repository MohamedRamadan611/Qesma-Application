import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_view_model.dart';
import 'expense_ui.dart';

/// A white section of the details page with a title, an optional count and a body.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.count, this.icon});

  final String title;
  final String? count;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                ExcludeSemantics(child: Icon(icon, color: QesmaColors.primary)),
                const SizedBox(width: QesmaSpacing.sm),
              ],
              Expanded(child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium))),
              if (count != null) Text(count!, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textHelper)),
            ],
          ),
          const SizedBox(height: QesmaSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Payers: who paid how much, then the payers' own sum. No "matches 100%" tick: whether
/// the payers cover the total is the server's rule, not something this page re-checks.
class PayersBlock extends StatelessWidget {
  const PayersBlock({super.key, required this.expense, required this.nameOf, required this.yourMemberId});

  final ExpenseView expense;
  final String Function(String) nameOf;
  final String? yourMemberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lines = payerLines(expense);
    return SectionCard(
      title: l10n.expensePayersTitle,
      icon: Icons.payments_outlined,
      count: countPhrase(lines.length, one: l10n.expensePayersCountOne, two: l10n.expensePayersCountTwo, few: l10n.expensePayersCount, many: l10n.expensePayersCountMany),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in lines) ...[
            _PersonRow(memberId: p.memberId, name: nameOf(p.memberId), isYou: p.memberId == yourMemberId, amountMinor: p.amountMinor),
            const SizedBox(height: QesmaSpacing.sm),
          ],
          DecoratedBox(
            decoration: BoxDecoration(color: QesmaColors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Text(
                l10n.expensePaidTotal(moneyDisplay(l10n, paidTotalMinor(expense))),
                style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.memberId, required this.name, required this.isYou, required this.amountMinor, this.subline, this.sublineSpoken});

  final String memberId;
  final String name;
  final bool isYou;
  final int amountMinor;
  final String? subline;

  /// The same line with amounts in words, for a screen reader.
  final String? sublineSpoken;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // At large text sizes the amount drops under the name instead of squeezing it.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amount = MoneyText(amountMinor, size: MoneySize.medium);
    return MergeSemantics(
      child: DecoratedBox(
      decoration: BoxDecoration(color: QesmaColors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
      child: Padding(
        padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MemberAvatar(memberId: memberId, name: name, size: 36),
                const SizedBox(width: QesmaSpacing.sm + 4),
                Expanded(
                  child: Wrap(
                    spacing: QesmaSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      if (isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
                    ],
                  ),
                ),
                if (!stacked) ...[const SizedBox(width: QesmaSpacing.sm), amount],
              ],
            ),
            if (stacked) ...[
              const SizedBox(height: QesmaSpacing.xs),
              Align(alignment: AlignmentDirectional.centerStart, child: amount),
            ],
            if (subline != null) ...[
              const SizedBox(height: QesmaSpacing.sm),
              Semantics(
                label: sublineSpoken ?? subline,
                child: ExcludeSemantics(child: Text(subline!, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary))),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

/// Items with their assignees, then the charges block: subtotal, service, tax, adjustment and
/// total, each exactly as the server sent it. A row whose charge the server left out
/// (`service` or `tax` null) or zeroed (`adjustmentMinor` 0) is not drawn.
class ItemsAndChargesBlock extends StatelessWidget {
  const ItemsAndChargesBlock({super.key, required this.expense, required this.nameOf});

  final ExpenseView expense;
  final String Function(String) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = expense.items?.toList() ?? const <ItemView>[];
    final charges = expense.charges;
    return SectionCard(
      title: l10n.expenseItemsTitle,
      icon: Icons.receipt_long_outlined,
      count: countPhrase(items.length, one: l10n.expenseItemsCountOne, two: l10n.expenseItemsCountTwo, few: l10n.expenseItemsCount, many: l10n.expenseItemsCountMany),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items) ...[
            _ItemRow(item: item, nameOf: nameOf),
            const SizedBox(height: QesmaSpacing.sm + 4),
          ],
          if (charges != null) _ChargesBox(charges: charges, totalMinor: expense.totalMinor),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.nameOf});

  final ItemView item;
  final String Function(String) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: QesmaSpacing.xs),
              Semantics(
                label: l10n.expenseAssignedTo(item.assigneeMemberIds.map(nameOf).join(l10n.expenseListSeparator)),
                child: ExcludeSemantics(
                  child: Wrap(
                    spacing: QesmaSpacing.xs,
                    runSpacing: QesmaSpacing.xs,
                    children: [for (final id in item.assigneeMemberIds) AppTag(label: nameOf(id))],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: QesmaSpacing.sm),
        MoneyText(item.amountMinor, size: MoneySize.small),
      ],
    ),
    );
  }
}

class _ChargesBox extends StatelessWidget {
  const _ChargesBox({required this.charges, required this.totalMinor});

  final Charges charges;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final service = charges.service;
    final tax = charges.tax;
    final adjustment = charges.adjustmentMinor;

    Widget row(Widget label, int minor, {bool signed = false}) => Padding(
          padding: const EdgeInsetsDirectional.only(bottom: QesmaSpacing.sm),
          child: Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: QesmaSpacing.sm),
              MoneyText(minor, size: MoneySize.small, signed: signed),
            ],
          ),
        );

    Widget labelWithRate(String text, int bps, {String? caption}) => Wrap(
          spacing: QesmaSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary)),
            AppTag(label: l10n.expensePercent(ltrIsolate(Bps.format(bps)))),
            if (caption != null) Text(caption, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.textHelper)),
          ],
        );

    final taxBase = tax == null
        ? null
        : switch (tax.base_) {
            'SUBTOTAL' => l10n.expenseTaxBaseSubtotal,
            'SUBTOTAL_PLUS_SERVICE' => l10n.expenseTaxBaseSubtotalPlusService,
            _ => null,
          };

    return DecoratedBox(
      decoration: BoxDecoration(color: QesmaColors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
      child: Padding(
        padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(Text(l10n.expenseSubtotal, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary)), charges.subtotalMinor),
            if (service != null) row(labelWithRate(l10n.expenseServiceLabel, service.bps), service.amountMinor, signed: true),
            if (tax != null) row(labelWithRate(l10n.expenseTaxLabel, tax.bps, caption: taxBase), tax.amountMinor, signed: true),
            if (adjustment != 0)
              row(Text(l10n.expenseAdjustmentLabel, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary)), adjustment, signed: true),
            const Divider(height: QesmaSpacing.md),
            Row(
              children: [
                Expanded(child: Text(l10n.expenseBillTotal, style: theme.textTheme.titleMedium)),
                const SizedBox(width: QesmaSpacing.sm),
                MoneyText(totalMinor, size: MoneySize.medium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One row per person with what they owe and, for a restaurant bill, the server's own parts
/// (items, service, tax, adjustment). Used by the details page (saved numbers) and by the bill
/// editor (the preview's numbers). Nothing is added up here; there is no "a + b + c = total" line.
class ShareRows extends StatelessWidget {
  const ShareRows({super.key, required this.shares, required this.nameOf, required this.yourMemberId});

  final List<ShareView> shares;
  final String Function(String) nameOf;
  final String? yourMemberId;

  /// The breakdown line, shown with amounts as digits and said with amounts in words.
  ({String shown, String said})? _subline(AppLocalizations l10n, ShareView share) {
    final parts = breakdownOf(share);
    if (parts.isEmpty) return null;
    String line(String Function(int) m, String Function(int) adj) {
      final texts = [
        if (parts.itemsMinor != null) l10n.expensePartItems(m(parts.itemsMinor!)),
        if (parts.serviceMinor != null) l10n.expensePartService(m(parts.serviceMinor!)),
        if (parts.taxMinor != null) l10n.expensePartTax(m(parts.taxMinor!)),
        if (parts.adjustmentMinor != null) l10n.expensePartAdjustment(adj(parts.adjustmentMinor!)),
      ];
      return texts.join(' + ');
    }

    return (
      shown: line((v) => moneyDisplay(l10n, v), (v) => moneyDisplay(l10n, v, signed: true)),
      said: line((v) => moneySpoken(l10n, v), (v) => moneySpoken(l10n, v)).replaceAll(' + ', l10n.expenseListSeparator),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final share in shares) ...[
          _PersonRow(
            memberId: share.memberId,
            name: nameOf(share.memberId),
            isYou: share.memberId == yourMemberId,
            amountMinor: share.owedMinor,
            subline: _subline(l10n, share)?.shown,
            sublineSpoken: _subline(l10n, share)?.said,
          ),
          const SizedBox(height: QesmaSpacing.sm),
        ],
      ],
    );
  }
}

/// Everyone's share on the details page, straight from `shares[]`.
class BreakdownBlock extends StatelessWidget {
  const BreakdownBlock({super.key, required this.expense, required this.nameOf, required this.yourMemberId});

  final ExpenseView expense;
  final String Function(String) nameOf;
  final String? yourMemberId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shares = expense.shares.toList();
    return SectionCard(
      title: l10n.expenseBreakdownTitle,
      icon: Icons.groups_outlined,
      count: countPhrase(shares.length, one: l10n.expenseBreakdownCountOne, two: l10n.expenseBreakdownCountTwo, few: l10n.expenseBreakdownCount, many: l10n.expenseBreakdownCountMany),
      child: ShareRows(shares: shares, nameOf: nameOf, yourMemberId: yourMemberId),
    );
  }
}
