import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// One member's balance as the server computed it: avatar, name, "(you)" and the pill with the
/// word (owes / is owed / settled), the sign and the amount. Colour only reinforces the words.
class MemberNetRow extends StatelessWidget {
  const MemberNetRow({super.key, required this.memberId, required this.name, required this.netMinor, required this.isYou});

  final String memberId;
  final String name;
  final int netMinor;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nameText = Text(isYou ? '$name ${l10n.membersYouTag}' : name, style: theme.textTheme.titleSmall);
    final spokenName = isYou ? '$name ${l10n.membersYouTag}' : name;
    return Semantics(
      container: true,
      label: l10n.balancesMemberSpoken(spokenName, balanceSpoken(l10n, netMinor)),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
            child: Row(
              children: [
                MemberAvatar(memberId: memberId, name: name, size: 40),
                const SizedBox(width: QesmaSpacing.sm + 4),
                Expanded(
                  // The pill sits at the end when it fits and drops under the name when it does not (large text).
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: QesmaSpacing.sm,
                    runSpacing: QesmaSpacing.xs,
                    children: [nameText, BalanceStatusChip(netMinor)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
