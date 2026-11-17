import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/features_for_mode.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/backup/application/backup_gateway.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/backup/backup_service.dart';

import '../../local/backend/support/local_http.dart';
import '../../local/backup/support/backup_support.dart';
import '../../support/test_app.dart' show Config, allConfigs;

class _FakeGateway implements BackupFileGateway {
  List<int>? picked;
  final shared = <String>[];
  bool userDismissesShareSheet = false;

  @override
  Future<bool> share(Uint8List bytes, String text) async {
    expect(bytes, isNotEmpty);
    shared.add(text);
    return !userDismissesShareSheet;
  }

  @override
  Future<List<int>?> pick() async => picked;
}

/// SA5: the Backup section of the profile hub, the confirm dialogs, the restore errors and the reminder banner, in the
/// real local-mode app, in Arabic and English at both text scales.
void main() {
  late LocalHttp http; // the phone's database
  late List<int> otherLedger; // a valid backup of a different ledger ("Mona" / "Dahab trip" / "Flat")
  late _FakeGateway gateway;
  late int now;

  setUp(() async {
    final source = await LocalHttp.open(profileName: 'Mona');
    await seedRichLedger(source);
    otherLedger = await exportBytes(source.db);
    await source.close();
    http = await LocalHttp.open(profileName: 'Omar');
    await http.group(name: 'Siwa');
    gateway = _FakeGateway();
    now = DateTime.now().toUtc().millisecondsSinceEpoch;
  });
  tearDown(() => http.close());

  Future<ProviderContainer> boot(WidgetTester tester, Config config, String location) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 900);
    tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(overrides: [
      ...localModeOverrides(http.db),
      backupFileGatewayProvider.overrideWithValue(gateway),
      backupServiceProvider.overrideWithValue(BackupService(http.db, appVersion: '0.1.0+1', clock: () => now)),
    ]);
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).set(config.locale);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
    await tester.pumpAndSettle();
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    return container;
  }

  AppLocalizations l10nOf(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

  /// The hub is a lazy list: at 2x text the Backup rows start off screen, so scroll to them first.
  Future<void> reveal(WidgetTester tester, String text) async {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.scrollUntilVisible(find.text(text), 300, scrollable: find.byType(Scrollable).first);
    // Clear of the bottom navigation bar.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await reveal(tester, text);
    await tester.ensureVisible(find.text(text).first);
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  for (final config in allConfigs) {
    group('(${config.name})', () {
      testWidgets('the hub has the Backup section; export asks first, warns about names and amounts, shares and remembers', (tester) async {
        await boot(tester, config, Routes.account);
        final l10n = l10nOf(tester);
        await reveal(tester, l10n.backupRestoreTitle);
        expect(find.text(l10n.backupSectionTitle), findsOneWidget);
        expect(find.text(l10n.backupNeverExported), findsOneWidget);
        expect(find.text(l10n.backupRestoreTitle), findsOneWidget);

        await tapText(tester, l10n.backupExportTitle);
        expect(find.text(l10n.backupExportBody), findsOneWidget, reason: 'the privacy warning is in the confirm dialog');
        await tapText(tester, l10n.commonCancel);
        expect(gateway.shared, isEmpty, reason: 'cancel shares nothing');

        await tapText(tester, l10n.backupExportTitle);
        await tapText(tester, l10n.backupExportConfirm);
        expect(gateway.shared, [l10n.backupShareText], reason: 'the share text says the file holds names and amounts');
        expect(find.text(l10n.backupExportDone), findsOneWidget);
        expect(find.text(l10n.backupNeverExported), findsNothing);
        expect((await http.db.metaDao.get()).lastExportAt, now);
      });

      testWidgets('a dismissed share sheet does not count as an export', (tester) async {
        gateway.userDismissesShareSheet = true;
        await boot(tester, config, Routes.account);
        final l10n = l10nOf(tester);
        await tapText(tester, l10n.backupExportTitle);
        await tapText(tester, l10n.backupExportConfirm);
        expect((await http.db.metaDao.get()).lastExportAt, isNull);
      });

      testWidgets('restore replaces everything only after the explicit confirm; cancel changes nothing', (tester) async {
        gateway.picked = otherLedger;
        await boot(tester, config, Routes.account);
        final l10n = l10nOf(tester);
        final before = await fingerprint(http.db);

        await tapText(tester, l10n.backupRestoreTitle);
        expect(find.text(l10n.backupRestoreConfirmTitle), findsOneWidget);
        expect(find.textContaining('2'), findsWidgets, reason: 'the dialog says what the file holds (2 groups)');
        expect(await fingerprint(http.db), before, reason: 'nothing is written while the dialog is open');
        await tapText(tester, l10n.commonCancel);
        expect(await fingerprint(http.db), before, reason: 'cancel changes nothing');

        await tapText(tester, l10n.backupRestoreTitle);
        await tapText(tester, l10n.backupRestoreConfirm);
        expect(await fingerprint(http.db), isNot(before));
        expect((await http.db.profileDao.find())!.displayName, 'Mona');
        final names = [for (final g in await http.db.select(http.db.expenseGroups).get()) g.name];
        expect(names, unorderedEquals(['Dahab trip', 'Flat']), reason: 'the old group is gone');
        expect(find.text(l10n.backupRestoreDone), findsOneWidget);
        // The groups list shows the restored data, not the cached old list.
        expect(find.text('Dahab trip').evaluate().length + find.text('Flat').evaluate().length, greaterThan(0), reason: 'at 2x text only one card may be on screen');
        expect(find.text('Siwa'), findsNothing);
      });

      testWidgets('a bad file explains itself, in the person\'s language, and changes nothing', (tester) async {
        gateway.picked = '{"formatVersion": 2}'.codeUnits;
        await boot(tester, config, Routes.account);
        final l10n = l10nOf(tester);
        final before = await fingerprint(http.db);
        await tapText(tester, l10n.backupRestoreTitle);
        expect(find.text(l10n.backupErrorNewer), findsOneWidget);
        await tapText(tester, l10n.commonOk);
        expect(await fingerprint(http.db), before);

        gateway.picked = 'not json'.codeUnits;
        await tapText(tester, l10n.backupRestoreTitle);
        expect(find.text(l10n.backupErrorUnreadable), findsOneWidget);
        await tapText(tester, l10n.commonOk);
        expect(await fingerprint(http.db), before);
      });

      testWidgets('picking nothing (cancel in the system picker) does nothing', (tester) async {
        await boot(tester, config, Routes.account);
        final l10n = l10nOf(tester);
        final before = await fingerprint(http.db);
        await tapText(tester, l10n.backupRestoreTitle);
        expect(find.text(l10n.backupRestoreConfirmTitle), findsNothing);
        expect(await fingerprint(http.db), before);
      });

      testWidgets('the reminder banner shows after 10 expenses, can be dismissed, and exporting from it works', (tester) async {
        late Future<void> Function(int) add;
        await tester.runAsync(() async {
          final g = (await http.get('/groups')).data['items'][0] as Map;
          final gid = g['id'] as String;
          final you = (await http.get('/groups/$gid')).data['yourMemberId'];
          add = (i) => http.expense(gid, {'title': 'E$i', 'expenseDate': '2026-11-10', 'splitType': 'EQUAL', 'totalMinor': 1000, 'payers': [{'memberId': you, 'amountMinor': 1000}]});
          for (var i = 0; i < 9; i++) {
            await add(i);
          }
        });
        final container = await boot(tester, config, Routes.home);
        final l10n = l10nOf(tester);
        expect(find.text(l10n.backupBannerTitle), findsNothing, reason: '9 expenses: not yet');

        await tester.runAsync(() => add(9));
        container.invalidate(backupStatusProvider);
        await tester.pumpAndSettle();
        expect(find.text(l10n.backupBannerTitle), findsOneWidget);
        await tester.tap(find.byTooltip(l10n.backupBannerDismiss));
        await tester.pumpAndSettle();
        expect(find.text(l10n.backupBannerTitle), findsNothing);
        expect((await http.db.metaDao.get()).backupReminderSnoozedUntil, isNotNull);

        // A week later it is back, and "Back up now" exports without asking again.
        now += 8 * 86400000;
        container.invalidate(backupStatusProvider);
        await tester.pumpAndSettle();
        expect(find.text(l10n.backupBannerTitle), findsOneWidget);
        await tapText(tester, l10n.backupBannerAction);
        expect(gateway.shared, hasLength(1));
        expect(find.text(l10n.backupBannerTitle), findsNothing);
      });
    });
  }

  test('only local mode has the backup feature (server mode never shows it)', () {
    expect(ModeFeatures.local.backup, isTrue);
    expect(ModeFeatures.server.backup, isFalse);
  });
}
