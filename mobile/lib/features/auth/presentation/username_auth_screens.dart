import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/status_banner.dart';
import '../application/username_auth_controller.dart';
import 'password_field.dart';

String _errorText(AppLocalizations l10n, UsernameAuthError error) => switch (error) {
      UsernameAuthError.invalidUsername => l10n.authErrorUsernameInvalid,
      UsernameAuthError.passwordShort => l10n.authErrorPasswordShort,
      UsernameAuthError.passwordLong => l10n.authErrorPasswordLong,
      UsernameAuthError.wrongCredentials => l10n.authErrorWrongCredentials,
      UsernameAuthError.usernameTaken => l10n.authErrorUsernameTaken,
      UsernameAuthError.passwordRejected => l10n.authErrorPasswordRejected,
      UsernameAuthError.rateLimited => l10n.errorRateLimited,
      UsernameAuthError.offline => l10n.errorNoConnection,
      UsernameAuthError.failed => l10n.errorUnexpected,
    };

/// Sign in with an email address and password.
class UsernameSignInScreen extends ConsumerStatefulWidget {
  const UsernameSignInScreen({super.key});

  @override
  ConsumerState<UsernameSignInScreen> createState() => _UsernameSignInScreenState();
}

class _UsernameSignInScreenState extends ConsumerState<UsernameSignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => ref.read(usernameAuthControllerProvider.notifier).signIn(_username.text, _password.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(usernameAuthControllerProvider);
    final controller = ref.read(usernameAuthControllerProvider.notifier);
    final error = state.error;
    return AppScaffold(
      title: l10n.authUsernameSignInTitle,
      showBack: true,
      onBack: () => context.go(Routes.signIn),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
          children: [
            AppTextField(
              controller: _username,
              label: l10n.fieldUsername,
                            enabled: !state.submitting,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              errorText: error == UsernameAuthError.invalidUsername ? l10n.authErrorUsernameInvalid : null,
              onChanged: (_) => controller.clearError(),
            ),
            const SizedBox(height: QesmaSpacing.md),
            PasswordField(
              controller: _password,
              label: l10n.fieldPassword,
              enabled: !state.submitting,
              onChanged: (_) => controller.clearError(),
              onSubmitted: (_) => _submit(),
            ),
            if (error != null && error != UsernameAuthError.invalidUsername) ...[
              const SizedBox(height: QesmaSpacing.md),
              StatusBanner(icon: Icons.error_outline, text: _errorText(l10n, error), tone: BannerTone.error),
            ],
            const SizedBox(height: QesmaSpacing.lg),
            AppButton(label: l10n.authUsernameSignInButton, loading: state.submitting, onPressed: state.submitting ? null : _submit),
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.authGoRegister,
              variant: AppButtonVariant.text,
              onPressed: state.submitting ? null : () => context.go(Routes.register),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create an account with an email address and password (the user is signed in right away).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => ref.read(usernameAuthControllerProvider.notifier).register(_username.text, _password.text, _name.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(usernameAuthControllerProvider);
    final controller = ref.read(usernameAuthControllerProvider.notifier);
    final error = state.error;
    final passwordError = switch (error) {
      UsernameAuthError.passwordShort => l10n.authErrorPasswordShort,
      UsernameAuthError.passwordLong => l10n.authErrorPasswordLong,
      _ => null,
    };
    return AppScaffold(
      title: l10n.authRegisterTitle,
      showBack: true,
      onBack: () => context.go(Routes.signIn),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
          children: [
            AppTextField(
              controller: _name,
              label: l10n.fieldDisplayNameOptional,
              enabled: !state.submitting,
              maxLength: 60,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => controller.clearError(),
            ),
            const SizedBox(height: QesmaSpacing.md),
            AppTextField(
              controller: _username,
              label: l10n.fieldUsername,
                            enabled: !state.submitting,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              errorText: error == UsernameAuthError.invalidUsername ? l10n.authErrorUsernameInvalid : null,
              onChanged: (_) => controller.clearError(),
            ),
            const SizedBox(height: QesmaSpacing.md),
            PasswordField(
              controller: _password,
              label: l10n.fieldPassword,
              newPassword: true,
              enabled: !state.submitting,
              errorText: passwordError,
              onChanged: (_) => controller.clearError(),
              onSubmitted: (_) => _submit(),
            ),
            if (passwordError == null) ...[
              const SizedBox(height: QesmaSpacing.xs),
              Text(l10n.authPasswordRules, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (error != null && error != UsernameAuthError.invalidUsername && passwordError == null) ...[
              const SizedBox(height: QesmaSpacing.md),
              StatusBanner(icon: Icons.error_outline, text: _errorText(l10n, error), tone: BannerTone.error),
            ],
            const SizedBox(height: QesmaSpacing.lg),
            AppButton(label: l10n.authRegisterButton, loading: state.submitting, onPressed: state.submitting ? null : _submit),
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.authGoSignIn,
              variant: AppButtonVariant.text,
              onPressed: state.submitting ? null : () => context.go(Routes.usernameSignIn),
            ),
          ],
        ),
      ),
    );
  }
}
