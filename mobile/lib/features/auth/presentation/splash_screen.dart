import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import '../../../core/theme/palette.dart';

/// First screen: looks for a stored session. If the server cannot be reached the session is
/// kept and the shared offline/error state offers a retry; the router moves on by itself
/// once the state changes.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    Widget body;
    if (state is AuthRestoreFailed) {
      final failure = state.failure;
      final offline = failure is ApiNoConnection || failure is ApiTimeout;
      body = offline
          ? NoInternetState(onRetry: controller.restore)
          : ErrorState(
              onRetry: controller.restore,
              message: errorCopyFor(l10n, failure).message,
              requestId: failure.problem?.requestId,
            );
    } else {
      body = Semantics(
        label: l10n.commonLoading,
        liveRegion: true,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(QesmaSpacing.lg),
            child: BrandHeader(tagline: l10n.brandTagline),
          ),
        ),
      );
    }
    return Scaffold(backgroundColor: context.colors.canvas, body: SafeArea(child: body));
  }
}
