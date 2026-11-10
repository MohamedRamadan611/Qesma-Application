import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/status_banner.dart';
import '../application/change_password_controller.dart';
import 'password_field.dart';

/// Change the password of an email account. Other devices are signed out by the server; this one continues.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(changePasswordControllerProvider.notifier).submit(_current.text, _next.text);
    if (!ok || !mounted) return;
    showAppSnackBar(context, AppLocalizations.of(context).passwordChanged);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(changePasswordControllerProvider);
    final controller = ref.read(changePasswordControllerProvider.notifier);
    final error = state.error;
    final newError = switch (error) {
      PasswordChangeError.newShort => l10n.authErrorPasswordShort,
      PasswordChangeError.newLong => l10n.authErrorPasswordLong,
      _ => null,
    };
    final bannerText = switch (error) {
      PasswordChangeError.currentEmpty => l10n.passwordCurrentWrong,
      PasswordChangeError.refused => l10n.passwordCurrentWrong,
      PasswordChangeError.rateLimited => l10n.errorRateLimited,
      PasswordChangeError.offline => l10n.errorNoConnection,
      PasswordChangeError.failed => l10n.errorUnexpected,
      _ => null,
    };
    return AppScaffold(
      title: l10n.passwordChangeTitle,
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
          children: [
            PasswordField(
              controller: _current,
              label: l10n.passwordCurrentLabel,
              enabled: !state.submitting,
              textInputAction: TextInputAction.next,
              onChanged: (_) => controller.clearError(),
            ),
            const SizedBox(height: QesmaSpacing.md),
            PasswordField(
              controller: _next,
              label: l10n.passwordNewLabel,
              newPassword: true,
              enabled: !state.submitting,
              errorText: newError,
              onChanged: (_) => controller.clearError(),
              onSubmitted: (_) => _submit(),
            ),
            if (newError == null) ...[
              const SizedBox(height: QesmaSpacing.xs),
              Text(l10n.authPasswordRules, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (bannerText != null) ...[
              const SizedBox(height: QesmaSpacing.md),
              StatusBanner(icon: Icons.error_outline, text: bannerText, tone: BannerTone.error),
            ],
            const SizedBox(height: QesmaSpacing.lg),
            AppButton(label: l10n.passwordChangeButton, loading: state.submitting, onPressed: state.submitting ? null : _submit),
          ],
        ),
      ),
    );
  }
}
