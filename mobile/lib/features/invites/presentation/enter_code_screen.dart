import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/invite_code.dart';

/// Code entry fallback of the join flow (no screenshot exists): type or paste the code (or the whole link).
/// The input is normalised (case, dashes, spaces, Arabic-Indic digits) before anything is sent anywhere.
class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key, this.initial, this.invalid = false});

  /// What a bad link carried (shown so the person can fix it).
  final String? initial;

  /// Opened from a link whose code cannot be right: the error is shown at once.
  final bool invalid;

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  late final TextEditingController _code = TextEditingController(text: widget.initial ?? '');
  late bool _showError = widget.invalid;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _continue() {
    final code = normaliseInviteCode(_code.text);
    if (code == null) {
      setState(() => _showError = true);
      return;
    }
    context.go(Routes.joinCode(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppScaffold(
      title: l10n.inviteEnterCodeTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.home),
      body: ListView(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        children: [
          Text(l10n.inviteEnterCodeBody, style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.lg),
          Directionality(
            textDirection: TextDirection.ltr,
            child: AppTextField(
              controller: _code,
              label: l10n.inviteCodeFieldLabel,
              hint: 'XXXX-XXXX',
              errorText: _showError ? l10n.inviteCodeInvalid : null,
              autocorrect: false,
              autofocus: true,
              textInputAction: TextInputAction.go,
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              onSubmitted: (_) => _continue(),
            ),
          ),
          const SizedBox(height: QesmaSpacing.lg),
          AppButton(label: l10n.inviteContinue, onPressed: _continue),
        ],
      ),
    );
  }
}
