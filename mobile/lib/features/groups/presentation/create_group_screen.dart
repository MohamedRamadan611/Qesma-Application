import 'package:flutter/material.dart';
import '../../../core/money/active_currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/format/clock.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/palette.dart';
import '../../../core/features_for_mode.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/create_group_controller.dart';
import '../data/group_type.dart';
import 'budget_settings_form.dart';
import 'group_type_dropdown.dart';
import 'group_ui.dart';
import 'member_names_input.dart';

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
  _MoneyMode _mode = _MoneyMode.none;

  /// The trip budget form (only used in budget mode). An empty amount is invalid there.
  String _budgetText = '';
  Date? _tripStart;
  Date? _tripEnd;

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
        .submit(name: _name.text.trim(), type: _type.wire, currencyCode: _currency, members: _members,
          poolOn: _mode == _MoneyMode.pool,
          treasurerName: _treasurer,
          budgetMinor: _mode == _MoneyMode.budget ? Money.parse(_budgetText) : null,
          tripStart: _mode == _MoneyMode.budget ? _tripStart : null,
          tripEnd: _mode == _MoneyMode.budget ? _tripEnd : null,
        );
    if (id == null || !mounted) return;
    final failed = ref.read(createGroupControllerProvider).failedMemberNames;
    if (ref.read(createGroupControllerProvider).treasurerFailed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupPoolSetFailed)));
    }
    if (ref.read(createGroupControllerProvider).budgetFailed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupBudgetSetFailed)));
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
    final features = ref.watch(modeFeaturesProvider);

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
            GroupTypeDropdown(value: _type, onChanged: state.submitting ? null : (t) => setState(() => _type = t)),
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
            if (features.pool || features.budget) ...[
              const SizedBox(height: QesmaSpacing.lg),
              // A199: a group has a pool treasurer or a trip budget, never both.
              Text(l10n.groupMoneyModeLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: QesmaSpacing.sm),
              // Vertical stack of selectable cards; the chosen one opens its details right below it.
              _ModeCard(
                icon: Icons.account_balance_wallet_outlined,
                title: l10n.groupMoneyModeNone,
                hint: l10n.groupMoneyModeNoneHint,
                selected: _mode == _MoneyMode.none,
                onTap: state.submitting ? null : () => setState(() => _mode = _MoneyMode.none),
              ),
              if (features.pool) ...[
                const SizedBox(height: QesmaSpacing.sm),
                _ModeCard(
                  icon: Icons.savings_outlined,
                  title: l10n.groupPoolToggle,
                  hint: l10n.groupPoolToggleHint,
                  selected: _mode == _MoneyMode.pool,
                  onTap: state.submitting ? null : () => setState(() => _mode = _MoneyMode.pool),
                  details: _mode == _MoneyMode.pool
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                        )
                      : null,
                ),
              ],
              if (features.budget) ...[
                const SizedBox(height: QesmaSpacing.sm),
                _ModeCard(
                  icon: Icons.trending_up,
                  title: l10n.groupBudgetToggle,
                  hint: l10n.groupBudgetToggleHint,
                  selected: _mode == _MoneyMode.budget,
                  onTap: state.submitting ? null : () => setState(() => _mode = _MoneyMode.budget),
                  details: _mode == _MoneyMode.budget
                      ? BudgetSettingsForm(
                          showHeader: false,
                          amountText: _budgetText,
                          amountInvalid: _budgetInvalid,
                          start: _tripStart,
                          end: _tripEnd,
                          enabled: !state.submitting,
                          onAmount: (text) => setState(() => _budgetText = text),
                          onPick: (start) => _pickTripDate(start: start),
                          onClearDate: (start) => setState(() => start ? _tripStart = null : _tripEnd = null),
                        )
                      : null,
                ),
              ],
              const SizedBox(height: QesmaSpacing.sm),
              Text(l10n.groupMoneyModeLocked, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
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

  bool get _budgetInvalid => _mode == _MoneyMode.budget && _budgetText.trim().isNotEmpty && Money.parse(_budgetText) == null;

  Future<void> _pickTripDate({required bool start}) async {
    final picked = await pickTripDate(
      context,
      today: ref.read(clockProvider)().toDate(),
      current: start ? _tripStart : _tripEnd,
      notBefore: start ? null : _tripStart,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _tripStart = picked;
        if (_tripEnd != null && _tripEnd!.compareTo(picked) < 0) _tripEnd = null;
      } else {
        _tripEnd = picked;
      }
    });
  }

  bool _canSubmit(CreateGroupState state) =>
      !state.submitting &&
      _name.text.trim().isNotEmpty &&
      (_mode != _MoneyMode.budget || (_budgetText.trim().isNotEmpty && !_budgetInvalid));
}

/// A199: what the group's money tracking is. A group has a shared pool or a trip budget, never both.
enum _MoneyMode { none, pool, budget }

/// One selectable option of the money-tracking choice (A199): icon, title and hint, a radio mark, and (when chosen)
/// its details below. One of these is always selected, so the group reads as a radio group.
class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.icon, required this.title, required this.hint, required this.selected, required this.onTap, this.details});

  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final radius = BorderRadius.circular(QesmaRadii.card);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title. $hint',
      onTap: onTap,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer.withValues(alpha: 0.35) : colors.card,
          borderRadius: radius,
          border: Border.all(color: selected ? colors.primary : colors.hairline, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(QesmaSpacing.md),
                  child: Row(
                    children: [
                      Icon(icon, color: selected ? colors.primary : colors.textHelper),
                      const SizedBox(width: QesmaSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: QesmaSpacing.sm),
                      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? colors.primary : colors.textHelper),
                    ],
                  ),
                ),
              ),
              if (details != null)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, 0, QesmaSpacing.md, QesmaSpacing.md),
                  child: details,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
