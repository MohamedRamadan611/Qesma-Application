import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Max length of a member name (same as the Members tab sheet).
const int memberNameMaxLength = 40;

/// Case-insensitive, whitespace-collapsed key used to spot a repeated name.
String memberNameKey(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Optional list of name-only members collected on the create-group screen.
/// The names are created after the group exists; the owner is added by the backend.
class MemberNamesInput extends StatefulWidget {
  const MemberNamesInput({super.key, required this.names, required this.onChanged, this.enabled = true});

  final List<String> names;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  @override
  State<MemberNamesInput> createState() => _MemberNamesInputState();
}

class _MemberNamesInputState extends State<MemberNamesInput> {
  final _controller = TextEditingController();
  bool _duplicate = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return;
    final key = memberNameKey(name);
    if (widget.names.any((n) => memberNameKey(n) == key)) {
      setState(() => _duplicate = true);
      return;
    }
    _controller.clear();
    setState(() => _duplicate = false);
    widget.onChanged([...widget.names, name]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: _controller,
                label: l10n.groupMemberNameOptional,
                hint: l10n.groupMembersNameHint,
                maxLength: memberNameMaxLength,
                enabled: widget.enabled,
                errorText: _duplicate ? l10n.groupMembersDuplicate : null,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_duplicate) setState(() => _duplicate = false);
                },
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: QesmaSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.lg),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52), padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.md)),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(l10n.groupMembersAddButton),
                onPressed: widget.enabled ? _add : null,
              ),
            ),
          ],
        ),
        if (widget.names.isNotEmpty) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.sm,
            children: [
              for (final name in widget.names)
                InputChip(
                  label: Text(name),
                  deleteButtonTooltipMessage: l10n.groupMembersRemove(name),
                  onDeleted: widget.enabled ? () => widget.onChanged([...widget.names]..remove(name)) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
