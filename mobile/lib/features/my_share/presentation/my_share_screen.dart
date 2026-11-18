import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/my_share_provider.dart';
import '../../expenses/data/expense_category.dart';
import 'category_drilldown_sheet.dart';

/// Screen displaying what the user consumed per month and category across all groups,
/// versus what they paid up front (STANDALONE_SPEC 8, Decision A130, A131).
class MyShareScreen extends ConsumerStatefulWidget {
  const MyShareScreen({super.key});

  @override
  ConsumerState<MyShareScreen> createState() => _MyShareScreenState();
}

class _MyShareScreenState extends ConsumerState<MyShareScreen> {
  String? _selectedCurrency;
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(myShareStreamProvider);

    return AppScaffold(
      title: l10n.myShareTitle,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            ErrorState(onRetry: () => ref.invalidate(myShareStreamProvider)),
        data: (result) {
          if (result.sections.isEmpty) {
            return _buildEmptyState(l10n, theme);
          }

          // Currencies are deterministic (EGP first, then alphabetical)
          final sections = result.sections;
          final currentCurrency =
              _selectedCurrency ?? sections.first.currencyCode;
          final section = sections.firstWhere(
            (s) => s.currencyCode == currentCurrency,
            orElse: () => sections.first,
          );

          if (section.months.isEmpty) {
            return _buildEmptyState(l10n, theme);
          }

          // Decide default month: Africa/Cairo decides "this month"
          // Africa/Cairo is UTC+2
          final cairoNow = DateTime.now().toUtc().add(const Duration(hours: 2));
          final cairoMonth =
              '${cairoNow.year}-${cairoNow.month.toString().padLeft(2, '0')}';

          final availableMonths = section.months.map((m) => m.month).toList();
          final currentMonth =
              _selectedMonth != null && availableMonths.contains(_selectedMonth)
              ? _selectedMonth!
              : (availableMonths.contains(cairoMonth)
                    ? cairoMonth
                    : availableMonths.first);

          final monthData = section.months.firstWhere(
            (m) => m.month == currentMonth,
          );

          return ListView(
            padding: const EdgeInsets.all(QesmaSpacing.md),
            children: [
              // Currency switcher if multiple currencies
              if (sections.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: sections.map((s) {
                      final selected = s.currencyCode == section.currencyCode;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: QesmaSpacing.sm,
                        ),
                        child: ChoiceChip(
                          label: Text(s.currencyCode),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCurrency = s.currencyCode;
                              _selectedMonth = null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: QesmaSpacing.md),
              ],

              // Month Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: section.months.map((m) {
                    final isSelected = m.month == currentMonth;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: QesmaSpacing.sm,
                      ),
                      child: ChoiceChip(
                        label: Text(
                          _monthLabel(
                            m.month,
                            Localizations.localeOf(context).toString(),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedMonth = m.month;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: QesmaSpacing.md),

              // Overview Card (Total consumed vs paid up front)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: QesmaSpacing.md,
                      runSpacing: QesmaSpacing.sm,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.myShareConsumed,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              moneyDisplay(l10n, monthData.totalConsumedMinor),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.mySharePaidUpFront,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              moneyDisplay(
                                l10n,
                                monthData.totalPaidUpFrontMinor,
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: QesmaSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: QesmaSpacing.sm),
                    // Difference status: neutral colour, because paying more or less is not good or bad.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: context.colors.textSecondary,
                        ),
                        const SizedBox(width: QesmaSpacing.xs),
                        Expanded(
                          child: Text(
                            monthData.netDiffMinor > 0
                                ? '${l10n.myShareYouPaidMore}: ${moneyDisplay(l10n, monthData.netDiffMinor)}'
                                : (monthData.netDiffMinor < 0
                                      ? '${l10n.myShareYouConsumedMore}: ${moneyDisplay(l10n, -monthData.netDiffMinor)}'
                                      : l10n.myShareBalanced),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: QesmaSpacing.xs),
                    Text(
                      l10n.myShareExplainer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: QesmaSpacing.lg),

              // Category Breakdown Header
              Text(
                l10n.myShareMonthlySpend,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.myShareHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: QesmaSpacing.sm),

              // Category list
              ...monthData.categories.map((catBreakdown) {
                final cat = ExpenseCategory.fromWire(catBreakdown.category);
                final (catBg, catFg) = cat.colors;
                final percentageFactor = catBreakdown.percentageBps / 10000.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
                  child: Semantics(
                    container: true,
                    label: l10n.myShareCategorySemantics(
                      cat.label(l10n),
                      Bps.format(catBreakdown.percentageBps),
                      moneySpoken(l10n, catBreakdown.consumedMinor),
                    ),
                    excludeSemantics: true,
                    button: true,
                    onTap: () => CategoryDrilldownSheet.show(
                      context,
                      breakdown: catBreakdown,
                      currencyCode: section.currencyCode,
                    ),
                    child: AppCard(
                      onTap: () => CategoryDrilldownSheet.show(
                        context,
                        breakdown: catBreakdown,
                        currencyCode: section.currencyCode,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: catBg,
                                  borderRadius: BorderRadius.circular(
                                    QesmaRadii.control,
                                  ),
                                ),
                                child: Icon(cat.icon, color: catFg, size: 20),
                              ),
                              const SizedBox(width: QesmaSpacing.sm),
                              Expanded(
                                child: Text(
                                  cat.label(l10n),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                ltrIsolate(
                                  '${Bps.format(catBreakdown.percentageBps)}%',
                                ),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: QesmaSpacing.xs),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          const SizedBox(height: QesmaSpacing.sm),
                          // Visual bar for LRM percentage
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentageFactor.clamp(0.0, 1.0),
                                  child: Container(height: 8, color: catFg),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: QesmaSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: QesmaSpacing.sm,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${l10n.myShareConsumed}: ${moneyDisplay(l10n, catBreakdown.consumedMinor)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              if (catBreakdown.paidUpFrontMinor > 0)
                                Text(
                                  '${l10n.mySharePaidUpFront}: ${moneyDisplay(l10n, catBreakdown.paidUpFrontMinor)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// "2026-11" -> "نوفمبر 2026" (localised month name and year).
  static String _monthLabel(String ym, String locale) {
    final parts = ym.split('-');
    final year = int.tryParse(parts[0]);
    final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (year == null || month == null) return ltrIsolate(ym);
    return DateFormat.yMMMM(locale).format(DateTime(year, month));
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QesmaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: QesmaSpacing.md),
            Text(
              l10n.myShareEmptyTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QesmaSpacing.sm),
            Text(
              l10n.myShareEmptyBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
