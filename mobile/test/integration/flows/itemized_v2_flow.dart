import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma_api/qesma_api.dart';

/// SA15 conformance (BSA2 contract, STANDALONE_SPEC 18, A171-A177): one validation matrix and one valid v2 bill, run
/// unchanged against the real Java backend (`../itemized_v2_flow_test.dart`, with `API_BASE_URL`) and against
/// `LocalBackend` (`test/local/conformance/`). Both must give the same status and `code` for every row, and the
/// preview of the valid bill must equal what create saves.
Future<void> runItemizedV2Flow(ProviderContainer container) async {
  final api = container.read(qesmaApiProvider);
  final expenses = api.getExpenseControllerApi();
  final group = (await api.getGroupControllerApi().createGroup(
        createGroupRequest: CreateGroupRequest((b) => b
          ..name = 'SA15 v2'
          ..type = 'OUTING'
          ..currencyCode = 'EGP'),
      ))
      .data!;
  final gid = group.id;
  final you = group.yourMemberId;
  final ali = (await api
          .getMemberControllerApi()
          .addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Ali')))
      .data!
      .id;

  ItemInput unit(String name, int unitAmount, {int? quantity, List<String>? to}) => ItemInput((b) => b
    ..name = name
    ..unitAmountMinor = unitAmount
    ..quantity = quantity
    ..assigneeMemberIds = ListBuilder(to ?? [you, ali]));
  ItemInput legacy(String name, int amount) => ItemInput((b) => b
    ..name = name
    ..amountMinor = amount
    ..assigneeMemberIds = ListBuilder([you, ali]));

  ExpenseCommand bill(
    List<ItemInput> items, {
    DiscountInput? discount,
    ServiceInput? service,
    TaxInput? tax,
    String splitType = 'ITEMIZED',
    int? payerAmount,
  }) =>
      ExpenseCommand((b) {
        b
          ..title = 'Koshary'
          ..expenseDate = Date(2026, 11, 20)
          ..splitType = splitType
          ..items = splitType == 'ITEMIZED' ? ListBuilder(items) : null
          ..discount = discount?.toBuilder()
          ..service = service?.toBuilder()
          ..tax = tax?.toBuilder();
        if (splitType != 'ITEMIZED') b.totalMinor = 10000;
        if (payerAmount != null) {
          b.payers = ListBuilder([
            PayerInput((p) => p
              ..memberId = you
              ..amountMinor = payerAmount),
          ]);
        }
      });
  DiscountInput discountBps(int bps) => DiscountInput((b) => b.bps = bps);
  DiscountInput discountAmount(int amount) => DiscountInput((b) => b.amountMinor = amount);

  // Every row is refused with 422 VALIDATION_ERROR by both backends (V15, V16 and the A177 ranges).
  final meal = [legacy('Meal', 10000)];
  final refused = <String, ExpenseCommand>{
    'item with both amountMinor and unitAmountMinor (V16)': bill([
      ItemInput((b) => b
        ..name = 'Both'
        ..amountMinor = 1000
        ..unitAmountMinor = 1000
        ..assigneeMemberIds = ListBuilder([you])),
    ]),
    'item with neither amountMinor nor unitAmountMinor': bill([
      ItemInput((b) => b
        ..name = 'None'
        ..assigneeMemberIds = ListBuilder([you])),
    ]),
    'quantity with a legacy amountMinor': bill([
      ItemInput((b) => b
        ..name = 'Mixed'
        ..amountMinor = 1000
        ..quantity = 2
        ..assigneeMemberIds = ListBuilder([you])),
    ]),
    'quantity 0 (V16)': bill([unit('Zero', 1000, quantity: 0)]),
    'quantity 1000 (V16)': bill([unit('Many', 1, quantity: 1000)]),
    'unit price 0': bill([unit('Free', 0, quantity: 2)]),
    'line above 10^12': bill([unit('Yacht', 1000000000000, quantity: 2)]),
    'discount equal to the subtotal (V15)': bill(meal, discount: discountAmount(10000)),
    'discount of 100% (V15)': bill(meal, discount: discountBps(10000)),
    'discount of 0%': bill(meal, discount: discountBps(0)),
    'discount amount 0': bill(meal, discount: discountAmount(0)),
    'percent discount that rounds to 0 piasters': bill([legacy('Gum', 10)], discount: discountBps(1)),
    'discount with both forms': bill(meal, discount: DiscountInput((b) => b
      ..bps = 1000
      ..amountMinor = 500)),
    'discount with neither form': bill(meal, discount: DiscountInput()),
    'service with both forms': bill(meal, service: ServiceInput((b) => b
      ..bps = 1200
      ..amountMinor = 500)),
    'service with neither form': bill(meal, service: ServiceInput()),
    'service amount 0': bill(meal, service: ServiceInput((b) => b.amountMinor = 0)),
    'service amount above 10^12': bill(meal, service: ServiceInput((b) => b.amountMinor = 1000000000001)),
    'tax with both forms': bill(meal, tax: TaxInput((b) => b
      ..bps = 1400
      ..amountMinor = 500)),
    'tax amount 0': bill(meal, tax: TaxInput((b) => b.amountMinor = 0)),
    'discount on an EQUAL expense': bill(const [], splitType: 'EQUAL', discount: discountBps(1000), payerAmount: 10000),
  };
  for (final row in refused.entries) {
    ApiFailure? failure;
    try {
      await expenses.previewExpense(gid: gid, expenseCommand: row.value);
    } catch (e) {
      failure = mapApiError(e);
    }
    expect(failure, isA<ApiHttpFailure>().having((f) => f.status, 'status', 422), reason: 'preview: ${row.key}');
    expect(failure?.problem?.code, ApiErrorCode.validationError, reason: 'preview: ${row.key}');
  }

  // A valid v2 bill: 3 x Pepsi 15.25 (both), 1 x Shawarma 85.00 (you), discount 10%, service 10.00 (amount), tax 14%
  // on the subtotal. Its preview is exactly what create saves (one code path), and GET returns the request's forms.
  final v2Items = [unit('Pepsi', 1525, quantity: 3), unit('Shawarma', 8500, to: [you])];
  ExpenseCommand v2([int? payer]) => bill(v2Items,
      discount: discountBps(1000),
      service: ServiceInput((b) => b.amountMinor = 1000),
      tax: TaxInput((b) => b
        ..bps = 1400
        ..base_ = 'SUBTOTAL'),
      payerAmount: payer);
  final preview = (await expenses.previewExpense(gid: gid, expenseCommand: v2())).data!;
  expect((preview.subtotalMinor, preview.discountMinor, preview.serviceMinor), (13075, 1308, 1000));
  expect(preview.totalMinor, 13075 - 1308 + 1000 + preview.taxMinor!);
  expect(preview.members.fold<int>(0, (a, m) => a + m.owedMinor), preview.totalMinor);
  expect(preview.members.fold<int>(0, (a, m) => a + m.discountMinor!), 1308);

  final created = (await expenses.createExpense(
    gid: gid,
    idempotencyKey: '5a150000-0000-4000-8000-${DateTime.now().microsecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}',
    expenseCommand: v2(preview.totalMinor),
  ))
      .data!;
  expect(created.totalMinor, preview.totalMinor);
  expect([for (final s in created.shares) (s.memberId, s.owedMinor, s.discountMinor, s.serviceMinor, s.taxMinor)],
      [for (final m in preview.members) (m.memberId, m.owedMinor, m.discountMinor, m.serviceMinor, m.taxMinor)]);
  expect([for (final i in created.items!) (i.name, i.quantity, i.unitAmountMinor, i.amountMinor)],
      [('Pepsi', 3, 1525, 4575), ('Shawarma', 1, 8500, 8500)]);
  final charges = created.charges!;
  expect((charges.discount?.bps, charges.discount?.amountMinor), (1000, 1308));
  expect((charges.service?.bps, charges.service?.amountMinor), (null, 1000));
  expect((charges.tax?.bps, charges.tax?.base_), (1400, 'SUBTOTAL'));

  final read = (await expenses.getExpense(gid: gid, eid: created.id)).data!;
  expect(read, created);
}
