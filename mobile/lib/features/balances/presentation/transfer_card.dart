import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/balance_colors.dart';
import '../../../core/theme/qesma_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// One of the server's suggested transfers: who pays whom, how much, and the button that opens the
/// Record payment sheet for exactly this transfer. Every value is the server's; nothing is derived.
class TransferCard extends StatelessWidget {
  const TransferCard({super.key, required this.transfer, required this.nameOf, required this.onRecord});

  final TransferView transfer;
  final String Function(String memberId) nameOf;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.balanceColors;
    final from = nameOf(transfer.fromMemberId);
    final to = nameOf(transfer.toMemberId);
    final amount = transfer.amountMinor;

    Widget person(String id, String name, String role, Color roleColor) => Expanded(
          child: Column(
            children: [
              MemberAvatar(memberId: id, name: name, size: 44),
              const SizedBox(height: QesmaSpacing.xs),
              Text(name, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
              Text(role, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: roleColor, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: l10n.balancesTransferSpoken(from, moneySpoken(l10n, amount), to),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      person(transfer.fromMemberId, from, l10n.balancesPays, colors.owes),
                      const Padding(
                        padding: EdgeInsets.only(top: QesmaSpacing.sm + 4),
                        child: Icon(Icons.arrow_forward, color: QesmaColors.textHelper),
                      ),
                      person(transfer.toMemberId, to, l10n.balancesReceives, colors.owed),
                    ],
                  ),
                  const SizedBox(height: QesmaSpacing.md),
                  Center(child: Text(moneyDisplay(l10n, amount), style: QesmaText.amountMedium())),
                ],
              ),
            ),
          ),
          const SizedBox(height: QesmaSpacing.md),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: l10n.balancesRecordPaymentSpoken(from, to, moneySpoken(l10n, amount)),
            onTap: onRecord,
            child: AppButton(label: l10n.balancesRecordPayment, icon: Icons.check, onPressed: onRecord),
          ),
        ],
      ),
    );
  }
}
