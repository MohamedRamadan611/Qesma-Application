import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/auth_controller.dart';
import '../application/auth_state.dart';
import 'auth_widgets.dart';
import '../../../core/theme/palette.dart';

/// Shows [SessionExpiredDialog] over whatever screen is open when the session ends, once,
/// and removes it when the user signs in again or goes back to the start.
class SessionExpiredHost extends ConsumerStatefulWidget {
  const SessionExpiredHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionExpiredHost> createState() => _SessionExpiredHostState();
}

class _SessionExpiredHostState extends ConsumerState<SessionExpiredHost> {
  bool _requested = false;
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final expired = next is AuthSessionExpired;
      if (expired && !_requested) _show();
      if (!expired && _requested) _close();
    });
    return widget.child;
  }

  void _show() {
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigatorContext = rootNavigatorKey.currentContext;
      if (!mounted || navigatorContext == null || ref.read(authControllerProvider) is! AuthSessionExpired) {
        _requested = false;
        return;
      }
      _shown = true;
      await showDialog<void>(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (_) => const PopScope(canPop: false, child: SessionExpiredDialog()),
      );
      _shown = false;
      _requested = false;
    });
  }

  void _close() {
    if (!_shown) {
      _requested = false;
      return;
    }
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) navigator.pop();
  }
}

/// P11-04: "your session ended". Sign in again, or go back to the start. No guest option.
class SessionExpiredDialog extends ConsumerWidget {
  const SessionExpiredDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final expired = state is AuthSessionExpired ? state : const AuthSessionExpired();
    final controller = ref.read(authControllerProvider.notifier);

    return AlertDialog(
      scrollable: true,
      icon: ExcludeSemantics(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
          child: Icon(Icons.lock_clock, size: 36, color: context.colors.onPrimaryContainer),
        ),
      ),
      title: Text(l10n.sessionExpiredTitle, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sessionExpiredBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: QesmaSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.tint,
              borderRadius: BorderRadius.circular(QesmaRadii.control),
              border: Border.all(color: context.colors.tintBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Text(l10n.sessionExpiredReassure, textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
            ),
          ),
          if (expired.error != null && expired.error != SignInError.cancelled) ...[
            const SizedBox(height: QesmaSpacing.md),
            SignInErrorBanner(error: expired.error),
          ],
          const SizedBox(height: QesmaSpacing.md),
          GoogleSignInButton(loading: expired.busy, onPressed: controller.signInWithGoogle),
          const SizedBox(height: QesmaSpacing.xs),
          AppButton(
            label: l10n.sessionExpiredLeave,
            variant: AppButtonVariant.text,
            onPressed: expired.busy ? null : controller.leaveExpiredSession,
          ),
        ],
      ),
    );
  }
}
