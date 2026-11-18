import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_draft.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/local/calculator/khorouga_calculator.dart';
import 'package:qesma_api/qesma_api.dart';

/// SA11 handoff, end to end without widgets: facade result -> ExpenseDraft -> the add form -> the ExpenseCommand
/// the form would send. Pinned as JSON so a change in any step shows up (A142: EXACT, FUEL/TRANSPORT, driver pays).
const _you = '00000000-0000-4000-8000-0000000000b1';
const _asem = '00000000-0000-4000-8000-0000000000b2';
const _mohsen = '00000000-0000-4000-8000-0000000000b3';
const _members = [_you, _asem, _mohsen];

Object? _commandFor(ExpenseDraft draft) {
  final form = formFromDraft(draft, date: Date(2026, 11, 19));
  final command = buildExpenseCommand(form, edit: false, memberIds: _members);
  expect(command, isNotNull, reason: 'the prefilled form must be saveable as is');
  return commandJson(command!);
}

Object? _golden(String name) => jsonDecode(File('test/features/calculator/goldens/$name').readAsStringSync());

void main() {
  const calc = KhorougaCalculator();

  test('fuel: 100 km at 8.1 L/100km, 13.75 EGP/L, a 25 EGP toll, the driver out (FUEL, driver pays)', () {
    final r = calc.fuel(const FuelInputs(
      distanceTenthsKm: 1000,
      consumptionTenths: 81,
      pricePerLitreMinor: 1375,
      tollsMinor: [2500],
      driver: CalcMember(_you, 1),
      driverIncluded: false,
      passengers: [CalcMember(_asem, 2), CalcMember(_mohsen, 3)],
    )) as CalcResult;
    final json = _commandFor(ExpenseDraft(
      title: 'Fuel, 100 km',
      totalMinor: r.totalMinor,
      category: 'FUEL',
      payerId: r.payerMemberId!,
      exactShares: r.shares,
    ));
    expect(json, _golden('fuel_command.json'));
  });

  test('ride: Asem gets out at stop 2, the others ride on (TRANSPORT, the chosen payer)', () {
    final r = calc.ride(const RideInputs(
      fareMinor: 15000,
      legDistancesTenthsKm: [60, 40],
      riders: [
        CalcRider(CalcMember(_you, 1), boardStop: 0, leaveStop: 2),
        CalcRider(CalcMember(_asem, 2), boardStop: 0, leaveStop: 1),
        CalcRider(CalcMember(_mohsen, 3), boardStop: 0, leaveStop: 2),
      ],
    )) as CalcResult;
    final json = _commandFor(ExpenseDraft(
      title: 'Shared ride',
      totalMinor: r.totalMinor,
      category: 'TRANSPORT',
      payerId: _mohsen,
      exactShares: r.shares,
    ));
    expect(json, _golden('ride_command.json'));
  });
}
