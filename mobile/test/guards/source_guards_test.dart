import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source guards (SCREEN_MAP rules 2, 3, 8, 9). They scan `lib/` and fail the build with
/// the offending file:line, so a violation cannot be merged by accident.
///
/// Excluded from every guard: generated code (`lib/core/l10n/generated`).
/// `core/money` is the only place allowed to do money arithmetic. `lib/local/db/` (drift persistence, SA2) and
/// `lib/local/service/` (local backend services, SA3: money only through qesma_engine calls and plain sums of
/// stored amounts) are exempt from the rounding scan only; `double`/`num` stay banned there.
/// `core/theme` and `core/widgets` may use `double` (pixel sizes) but nothing money-related.

List<File> _dartFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) => !_rel(f).startsWith('lib/core/l10n/generated/'))
    .toList();

String _rel(File f) => f.path.replaceAll('\\', '/');

/// Source lines without comments and string contents' effect on the patterns below.
Iterable<MapEntry<int, String>> _codeLines(File file) sync* {
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith('//') || line.startsWith('///') || line.startsWith('*')) continue;
    yield MapEntry(i + 1, line);
  }
}

List<String> _scan(
  RegExp pattern, {
  bool Function(String path)? skip,
}) {
  final hits = <String>[];
  for (final file in _dartFiles()) {
    final path = _rel(file);
    if (skip != null && skip(path)) continue;
    for (final line in _codeLines(file)) {
      if (pattern.hasMatch(line.value)) hits.add('$path:${line.key}: ${line.value}');
    }
  }
  return hits;
}

