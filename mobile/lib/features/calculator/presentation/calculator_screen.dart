import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/format/date_format.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/calculator/calculator_providers.dart';
import '../../../local/calculator/fuel_prices_repository.dart';
import '../../../local/calculator/khorouga_calculator.dart';
import '../../expenses/application/expense_draft.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/calculator_controller.dart';
import '../application/calculator_state.dart';

/// Khorouga calculator (حاسبة البنزين والمشوار, SA11, STANDALONE_SPEC 11): road-trip fuel + tolls, or a shared ride
/// with stops. Every number comes from the local engine through the facade (A149); this screen only shows it.
/// "Create the expense" opens the add-expense form filled in as EXACT; nothing is saved here (A142).
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key, required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final group = ref.watch(groupDetailControllerProvider(gid)).group;
    final s = ref.watch(calculatorControllerProvider(gid));
    final out = ref.watch(calculatorOutputProvider(gid));
    final c = ref.read(calculatorControllerProvider(gid).notifier);

    if (group == null) {
      return AppScaffold(
        title: l10n.calcTitle,
        showBack: true,
        onBack: () => goBackOr(context, Routes.group(gid)),
        body: const SkeletonList(itemCount: 3),
      );
    }

    final result = out.result;
    return AppScaffold(
      title: l10n.calcTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.group(gid)),
      body: ListView(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        children: [
          AppSegmentedTabs(
            items: [AppTabItem(label: l10n.calcTabFuel), AppTabItem(label: l10n.calcTabRide)],
            selectedIndex: s.tab,
            onChanged: c.setTab,
          ),
          const SizedBox(height: QesmaSpacing.md),
          if (s.tab == 0) _FuelInputs(gid: gid, group: group, out: out) else _RideInputs(gid: gid, group: group, out: out),
          const SizedBox(height: QesmaSpacing.lg),
          _ResultCard(group: group, out: out, ride: s.tab == 1),
        ],
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              label: l10n.calcCreateExpense,
              onPressed: result == null || out.payerId == null ? null : () => _create(context, l10n, s, out, result),
            ),
            const SizedBox(height: QesmaSpacing.xs),
            Text(l10n.calcCreateHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _create(BuildContext context, AppLocalizations l10n, CalculatorState s, CalculatorOutput out, CalcResult result) {
    final ride = s.tab == 1;
    final distance = out.distanceTenths ?? 0;
    final draft = ExpenseDraft(
      title: ride
          ? l10n.calcDraftRideTitle
          : distance > 0
              ? l10n.calcDraftFuelTitle(Tenths.format(distance))
              : l10n.calcDraftTollsTitle,
      totalMinor: result.totalMinor,
      category: ride ? 'TRANSPORT' : 'FUEL',
      payerId: out.payerId!,
      exactShares: result.shares,
    );
    context.push(Routes.addExpense(gid), extra: draft);
  }
}

String fuelTypeLabel(AppLocalizations l10n, FuelType type) => switch (type) {
      FuelType.gasoline80 => l10n.calcFuel80,
      FuelType.gasoline92 => l10n.calcFuel92,
      FuelType.gasoline95 => l10n.calcFuel95,
      FuelType.diesel => l10n.calcFuelDiesel,
    };

const _decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

class _FuelInputs extends ConsumerWidget {
  const _FuelInputs({required this.gid, required this.group, required this.out});

