import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/db/local_database.dart';

/// SA4: the real app (router, screens, repositories) in local mode over `LocalBackend` on an in-memory database.
Future<ProviderContainer> _boot(WidgetTester tester, LocalDatabase db, {Locale locale = const Locale('en')}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: localModeOverrides(db));
  addTearDown(container.dispose);
  container.read(localeProvider.notifier).set(locale);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
  await tester.pumpAndSettle();
  return container;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Scaffold).first));

void main() {
  testWidgets('fresh install -> name -> create group -> add member -> equal expense -> balances; no server controls', (tester) async {
    final db = LocalDatabase.inMemory();
    addTearDown(db.close);
    final container = await _boot(tester, db);
    var l10n = _l10n(tester);

    // Welcome: no sign-in anywhere.
    expect(find.text(l10n.welcomeStart), findsOneWidget);
    await tester.tap(find.text(l10n.welcomeStart));
    await tester.pumpAndSettle();

    // "What's your name?"
    expect(find.text(l10n.onboardingNameTitle), findsOneWidget);
    await tester.tap(find.text(l10n.onboardingContinue));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileNameRequired), findsOneWidget, reason: 'blank name is refused in place');
    await tester.enterText(find.byType(TextField), '  Mona  ');
    await tester.tap(find.text(l10n.onboardingContinue));
    await tester.pumpAndSettle();

    // Groups list (empty): no join-by-code entry.
    l10n = _l10n(tester);
    expect(find.text(l10n.groupsEmptyTitle), findsOneWidget);
    expect(find.text(l10n.inviteEnterCodeButton), findsNothing);
    await tester.tap(find.text(l10n.groupsNew).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Siwa trip');
    await tester.pump();
    await tester.tap(find.text(l10n.groupCreateButton));
    await tester.pumpAndSettle();

    // Group home -> Members: add one member; the owner sees no role/invite/leave/transfer controls.
    expect(find.text('Siwa trip'), findsWidgets);
    await tester.tap(find.text(l10n.groupTabMembers));
    await tester.pumpAndSettle();
    expect(find.text('Mona'), findsOneWidget, reason: 'member #1 is the profile name');
    await tester.tap(find.text(l10n.membersAdd));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Omar');
    await tester.pump();
    await tester.tap(find.text(l10n.memberSave));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.text('Omar'), findsOneWidget);
    for (final text in [l10n.inviteAction, l10n.membersTransfer, l10n.membersLeave, l10n.membersRoleOwner, l10n.membersBadgeNameOnly]) {
      expect(find.text(text), findsNothing, reason: text);
    }

    // Expenses tab -> add an equal expense paid by "you".
    await tester.tap(find.text(l10n.groupTabExpenses));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.expensesAdd).first);
    await tester.pumpAndSettle();
    // SA11: in local mode the button opens a menu (plain expense or the calculator).
    await tester.tap(find.text(l10n.calcMenuAddExpenseHint));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Dinner');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.expenseFormSave));
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsWidgets);
    container.read(routerProvider).pop(); // back from the expense details to the group
    await tester.pumpAndSettle();

    // Balances: Omar owes Mona 50.00; recording is a plain payment, no pending chip; the receiver gets the local WhatsApp reminder (SA9, no server call).
    await tester.tap(find.text(l10n.groupTabBalances));
    await tester.pumpAndSettle();
    expect(find.text(l10n.payReceived), findsOneWidget, reason: 'Mona is owed 50.00: record that it arrived');
    expect(find.text(l10n.payNoHandles('Omar')), findsNothing);
    expect(find.text(l10n.pendingBadge), findsNothing);
    expect(find.text(l10n.balancesAllSettledTitle), findsNothing);
    expect(find.text(l10n.remindButton), findsOneWidget, reason: 'SA9: the receiver can send a WhatsApp reminder in local mode');

    // Record the full payment: it counts at once (no pending, no review) and everyone is settled.
    await tester.tap(find.text(l10n.payReceived));
    await tester.pumpAndSettle();
    expect(find.text(l10n.paymentHintConfirmed), findsNothing);
    expect(find.text(l10n.paymentHintPending('Omar')), findsNothing);
    await tester.tap(find.textContaining('Full amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Confirm payment'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.balancesAllSettledTitle), findsWidgets);
    expect(find.text(l10n.settlementChipPending), findsNothing);
  });

  testWidgets('a second launch on the same database skips onboarding', (tester) async {
    final db = LocalDatabase.inMemory();
    addTearDown(db.close);
    final first = await _boot(tester, db);
    await tester.tap(find.text(_l10n(tester).welcomeStart));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mona');
    await tester.tap(find.text(_l10n(tester).onboardingContinue));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    first.dispose();

    await _boot(tester, db);
    final l10n = _l10n(tester);
    expect(find.text(l10n.onboardingNameTitle), findsNothing);
    expect(find.text(l10n.groupsEmptyTitle), findsOneWidget);
  });
}
