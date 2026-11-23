import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/application/expense_form_state.dart' show kMaxShareUnits, kMinShareUnits;
import '../../expenses/presentation/itemized_items_card.dart' show QuantityStepper;

/// "Default share" of one member (SA19): the units a shares split starts this person with (1..100). Save sends it,
/// "Clear" removes it (new splits then start at 1). [onSave] returns the failure or null; the sheet closes on success.
Future<void> showDefaultShareSheet(
  BuildContext context, {
  required MemberDto member,
  required Future<ApiFailure?> Function(int? units) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _DefaultShareSheet(member: member, onSave: onSave),
    ),
  );
}

class _DefaultShareSheet extends StatefulWidget {
  const _DefaultShareSheet({required this.member, required this.onSave});

  final MemberDto member;
  final Future<ApiFailure?> Function(int? units) onSave;

  @override
  State<_DefaultShareSheet> createState() => _DefaultShareSheetState();
}

class _DefaultShareSheetState extends State<_DefaultShareSheet> {
  late int _units = widget.member.defaultShareUnits ?? kMinShareUnits;
  bool _saving = false;
  ApiFailure? _failure;

  Future<void> _submit(int? units) async {
    setState(() {
      _saving = true;
      _failure = null;
    });
    final failure = await widget.onSave(units);
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
    final theme = Theme.of(context);
    final name = widget.member.displayName;
    final failure = _failure;
    final hasDefault = widget.member.defaultShareUnits != null;

    return AppBottomSheet(
      title: l10n.memberDefaultShareTitle(name),
      action: AppButton(
        label: l10n.commonSave,
        icon: Icons.check,
        loading: _saving,
        onPressed: _saving ? null : () => _submit(_units),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.memberDefaultShareBody, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: QuantityStepper(
              quantity: _units,
              name: name,
              min: kMinShareUnits,
              max: kMaxShareUnits,
              label: l10n.sharesStepperLabel,
              decreaseTooltip: l10n.sharesStepperMinus,
              increaseTooltip: l10n.sharesStepperPlus,
              threeDigits: true,
              onStep: (delta) => setState(() => _units = (_units + delta).clamp(kMinShareUnits, kMaxShareUnits)),
            ),
          ),
          if (hasDefault) ...[
            const SizedBox(height: QesmaSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _saving ? null : () => _submit(null),
                style: TextButton.styleFrom(minimumSize: const Size(0, kMinTouch)),
                child: Text(l10n.memberDefaultShareClear),
              ),
            ),
          ],
          if (failure != null) ...[
            const SizedBox(height: QesmaSpacing.md),
            ErrorBanner(errorCopyFor(l10n, failure).message),
          ],
        ],
      ),
    );
  }
}