void main() {
  _fl14TimeGuard();
  _sa10PoolGuard();
  _sa16ItemizedGuard();
  _sa17ReceiptScanGuard();
  _sa19SharesGuard();
  _sa20BudgetGuard();
  test('no money arithmetic or floating point outside core/money', () {
    final hits = <String>[
      // Floating point types and conversions: allowed only for pixel sizes in theme/widgets.
      ..._scan(
        RegExp(r'\b(double|num)\b|\.toDouble\(|double\.parse|double\.tryParse'),
        skip: (p) => p.startsWith('lib/core/money/') || p.startsWith('lib/core/theme/') || p.startsWith('lib/core/widgets/'),
      ),
      // The classic piaster/EGP conversions and rounding, allowed nowhere but core/money and the local
      // persistence layer (SA2, STANDALONE_SPEC 15.2: it stores amounts, it does not compute them).
      // double/num above stay banned in lib/local/.
      ..._scan(
        RegExp(r'[/*]\s*100\b|~/\s*100\b|\.round\(\)|\.floor\(\)|\.ceil\(\)|\.truncate\(\)|\.toStringAsFixed\('),
        skip: (p) => p.startsWith('lib/core/money/') || p.startsWith('lib/local/db/') || p.startsWith('lib/local/service/'),
      ),
    ];
    expect(hits, isEmpty, reason: 'Money is int piasters; use core/money (parse/format) or ask the backend.\n${hits.join('\n')}');
  });

  test('no hard-coded user-visible strings (everything comes from the ARB files)', () {
    // Text('literal'), SelectableText('literal') and the usual named text parameters with a letter inside.
    final letters = r'[A-Za-z؀-ۿ]';
    final pattern = RegExp(
      "\\b(?:Text|SelectableText)\\(\\s*(?:const\\s+)?r?['\"][^'\"\$]*$letters"
      "|\\b(?:title|label|labelText|hintText|helperText|errorText|tooltip|semanticsLabel|semanticLabel|content)\\s*:\\s*(?:const\\s+)?(?:Text\\()?r?['\"][^'\"\$]*$letters",
    );
    // Only the debug-only catalogue (sample data for design reviews) may hold literal text.
    final hits = _scan(pattern, skip: (p) => p.startsWith('lib/core/widgets/catalogue/'));
    expect(hits, isEmpty, reason: 'Add the string to lib/core/l10n/app_ar.arb and app_en.arb instead.\n${hits.join('\n')}');
  });

  test('the debug-only fake token format appears only in dev_settings.dart', () {
    final hits = _scan(
      RegExp('''['"]fake:'''),
      skip: (p) => p == 'lib/core/api/dev_settings.dart',
    );
    expect(hits, isEmpty, reason: hits.join('\n'));

    final source = File('lib/core/api/dev_settings.dart').readAsStringSync();
    final tokenLine = source.split('\n').firstWhere((l) => l.contains("'fake:"));
    expect(tokenLine, contains('kDebugMode ?'), reason: 'the fake token must be guarded by kDebugMode');
  });

  test('nothing in lib/ logs or prints (use the request logger, which never logs tokens)', () {
    final hits = _scan(
      RegExp(r'\bprint\(|\bdebugPrint\(|\bdeveloper\.log\('),
      // The three debug-only sinks: enums, status codes, request ids and error types only.
      skip: (p) =>
          p == 'lib/core/api/dio_factory.dart' || p == 'lib/core/auth/auth_log.dart' || p == 'lib/local/backend/local_log.dart',
    );
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('no raw colours outside core/theme (use QesmaColors / the ColorScheme)', () {
    final hits = _scan(
      RegExp(r'\bColor\(\s*0x|\bColors\.(?!transparent\b)|\bColor\.fromARGB|\bColor\.fromRGBO'),
      skip: (p) => p.startsWith('lib/core/theme/'),
    );
    expect(
      hits,
      isEmpty,
      reason: 'Define the colour in lib/core/theme/tokens.dart and check its contrast.\n${hits.join('\n')}',
    );
  });

  test('colours come from the theme palette (context.colors), never from QesmaColors, so dark mode reaches every widget', () {
    final hits = _scan(RegExp(r'\bQesmaColors\b'), skip: (p) => p.startsWith('lib/core/theme/'));
    expect(hits, isEmpty, reason: 'Use context.colors.x (lib/core/theme/palette.dart); QesmaColors is the light palette only.\n${hits.join('\n')}');
  });

  test('layout is direction-aware: no physical left/right (RTL must mirror automatically)', () {
    final hits = _scan(
      RegExp(
        r'EdgeInsets\.only\([^)]*\b(left|right)\s*:'
        r'|EdgeInsets\.fromLTRB'
        r'|\bAlignment\.(top|center|bottom)?(Left|Right)\b'
        r'|TextAlign\.(left|right)\b'
        r'|Positioned\([^)]*\b(left|right)\s*:'
        r'|BorderRadius\.only\([^)]*\b(topLeft|topRight|bottomLeft|bottomRight)\b'
        r'|MainAxisAlignment\.(left|right)',
      ),
      skip: (p) => p.startsWith('lib/core/l10n/generated/'),
    );
    expect(
      hits,
      isEmpty,
      reason: 'Use EdgeInsetsDirectional / AlignmentDirectional / TextAlign.start|end.\n${hits.join('\n')}',
    );
  });

  test('the component catalogue exists only in debug builds and is imported by nothing else', () {
    final lines = File('lib/core/router/app_router.dart').readAsLinesSync();
    final routeLine = lines.firstWhere((l) => l.contains('Routes.catalogue') && l.contains('GoRoute('));
    expect(routeLine, contains('if (kDebugMode)'), reason: 'the /_catalog route must be declared under kDebugMode');
    final initialLine = lines.firstWhere((l) => l.contains('_initialRouteDefine.isNotEmpty'));
    expect(initialLine, contains('kDebugMode'), reason: 'INITIAL_ROUTE must be ignored outside debug builds');

    final importers = _scan(
      RegExp(r"import\s+'[^']*catalogue/"),
      skip: (p) => p == 'lib/core/router/app_router.dart',
    );
    expect(importers, isEmpty, reason: importers.join('\n'));
  });

  test('token identifiers stay inside the session code (never in widgets, routes or other features)', () {
    final hits = _scan(
      RegExp(r'\b(accessToken|refreshToken|idToken)\b'),
      skip: (p) => p.startsWith('lib/core/auth/') || p.startsWith('lib/features/auth/application/'),
    );
    expect(hits, isEmpty, reason: 'Only lib/core/auth and lib/features/auth/application may touch tokens.\n${hits.join('\n')}');
  });
  test('qesma_engine is imported only under lib/local/ (A149: features never compute splits or balances)', () {
    final hits = _scan(RegExp(r"import\s+'package:qesma_engine/"), skip: (p) => p.startsWith('lib/local/'));
    expect(hits, isEmpty, reason: 'Reach the engine through the local backend.\n${hits.join('\n')}');
  });

  test('the generated API is used only by repositories and core wiring (widgets and notifiers never touch it)', () {
    final hits = _scan(
      RegExp(r'qesmaApiProvider|authlessApiProvider|get\w+ControllerApi\(\)'),
      skip: (p) => p.startsWith('lib/core/') || p.contains('/data/') || p.startsWith('lib/features/auth/application/'),
    );
    expect(hits, isEmpty, reason: 'Go through a repository in features/*/data.\n${hits.join('\n')}');
  });

  test('the body of an expense is built in ONE place (the command builder), never in widgets or notifiers', () {
    final hits = _scan(
      RegExp(r'\bExpenseCommand\('),
      skip: (p) => p == 'lib/features/expenses/application/expense_command_builder.dart',
    );
    expect(hits, isEmpty, reason: 'Build the request with buildExpenseCommand / buildEqualPreview / buildPayersCheck.\n${hits.join('\n')}');
  });

  test('the body of a payment is built in ONE place (record_payment_state), never in widgets or notifiers', () {
    final hits = _scan(
      RegExp(r'\bSettlementCommand\('),
      skip: (p) => p == 'lib/features/balances/application/record_payment_state.dart',
    );
    expect(hits, isEmpty, reason: 'Build the request with buildSettlementCommand.\n${hits.join('\n')}');
  });

  test('no arithmetic on balances: nets, transfers and payment amounts are shown as the server sent them', () {
    // Sums, differences, products and folds over nets/transfers/amounts would be the client calculating balances.
    final hits = _scan(
      RegExp(
        r'(netMinor|amountMinor|\.nets\b|\.transfers\b)[^;]*(\.fold\(|\.reduce\(|\.sum\b)'
        r'|(netMinor|amountMinor)\s*[-+*/%]\s*[\w(]'
        r'|[\w)]\s*[-+*/%]\s*\w*\.?(netMinor|amountMinor)\b',
      ),
      skip: (p) => !p.startsWith('lib/features/balances/'),
    );
    expect(hits, isEmpty, reason: 'Balances and transfers come only from the endpoint (SCREEN_MAP).\n${hits.join('\n')}');
  });

  // FL13: a pending payment is information next to the server's amount; the client never subtracts it
  // (SCREEN_MAP rule 2, PHASE2_SPEC 6, decision A83).
  final pendingArithmetic = RegExp(
    r'pendingMinor\s*[-+*/%]\s*[\w(]'
    r'|[\w)]\s*[-+*/%]=?\s*\w*\.?pendingMinor\b'
    r'|pendingMinor[^;]*(\.fold\(|\.reduce\(|\.sum\b)'
    r'|\b(amountMinor|netMinor)\b[^;]*\bpendingMinor\b[^;]*[-+]'
    r'|\bpendingMinor\b[^;]*\b(amountMinor|netMinor)\b\s*[-+]',
  );

  test('pendingMinor is never added to or subtracted from anything (shown beside the server amount, never applied to it)', () {
    final hits = _scan(pendingArithmetic);
    expect(hits, isEmpty, reason: 'Pending is informational (A83): the server owns every number.\n${hits.join('\n')}');
  });

  test('the pending arithmetic guard is alive', () {
    for (final bad in [
      'final left = t.amountMinor - t.pendingMinor;',
      'total += t.pendingMinor;',
      't.pendingMinor + 1',
      'items.map((t) => t.pendingMinor).fold(0, (a, b) => a + b)',
    ]) {
      expect(pendingArithmetic.hasMatch(bad), isTrue, reason: bad);
    }
    for (final fine in ['if (transfer.pendingMinor > 0) badge()', 'moneyDisplay(l10n, transfer.pendingMinor)']) {
      expect(pendingArithmetic.hasMatch(fine), isFalse, reason: fine);
    }
  });

  test('no analytics, tracking or crash SDKs and no extra preference/connectivity/version packages (FL8 constraint)', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final deps = pubspec.split('dev_dependencies:').first;
    for (final banned in ['analytics', 'sentry', 'crashlytics', 'amplitude', 'mixpanel', 'shared_preferences', 'connectivity_plus', 'package_info_plus']) {
      expect(deps.contains(banned), isFalse, reason: 'pubspec depends on $banned');
    }
  });

  test('Firebase is limited to exactly firebase_core, firebase_ai and firebase_app_check (ADR-012, SA12)', () {
    final deps = File('pubspec.yaml').readAsStringSync().split('dev_dependencies:').first;
    final firebase = RegExp(r'^\s*(firebase\w*):', multiLine: true).allMatches(deps).map((m) => m.group(1)).toSet();
    expect(firebase, {'firebase_core', 'firebase_ai', 'firebase_app_check'});
  });

  test('Firebase and image_picker are imported only by the receipt scan (and main for startup)', () {
    final hits = _scan(
      RegExp(r"import 'package:(firebase\w*|image_picker)/"),
      skip: (p) => p.startsWith('lib/features/receipt_scan/'),
    );
    expect(hits, isEmpty, reason: 'only lib/features/receipt_scan may import Firebase or image_picker:\n${hits.join('\n')}');
  });

  test('the receipt scan writes no file: the photo lives in memory and the picker copy is deleted (SA12)', () {
    final hits = <String>[];
    for (final file in Directory('lib/features/receipt_scan').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final line in _codeLines(file)) {
        if (RegExp(r'writeAsBytes|writeAsString|openWrite|\.copy\(|getApplicationDocumentsDirectory|getExternalStorage|ImageGallerySaver').hasMatch(line.value)) {
          hits.add('${_rel(file)}:${line.key}: ${line.value}');
        }
      }
    }
    expect(hits, isEmpty, reason: 'the image must never be stored:\n${hits.join('\n')}');
  });

  test('Android auto-backup is on and limited to the local database file (A128, replaces the FL2 allowBackup=false rule)', () {
    final main = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(main, contains('android:allowBackup="true"'));
    expect(main, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(main, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
    final dbName = RegExp("localDatabaseFileName = '([^']+)'").firstMatch(File('lib/local/db/local_database_provider.dart').readAsStringSync())!.group(1)!;
    for (final rules in ['backup_rules.xml', 'data_extraction_rules.xml']) {
      final xml = File('android/app/src/main/res/xml/$rules').readAsStringSync();
      expect(xml, contains('<include domain="root" path="app_flutter/$dbName"/>'), reason: rules);
      // The only include is the database file; the WAL side files and secure storage are excluded explicitly.
      expect(RegExp('<include ').allMatches(xml).length, rules == 'backup_rules.xml' ? 1 : 2, reason: rules);
      expect(xml, contains('path="app_flutter/$dbName-wal"'), reason: rules);
      expect(xml, contains('FlutterSecureStorage.xml'), reason: rules);
    }
  });

  test('the Android release manifest has no cleartext, no emulator host and no fake token', () {
    final main = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(main, isNot(contains('usesCleartextTraffic')));
    expect(main, isNot(contains('networkSecurityConfig')));
    expect(main, isNot(contains('10.0.2.2')));
    expect(main, contains('android.permission.INTERNET'));

    final debug = File('android/app/src/debug/res/xml/network_security_config.xml').readAsStringSync();
    expect(debug, contains('10.0.2.2'));
    expect(File('android/app/src/main/res/xml/network_security_config.xml').existsSync(), isFalse,
        reason: 'a network security config in main would apply to release builds');
  });
}

// FL14: Remind is enabled from the server's timestamp (`canRemindAt`, `nextAllowedAt`) and nothing else. The 24-hour window is
// the server's rule: the client must not work out a window, add a duration or take a difference of times.
void _fl14TimeGuard() {
  test('Remind and payment-details code do no date or duration arithmetic and no money arithmetic', () {
    final hits = <String>[];
    for (final file in _dartFiles()) {
      final path = _rel(file);
      final isRemind = path.contains('/remind_') || path == 'lib/features/balances/presentation/transfer_card.dart';
      final isHandles = path.contains('/payment_handles');
      if (!isRemind && !isHandles) continue;
      for (final line in _codeLines(file)) {
        if (RegExp(r'\bDuration\(|\.difference\(|\.subtract\(|\.add\(\s*(const\s+)?Duration|\bhours\s*:|\binHours\b|\b24\b').hasMatch(line.value)) {
          hits.add('$path:${line.key}: ${line.value}');
        }
        if (RegExp(r'\b(amountMinor|pendingMinor|netMinor)\b\s*[-+*/%]|[-+*/%]\s*\w*\.?\b(amountMinor|pendingMinor|netMinor)\b').hasMatch(line.value)) {
          hits.add('$path:${line.key}: ${line.value}');
        }
      }
    }
    expect(hits, isEmpty, reason: 'Compare the server timestamps with now; never derive a window.\n${hits.join('\n')}');
  });

  test('the guard is alive: the Remind files exist and are scanned', () {
    final scanned = _dartFiles().map(_rel).where((p) => p.contains('/remind_') || p.contains('/payment_handles')).toList();
    expect(scanned.length, greaterThanOrEqualTo(4), reason: scanned.join('\n'));
  });
}

// SA10 (STANDALONE_SPEC 10, A136): the pool meter is `GroupDto.poolBalanceMinor`, computed by the backend and never
// stored; deposited and spent come from the local read-model. Widgets never add, subtract or fold them, nor work a
// meter out of deposits or expenses. A negative meter is shown through `Money.magnitude` (core/money).
final _poolArithmetic = RegExp(
  r'\b(poolBalanceMinor|depositedMinor|spentMinor|meterMinor)\b\s*[-+*/%]\s*[\w(]'
  r'|[\w)]\s*[-+*/%]=?\s*\w*\.?\b(poolBalanceMinor|depositedMinor|spentMinor|meterMinor)\b'
  r'|\b(poolBalanceMinor|depositedMinor|spentMinor|deposits|amountMinor)\b[^;]*(\.fold\(|\.reduce\(|\.sum\b)'
  r'|\.abs\(\)',
);

bool _isPoolUi(String path) =>
    path.startsWith('lib/features/pool/') ||
    path == 'lib/features/groups/presentation/edit_group_screen.dart' ||
    path == 'lib/features/groups/presentation/group_home_screen.dart';

void _sa10PoolGuard() {
  test('no arithmetic on the pool meter in the UI: the remaining amount is poolBalanceMinor as the backend sent it', () {
    final hits = _scan(_poolArithmetic, skip: (p) => !_isPoolUi(p));
    expect(hits, isEmpty, reason: 'The meter is computed in lib/local, never in widgets (A136).\n${hits.join('\n')}');
  });

  test('the pool guard is alive: the pool files are scanned and the pattern catches a widget-side meter', () {
    final scanned = _dartFiles().map(_rel).where(_isPoolUi).toList();
    expect(scanned.length, greaterThanOrEqualTo(4), reason: scanned.join('\n'));
    expect(_poolArithmetic.hasMatch('final left = s.depositedMinor - s.spentMinor;'), isTrue);
    expect(_poolArithmetic.hasMatch('final total = s.deposits.fold(0, (a, d) => a + d.amountMinor);'), isTrue);
    expect(_poolArithmetic.hasMatch('Text(moneyDisplay(l10n, meter.abs()))'), isTrue);
    expect(_poolArithmetic.hasMatch('MoneyText(group.poolBalanceMinor ?? 0)'), isFalse);
  });
}

// SA16 (STANDALONE_SPEC 18.5): the itemized editor does no money math. Every computed amount (subtotal, discount,
// service, tax, per-person parts, totals) is the preview's; the item line shows the typed quantity and price as typed and
// never multiplies them. The one calculation of the printed-total tolerance (A174) lives in core/money.
final _itemizedArithmetic = RegExp(
  r'\b\w*Minor\w*\b\s*[-+*/%]\s*[\w(]'
  r'|[\w)]\s*[-+*/%]=?\s*\w*\.?\b\w*Minor\w*\b'
  r'|\bquantity\b\s*\*|\*\s*\w*\.?\bquantity\b'
  r'|\.fold\(|\.reduce\(|\.abs\(\)',
);

bool _isItemizedUi(String path) =>
    path.startsWith('lib/features/expenses/presentation/itemized_') ||
    path == 'lib/features/expenses/presentation/member_picker_sheet.dart' ||
    path == 'lib/features/expenses/presentation/assignee_summary_chip.dart' ||
    path == 'lib/features/expenses/presentation/unit_split_sheet.dart' ||
    path == 'lib/features/expenses/presentation/expense_blocks.dart';

void _sa16ItemizedGuard() {
  test('no money arithmetic in the itemized editor and the details blocks (SA16)', () {
    final hits = _scan(_itemizedArithmetic, skip: (p) => !_isItemizedUi(p));
    expect(hits, isEmpty, reason: 'Amounts come from the preview and are shown as sent; quantity x price is never worked out here.\n${hits.join('\n')}');
  });

  test('the itemized guard is alive: files are scanned and the pattern catches widget-side money math', () {
    final scanned = _dartFiles().map(_rel).where(_isItemizedUi).toList();
    expect(scanned.length, greaterThanOrEqualTo(8), reason: scanned.join('\n'));
    expect(_itemizedArithmetic.hasMatch('final line = item.unitAmountMinor * item.quantity;'), isTrue);
    expect(_itemizedArithmetic.hasMatch('final left = share.owedMinor - share.discountMinor!;'), isTrue);
    expect(_itemizedArithmetic.hasMatch('final sum = shares.fold(0, (a, s) => a + s.owedMinor);'), isTrue);
    expect(_itemizedArithmetic.hasMatch("Text(l10n.expenseItzLineTimes('\${item.quantity}', moneyDisplay(l10n, unit)))"), isFalse);
  });

  test('the printed-total tolerance constant is defined once, in core/money', () {
    final defs = _scan(RegExp(r'\bkPrintedTotalTolerance\s*='));
    expect(defs, hasLength(1), reason: defs.join('\n'));
    expect(defs.single, contains('lib/core/money/money.dart'));
  });

  test('only the request builder constructs the discount, service, tax and item inputs', () {
    final hits = _scan(
      RegExp(r'\b(DiscountInput|ServiceInput|TaxInput|ItemInput)\('),
      skip: (p) => p == 'lib/features/expenses/application/expense_command_builder.dart' || p.startsWith('lib/local/'),
    );
    expect(hits, isEmpty, reason: 'Build the request with buildItemizedCommand.\n${hits.join('\n')}');
  });
}

// SA19 (STANDALONE_SPEC 15, BSA3): the shares editor shows what the server returned. Owed amounts, units and presence
// ranges are the preview's / the expense's; the UI does no money math and no date or day arithmetic (no day count is
// shown, A198). Choosing dates is a picker's job and comparing them is the controller's; formatting is text only.
final _sharesDateMath = RegExp(
  r'\.difference\(|\binDays\b|\bDuration\(|\bDateUtils\.|\b\w*(Date|date|From|To|from|to)\w*\.(add|subtract)\(',
);

bool _isSharesUi(String path) =>
    path == 'lib/features/expenses/presentation/shares_editor.dart' ||
    path == 'lib/features/expenses/presentation/split_section.dart' ||
    path == 'lib/features/expenses/presentation/revisions_sheet.dart' ||
    path == 'lib/features/expenses/presentation/expense_ui.dart' ||
    path == 'lib/features/expenses/presentation/expense_blocks.dart' ||
    path == 'lib/features/members/presentation/default_share_sheet.dart';

void _sa19SharesGuard() {
  test('no money arithmetic in the shares UI (SA19): amounts come from the preview', () {
    final hits = _scan(_itemizedArithmetic, skip: (p) => !_isSharesUi(p));
    expect(hits, isEmpty, reason: 'Owed amounts come from the preview and are shown as sent.\n${hits.join('\n')}');
  });

  test('no date or day arithmetic in the shares UI (SA19): no day count, no computed default range', () {
    final hits = _scan(_sharesDateMath, skip: (p) => !_isSharesUi(p));
    expect(hits, isEmpty, reason: 'Days present are shown as the server stored them; nothing is counted or computed here (A198).\n${hits.join('\n')}');
  });

  test('the shares guard is alive: the six files are scanned and the patterns catch widget-side math', () {
    final scanned = _dartFiles().map(_rel).where(_isSharesUi).toList();
    expect(scanned, hasLength(6), reason: scanned.join('\n'));
    expect(_sharesDateMath.hasMatch('final days = to.difference(from).inDays + 1;'), isTrue);
    expect(_sharesDateMath.hasMatch('final days = range.end.difference(range.start);'), isTrue);
    expect(_sharesDateMath.hasMatch('final end = periodFrom.add(const Duration(days: 30));'), isTrue);
    expect(_sharesDateMath.hasMatch('final last = DateUtils.addDaysToDate(from, 30);'), isTrue);
    expect(_sharesDateMath.hasMatch('final start = presentFrom.subtract(x);'), isTrue);
    expect(_sharesDateMath.hasMatch('if (from.compareTo(periodFrom) < 0) return;'), isFalse);
    expect(_sharesDateMath.hasMatch('items.add(Text(dateRangeText(l10n, from, to)));'), isFalse);
    expect(_itemizedArithmetic.hasMatch('final left = share.owedMinor - other.owedMinor;'), isTrue);
  });

  test('only the request builder constructs a ShareParticipantInput (SA19)', () {
    final hits = _scan(
      RegExp(r'\bShareParticipantInput\('),
      skip: (p) => p == 'lib/features/expenses/application/expense_command_builder.dart' || p.startsWith('lib/local/'),
    );
    expect(hits, isEmpty, reason: 'Build the request with buildExpenseCommand.\n${hits.join('\n')}');
  });
}

// SA17 (STANDALONE_SPEC 18.4, A176): the receipt scan copies what the model read and never computes. A quantity above 1
// without a unit price is flagged for the user; the client does not divide the line total. The parser and the mapper
// may compare (>=, ==) but never add, multiply, divide or round an amount, a quantity or a percentage.
final _scanArithmetic = RegExp(
  r'\b(\w*Minor\w*|quantity|qty|unitPrice|unit|lineTotal|amount|subtotal|total|percent|bps)\b\s*(~/|[-+*/%])=?\s*[\w(]'
  r'|[\w)\]]\s*(~/|[-+*/%])=?\s*\b(\w*Minor\w*|quantity|qty|unitPrice|unit|lineTotal|amount|subtotal|total|percent|bps)\b'
  r'|\.fold\(|\.reduce\(|\.round\(|\.floor\(|\.ceil\(|\.truncate\(|\.toInt\(|\bdouble\b|\bnum\b|toDouble',
);

bool _isReceiptScanLogic(String path) =>
    path == 'lib/features/receipt_scan/application/receipt_parser.dart' ||
    path == 'lib/features/receipt_scan/application/receipt_draft_mapper.dart' ||
    path == 'lib/features/receipt_scan/application/parsed_receipt.dart' ||
    path == 'lib/features/receipt_scan/presentation/scan_flow.dart';

void _sa17ReceiptScanGuard() {
  test('no client-side division or other money math in the receipt scan (SA17)', () {
    final hits = _scan(_scanArithmetic, skip: (p) => !_isReceiptScanLogic(p));
    expect(hits, isEmpty, reason: 'The scan copies the printed numbers; the client never divides a line total or computes a price.\n${hits.join('\n')}');
  });

  test('the receipt scan guard is alive: the four files are scanned and the pattern catches money math', () {
    final scanned = _dartFiles().map(_rel).where(_isReceiptScanLogic).toList();
    expect(scanned, hasLength(4), reason: scanned.join('\n'));
    expect(_scanArithmetic.hasMatch('final unit = lineTotal ~/ quantity;'), isTrue);
    expect(_scanArithmetic.hasMatch('final unit = lineTotalMinor / item.quantity;'), isTrue);
    expect(_scanArithmetic.hasMatch('final line = unitPrice * quantity;'), isTrue);
    expect(_scanArithmetic.hasMatch('final sum = items.fold(0, (a, i) => a + i.minor);'), isTrue);
    expect(_scanArithmetic.hasMatch('final left = subtotal - discount;'), isTrue);
    expect(_scanArithmetic.hasMatch('if (amount >= subtotal) return dropped;'), isFalse);
    expect(_scanArithmetic.hasMatch('final opensAs = quantity > 1 ? quantity : 1;'), isFalse);
  });

  test('the model never decides a number: the prompt says to copy and never calculate, and the model id is one constant', () {
    final reader = File('lib/features/receipt_scan/application/firebase_receipt_reader.dart').readAsStringSync();
    expect(reader, contains('Never calculate, correct or guess a number.'));
    expect(RegExp(r'gemini-[\w.-]+').allMatches(reader).length, 1, reason: 'the model id appears once (kReceiptModel)');
  });
}

// SA20 (STANDALONE_SPEC 20.2, A191): every trip-budget figure (remaining, over by, progress, per day, per head) is a
// field of `BudgetSummary`, computed by the pure engine in lib/local. Widgets under lib/features/budget never add,
// subtract, multiply, divide, fold or round; the bar's fraction is made in core/widgets (`BpsBar`).
final _budgetArithmetic = RegExp(
  r'\b(\w*Minor|\w*Bps|elapsedDays|daysLeft|totalMinor)\b\s*(~/|[-+*/%])=?\s*[\w(]'
  r'|[\w)\]]\s*(~/|[-+*/%])=?\s*\b(\w*Minor|\w*Bps|elapsedDays|daysLeft)\b'
  r'|\.fold\(|\.reduce\(|\.round\(|\.floor\(|\.ceil\(|\.truncate\(|\.toInt\(|\.abs\(\)|\bdouble\b|\bnum\b|toDouble|\.sum\b',
);

bool _isBudgetUi(String path) => path.startsWith('lib/features/budget/');

void _sa20BudgetGuard() {
  test('no arithmetic or floating point on budget figures in lib/features/budget (SA20)', () {
    final hits = _scan(_budgetArithmetic, skip: (p) => !_isBudgetUi(p));
    expect(hits, isEmpty, reason: 'Budget figures come precomputed from BudgetSummary.\n${hits.join('\n')}');
  });

  test('the budget guard is alive: the budget files are scanned, import no engine, and the pattern catches widget math', () {
    final scanned = _dartFiles().where((f) => _isBudgetUi(_rel(f))).toList();
    expect(scanned.length, greaterThanOrEqualTo(3), reason: scanned.map(_rel).join('\n'));
    for (final file in scanned) {
      expect(file.readAsStringSync(), isNot(contains('package:qesma_engine')), reason: _rel(file));
    }
    expect(_budgetArithmetic.hasMatch('final left = summary.budgetMinor - summary.spentMinor;'), isTrue);
    expect(_budgetArithmetic.hasMatch('final pct = summary.spentMinor * 100;'), isTrue);
    expect(_budgetArithmetic.hasMatch('final fill = summary.barFillBps / 10000;'), isTrue);
    expect(_budgetArithmetic.hasMatch('final total = days.fold(0, (a, d) => a + d.totalMinor);'), isTrue);
    expect(_budgetArithmetic.hasMatch('MoneyText(summary.remainingMinor, size: MoneySize.large)'), isFalse);
    expect(_budgetArithmetic.hasMatch("Text(ltrIsolate('\${Bps.format(summary.progressBps)}%'))"), isFalse);
  });
}
