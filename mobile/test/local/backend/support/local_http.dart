import 'package:dio/dio.dart';
import 'package:qesma/core/api/uuid_v4.dart';
import 'package:qesma/local/backend/local_backend.dart';
import 'package:qesma/local/backend/local_log.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/service/local_context.dart';
import 'package:qesma/local/service/profile_service.dart';

/// A raw HTTP client over [LocalBackend] on an in-memory database, for contract-level tests (status codes, headers,
/// Problem JSON). Every status is returned (no throwing), so tests assert on it directly.
class LocalHttp {
  LocalHttp._(this.db, this.dio, this.failures, this.now);

  final LocalDatabase db;
  final Dio dio;
  final List<LocalFailure> failures;

  /// The fake clock (UTC epoch ms); tests move it forward with [advance].
  final List<int> now;

  static Future<LocalHttp> open({String profileName = 'Tester', bool withProfile = true, LocalDatabase? database}) async {
    final db = database ?? LocalDatabase.inMemory();
    final now = [DateTime.utc(2026, 11, 17, 10).millisecondsSinceEpoch];
    int clock() => now[0];
    if (withProfile) await ProfileService(LocalContext(db, clock: clock)).ensureProfile(profileName);
    final failures = <LocalFailure>[];
    final dio = Dio(BaseOptions(
      baseUrl: 'https://local.qesma.invalid',
      validateStatus: (_) => true,
      responseType: ResponseType.json,
    ))
      ..httpClientAdapter = LocalBackend(db, clock: clock, failureLog: failures.add);
    return LocalHttp._(db, dio, failures, now);
  }

  void advance(Duration d) => now[0] += d.inMilliseconds;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      dio.get<dynamic>('/api/v1$path', queryParameters: query);

  Future<Response<dynamic>> post(String path, Object? body, {String? key, Map<String, String>? headers}) =>
      dio.post<dynamic>('/api/v1$path',
          data: body, options: Options(headers: {'Idempotency-Key': ?key, ...?headers}));

  Future<Response<dynamic>> put(String path, Object? body, {String? ifMatch}) =>
      dio.put<dynamic>('/api/v1$path', data: body, options: Options(headers: {'If-Match': ?ifMatch}));

  Future<Response<dynamic>> patch(String path, Object? body, {String? ifMatch}) =>
      dio.patch<dynamic>('/api/v1$path', data: body, options: Options(headers: {'If-Match': ?ifMatch}));

  Future<Response<dynamic>> delete(String path, {String? ifMatch}) =>
      dio.delete<dynamic>('/api/v1$path', options: Options(headers: {'If-Match': ?ifMatch}));

  // ---- seeding helpers -------------------------------------------------------------------------------------

  /// Creates a group and returns its GroupDto JSON.
  Future<Map<String, dynamic>> group({String name = 'Dahab', String type = 'TRIP'}) async {
    final r = await post('/groups', {'name': name, 'type': type});
    if (r.statusCode != 201) throw StateError('group create failed: ${r.statusCode} ${r.data}');
    return (r.data as Map).cast<String, dynamic>();
  }

  /// Adds a member and returns its id.
  Future<String> member(String gid, String name) async {
    final r = await post('/groups/$gid/members', {'displayName': name});
    if (r.statusCode != 201) throw StateError('member add failed: ${r.statusCode} ${r.data}');
    return (r.data as Map)['id'] as String;
  }

  /// Creates an expense with a fresh key and returns the response.
  Future<Response<dynamic>> expense(String gid, Map<String, Object?> body, {String? key}) =>
      post('/groups/$gid/expenses', body, key: key ?? newUuidV4());

  Future<Response<dynamic>> settlement(String gid, Map<String, Object?> body, {String? key}) =>
      post('/groups/$gid/settlements', body, key: key ?? newUuidV4());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle()).read<int>('n');

  Future<void> close() => db.close();
}

Map<String, Object?> equalBody(int total, List<({String id, int amount})> payers,
        {List<String>? participants, String title = 'Dinner', String date = '2026-11-10'}) =>
    {
      'title': title,
      'expenseDate': date,
      'splitType': 'EQUAL',
      'totalMinor': total,
      'payers': [for (final p in payers) {'memberId': p.id, 'amountMinor': p.amount}],
      'participantMemberIds': ?participants,
    };
