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
  ..kind = 'PAYMENT'
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
      ..paidFromPool = false
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
            ..amountMinor = i.amountMinor
            ..assigneeMemberIds = ListBuilder(
              (g.assignees.where((a) => a.itemId == i.id).map((a) => a.memberId).toList()
                ..sort((x, y) => order(x).compareTo(order(y)))),
            )),
      ]);
      b.charges = ChargesBuilder()
        ..subtotalMinor = e.subtotalMinor
        ..adjustmentMinor = e.adjustmentMinor
        ..service = e.serviceBps == null
            ? null
            : (ServiceChargeBuilder()
              ..bps = e.serviceBps
              ..amountMinor = e.serviceMinor)
        ..tax = e.taxBps == null
            ? null
            : (TaxChargeBuilder()
              ..bps = e.taxBps
              ..base_ = e.taxBase
              ..amountMinor = e.taxMinor);
    }
  });
}
