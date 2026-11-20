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
import '../application/expense_preview_controller.dart';
import 'expense_blocks.dart';
import 'status_banner.dart';

/// Per-person breakdown (one expandable row each), the bill total, the printed-total comparison and the payers banner.
/// Every amount is the preview's, shown only while that preview answers for the bill as it is now.
class BreakdownCard extends ConsumerWidget {
  const BreakdownCard({
    super.key,
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
      body = Text(l10n.expenseItemizedIncomplete, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary));
    } else if (current != null) {
      final shares = current!.members.toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareRows(shares: shares, nameOf: nameOf, yourMemberId: yourMemberId, expandable: true),
          DecoratedBox(
            decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
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
          // SA12: the total printed on a scanned receipt against the preview's own total (a comparison, no arithmetic).
          // After the tolerance (A174) set the adjustment, the totals are equal and this is the "match" the user sees.
          if (form.printedTotalMinor != null) ...[
            const SizedBox(height: QesmaSpacing.sm),
            current!.totalMinor == form.printedTotalMinor
                ? StatusBanner(icon: Icons.check_circle_outline, text: l10n.scanTotalMatches(Money.format(form.printedTotalMinor!)), tone: BannerTone.success)
                : StatusBanner(icon: Icons.error_outline, text: l10n.scanTotalDiffers(Money.format(form.printedTotalMinor!)), tone: BannerTone.error),
          ],
          if (matchKey != null) ...[const SizedBox(height: QesmaSpacing.sm), _MatchBanner(state: match, key_: matchKey!)],
        ],
      );
    } else if (preview.status == PreviewStatus.failed && preview.key == splitKey) {
      body = Row(
        children: [
          Expanded(child: Semantics(liveRegion: true, child: Text(l10n.expenseItemizedFailed, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.error)))),
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
            Expanded(child: Text(l10n.expenseItemizedLoading, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))),
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
