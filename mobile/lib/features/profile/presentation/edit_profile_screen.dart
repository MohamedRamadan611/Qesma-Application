import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../expenses/presentation/status_banner.dart';
import '../application/update_profile_controller.dart';
import '../../../core/theme/palette.dart';

/// Edit profile (P10-02): the display name only (required, at most 60 characters, trimmed). The email
/// is shown read only. Leaving with a changed name asks first.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name = TextEditingController(text: ref.read(updateProfileControllerProvider).form.name);
  bool _touched = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _touched = true);
    final saved = await ref.read(updateProfileControllerProvider.notifier).save();
    if (!saved || !mounted) return;
    showAppSnackBar(context, AppLocalizations.of(context).profileSaved);
    context.pop();
  }

  Future<void> _askDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.profileDiscardTitle,
      message: l10n.profileDiscardBody,
      confirmLabel: l10n.profileDiscardConfirm,
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(updateProfileControllerProvider);
    final form = state.form;
    final auth = ref.watch(authControllerProvider);
    final email = auth is AuthSignedIn ? auth.user.email : null;
    final error = switch (form.error) {
      NameError.empty => _touched ? l10n.profileNameRequired : null,
      NameError.tooLong => l10n.profileNameTooLong,
      null => null,
    };
    return PopScope(
      canPop: !form.dirty || state.saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askDiscard();
      },
      child: AppScaffold(
        title: l10n.profileEditTitle,
        body: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
          children: [
            AppTextField(
              controller: _name,
              label: l10n.profileNameLabel,
              errorText: error,
              maxLength: kDisplayNameMax,
              enabled: !state.saving,
              textInputAction: TextInputAction.done,
              onChanged: (text) {
                _touched = true;
                ref.read(updateProfileControllerProvider.notifier).setName(text);
              },
              onSubmitted: (_) => _save(),
            ),
            if (error == null) ...[
              const SizedBox(height: QesmaSpacing.xs),
              Text(l10n.profileNameHint, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
            ],
            const SizedBox(height: QesmaSpacing.lg),
            if (email != null)
              MergeSemantics(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.profileEmailLabel, style: theme.textTheme.labelLarge),
                      const SizedBox(height: QesmaSpacing.xs),
                      Text(email, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: QesmaSpacing.xs),
                      Row(
                        children: [
                          ExcludeSemantics(child: Icon(Icons.lock_outline, size: 16, color: context.colors.textHelper)),
                          const SizedBox(width: QesmaSpacing.xs),
                          Expanded(child: Text(l10n.profileEmailLocked, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (state.failure != null) ...[
              const SizedBox(height: QesmaSpacing.md),
              StatusBanner(icon: Icons.error_outline, text: errorCopyFor(l10n, state.failure!).message, tone: BannerTone.error),
            ],
            const SizedBox(height: QesmaSpacing.lg),
            AppButton(label: l10n.profileSave, icon: Icons.check, loading: state.saving, onPressed: form.canSave && !state.saving ? _save : null),
            const SizedBox(height: QesmaSpacing.xs),
            AppButton(label: l10n.commonCancel, variant: AppButtonVariant.text, onPressed: state.saving ? null : () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }
}
