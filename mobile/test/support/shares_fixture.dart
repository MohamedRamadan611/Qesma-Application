import 'expense_form_rig.dart';
import 'fake_expenses_server.dart';

/// A saved SHARES expense (BSA3): rent for November, units 2/1/1, the third person present from 12 Nov. The saved amounts are
/// real engine numbers (V23). (The fake server's own preview uses its distinctive per-unit amount.)
Map<String, dynamic> sharesExpenseJson() => {
      ...copyJson(fixtureMap('expense_equal_v2')),
      'id': 'shares-1',
      'title': 'Rent',
      'splitType': 'SHARES',
      'category': 'OTHER',
      'paidFromPool': false,
      'totalMinor': 900000,
      'expenseDate': '2026-11-01',
      'periodFrom': '2026-11-01',
      'periodTo': '2026-11-30',
      'version': 1,
      'payers': [
        {'memberId': kYou, 'amountMinor': 900000},
      ],
      'shares': [
        {'memberId': kYou, 'owedMinor': 495413, 'shareUnits': 2, 'presentFrom': '2026-11-01', 'presentTo': '2026-11-30'},
        {'memberId': kAsem, 'owedMinor': 247706, 'shareUnits': 1, 'presentFrom': '2026-11-01', 'presentTo': '2026-11-30'},
        {'memberId': kMohsen, 'owedMinor': 156881, 'shareUnits': 1, 'presentFrom': '2026-11-12', 'presentTo': '2026-11-30'},
      ],
    };
