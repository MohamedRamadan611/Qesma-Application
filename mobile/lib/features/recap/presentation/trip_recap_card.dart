import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/category_colors.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/money_text.dart';
import '../../../local/insights/trip_recap_repository.dart';
import '../../expenses/data/expense_category.dart';

/// Fixed-size portrait recap card (360x450 dp, renders at 3x to 1080x1350 px).
/// Fixed text scaling ensures that user font adjustments do not break the exported share image.
class TripRecapCard extends StatelessWidget {
  const TripRecapCard({
    super.key,
    required this.groupName,
    required this.recap,
  });

  final String groupName;
  final TripRecapResult recap;

  static const cardWidth = 360.0;
  static const cardHeight = 450.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    // Non-zero categories sorted by total descending
    final activeCategories = recap.categoryBreakdown
        .where((c) => c.totalMinor > 0)
        .toList()
      ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.all(QesmaSpacing.md),
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: BorderRadius.circular(QesmaRadii.card),
          border: Border.all(color: colors.hairline),
          boxShadow: QesmaShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header: Branding + Date range
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pie_chart_outline,
                    size: 16,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: QesmaSpacing.xs + 2),
                Expanded(
                  child: Text(
                    l10n.recapWatermark,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: QesmaSpacing.sm),
                Text(
                  '${recap.dateRangeStart} – ${recap.dateRangeEnd}',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: QesmaSpacing.xs),
            Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: QesmaSpacing.sm),

            // 2. Hero Card: Total Spent + Count
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: QesmaSpacing.md,
                vertical: QesmaSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(QesmaRadii.control),
                border: Border.all(color: colors.hairline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.recapTotalSpent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          moneyDisplay(l10n, recap.totalSpentMinor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: QesmaSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: QesmaSpacing.sm + 2,
                      vertical: QesmaSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(QesmaRadii.pill),
                    ),
                    child: Text(
                      l10n.recapExpensesCount(recap.expenseCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: QesmaSpacing.sm),

            // 3. Highlights Row: Top Payer & Biggest Expense
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(QesmaSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(QesmaRadii.control),
                      border: Border.all(color: colors.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.military_tech_outlined,
                              size: 15,
                              color: colors.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l10n.recapTopPayer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recap.topPayer.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          moneyDisplay(l10n, recap.topPayer.amountPaidMinor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(QesmaSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(QesmaRadii.control),
                      border: Border.all(color: colors.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 15,
                              color: colors.info,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l10n.recapBiggestExpense,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recap.biggestExpense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          moneyDisplay(l10n, recap.biggestExpense.totalMinor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QesmaSpacing.sm),

            // 4. Category Split Breakdown
            Container(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 2),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(QesmaRadii.control),
                border: Border.all(color: colors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recapCategoriesTitle,
                    style: TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: QesmaSpacing.xs + 2),

                  // Segmented horizontal progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          for (final cat in activeCategories)
                            if (cat.percentageBps > 0)
                              Expanded(
                                flex: cat.percentageBps,
                                child: Container(
                                  color: categoryThemeColors(
                                    ExpenseCategory.fromWire(cat.category),
                                  ).$2,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: QesmaSpacing.sm),

                  // Top categories chips (up to 4)
                  for (final cat in activeCategories.take(4)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: categoryThemeColors(
                                ExpenseCategory.fromWire(cat.category),
                              ).$2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            ExpenseCategory.fromWire(cat.category).icon,
                            size: 13,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ExpenseCategory.fromWire(cat.category).label(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 11,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            moneyDisplay(l10n, cat.totalMinor),
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${Bps.format(cat.percentageBps)}%',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 10,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),

            // 5. Footer: App branding and link
            Row(
              children: [
                Text(
                  l10n.recapWatermark,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.recapPlayLink,
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
