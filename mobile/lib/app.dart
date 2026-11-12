import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/connectivity.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/widgets/app_states.dart';
import 'features/auth/presentation/session_expired_dialog.dart';
import 'features/groups/application/freshness.dart';

class QesmaApp extends ConsumerWidget {
  const QesmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => FreshnessHost(
        child: SessionExpiredHost(child: _OfflineHost(child: child ?? const SizedBox.shrink())),
      ),
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider), // the phone's setting unless the user chose one
    );
  }
}

/// Shows the thin offline banner above whatever screen is open while the API cannot be reached.
/// It disappears by itself on the next answer from the server. Content is never blocked.
class _OfflineHost extends ConsumerWidget {
  const _OfflineHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    if (online) return child;
    return Column(
      children: [
        SafeArea(bottom: false, child: OfflineBanner(visible: !online)),
        // The banner already covers the status bar, so the screen below must not pad for it again.
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}
