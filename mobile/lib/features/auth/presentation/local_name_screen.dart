import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/local_auth_controller.dart';
import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/status_banner.dart';
import '../../profile/application/update_profile_controller.dart';
import '../application/auth_controller.dart';

/// Local mode, first run: "what's your name?" (STANDALONE_SPEC 2). One field, 1 to 60 characters after trimming.
/// Saving creates the local profile (`PATCH /me`); the router then moves to the groups list by itself. The name is
/// never logged.
class LocalNameScreen extends ConsumerStatefulWidget {
  const LocalNameScreen({super.key});

  @override
  ConsumerState<LocalNameScreen> createState() => _LocalNameScreenState();
}

class _LocalNameScreenState extends ConsumerState<LocalNameScreen> {
  final TextEditingController _name = TextEditingController();
  bool _touched = false;
  bool _saving = false;
  ApiFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ProfileForm get _form => ProfileForm(original: '', name: _name.text);

  Future<void> _save() async {
    setState(() => _touched = true);
    if (_saving || _form.error != null) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    final controller = ref.read(authControllerProvider.notifier) as LocalAuthController;
    final failure = await controller.createProfile(_form.trimmed);
    if (mounted && failure != null) {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = switch (_form.error) {
      NameError.empty => _touched ? l10n.profileNameRequired : null,
      NameError.tooLong => l10n.profileNameTooLong,
      null => null,
    };
    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QesmaSpacing.margin),
          children: [
            const SizedBox(height: QesmaSpacing.lg),
            Center(child: BrandHeader(tagline: l10n.brandTagline, logoSize: 72)),
            const SizedBox(height: QesmaSpacing.xl),
            Semantics(header: true, child: Text(l10n.onboardingNameTitle, style: theme.textTheme.headlineMedium)),
            const SizedBox(height: QesmaSpacing.md),
            AppTextField(
              controller: _name,
              label: l10n.profileNameLabel,
              errorText: error,
              maxLength: kDisplayNameMax,
              enabled: !_saving,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() => _touched = true),
              onSubmitted: (_) => _save(),
            ),
            if (error == null) ...[
              const SizedBox(height: QesmaSpacing.xs),
              Text(l10n.onboardingNameHelper, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
            ],
            if (_failure != null) ...[
              const SizedBox(height: QesmaSpacing.md),
              StatusBanner(icon: Icons.error_outline, text: errorCopyFor(l10n, _failure!).message, tone: BannerTone.error),
            ],
            const SizedBox(height: QesmaSpacing.lg),
            AppButton(label: l10n.onboardingContinue, icon: Icons.arrow_forward, loading: _saving, onPressed: _saving ? null : _save),
          ],
        ),
      ),
    );
  }
}
