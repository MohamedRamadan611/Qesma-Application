import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Groups of this many members or fewer keep inline chips on an item card; bigger groups get the summary chip.
const int kInlineChipMembers = 5;

/// Up to three avatars, then "+N", or "everyone", or "Choose people" while nobody is chosen. Tapping it opens the
/// member picker. [people] are the assignees who are current members, in member order.
class AssigneeSummaryChip extends StatelessWidget {
  const AssigneeSummaryChip({super.key, required this.people, required this.totalMembers, required this.onTap, this.hasError = false});

  final List<MemberDto> people;
  final int totalMembers;
  final VoidCallback onTap;
  final bool hasError;

  static const int _avatars = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final everyone = people.isNotEmpty && people.length == totalMembers;
    final extra = people.length - _avatars;
    final label = people.isEmpty ? l10n.expenseItzSummaryNone : (everyone ? l10n.expenseItzSummaryAll : (extra > 0 ? l10n.expenseItzSummaryMore('$extra') : null));
    final spoken = people.isEmpty ? l10n.expenseItzSummaryNone : l10n.expenseItzSummarySpoken(people.map((p) => p.displayName).join(l10n.expenseListSeparator));
    final border = hasError ? context.colors.error : context.colors.buttonBorder;
    return Semantics(
      button: true,
      label: spoken,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.pill),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: Center(
              widthFactor: 1,
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(QesmaRadii.pill),
                  border: Border.all(color: border, width: hasError ? 1.5 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (people.isEmpty)
                      Icon(Icons.group_add_outlined, size: 20, color: hasError ? context.colors.error : context.colors.primary)
                    else
                      SizedBox(
                        width: 28.0 + 18.0 * (people.length.clamp(1, _avatars) - 1),
                        height: 28,
                        child: Stack(
                          children: [
                            for (var i = 0; i < people.length.clamp(0, _avatars); i++)
                              PositionedDirectional(
                                start: 18.0 * i,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.colors.card, width: 2)),
                                  child: MemberAvatar(memberId: people[i].id, name: people[i].displayName, size: 28),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (label != null) ...[const SizedBox(width: QesmaSpacing.sm), Text(label, style: theme.textTheme.labelLarge)],
                    const SizedBox(width: QesmaSpacing.xs),
                    const Icon(Icons.arrow_drop_down, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
