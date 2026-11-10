import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/dev_settings.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import 'auth_widgets.dart';
import '../../../core/theme/palette.dart';

/// Google sign-in. No guest mode. In debug builds a second link signs in with the backend's
/// `fake-auth` token so the app runs against a local backend without Google.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final loading = state is AuthSigningIn;
    final error = state is AuthSignedOut ? state.error : null;

    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(QesmaSpacing.margin),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: BrandHeader(tagline: l10n.welcomeTitle)),
                      const SizedBox(height: QesmaSpacing.xl),
                      if (error != null && error != SignInError.cancelled) ...[
                        SignInErrorBanner(error: error),
                        const SizedBox(height: QesmaSpacing.md),
                      ],
                      GoogleSignInButton(loading: loading, onPressed: controller.signInWithGoogle),
                      const SizedBox(height: QesmaSpacing.sm),
                      AppButton(
                        label: l10n.authUsernameContinue,
                        icon: Icons.mail_outline,
                        variant: AppButtonVariant.secondary,
                        onPressed: loading ? null : () => context.go(Routes.usernameSignIn),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: QesmaSpacing.sm),
                        AppButton(
                          label: l10n.devFakeSignIn,
                          variant: AppButtonVariant.text,
                          onPressed: loading ? null : () => controller.signInWithIdToken(DevSettings.fakeToken),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, 0, QesmaSpacing.margin, QesmaSpacing.sm),
              child: ConsentFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
