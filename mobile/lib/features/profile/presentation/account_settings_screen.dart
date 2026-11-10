import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import 'profile_hub_screen.dart';
import '../../../core/theme/palette.dart';

/// Account settings (P10-03), reduced to what exists: the connected Google account (read only) and
/// sign out. Payment handles, export, devices, "sign out everywhere" and account deletion are not
/// part of Phase 1 (deletion is an open item before a public release).
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthSignedIn ? auth.user : null;
    final email = user?.email;
    return AppScaffold(
      title: l10n.profileAccountSettings,
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
        children: [
          AppCard(
            child: MergeSemantics(
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(Icons.account_circle_outlined, color: context.colors.primary, size: 32)),
                  const SizedBox(width: QesmaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.hasPassword ?? false ? l10n.accountSignedInWithPassword : l10n.accountGoogleTitle, style: theme.textTheme.titleSmall),
                        if (email != null) Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  AppTag(label: l10n.accountConnected, tone: AppTagTone.success),
                ],
              ),
            ),
          ),
          const SizedBox(height: QesmaSpacing.lg),
          AppButton(label: l10n.homeSignOut, icon: Icons.logout, variant: AppButtonVariant.destructive, onPressed: () => confirmSignOut(context, ref)),
        ],
      ),
    );
  }
}