  final String gid;
  final GroupDto group;
  final CalculatorOutput out;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = ref.watch(calculatorControllerProvider(gid));
    final c = ref.read(calculatorControllerProvider(gid).notifier);
    final prices = ref.watch(fuelPricesProvider).value ?? const {};
    final saved = prices[s.fuelType];
    final members = calculatorMembers(group);
    final nameOf = memberNameResolver(group, l10n);
    final driver = resolvedDriver(s, group);
    final passengers = resolvedPassengers(s, group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputField(
          key: const ValueKey('calc-distance'),
          initial: s.distanceText,
          label: l10n.calcDistance,
          errorText: out.distanceError ? l10n.calcDistanceError : null,
          onChanged: c.setDistance,
        ),
        const SizedBox(height: QesmaSpacing.sm),
        _InputField(
          key: const ValueKey('calc-consumption'),
          initial: s.consumptionText,
          label: l10n.calcConsumption,
          hint: l10n.calcConsumptionHint,
          errorText: out.consumptionError ? l10n.calcConsumptionError : null,
          onChanged: c.setConsumption,
        ),
        const SizedBox(height: QesmaSpacing.md),
        _SectionLabel(l10n.calcFuelType),
        Wrap(
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            for (final type in FuelType.values)
              AppChoiceChip(label: fuelTypeLabel(l10n, type), selected: s.fuelType == type, onSelected: (_) => c.setFuelType(type)),
          ],
        ),
        const SizedBox(height: QesmaSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                saved == null
                    ? l10n.calcPriceNotSet
                    : l10n.calcPriceSaved(moneyDisplay(l10n, saved.pricePerLitreMinor), ltrIsolate(isoDate(saved.updatedAt))),
                style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper),
              ),
            ),
            TextButton(
              onPressed: () => _editPrice(context, ref, s.fuelType, saved),
              child: Text(saved == null ? l10n.calcPriceSet : l10n.calcPriceEdit),
            ),
          ],
        ),
        const SizedBox(height: QesmaSpacing.md),
        _SectionLabel(l10n.calcTolls),
        for (var i = 0; i < s.tolls.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: _InputField(
                    key: ValueKey('calc-toll-${s.tolls[i].id}'),
                    initial: s.tolls[i].text,
                    label: l10n.calcTollLabel('${i + 1}'),
                    errorText: out.tollErrors.contains(s.tolls[i].id) ? l10n.calcTollError : null,
                    onChanged: (t) => c.setToll(s.tolls[i].id, t),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.calcTollRemove,
                  onPressed: () => c.removeToll(s.tolls[i].id),
                ),
              ],
            ),
          ),
        if (s.tolls.length < CalculatorLimits.maxTolls)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(onPressed: c.addToll, icon: const Icon(Icons.add), label: Text(l10n.calcTollAdd)),
          ),
        const SizedBox(height: QesmaSpacing.md),
        _SectionLabel(l10n.calcDriver),
        Wrap(
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            for (final m in members)
              AppChoiceChip(label: nameOf(m.id), selected: driver == m.id, onSelected: (_) => c.setDriver(m.id)),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.calcDriverShares),
          value: s.driverIncluded,
          onChanged: c.setDriverIncluded,
        ),
        _SectionLabel(l10n.calcPassengers),
        Wrap(
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            for (final m in members)
              if (m.id != driver)
                AppChoiceChip(label: nameOf(m.id), selected: passengers.contains(m.id), onSelected: (_) => c.togglePassenger(m.id)),
          ],
        ),
      ],
    );
  }

  Future<void> _editPrice(BuildContext context, WidgetRef ref, FuelType type, SavedFuelPrice? saved) async {
    final l10n = AppLocalizations.of(context);
    final price = await showDialog<int>(
      context: context,
      builder: (_) => _PriceDialog(
        title: l10n.calcPriceDialogTitle(fuelTypeLabel(l10n, type)),
        initial: saved == null ? '' : Money.formatPlain(saved.pricePerLitreMinor),
      ),
    );
    if (price != null) await ref.read(fuelPricesRepositoryProvider).save(type, price);
  }
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final _text = TextEditingController(text: widget.initial);
  bool _showError = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  int? get _price {
    final minor = Money.parse(_text.text);
    return minor == null || minor > CalculatorLimits.maxPricePerLitreMinor ? null : minor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.calcPriceDialogHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: QesmaSpacing.sm),
            AppTextField(
              controller: _text,
              label: l10n.calcPriceEdit,
              autofocus: true,
              keyboardType: _decimalKeyboard,
              errorText: _showError ? l10n.calcPriceError : null,
              onChanged: (_) => setState(() => _showError = false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        TextButton(
          onPressed: () {
            final price = _price;
            if (price == null) {
              setState(() => _showError = true);
            } else {
              Navigator.of(context).pop(price);
            }
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _RideInputs extends ConsumerWidget {
  const _RideInputs({required this.gid, required this.group, required this.out});

  final String gid;
  final GroupDto group;
  final CalculatorOutput out;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(calculatorControllerProvider(gid));
    final c = ref.read(calculatorControllerProvider(gid).notifier);
    final members = calculatorMembers(group);
    final nameOf = memberNameResolver(group, l10n);
    final payer = resolvedFarePayer(s, group);
    final riders = resolvedRiders(s, members);
    final legs = s.legTexts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputField(
          key: const ValueKey('calc-fare'),
          initial: s.fareText,
          label: l10n.calcFare,
          errorText: out.fareError ? l10n.expenseFormAmountInvalid : null,
          onChanged: c.setFare,
        ),
        const SizedBox(height: QesmaSpacing.md),
        _SectionLabel(l10n.calcFarePayer),
        Wrap(
          spacing: QesmaSpacing.sm,
          runSpacing: QesmaSpacing.xs,
          children: [
            for (final m in members)
              AppChoiceChip(label: nameOf(m.id), selected: payer == m.id, onSelected: (_) => c.setFarePayer(m.id)),
          ],
        ),
        const SizedBox(height: QesmaSpacing.md),
        _SectionLabel(l10n.calcStops),
        for (var i = 0; i < legs; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
            child: _InputField(
              key: ValueKey('calc-leg-$i'),
              initial: s.legTexts[i],
              label: l10n.calcLegDistance('${i + 1}', '${i + 2}'),
              errorText: out.legErrors.contains(i) ? l10n.calcDistanceError : null,
              onChanged: (t) => c.setLeg(i, t),
            ),
          ),
        Wrap(
          spacing: QesmaSpacing.sm,
          children: [
            if (legs < CalculatorLimits.maxLegs)
              TextButton.icon(onPressed: c.addStop, icon: const Icon(Icons.add), label: Text(l10n.calcStopAdd)),
            if (legs > 1)
              TextButton.icon(onPressed: c.removeStop, icon: const Icon(Icons.remove), label: Text(l10n.calcStopRemove)),
          ],
        ),
        const SizedBox(height: QesmaSpacing.md),
        _SectionLabel(l10n.calcRiders),
        for (final m in members) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppChoiceChip(label: nameOf(m.id), selected: riders.containsKey(m.id), onSelected: (_) => c.toggleRider(m.id)),
          ),
          if (riders[m.id] case final stops?)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: QesmaSpacing.md, bottom: QesmaSpacing.sm),
              child: Wrap(
                spacing: QesmaSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StopPicker(
                    label: l10n.calcGetsIn,
                    value: stops.boardStop,
                    stops: [for (var i = 0; i < legs; i++) i],
                    onChanged: (v) => c.setRiderStops(m.id, board: v),
                  ),
                  _StopPicker(
                    label: l10n.calcGetsOut,
                    value: stops.leaveStop,
                    stops: [for (var i = 1; i <= legs; i++) i],
                    onChanged: (v) => c.setRiderStops(m.id, leave: v),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _StopPicker extends StatelessWidget {
  const _StopPicker({required this.label, required this.value, required this.stops, required this.onChanged});

  final String label;
  final int value;
  final List<int> stops;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: QesmaSpacing.xs),
        DropdownButton<int>(
          value: stops.contains(value) ? value : null,
          items: [for (final s in stops) DropdownMenuItem(value: s, child: Text(l10n.calcStopName('${s + 1}')))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.group, required this.out, required this.ride});

  final GroupDto group;
  final CalculatorOutput out;
  final bool ride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final outcome = out.outcome;
    if (outcome == null) {
      if (ride) return const SizedBox.shrink();
      return Text(l10n.calcErrorZero, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper));
    }
    if (outcome is CalcInvalid) {
      final message = switch (outcome.reason) {
        CalcInvalidReason.noSharers => l10n.calcErrorNoSharers,
        CalcInvalidReason.legsWithoutRiders => l10n.calcErrorEmptyLeg('${outcome.legs.first + 1}', '${outcome.legs.first + 2}'),
        CalcInvalidReason.zeroTotal => l10n.calcErrorZero,
        CalcInvalidReason.totalTooLarge => l10n.calcErrorTooLarge,
        CalcInvalidReason.outOfRange => l10n.calcErrorRange,
      };
      return Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))),
          ],
        ),
      );
    }
    final r = outcome as CalcResult;
    final nameOf = memberNameResolver(group, l10n);
    final legFares = r.legFaresMinor ?? const <int>[];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.calcResultTitle, style: theme.textTheme.titleMedium)),
          const SizedBox(height: QesmaSpacing.sm),
          if (r.fuelMinor != null) _Line(label: l10n.calcFuelCost, minor: r.fuelMinor!),
          if ((r.tollsMinor ?? 0) > 0) _Line(label: l10n.calcTollsCost, minor: r.tollsMinor!),
          for (var i = 0; i < legFares.length; i++) _Line(label: l10n.calcLegFare('${i + 1}', '${i + 2}'), minor: legFares[i]),
          _Line(label: l10n.calcTotal, minor: r.totalMinor, strong: true),
          const Divider(height: QesmaSpacing.lg),
          for (final e in r.shares.entries) _Line(label: nameOf(e.key), minor: e.value),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.minor, this.strong = false});

  final String label;
  final int minor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: strong ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)),
          const SizedBox(width: QesmaSpacing.sm),
          MoneyText(minor),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: QesmaSpacing.xs),
        child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.labelLarge)),
      );
}

/// A text field that owns its controller (the typed text lives in the calculator state).
class _InputField extends StatefulWidget {
  const _InputField({super.key, required this.initial, required this.label, required this.onChanged, this.hint, this.errorText});

  final String initial;
  final String label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
        controller: _controller,
        label: widget.label,
        hint: widget.hint,
        errorText: widget.errorText,
        keyboardType: _decimalKeyboard,
        showClear: false,
        onChanged: widget.onChanged,
      );
}
