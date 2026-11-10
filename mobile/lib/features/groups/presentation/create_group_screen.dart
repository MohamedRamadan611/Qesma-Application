import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/create_group_controller.dart';
import '../data/group_type.dart';
import 'group_ui.dart';
import '../../../core/theme/palette.dart';

/// Create group (P2-02): name (max 60), type chips, fixed EGP. No photo, no contacts.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _name = TextEditingController();
  GroupType _type = GroupType.trip;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = await ref.read(createGroupControllerProvider.notifier).submit(name: _name.text.trim(), type: _type.wire);
    if (id != null && mounted) context.go(Routes.group(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(createGroupControllerProvider);

    final failure = state.failure;
    final message = failure == null
        ? null
        : state.outcomeUnknown
            ? l10n.groupCreateOutcomeUnknown
            : errorCopyFor(l10n, failure).message;

    return AppScaffold(
      title: l10n.groupCreateTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.home),
      body: ListView(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        children: [
          Text(l10n.groupCreateSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.lg),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => AppTextField(
              controller: _name,
              label: l10n.groupNameLabel,
              hint: l10n.groupNameHint,
              maxLength: 60,
              enabled: !state.submitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canSubmit(state) ? _submit() : null,
            ),
          ),
          const SizedBox(height: QesmaSpacing.lg),
          Text(l10n.groupTypeLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: QesmaSpacing.sm),
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.sm,
            children: [
              for (final type in GroupType.values)
                AppChoiceChip(
                  label: type.label(l10n),
                  icon: type.icon,
                  selected: _type == type,
                  onSelected: state.submitting ? null : (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.lg),
          Text(l10n.groupCurrencyLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: QesmaSpacing.sm),
          AppCard(
            color: context.colors.tint,
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.lock_outline, color: context.colors.textSecondary)),
                const SizedBox(width: QesmaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.groupCurrencyValue, style: theme.textTheme.titleMedium),
                      Text(l10n.groupCurrencyNote, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: QesmaSpacing.lg),
            ErrorBanner(message),
          ],
          const SizedBox(height: QesmaSpacing.lg),
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => AppButton(
              label: l10n.groupCreateButton,
              icon: Icons.add_circle_outline,
              loading: state.submitting,
              onPressed: _canSubmit(state) ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit(CreateGroupState state) => !state.submitting && _name.text.trim().isNotEmpty;
}
