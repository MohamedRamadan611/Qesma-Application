import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma_api/qesma_api.dart';
import 'package:qesma/features/balances/application/balances_controller.dart';
import 'package:qesma/features/groups/application/group_detail_controller.dart';
import 'package:qesma/features/recap/application/trip_recap_formatter.dart';
import 'package:qesma/features/recap/application/trip_recap_sharer.dart';
import 'package:qesma/features/recap/presentation/trip_recap_card.dart';
import 'package:qesma/features/recap/presentation/trip_recap_screen.dart';
import 'package:qesma/local/insights/trip_recap_provider.dart';
import 'package:qesma/local/insights/trip_recap_repository.dart';

import '../../support/test_app.dart';

class _FakeSharer implements TripRecapSharer {
  Uint8List? lastSharedImage;
  String? lastSharedText;

  @override
  Future<bool> shareImage(Uint8List pngBytes, {String? text}) async {
    lastSharedImage = pngBytes;
    return true;
  }

  @override
  Future<bool> shareText(String text) async {
    lastSharedText = text;
    return true;
  }
}

class _TestGroupDetailController extends GroupDetailController {
  _TestGroupDetailController(super.gid, this._group);
  final GroupDto _group;

  @override
  GroupDetailState build() => GroupDetailState(group: _group, loading: false);
}

class _TestBalancesController extends BalancesController {
  _TestBalancesController(super.gid, this._balances);
  final BalanceView _balances;

  @override
  BalancesState build() =>
      BalancesState(status: BalancesStatus.ready, balances: _balances);
}

TripRecapResult _sampleRecap() {
  return const TripRecapResult(
    totalSpentMinor: 95000,
    expenseCount: 4,
    dateRangeStart: '2026-11-01',
    dateRangeEnd: '2026-11-05',
    topPayer: TripRecapTopPayer(
      memberId: 'm1',
      displayName: 'Ahmed',
      amountPaidMinor: 60000,
    ),
    biggestExpense: TripRecapBiggestExpense(
      expenseId: 'e1',
      title: 'Seafood Dinner',
      totalMinor: 45000,
      expenseDate: '2026-11-02',
    ),
    categoryBreakdown: [
      TripRecapCategoryBreakdown(category: 'FOOD', totalMinor: 45000, percentageBps: 4737),
      TripRecapCategoryBreakdown(category: 'TRANSPORT', totalMinor: 20000, percentageBps: 2105),
      TripRecapCategoryBreakdown(category: 'FUEL', totalMinor: 15000, percentageBps: 1579),
      TripRecapCategoryBreakdown(category: 'ACCOMMODATION', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'GROCERIES', totalMinor: 15000, percentageBps: 1579),
      TripRecapCategoryBreakdown(category: 'SHOPPING', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'ENTERTAINMENT', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'BILLS', totalMinor: 0, percentageBps: 0),
      TripRecapCategoryBreakdown(category: 'OTHER', totalMinor: 0, percentageBps: 0),
    ],
    memberPaidTotals: [
      TripRecapMemberPaidTotal(memberId: 'm1', displayName: 'Ahmed', sortOrder: 0, amountPaidMinor: 60000),
      TripRecapMemberPaidTotal(memberId: 'm2', displayName: 'Mona', sortOrder: 1, amountPaidMinor: 35000),
    ],
  );
}

GroupDto _sampleGroup(String gid) {
  final now = DateTime.utc(2026, 11, 1);
  return GroupDto((b) => b
    ..id = gid
    ..name = 'Dahab Trip'
    ..type = 'TRIP'
    ..currencyCode = 'EGP'
    ..totalSpentMinor = 95000
    ..poolBalanceMinor = 0
    ..treasurerMemberId = 'm1'
    ..yourNetMinor = 0
    ..version = 1
    ..muted = false
    ..createdAt = now
    ..updatedAt = now
    ..yourRole = 'OWNER'
    ..yourMemberId = 'm1'
    ..members = ListBuilder([
      MemberDto((m) => m
        ..id = 'm1'
        ..displayName = 'Ahmed'
        ..role = 'OWNER'
        ..isYou = true
        ..hasAccount = true
        ..status = 'ACTIVE'
        ..createdAt = now
        ..sortOrder = 0),
      MemberDto((m) => m
        ..id = 'm2'
        ..displayName = 'Mona'
        ..role = 'MEMBER'
        ..isYou = false
        ..hasAccount = true
        ..status = 'ACTIVE'
        ..createdAt = now
        ..sortOrder = 1),
    ]));
}

