import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/theme/palette.dart';

/// A white group of rows with a small title above it (the hub's "Preferences", "About the app").
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: QesmaSpacing.xs, bottom: QesmaSpacing.sm),
          child: Semantics(header: true, child: Text(title, style: theme.textTheme.labelLarge?.copyWith(color: context.colors.textSecondary))),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.colors.hairline),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row: icon, title, an optional value, and a chevron when it opens something. The whole row
/// is one tap target (at least 56 px) read as "title, value, button".
class ProfileRow extends StatelessWidget {
  const ProfileRow({super.key, required this.icon, required this.title, this.value, this.onTap});

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = [title, ?value].join('، ');
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: QesmaSpacing.md, vertical: QesmaSpacing.sm),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
              child: Padding(padding: const EdgeInsets.all(QesmaSpacing.sm), child: Icon(icon, size: 20, color: context.colors.onPrimaryContainer)),
            ),
            const SizedBox(width: QesmaSpacing.sm + 4),
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            if (value != null) ...[
              const SizedBox(width: QesmaSpacing.sm),
              Flexible(child: Text(value!, textAlign: TextAlign.end, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary))),
            ],
            if (onTap != null) ...[
              const SizedBox(width: QesmaSpacing.xs),
              Icon(Icons.chevron_right, color: context.colors.textHelper),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
