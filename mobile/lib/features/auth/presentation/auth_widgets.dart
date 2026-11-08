import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/qesma_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_state.dart';

/// Terms and privacy pages. PLACEHOLDER URLs until the legal pages exist (open item: the
/// Play Store needs a real privacy policy before release).
abstract final class LegalLinks {
  static final Uri terms = Uri.parse('https://qesma.app/terms');
  static final Uri privacy = Uri.parse('https://qesma.app/privacy');
}

/// Opens a URL in the browser. Overridden in tests.
final urlOpenerProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// "By signing in you agree to the Terms of Use and the Privacy Policy" with two links,
/// each a 48 px target.
class ConsentFooter extends ConsumerWidget {
  const ConsentFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: QesmaColors.textSecondary);

    Future<void> open(Uri uri) async {
      var opened = false;
      try {
        opened = await ref.read(urlOpenerProvider)(uri);
      } catch (_) {
        opened = false;
      }
      if (!opened && context.mounted) showAppSnackBar(context, l10n.legalOpenFailed);
    }

    Widget link(String label, Uri uri) => TextButton(
          onPressed: () => open(uri),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, kMinTouch),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
            foregroundColor: QesmaColors.textPrimary,
          ),
          child: Text(label, style: style?.copyWith(color: QesmaColors.textPrimary, decoration: TextDecoration.underline)),
        );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(l10n.legalConsentPrefix, style: style),
        link(l10n.legalTerms, LegalLinks.terms),
        Text(l10n.legalAnd, style: style),
        link(l10n.legalPrivacy, LegalLinks.privacy),
      ],
    );
  }
}

/// "Continue with Google": white button with Google's own "G" (bundled, unmodified).
/// NOT VERIFIED against Google's current branding guidelines (see assets/brand/README.md).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = onPressed != null && !loading;
    final label = l10n.signInWithGoogle;
    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, ${l10n.commonLoading}' : label,
      excludeSemantics: true,
      child: Material(
        color: QesmaColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          side: const BorderSide(color: QesmaColors.buttonBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(QesmaRadii.control),
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: QesmaSpacing.md, vertical: QesmaSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                  else
                    Image.asset('assets/brand/google_g.png', width: 24, height: 24, excludeFromSemantics: true),
                  const SizedBox(width: QesmaSpacing.md - 4),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: QesmaText.textTheme().labelLarge?.copyWith(color: QesmaColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline sign-in error under the button. Announced to screen readers when it appears.
/// A cancelled picker shows nothing.
class SignInErrorBanner extends StatelessWidget {
  const SignInErrorBanner({super.key, required this.error});

  final SignInError? error;

  @override
  Widget build(BuildContext context) {
    final current = error;
    if (current == null || current == SignInError.cancelled) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final message = switch (current) {
      SignInError.rateLimited => l10n.errorRateLimited,
      SignInError.providerUnavailable => l10n.errorAuthProviderUnavailable,
      SignInError.offline => l10n.errorNoConnection,
      SignInError.notConfigured => kDebugMode ? l10n.signInNotConfigured : l10n.signInFailed,
      SignInError.failed || SignInError.cancelled => l10n.signInFailed,
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QesmaColors.errorContainer,
          borderRadius: BorderRadius.circular(QesmaRadii.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: Icon(Icons.error_outline, color: QesmaColors.error, size: 20)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(
                child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: QesmaColors.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