BalanceView _sampleBalances() {
  return BalanceView((b) => b
    ..nets = ListBuilder<Net>([])
    ..transfers = ListBuilder([
      TransferView((t) => t
        ..fromMemberId = 'm2'
        ..toMemberId = 'm1'
        ..amountMinor = 12500
        ..pendingMinor = 0
        ..hasDispute = false
        ..openSettlementIds = ListBuilder<String>()),
    ]));
}

void main() {
  setUpAll(loadAppFonts);

  const gid = 'g1';

  group('TripRecapFormatter', () {
    testWidgets('formats text summary with transfers (Western digits and EGP)', (tester) async {
      await pumpApp(tester, const SizedBox(), locale: const Locale('ar'));
      final l10n = l10nOf(tester);

      final transfers = [
        TransferView((t) => t
          ..fromMemberId = 'm2'
          ..toMemberId = 'm1'
          ..amountMinor = 12500
          ..pendingMinor = 0
          ..hasDispute = false
          ..openSettlementIds = ListBuilder<String>()),
      ];

      final text = TripRecapFormatter.formatTextSummary(
        l10n: l10n,
        groupName: 'Dahab Trip',
        totalSpentMinor: 95000,
        expenseCount: 4,
        transfers: transfers,
        nameOf: (id) => id == 'm1' ? 'Ahmed' : 'Mona',
      );

      expect(text, contains('Dahab Trip'));
      expect(text, contains('950.00'));
      expect(text, contains('Ahmed'));
      expect(text, contains('Mona'));
      expect(text, contains('125.00'));
      expect(text, contains('qesma.app'));
      expect(hasNonWesternDigits(text), isFalse, reason: 'Must use Western digits');
    });

    testWidgets('formats text summary when all settled', (tester) async {
      await pumpApp(tester, const SizedBox(), locale: const Locale('ar'));
      final l10n = l10nOf(tester);

      final text = TripRecapFormatter.formatTextSummary(
        l10n: l10n,
        groupName: 'Dahab Trip',
        totalSpentMinor: 5000,
        expenseCount: 1,
        transfers: const [],
        nameOf: (id) => id,
      );

      expect(text, contains(l10n.recapTextSummaryAllSettled));
      expect(text, contains('qesma.app'));
    });
  });

  group('TripRecapScreen', () {
    late _FakeSharer fakeSharer;

    setUp(() {
      fakeSharer = _FakeSharer();
    });

    testWidgets('shows empty state when group has no expenses', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            tripRecapProvider(gid).overrideWith((ref) => Stream.value(null)),
            groupDetailControllerProvider(gid)
                .overrideWith(() => _TestGroupDetailController(gid, _sampleGroup(gid))),
            balancesControllerProvider(gid)
                .overrideWith(() => _TestBalancesController(gid, _sampleBalances())),
            tripRecapSharerProvider.overrideWithValue(fakeSharer),
          ],
          child: const TripRecapScreen(gid: gid),
        ),
        locale: const Locale('ar'),
        scaffold: false,
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);
      expect(find.text(l10n.recapEmptyTitle), findsOneWidget);
      expect(find.text(l10n.recapEmptyBody), findsOneWidget);
    });

    testWidgets('renders recap card and share buttons when data is present', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            tripRecapProvider(gid).overrideWith((ref) => Stream.value(_sampleRecap())),
            groupDetailControllerProvider(gid)
                .overrideWith(() => _TestGroupDetailController(gid, _sampleGroup(gid))),
            balancesControllerProvider(gid)
                .overrideWith(() => _TestBalancesController(gid, _sampleBalances())),
            tripRecapSharerProvider.overrideWithValue(fakeSharer),
          ],
          child: const TripRecapScreen(gid: gid),
        ),
        locale: const Locale('ar'),
        scaffold: false,
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);
      expect(find.byType(TripRecapCard), findsOneWidget);
      expect(find.text('Dahab Trip'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Seafood Dinner'), findsOneWidget);

      expect(find.text(l10n.recapShareImage), findsOneWidget);
      expect(find.text(l10n.recapShareText), findsOneWidget);
    });

    testWidgets('privacy confirm dialog appears before sharing image (A134)', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            tripRecapProvider(gid).overrideWith((ref) => Stream.value(_sampleRecap())),
            groupDetailControllerProvider(gid)
                .overrideWith(() => _TestGroupDetailController(gid, _sampleGroup(gid))),
            balancesControllerProvider(gid)
                .overrideWith(() => _TestBalancesController(gid, _sampleBalances())),
            tripRecapSharerProvider.overrideWithValue(fakeSharer),
          ],
          child: const TripRecapScreen(gid: gid),
        ),
        locale: const Locale('ar'),
        scaffold: false,
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);

      // Tap share image button
      await tester.tap(find.text(l10n.recapShareImage));
      await tester.pumpAndSettle();

      // Confirmation dialog should be visible
      expect(find.text(l10n.recapConfirmShareTitle), findsOneWidget);
      expect(find.text(l10n.recapConfirmShareBody), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.recapConfirmShareTitle), findsNothing);
      expect(fakeSharer.lastSharedImage, isNull, reason: 'Share should be cancelled');

      // Tap share image again and confirm
      await tester.tap(find.text(l10n.recapShareImage));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.recapConfirmShareAction));
      await tester.pump();
      await tester.runAsync(() async => await Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(fakeSharer.lastSharedImage, isNotNull, reason: 'Share should execute on confirm');
    });

    testWidgets('privacy confirm dialog appears before sharing text (A134)', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            tripRecapProvider(gid).overrideWith((ref) => Stream.value(_sampleRecap())),
            groupDetailControllerProvider(gid)
                .overrideWith(() => _TestGroupDetailController(gid, _sampleGroup(gid))),
            balancesControllerProvider(gid)
                .overrideWith(() => _TestBalancesController(gid, _sampleBalances())),
            tripRecapSharerProvider.overrideWithValue(fakeSharer),
          ],
          child: const TripRecapScreen(gid: gid),
        ),
        locale: const Locale('ar'),
        scaffold: false,
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester);

      // Tap share text button
      await tester.tap(find.text(l10n.recapShareText));
      await tester.pumpAndSettle();

      // Confirm dialog visible
      expect(find.text(l10n.recapConfirmShareTitle), findsOneWidget);

      // Confirm
      await tester.tap(find.text(l10n.recapConfirmShareAction));
      await tester.pumpAndSettle();

      expect(fakeSharer.lastSharedText, isNotNull);
      expect(fakeSharer.lastSharedText, contains('Dahab Trip'));
      expect(fakeSharer.lastSharedText, contains('125.00'));
    });

    testWidgets('screen survives text scale 2.0 without overflow', (tester) async {
      await pumpApp(
        tester,
        ProviderScope(
          overrides: [
            tripRecapProvider(gid).overrideWith((ref) => Stream.value(_sampleRecap())),
            groupDetailControllerProvider(gid)
                .overrideWith(() => _TestGroupDetailController(gid, _sampleGroup(gid))),
            balancesControllerProvider(gid)
                .overrideWith(() => _TestBalancesController(gid, _sampleBalances())),
            tripRecapSharerProvider.overrideWithValue(fakeSharer),
          ],
          child: const TripRecapScreen(gid: gid),
        ),
        locale: const Locale('en'),
        textScale: 2.0,
        scaffold: false,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
