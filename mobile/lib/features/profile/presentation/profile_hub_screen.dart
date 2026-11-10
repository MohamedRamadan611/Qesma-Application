import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_info.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../groups/application/groups_list_controller.dart';
import 'appearance_sheet.dart';
import 'language_sheet.dart';
import 'profile_rows.dart';
import '../../../core/theme/palette.dart';

/// Asks, then signs out (the local wipe happens first, the router moves to the welcome screen).
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.profileSignOutTitle,
    message: l10n.profileSignOutBody,
    confirmLabel: l10n.homeSignOut,
    destructive: true,
  );
  if (confirmed) await ref.read(authControllerProvider.notifier).signOut();
}

/// The Account tab (P10-01): who you are (name, the connected Google account), how many groups you
/// are in, your net across groups when the groups list can say it, the language, the legal pages,
/// the version, and sign out. No role badge, avatar photo, notifications, currency, payment handles,
/// export, devices or account deletion: Phase 1 has no data or backend for them.
class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final groups = ref.watch(groupsListControllerProvider);
    final open = ref.read(urlOpenerProvider);
    final user = auth is AuthSignedIn ? auth.user : null;
    final name = user?.displayName ?? '';
    final email = user?.email;

    // The count is known only when every page of the list is loaded.
    final countKnown = groups.status == GroupsStatus.ready && !groups.hasMore;
    final count = groups.items.length;
    final net = groups.netTotalMinor;

    return AppScaffold(
      title: l10n.profileTitle,
      showBack: false,
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MemberAvatar(memberId: user?.id ?? 'me', name: name, size: 56),
                    const SizedBox(width: QesmaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(header: true, child: Text(name, style: theme.textTheme.headlineMedium)),
                          if (user?.username != null) Text(ltrIsolate('@${user!.username}'), style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                          if (email != null) Text(email, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                          Text(user?.hasPassword ?? false ? l10n.accountSignedInWithPassword : l10n.accountGoogleTitle, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (countKnown && count > 0) ...[
                  const SizedBox(height: QesmaSpacing.md),
                  DecoratedBox(
                    decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                    child: Padding(
                      padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: QesmaSpacing.sm,
                        runSpacing: QesmaSpacing.sm,
                        children: [
                          Text(
                            countPhrase(count, one: l10n.profileGroupsOne, two: l10n.profileGroupsTwo, few: l10n.profileGroups, many: l10n.profileGroupsMany),
                            style: theme.textTheme.titleSmall,
                          ),
                          if (net != null) BalanceStatusChip(net),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: QesmaSpacing.md),
                AppButton(label: l10n.profileEdit, icon: Icons.edit_outlined, variant: AppButtonVariant.secondary, onPressed: () => context.push(Routes.editProfile)),
              ],
            ),
          ),
          const SizedBox(height: QesmaSpacing.lg),
          ProfileSection(
            title: l10n.profileSectionPrefs,
            children: [
              ProfileRow(
                icon: Icons.language,
                title: l10n.profileLanguage,
                value: locale.languageCode == 'ar' ? l10n.languageArabic : l10n.languageEnglish,
                onTap: () => showLanguageSheet(context),
              ),
              ProfileRow(
                icon: Icons.brightness_6_outlined,
                title: l10n.profileAppearance,
                value: appearanceLabel(l10n, themeMode),
                onTap: () => showAppearanceSheet(context),
              ),
              if (user?.hasPassword ?? false)
                ProfileRow(icon: Icons.password_outlined, title: l10n.profileChangePassword, onTap: () => context.push(Routes.changePassword)),
              ProfileRow(icon: Icons.manage_accounts_outlined, title: l10n.profileAccountSettings, onTap: () => context.push(Routes.accountSettings)),
            ],
          ),
          const SizedBox(height: QesmaSpacing.lg),
          ProfileSection(
            title: l10n.profileSectionAbout,
            children: [
              ProfileRow(icon: Icons.description_outlined, title: l10n.legalTerms, onTap: () => open(LegalLinks.terms)),
              ProfileRow(icon: Icons.lock_outline, title: l10n.legalPrivacy, onTap: () => open(LegalLinks.privacy)),
              ProfileRow(icon: Icons.info_outline, title: l10n.profileVersion, value: ltrIsolate(AppInfo.display)),
            ],
          ),
          const SizedBox(height: QesmaSpacing.lg),
          AppButton(label: l10n.homeSignOut, icon: Icons.logout, variant: AppButtonVariant.destructive, onPressed: () => confirmSignOut(context, ref)),
        ],
      ),
    );
  }
}
