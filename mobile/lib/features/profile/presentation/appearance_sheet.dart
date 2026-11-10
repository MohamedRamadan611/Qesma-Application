import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// The words for a theme mode ("Follow phone", "Light", "Dark").
String appearanceLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
      ThemeMode.system => l10n.appearanceSystem,
      ThemeMode.light => l10n.appearanceLight,
      ThemeMode.dark => l10n.appearanceDark,
    };

/// Follow the phone (default), light or dark. Choosing applies at once and is remembered on the device.
Future<void> showAppearanceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<void>(context, title: l10n.appearanceSheetTitle, child: const _AppearanceChoices(), useRootNavigator: true);
}

class _AppearanceChoices extends ConsumerWidget {
  const _AppearanceChoices();

  Future<void> _pick(BuildContext context, WidgetRef ref, ThemeMode mode) async {
    final navigator = Navigator.of(context);
    await ref.read(themeModeProvider.notifier).choose(mode);
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(themeModeProvider);
    Widget choice(ThemeMode mode, IconData icon) {
      final label = appearanceLabel(l10n, mode);
      return Padding(
        padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
        child: Semantics(
          button: true,
          selected: current == mode,
          label: label,
          excludeSemantics: true,
          onTap: () => _pick(context, ref, mode),
          child: AppCard(
            onTap: () => _pick(context, ref, mode),
            child: Row(
              children: [
                Icon(icon, color: context.colors.textSecondary),
                const SizedBox(width: QesmaSpacing.sm + 4),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
                if (current == mode) Icon(Icons.check_circle, color: context.colors.primary),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        choice(ThemeMode.system, Icons.brightness_auto_outlined),
        choice(ThemeMode.light, Icons.light_mode_outlined),
        choice(ThemeMode.dark, Icons.dark_mode_outlined),
      ],
    );
  }
}
