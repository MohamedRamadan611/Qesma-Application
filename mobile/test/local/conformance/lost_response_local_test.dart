import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/idempotent_action.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma/local/backend/local_backend.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/service/local_context.dart';
import 'package:qesma/local/service/profile_service.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/faulty_adapter.dart';

/// FL9 scenario (e) in local mode: the first create is processed but its response is "lost"; the app's
/// IdempotentAction keeps the key, the retry is answered from the key store, and exactly one expense exists.
/// (FL9 (a) seeded data, (f) token expiry and the offline path are server-only.)
void main() {
  test('a lost create response and a retry with the same key give exactly one expense', () async {
    final db = LocalDatabase.inMemory();
    addTearDown(db.close);
    await ProfileService(LocalContext(db)).ensureProfile('Tester');
    final adapter = FaultyAdapter(LocalBackend(db));
    final container = ProviderContainer(overrides: [
      httpAdapterProvider.overrideWithValue(adapter),
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);

    final api = container.read(qesmaApiProvider);
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'Lost response'
            ..type = 'TRIP'),
        ))
        .data!;
    final gid = group.id;
    await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'));
    final command = ExpenseCommand((b) => b
      ..title = 'Lunch'
      ..expenseDate = Date(2026, 10, 20)
      ..splitType = 'EQUAL'
      ..totalMinor = 25050
      ..payers.add(PayerInput((x) => x
        ..memberId = group.yourMemberId
        ..amountMinor = 25050)));
    final repo = container.read(expensesRepositoryProvider);
    final action = IdempotentAction();

    var dropped = false;
    adapter.decide = (o) {
      if (!dropped && o.method == 'POST' && o.uri.path.endsWith('/expenses')) {
        dropped = true;
        return Fault.dropResponse;
      }
      return null;
    };
    Object? failure;
    try {
      await action.run(command.title, (key) => repo.create(gid, command, key));
    } catch (e) {
      failure = e;
    }
    expect((failure! as ApiFailure).retryable, isTrue);
    final firstKey = action.currentKey;

    final created = await action.run(command.title, (key) => repo.create(gid, command, key));
    expect(created.replayed, isTrue, reason: 'answered from the key store');
    expect(adapter.idempotencyKeys.where((k) => k == firstKey), hasLength(2));
    expect((await api.getExpenseControllerApi().listExpenses(gid: gid)).data!.items, hasLength(1));
    expect((await api.getGroupControllerApi().getGroup(gid: gid)).data!.totalSpentMinor, 25050);
  });
}
