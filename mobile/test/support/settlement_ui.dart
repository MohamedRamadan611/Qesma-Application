import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/router/app_router.dart';

import 'expenses_ui.dart';
import 'fake_balances_server.dart';
import 'fake_expenses_server.dart';

const ar = Locale('ar');
const en = Locale('en');

/// Opens the group home on [tab] ('balances' by default) with the fake server as it is now.
Future<void> openGroupTab(
  WidgetTester tester,
  FakeBalancesServer server, {
  Locale locale = ar,
  double textScale = 1.0,
  double height = 2600,
  String tab = 'balances',
}) async {
  await pumpExpensesApp(tester, server, locale: locale, textScale: textScale, height: height, route: '${Routes.group(server.gid)}?tab=$tab');
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

/// Opens the settlement detail screen.
Future<void> openSettlementDetail(
  WidgetTester tester,
  FakeBalancesServer server,
  String sid, {
  Locale locale = ar,
  double textScale = 1.0,
  double height = 2200,
}) async {
  await pumpExpensesApp(tester, server, locale: locale, textScale: textScale, height: height, route: Routes.settlement(server.gid, sid));
  await tester.pump(const Duration(milliseconds: 10));
  await tester.pumpAndSettle();
}

/// V1 balances with the receiver's handles on the first transfer, as the backend sends them to the payer (B14).
Map<String, dynamic> withHandles(Map<String, dynamic> balances, {String? instapay, String? wallet}) {
  final copy = copyJson(balances);
  final transfers = (copy['transfers'] as List).cast<Map<String, dynamic>>();
  transfers.first['receiverHandles'] = {'instapay': ?instapay, 'wallet': ?wallet};
  return copy;
}

/// Every text written to the clipboard, in order.
List<String> spyClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return copied;
}

/// All the text on screen as one string (for "nothing of this appears" checks).
String allText(WidgetTester tester) => [
      for (final e in find.byType(Text).evaluate()) (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText() ?? '',
      for (final e in find.byType(SelectableText).evaluate()) (e.widget as SelectableText).data ?? '',
    ].join('\n');
