import 'package:flutter/material.dart';
import '../../../core/money/active_currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/features_for_mode.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/create_group_controller.dart';
import '../data/group_type.dart';
import 'group_ui.dart';
import 'member_names_input.dart';
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
  List<String> _members = const [];
  String _currency = kDefaultCurrency;
  bool _pool = false;

  /// The treasurer among the names added here; null = the creator.
  String? _treasurer;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final id = await ref
        .read(createGroupControllerProvider.notifier)
        .submit(name: _name.text.trim(), type: _type.wire, currencyCode: _currency, members: _members, poolOn: _pool, treasurerName: _treasurer);
    if (id == null || !mounted) return;
    final failed = ref.read(createGroupControllerProvider).failedMemberNames;
    if (ref.read(createGroupControllerProvider).treasurerFailed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupPoolSetFailed)));
    }
    if (failed.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.groupMembersPartialFail(failed.length))),
      );
    }
    context.go(Routes.group(id));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.groupCreateSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
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
                    onSelected: state.submitting
                        ? null
                        : (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: QesmaSpacing.lg),
            Text(l10n.groupCurrencyLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: QesmaSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              isExpanded: true,
              decoration: InputDecoration(helperText: l10n.groupCurrencyNote, helperMaxLines: 2),
              items: [
                for (final c in kCurrencyOptions)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.name(Localizations.localeOf(context).languageCode == 'ar')} (${c.code})', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: state.submitting ? null : (value) => setState(() => _currency = value ?? kDefaultCurrency),
            ),
            const SizedBox(height: QesmaSpacing.lg),
            MemberNamesInput(
              names: _members,
              enabled: !state.submitting,
              onChanged: (names) => setState(() {
                _members = names;
                if (_treasurer != null && !names.contains(_treasurer)) _treasurer = null;
              }),
            ),
            if (ref.watch(modeFeaturesProvider).pool) ...[
              const SizedBox(height: QesmaSpacing.md),
              SwitchListTile.adaptive(
                value: _pool,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.groupPoolToggle),
                subtitle: Text(l10n.groupPoolToggleHint),
                onChanged: state.submitting ? null : (v) => setState(() => _pool = v),
              ),
              if (_pool) ...[
                Text(l10n.groupPoolWho, style: theme.textTheme.labelLarge),
                const SizedBox(height: QesmaSpacing.sm),
                Wrap(
                  spacing: QesmaSpacing.sm,
                  runSpacing: QesmaSpacing.sm,
                  children: [
                    AppChoiceChip(
                      label: l10n.groupPoolMe,
                      icon: Icons.person_outline,
                      selected: _treasurer == null,
                      onSelected: state.submitting ? null : (_) => setState(() => _treasurer = null),
                    ),
                    for (final n in _members)
                      AppChoiceChip(
                        label: n,
                        icon: Icons.person_outline,
                        selected: _treasurer == n,
                        onSelected: state.submitting ? null : (_) => setState(() => _treasurer = n),
                      ),
                  ],
                ),
              ],
            ],
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
      ),
    );
  }

  bool _canSubmit(CreateGroupState state) =>
      !state.submitting && _name.text.trim().isNotEmpty;
}
