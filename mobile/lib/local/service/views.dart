import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:qesma_api/qesma_api.dart';

import '../db/daos/expenses_dao.dart';
import '../db/local_database.dart';

/// Rows -> the generated `qesma_api` DTOs, so every response is built from the same contract the client decodes
/// (STANDALONE_SPEC 3.1). Timestamps are stored as UTC epoch milliseconds (A151) and shown as ISO-8601 UTC.

DateTime utc(int millis) => DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

Date dateOf(String isoDate) {
  final p = isoDate.split('-');
  return Date(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// The JSON value of a DTO, encoded by the generated serializers (null fields are omitted, as the client expects).
Object? toJsonValue<T>(Serializer<T> serializer, T value) => standardSerializers.serializeWith(serializer, value);

/// Text form of [toJsonValue], used for stored revision snapshots and idempotent responses.
String toJsonText<T>(Serializer<T> serializer, T value) => jsonEncode(toJsonValue(serializer, value));

T fromJsonText<T extends Object>(Serializer<T> serializer, String text) =>
    standardSerializers.deserializeWith(serializer, jsonDecode(text)) as T;

UserDto userDto(LocalProfileRow p) => UserDto((b) => b
  ..id = p.id
  ..displayName = p.displayName
  ..emailVerified = false
  ..hasPassword = false
  ..notificationsEnabled = false);

MemberDto memberDto(MemberRow m, String profileId) => MemberDto((b) => b
  ..id = m.id
  ..displayName = m.displayName
  ..sortOrder = m.sortOrder
  ..createdAt = utc(m.createdAt)
  ..isYou = m.userId == profileId
  ..role = m.role
  ..status = m.status
  ..hasAccount = m.userId != null);

SettlementView settlementView(SettlementRow s) => SettlementView((b) => b
  ..id = s.id
  ..groupId = s.groupId
  ..fromMemberId = s.fromMemberId
  ..toMemberId = s.toMemberId
  ..amountMinor = s.amountMinor
  ..settledOn = dateOf(s.settledOn)
  ..note = s.note
  ..createdAt = utc(s.createdAt)
  ..status = s.status
  ..kind = s.kind
  ..recordedByAdmin = s.recordedByAdmin == 1
  ..createdByMemberId = s.createdByMemberId
  ..declaredAt = utc(s.declaredAt)
  ..confirmedAt = s.confirmedAt == null ? null : utc(s.confirmedAt!)
  ..disputedAt = s.disputedAt == null ? null : utc(s.disputedAt!)
  ..cancelledAt = s.cancelledAt == null ? null : utc(s.cancelledAt!));

/// An expense as GET shows it: payers, shares and assignees in member sortOrder (unknown ids last), items in the
/// order the client sent them; `items` and `charges` only for ITEMIZED (Java `PageMapper.view`).
ExpenseView expenseView(ExpenseGraph g, Map<String, int> sortOrders) {
  final e = g.expense;
  int order(String memberId) => sortOrders[memberId] ?? 0x7FFFFFFF;
  final payers = [...g.payers]..sort((a, b) => order(a.memberId).compareTo(order(b.memberId)));
  final splits = [...g.splits]..sort((a, b) => order(a.memberId).compareTo(order(b.memberId)));
  final itemized = e.splitType == 'ITEMIZED';
  return ExpenseView((b) {
    b
      ..id = e.id
      ..groupId = e.groupId
      ..title = e.title
      ..splitType = e.splitType
      ..totalMinor = e.totalMinor
      ..expenseDate = dateOf(e.expenseDate)
      ..createdAt = utc(e.createdAt)
      ..version = e.version
      ..category = e.category
      ..paidFromPool = e.paidFromPool == 1
      ..payers = ListBuilder([
        for (final p in payers)
          PayerView((v) => v
            ..memberId = p.memberId
            ..amountMinor = p.amountMinor),
      ])
      ..shares = ListBuilder([
        for (final s in splits)
          ShareView((v) => v
            ..memberId = s.memberId
            ..owedMinor = s.owedMinor
            ..itemsMinor = s.itemsMinor
            ..discountMinor = s.discountMinor
            ..serviceMinor = s.serviceMinor
            ..taxMinor = s.taxMinor
            ..adjustmentMinor = s.adjustmentMinor),
      ]);
    if (itemized) {
      final items = [...g.items]..sort((a, c) => a.sortOrder.compareTo(c.sortOrder));
      b.items = ListBuilder([
        for (final i in items)
          ItemView((v) => v
            ..id = i.id
            ..name = i.name
            ..quantity = i.quantity
            ..unitAmountMinor = i.unitAmountMinor
            ..amountMinor = i.amountMinor
            ..assigneeMemberIds = ListBuilder(
              (g.assignees.where((a) => a.itemId == i.id).map((a) => a.memberId).toList()
                ..sort((x, y) => order(x).compareTo(order(y)))),
            )),
      ]);
      b.charges = ChargesBuilder()
        ..subtotalMinor = e.subtotalMinor
        ..adjustmentMinor = e.adjustmentMinor
        // A charge is shown when either form is set; bps is null in the amount form and amountMinor is the
        // computed total (A177).
        ..discount = e.discountBps == null && e.discountAmountMinor == null
            ? null
            : (DiscountChargeBuilder()
              ..bps = e.discountBps
              ..amountMinor = e.discountMinor)
        ..service = e.serviceBps == null && e.serviceAmountMinor == null
            ? null
            : (ServiceChargeBuilder()
              ..bps = e.serviceBps
              ..amountMinor = e.serviceMinor)
        ..tax = e.taxBps == null && e.taxAmountMinor == null
            ? null
            : (TaxChargeBuilder()
              ..bps = e.taxBps
              ..base_ = e.taxBase
              ..amountMinor = e.taxMinor);
    }
  });
}

/// Port of Java `ExpenseService.upgradeSnapshot` (A177): an ExpenseView JSON written before SA15 lacks the itemized
/// v2 fields. A missing item `quantity` reads as 1 with `unitAmountMinor` = `amountMinor`; a missing share
/// `discountMinor` reads as 0 for an itemized share (it has `itemsMinor`) and stays absent otherwise; a missing
/// `charges.discount` stays absent (no discount existed). Used on revision snapshots and replayed create responses;
/// the stored text is never rewritten. Anything that is not an object is returned unchanged.
String upgradeExpenseJsonText(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException {
    return text;
  }
  if (root is! Map<String, dynamic>) return text;
  var changed = false;
  for (final item in (root['items'] as List<dynamic>?) ?? const <dynamic>[]) {
    if (item is Map<String, dynamic> && !item.containsKey('quantity')) {
      item['quantity'] = 1;
      item['unitAmountMinor'] = item['amountMinor'];
      changed = true;
    }
  }
  for (final share in (root['shares'] as List<dynamic>?) ?? const <dynamic>[]) {
    if (share is Map<String, dynamic> && !share.containsKey('discountMinor') && share['itemsMinor'] != null) {
      share['discountMinor'] = 0;
      changed = true;
    }
  }
  return changed ? jsonEncode(root) : text;
}
