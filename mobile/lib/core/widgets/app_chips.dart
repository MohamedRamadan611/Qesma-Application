import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Selectable pill (type chips, filters). A check mark accompanies the selected state so
/// selection is never shown by colour alone. 48 px touch height.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({super.key, required this.label, required this.selected, required this.onSelected, this.icon});

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = selected ? QesmaColors.onPrimaryContainer : QesmaColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onSelected != null,
      label: label,
      // Without an explicit tap action a screen reader has nothing to activate (the child is excluded).
      onTap: onSelected == null ? null : () => onSelected!(!selected),
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.pill),
          onTap: onSelected == null ? null : () => onSelected!(!selected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: Center(
              widthFactor: 1,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? QesmaColors.primaryContainer : QesmaColors.card,
                  borderRadius: BorderRadius.circular(QesmaRadii.pill),
                  border: Border.all(
                    color: selected ? QesmaColors.primary : QesmaColors.buttonBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[Icon(Icons.check, size: 18, color: fg), const SizedBox(width: 6)]
                    else if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                    Flexible(child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg))),
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

/// One tab of [AppSegmentedTabs].
class AppTabItem {
  const AppTabItem({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// Segmented tabs (Expenses / Balances / Members). Items are listed in logical order; in a
/// right-to-left layout the first one sits on the right automatically.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({super.key, required this.items, required this.selectedIndex, required this.onChanged});

  final List<AppTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: QesmaColors.tint,
        borderRadius: BorderRadius.circular(QesmaRadii.control + 4),
        border: Border.all(color: QesmaColors.tintBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  inMutuallyExclusiveGroup: true,
                  label: items[i].label,
                  onTap: () => onChanged(i),
                  child: ExcludeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(QesmaRadii.control),
                      onTap: () => onChanged(i),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: kMinTouch),
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == selectedIndex ? QesmaColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(QesmaRadii.control),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (items[i].icon != null) ...[
                              Icon(
                                items[i].icon,
                                size: 18,
                                color: i == selectedIndex ? QesmaColors.onPrimary : QesmaColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                items[i].label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: i == selectedIndex ? QesmaColors.onPrimary : QesmaColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum AppTagTone { neutral, primary, info, success, warning }

/// Small non-interactive pill (group type, split type).
class AppTag extends StatelessWidget {
  const AppTag({super.key, required this.label, this.tone = AppTagTone.neutral, this.icon});

  final String label;
  final AppTagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      AppTagTone.neutral => (QesmaColors.textSecondary, QesmaColors.surfaceLow),
      AppTagTone.primary => (QesmaColors.onPrimaryContainer, QesmaColors.primaryContainer),
      AppTagTone.info => (QesmaColors.info, QesmaColors.infoContainer),
      AppTagTone.success => (QesmaColors.success, QesmaColors.successContainer),
      AppTagTone.warning => (QesmaColors.warning, QesmaColors.warningContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.pill)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
            Flexible(child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg))),
          ],
        ),
      ),
    );
  }
}
