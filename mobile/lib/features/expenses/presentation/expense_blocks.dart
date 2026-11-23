import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_view_model.dart';
import 'expense_ui.dart';
import '../../../core/theme/palette.dart';

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
                ExcludeSemantics(child: Icon(icon, color: context.colors.primary)),
                const SizedBox(width: QesmaSpacing.sm),
              ],
              Expanded(child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium))),
              if (count != null) Text(count!, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
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
            decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Text(
                l10n.expensePaidTotal(moneyDisplay(l10n, paidTotalMinor(expense))),
                style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatefulWidget {
  const _PersonRow({required this.memberId, required this.name, required this.isYou, required this.amountMinor, this.subline, this.sublineSpoken, this.itemsLine, this.expandable = false});

  final String memberId;

  /// "Items: Pizza ×2, Cola": the names of the items this person takes part in (details page only).
  final String? itemsLine;
  final String name;
  final bool isYou;
  final int amountMinor;
  final String? subline;

  /// The same line with amounts in words, for a screen reader.
  final String? sublineSpoken;

  /// The parts are folded under the name and total until tapped (the editor's breakdown, SA16).
  final bool expandable;

  @override
  State<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<_PersonRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // At large text sizes the amount drops under the name instead of squeezing it.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amount = MoneyText(widget.amountMinor, size: MoneySize.medium);
    final canFold = widget.expandable && widget.subline != null;
    final showSubline = widget.subline != null && (!widget.expandable || _expanded);

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MemberAvatar(memberId: widget.memberId, name: widget.name, size: 36),
            const SizedBox(width: QesmaSpacing.sm + 4),
            Expanded(
              child: Wrap(
                spacing: QesmaSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(widget.name, style: theme.textTheme.titleMedium),
                  if (widget.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
                ],
              ),
            ),
            if (!stacked) ...[const SizedBox(width: QesmaSpacing.sm), amount],
            if (canFold) Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        if (stacked) ...[
          const SizedBox(height: QesmaSpacing.xs),
          Align(alignment: AlignmentDirectional.centerStart, child: amount),
        ],
      ],
    );

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canFold)
                Semantics(
                  button: true,
                  expanded: _expanded,
                  onTapHint: _expanded ? l10n.expenseItzCollapsePerson(widget.name) : l10n.expenseItzExpandPerson(widget.name),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(QesmaRadii.control),
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: ConstrainedBox(constraints: const BoxConstraints(minHeight: kMinTouch), child: header),
                  ),
                )
              else
                header,
              // Main line: "100 EGP items + 15 service"; the item names follow as a description.
              if (showSubline) ...[
                const SizedBox(height: QesmaSpacing.sm),
                Semantics(
                  label: widget.sublineSpoken ?? widget.subline,
                  child: ExcludeSemantics(child: Text(widget.subline!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                ),
              ],
              if (widget.itemsLine != null) ...[
                const SizedBox(height: QesmaSpacing.xs),
                Text(widget.itemsLine!, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Items with their assignees, then the charges block: subtotal, service, tax, delivery, adjustment and
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

class _ItemRow extends StatefulWidget {
  const _ItemRow({required this.item, required this.nameOf});

  final ItemView item;
  final String Function(String) nameOf;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  static const int _shownNames = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final item = widget.item;
    final names = [for (final id in item.assigneeMemberIds) widget.nameOf(id)];
    final folds = names.length > _shownNames;
    final shown = folds && !_expanded ? names.take(_shownNames).toList() : names;
    final extra = names.length - _shownNames;
    // Quantity and unit price exactly as saved; the amount on the right is the server's line total.
    final qtyLine = item.quantity > 1 ? l10n.expenseItzLineTimes(ltrIsolate('${item.quantity}'), moneyDisplay(l10n, item.unitAmountMinor)) : null;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium),
                if (qtyLine != null) Text(qtyLine, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: QesmaSpacing.xs),
                Semantics(
                  label: l10n.expenseAssignedTo(names.join(l10n.expenseListSeparator)),
                  child: ExcludeSemantics(
                    child: Wrap(
                      spacing: QesmaSpacing.xs,
                      runSpacing: QesmaSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final name in shown) AppTag(label: name),
                        if (folds)
                          TextButton(
                            style: TextButton.styleFrom(minimumSize: const Size(kMinTouch, kMinTouch)),
                            onPressed: () => setState(() => _expanded = !_expanded),
                            child: Text(_expanded ? l10n.expenseItzAssigneesCollapseSpoken : l10n.expenseItzSummaryMore('$extra')),
                          ),
                      ],
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
    final discount = charges.discount;
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

    // BSA2: bps is null when the charge was given as an amount; then there is no rate to show.
    Widget labelWithRate(String text, int? bps, {String? caption}) => Wrap(
          spacing: QesmaSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
            if (bps != null) AppTag(label: l10n.expensePercent(ltrIsolate(Bps.format(bps)))),
            if (caption != null) Text(caption, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
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
      decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
      child: Padding(
        padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row(Text(l10n.expenseSubtotal, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)), charges.subtotalMinor),
            if (discount != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: QesmaSpacing.sm),
                child: Row(
                  children: [
                    Expanded(child: labelWithRate(l10n.expenseItzDetailsDiscount, discount.bps)),
                    const SizedBox(width: QesmaSpacing.sm),
                    Text('${Money.minus}${moneyDisplay(l10n, discount.amountMinor)}', style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
            if (service != null) row(labelWithRate(l10n.expenseServiceLabel, service.bps), service.amountMinor, signed: true),
            if (tax != null) row(labelWithRate(l10n.expenseTaxLabel, tax.bps, caption: taxBase), tax.amountMinor, signed: true),
            if (charges.deliveryMinor != 0)
              row(Text(l10n.expenseItzDeliveryLabel, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)), charges.deliveryMinor, signed: true),
            if (adjustment != 0)
              row(Text(l10n.expenseAdjustmentLabel, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)), adjustment, signed: true),
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
  const ShareRows({super.key, required this.shares, required this.nameOf, required this.yourMemberId, this.items, this.expandable = false});

  final List<ShareView> shares;

  /// The bill's items; when given, each person's row lists the names of the items they take part in.
  final List<ItemView>? items;
  final String Function(String) nameOf;
  final String? yourMemberId;

  /// The editor's breakdown: the parts of each person's share are folded under their name and total until tapped.
  final bool expandable;

  /// The breakdown line, shown with amounts as digits and said with amounts in words.
  ({String shown, String said})? _subline(AppLocalizations l10n, ShareView share) {
    final parts = breakdownOf(share);
    if (parts.isEmpty) return null;
    String line(String Function(int) m, String Function(int) adj) {
      final texts = [
        if (parts.itemsMinor != null) l10n.expensePartItems(m(parts.itemsMinor!)),
        if (parts.discountMinor != null) l10n.expenseItzPartDiscount('${Money.minus}${m(parts.discountMinor!)}'),
        if (parts.serviceMinor != null) l10n.expensePartService(m(parts.serviceMinor!)),
        if (parts.taxMinor != null) l10n.expensePartTax(m(parts.taxMinor!)),
        if (parts.deliveryMinor != null) l10n.expensePartDelivery(m(parts.deliveryMinor!)),
        if (parts.adjustmentMinor != null) l10n.expensePartAdjustment(adj(parts.adjustmentMinor!)),
      ];
      return texts.join(' + ');
    }

    return (
      shown: line((v) => moneyDisplay(l10n, v), (v) => moneyDisplay(l10n, v, signed: true)),
      said: line((v) => moneySpoken(l10n, v), (v) => moneySpoken(l10n, v)).replaceAll(' + ', l10n.expenseListSeparator),
    );
  }

  String? _itemsLine(AppLocalizations l10n, String memberId) {
    final mine = [
      for (final item in items ?? const <ItemView>[])
        if (item.assigneeMemberIds.contains(memberId)) item.quantity > 1 ? '${item.name} ×${item.quantity}' : item.name,
    ];
    if (mine.isEmpty) return null;
    return l10n.expensePersonItemsList(mine.join(l10n.expenseListSeparator));
  }

  /// SA19: "2 shares · Days present: 2026-11-12 – 2026-11-30", exactly what the server stored for a shares split.
  String? _sharesLine(AppLocalizations l10n, ShareView share) {
    final units = share.shareUnits;
    if (units == null) return null;
    return [unitsText(l10n, units), ?presenceLineOf(l10n, share)].join(' · ');
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
            itemsLine: _itemsLine(l10n, share.memberId) ?? _sharesLine(l10n, share),
            expandable: expandable,
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
      child: ShareRows(shares: shares, nameOf: nameOf, yourMemberId: yourMemberId, items: expense.items?.toList()),
    );
  }
}
