import 'package:flutter/material.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import 'group_dialogs.dart';

/// Add or rename a member (P4): one name field (max 40), inline `DUPLICATE_MEMBER_NAME`
/// error with the suggestion, no colour picker. [onSave] returns the failure or null.
Future<void> showMemberNameSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  String initialName = '',
  required Future<ApiFailure?> Function(String name) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _MemberNameSheet(title: title, subtitle: subtitle, initialName: initialName, onSave: onSave),
    ),
  );
}

class _MemberNameSheet extends StatefulWidget {
  const _MemberNameSheet({required this.title, required this.subtitle, required this.initialName, required this.onSave});

  final String title;
  final String? subtitle;
  final String initialName;
  final Future<ApiFailure?> Function(String name) onSave;

  @override
  State<_MemberNameSheet> createState() => _MemberNameSheetState();
}

class _MemberNameSheetState extends State<_MemberNameSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  bool _saving = false;
  ApiFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(name);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = _failure;
    final duplicate = failure != null && codeOf(failure) == ApiErrorCode.duplicateMemberName;
    final name = _name.text.trim();

    return AppBottomSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      action: ListenableBuilder(
        listenable: _name,
        builder: (context, _) => AppButton(
          label: l10n.memberSave,
          icon: Icons.check,
          loading: _saving,
          onPressed: !_saving && _name.text.trim().isNotEmpty ? _save : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _name,
            label: l10n.memberNameLabel,
            maxLength: 40,
            enabled: !_saving,
            autofocus: true,
            textInputAction: TextInputAction.done,
            errorText: duplicate ? errorCopyFor(l10n, failure, memberName: name).message : null,
          ),
          if (failure != null && !duplicate) ...[
            const SizedBox(height: QesmaSpacing.md),
            ErrorBanner(errorCopyFor(l10n, failure).message),
          ],
        ],
      ),
    );
  }
}
