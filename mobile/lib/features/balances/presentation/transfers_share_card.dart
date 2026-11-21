import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/widgets.dart';

/// The suggested transfers of a group as one shareable image ("who pays whom"), without any trip-recap statistics.
class TransfersShareCard extends StatelessWidget {
  const TransfersShareCard({super.key, required this.groupName, required this.transfers, required this.nameOf});

  final String groupName;
  final List<TransferView> transfers;
  final String Function(String memberId) nameOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ShareCardFrame(
      title: l10n.balancesSuggestedTitle,
      subtitle: groupName,
      children: [
        for (final t in transfers)
          ShareCardRow(
            label: l10n.recapTextSummaryTransferLine(nameOf(t.fromMemberId), nameOf(t.toMemberId), '').replaceFirst(RegExp(r'^•\s*'), '').replaceFirst(RegExp(r':\s*$'), ''),
            value: moneyDisplay(l10n, t.amountMinor),
          ),
      ],
    );
  }
}
