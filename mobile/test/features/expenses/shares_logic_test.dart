import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/expenses/application/expense_command_builder.dart';
import 'package:qesma/features/expenses/application/expense_form_prefill.dart';
import 'package:qesma/features/expenses/application/expense_form_state.dart';
import 'package:qesma/features/expenses/application/shares_field_errors.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/fake_expenses_server.dart';

const List<String> _members = [kYou, kAsem, kMohsen];

Map<String, dynamic> _wire(ExpenseCommand command) => (jsonDecode(jsonEncode(commandJson(command))) as Map).cast<String, dynamic>();

ExpenseFormState _form({SharesDraft? shares, String amount = '9000'}) => ExpenseFormState(
      title: 'Rent',
      amountText: amount,
      date: Date(2026, 11, 1),
      singlePayerId: kYou,
      splitMode: SplitMode.shares,
      shares: shares ??
          const SharesDraft(rows: [
            ShareRowDraft(memberId: kYou, units: 2),
            ShareRowDraft(memberId: kAsem, units: 1),
            ShareRowDraft(memberId: kMohsen, units: 1),
          ]),
    );

ApiHttpFailure _failure(String title) => ApiHttpFailure(status: 422, problem: ApiProblem.tryParse({'code': 'VALIDATION_ERROR', 'title': title, 'status': 422}, fallbackStatus: 422));

