import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/profile/data/profile_repository.dart';

/// FL8 / FL14 profile requests: the display name is changed with `PATCH /me` (trimmed) and read back with
/// `GET /me`; an empty or 61-character name is VALIDATION_ERROR; the own payment handles are saved normalized and
/// cleared again.
///
/// Shared by the server run (`../profile_flow_test.dart`, after a fake sign-in) and the local-mode conformance
/// run (`test/local/conformance/`), which plugs `LocalBackend` into `httpAdapterProvider` (SA3).
Future<void> runProfileFlow(ProviderContainer container) async {
  final repo = container.read(profileRepositoryProvider);
  final api = container.read(qesmaApiProvider);

  final updated = await repo.updateName('Mohamed Ramadan');
  expect(updated.displayName, 'Mohamed Ramadan');
  expect((await api.getMeControllerApi().getMe()).data!.displayName, 'Mohamed Ramadan', reason: 'GET /me agrees');
  expect((await repo.updateName('  محمد رمضان  ')).displayName, 'محمد رمضان', reason: 'trimmed by the server');

  Future<ApiErrorCode?> refused(String name) async {
    try {
      await repo.updateName(name);
    } catch (e) {
      return (e as ApiHttpFailure).problem?.code;
    }
    return null;
  }

  expect(await refused('a' * 61), ApiErrorCode.validationError);
  expect(await refused('   '), ApiErrorCode.validationError);
  expect(await refused('ب' * 60), isNull, reason: '60 Arabic letters are 60 code points: accepted');

  // Own payment handles: Arabic-Indic digits, spaces and +20 are normalized; blank removes a handle.
  final saved = await repo.savePaymentHandles(instapay: ' Mohamed@InstaPay ', wallet: '+20 ١٠١ ٢٣٤ ٥٦٧٨');
  expect((saved.instapay, saved.wallet), ('mohamed@instapay', '01012345678'));
  final read = await repo.paymentHandles();
  expect((read.instapay, read.wallet), ('mohamed@instapay', '01012345678'));
  final cleared = await repo.savePaymentHandles(instapay: '', wallet: '01012345678');
  expect((cleared.instapay, cleared.wallet), (null, '01012345678'));
  Object? bad;
  try {
    await repo.savePaymentHandles(instapay: null, wallet: '0123');
  } catch (e) {
    bad = e;
  }
  expect((bad! as ApiHttpFailure).problem?.code, ApiErrorCode.validationError);
}
