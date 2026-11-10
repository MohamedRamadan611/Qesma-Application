import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/theme/palette.dart';

/// Arabic or English. Choosing applies at once (the layout flips) and is remembered on the device.
Future<void> showLanguageSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<void>(context, title: l10n.languageSheetTitle, child: const _LanguageChoices(), useRootNavigator: true);
}

class _LanguageChoices extends ConsumerWidget {
  const _LanguageChoices();

  Future<void> _pick(BuildContext context, WidgetRef ref, String code) async {
    final navigator = Navigator.of(context);
    await ref.read(localeProvider.notifier).choose(Locale(code));
    navigator.maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeProvider).languageCode;
    Widget choice(String code, String label) => Padding(
          padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
          child: Semantics(
            button: true,
            selected: current == code,
            label: label,
            excludeSemantics: true,
            onTap: () => _pick(context, ref, code),
            child: AppCard(
              onTap: () => _pick(context, ref, code),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
                  if (current == code) Icon(Icons.check_circle, color: context.colors.primary),
                ],
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [choice('ar', l10n.languageArabic), choice('en', l10n.languageEnglish)],
    );
  }
}