void main() {
  group('the SHARES request', () {
    test('sends units per person in member order, no period and no presence while the period is off', () {
      final wire = _wire(buildExpenseCommand(_form(), edit: false, memberIds: _members)!);
      expect(wire['splitType'], 'SHARES');
      expect(wire['totalMinor'], 900000);
      expect(wire['shareParticipants'], [
        {'memberId': kYou, 'shareUnits': 2},
        {'memberId': kAsem, 'shareUnits': 1},
        {'memberId': kMohsen, 'shareUnits': 1},
      ]);
      for (final key in ['periodFrom', 'periodTo', 'participantMemberIds', 'shares', 'items']) {
        expect(wire.containsKey(key), isFalse, reason: key);
      }
    });

    test('with a period it sends both dates, and presence only for people who are not there for the whole period', () {
      final shares = SharesDraft(
        periodOn: true,
        periodFrom: Date(2026, 11, 1),
        periodTo: Date(2026, 11, 30),
        rows: [
          const ShareRowDraft(memberId: kYou, units: 2),
          const ShareRowDraft(memberId: kAsem),
          ShareRowDraft(memberId: kMohsen, presentFrom: Date(2026, 11, 12), presentTo: Date(2026, 11, 30)),
        ],
      );
      final wire = _wire(buildExpenseCommand(_form(shares: shares), edit: true, memberIds: _members)!);
      expect(wire['periodFrom'], '2026-11-01');
      expect(wire['periodTo'], '2026-11-30');
      expect(wire['shareParticipants'], [
        {'memberId': kYou, 'shareUnits': 2},
        {'memberId': kAsem, 'shareUnits': 1},
        {'memberId': kMohsen, 'shareUnits': 1, 'presentFrom': '2026-11-12', 'presentTo': '2026-11-30'},
      ]);
      expect(wire.containsKey('participantMemberIds'), isFalse, reason: 'an edit still sends shareParticipants only');
    });

    test('presence is not sent when the period is off, and the order is the group\'s, not the draft\'s', () {
      final shares = SharesDraft(rows: [
        ShareRowDraft(memberId: kMohsen, units: 3, presentFrom: Date(2026, 11, 12), presentTo: Date(2026, 11, 30)),
        const ShareRowDraft(memberId: kYou),
      ]);
      final wire = _wire(buildExpenseCommand(_form(shares: shares), edit: false, memberIds: _members)!);
      expect((wire['shareParticipants'] as List).map((p) => (p as Map)['memberId']), [kYou, kMohsen]);
      expect(jsonEncode(wire), isNot(contains('present')));
    });

    test('a preview goes without a title and payers while they are missing; a save needs them', () {
      final untitled = _form().copyWith(title: '', singlePayerId: kYou);
      expect(buildExpenseCommand(untitled, edit: false, memberIds: _members), isNull);
      expect(buildExpenseCommand(untitled, edit: false, memberIds: _members, preview: true), isNotNull);
    });

    test('nothing is built for an empty list, an out-of-range unit count or a period with one date', () {
      expect(buildExpenseCommand(_form(shares: const SharesDraft()), edit: false, memberIds: _members), isNull);
      expect(buildExpenseCommand(_form(shares: const SharesDraft(rows: [ShareRowDraft(memberId: kYou, units: 101)])), edit: false, memberIds: _members), isNull);
      expect(buildExpenseCommand(_form(shares: SharesDraft(periodOn: true, periodFrom: Date(2026, 11, 1), rows: const [ShareRowDraft(memberId: kYou)])), edit: false, memberIds: _members), isNull);
    });

    test('commandKey does not depend on the order of shareParticipants', () {
      final a = buildExpenseCommand(_form(), edit: false, memberIds: _members)!;
      final reversed = a.rebuild((b) => b.shareParticipants.replace(a.shareParticipants!.toList().reversed));
      expect(commandKey(reversed), commandKey(a));
      final changed = a.rebuild((b) => b.shareParticipants.replace([for (final p in a.shareParticipants!) p.rebuild((x) => x.shareUnits = x.shareUnits! + 1)]));
      expect(commandKey(changed), isNot(commandKey(a)));
    });
  });

  group('the form state', () {
    test('valid needs people, units 1..100 and a complete period; units and dates are not counted or converted', () {
      expect(const SharesDraft().valid(_members), isFalse);
      expect(const SharesDraft(rows: [ShareRowDraft(memberId: kYou, units: 0)]).valid(_members), isFalse);
      expect(const SharesDraft(rows: [ShareRowDraft(memberId: kYou, units: 100)]).valid(_members), isTrue);
      expect(const SharesDraft(rows: [ShareRowDraft(memberId: 'gone')]).valid(_members), isFalse, reason: 'a removed member\'s row is ignored');
      expect(const SharesDraft(periodOn: true, rows: [ShareRowDraft(memberId: kYou)]).valid(_members), isFalse);
    });

    test('changing units, the period or a presence makes the form differ from how it was opened', () {
      final base = _form();
      expect(base.differsFrom(_form()), isFalse);
      expect(base.differsFrom(_form(shares: base.shares.copyWith(rows: [base.shares.rows.first.copyWith(units: 3), ...base.shares.rows.skip(1)]))), isTrue);
      expect(base.differsFrom(_form(shares: base.shares.copyWith(periodOn: true, periodFrom: Date(2026, 11, 1), periodTo: Date(2026, 11, 30)))), isTrue);
    });
  });

  group('opening a saved SHARES expense', () {
    ExpenseView expense({bool period = true}) => expenseFrom({
          ...copyJson(fixtureMap('expense_equal_v2')),
          'splitType': 'SHARES',
          'totalMinor': 900000,
          if (period) 'periodFrom': '2026-11-01',
          if (period) 'periodTo': '2026-11-30',
          'payers': [
            {'memberId': kYou, 'amountMinor': 900000},
          ],
          'shares': [
            {'memberId': kYou, 'owedMinor': 495413, 'shareUnits': 2, if (period) 'presentFrom': '2026-11-01', if (period) 'presentTo': '2026-11-30'},
            {'memberId': kAsem, 'owedMinor': 247706, 'shareUnits': 1, if (period) 'presentFrom': '2026-11-01', if (period) 'presentTo': '2026-11-30'},
            {'memberId': kMohsen, 'owedMinor': 156881, 'shareUnits': 1, if (period) 'presentFrom': '2026-11-12', if (period) 'presentTo': '2026-11-30'},
          ],
        });

    test('units and period are restored; presence equal to the period opens as the full period', () {
      final form = formFromExpense(expense(), memberIds: _members, fallbackPayerId: kYou);
      expect(form.splitMode, SplitMode.shares);
      expect([for (final r in form.shares.rows) r.units], [2, 1, 1]);
      expect(form.shares.periodOn, isTrue);
      expect(form.shares.periodFrom, Date(2026, 11, 1));
      expect(form.shares.rows[0].hasPresence, isFalse);
      expect(form.shares.rows[2].presentFrom, Date(2026, 11, 12));
      expect(form.shares.rows[2].presentTo, Date(2026, 11, 30));
      // And what it sends back is the same question the user would ask again.
      final wire = _wire(buildExpenseCommand(form, edit: true, memberIds: _members)!);
      expect(wire['shareParticipants'], [
        {'memberId': kYou, 'shareUnits': 2},
        {'memberId': kAsem, 'shareUnits': 1},
        {'memberId': kMohsen, 'shareUnits': 1, 'presentFrom': '2026-11-12', 'presentTo': '2026-11-30'},
      ]);
    });

    test('without a period nothing is restored but the units', () {
      final form = formFromExpense(expense(period: false), memberIds: _members, fallbackPayerId: kYou);
      expect(form.shares.periodOn, isFalse);
      expect(form.shares.periodFrom, isNull);
      expect(form.shares.rows.every((r) => !r.hasPresence), isTrue);
    });
  });

  group('field paths of a validation problem', () {
    test('parses the first shares field of the title or the detail', () {
      expect(SharesFieldPath.parse('shareParticipants[1].shareUnits must be between 1 and 100'), const SharesFieldPath(SharesField.shareUnits, 1));
      expect(SharesFieldPath.parse('shareParticipants[0].presentFrom must lie inside the period'), const SharesFieldPath(SharesField.presentFrom, 0));
      expect(SharesFieldPath.parse('shareParticipants[12].presentTo must not be before presentFrom'), const SharesFieldPath(SharesField.presentTo, 12));
      expect(SharesFieldPath.parse('periodTo must not be before periodFrom'), const SharesFieldPath(SharesField.periodTo));
      expect(SharesFieldPath.parse('The period (periodFrom..periodTo) must be at most 366 days')?.isPeriod, isTrue);
      expect(SharesFieldPath.parse('shareParticipants[2].presentFrom/presentTo need periodFrom and periodTo'), const SharesFieldPath(SharesField.presentFrom, 2));
    });

    test('anything else is not a field path', () {
      for (final text in [null, '', 'title is required', 'shareParticipants is required for SHARES expenses', 'shareParticipants[x].shareUnits', 'myperiodFromX']) {
        expect(SharesFieldPath.parse(text), isNull, reason: '$text');
      }
    });

    test('ApiProblem carries it from title or detail', () {
      final fromTitle = ApiProblem.tryParse({'code': 'VALIDATION_ERROR', 'title': 'periodTo must not be before periodFrom', 'status': 422}, fallbackStatus: 422);
      expect(fromTitle!.fieldPath, const SharesFieldPath(SharesField.periodTo));
      final fromDetail = ApiProblem.tryParse({'code': 'VALIDATION_ERROR', 'title': 'Validation failed', 'detail': 'shareParticipants[1].shareUnits must be between 1 and 100', 'status': 422}, fallbackStatus: 422);
      expect(fromDetail!.fieldPath, const SharesFieldPath(SharesField.shareUnits, 1));
      expect(ApiProblem.tryParse({'code': 'NOT_FOUND', 'status': 404}, fallbackStatus: 404)!.fieldPath, isNull);
    });

    test('an index maps to the i-th person in member order; unknown indexes and other failures are ignored', () {
      final errors = sharesFieldErrorsOf([
        _failure('shareParticipants[1].shareUnits must be between 1 and 100'),
        _failure('periodTo must not be before periodFrom'),
        _failure('shareParticipants[9].presentFrom must lie inside the period'),
        const ApiNoConnection(),
        null,
      ], _members);
      expect(errors.byMember, {kAsem: SharesErrorKind.units});
      expect(errors.period, isTrue);
      expect(sharesFieldErrorsOf([_failure('x')], _members).isEmpty, isTrue);
    });
  });
}
