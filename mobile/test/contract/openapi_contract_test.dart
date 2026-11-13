import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const _regenerate = 'bash mobile/tool/generate_api.sh   (needs Docker; run from the repository root)';

String _normalizedContract() => File('../docs/openapi.json').readAsStringSync().replaceAll('\r', '');

void main() {
  test('the generated client matches docs/openapi.json (hash)', () {
    final expected = File('openapi.sha256').readAsStringSync().trim();
    final actual = sha256.convert(utf8.encode(_normalizedContract())).toString();
    expect(
      actual,
      expected,
      reason: 'docs/openapi.json changed but the generated client was not refreshed.\n'
          'Regenerate with: $_regenerate\n'
          'then review the diff of mobile/packages/qesma_api and commit it with mobile/openapi.sha256.',
    );
  });

  test('the hash is stable across CRLF and LF checkouts', () {
    final lf = _normalizedContract();
    final crlf = lf.replaceAll('\n', '\r\n');
    final fromCrlf = sha256.convert(utf8.encode(crlf.replaceAll('\r', ''))).toString();
    expect(fromCrlf, sha256.convert(utf8.encode(lf)).toString());
  });

  test('every operation of the contract exists in the generated package under its operationId', () {
    final paths = (jsonDecode(_normalizedContract()) as Map<String, dynamic>)['paths'] as Map<String, dynamic>;
    final operations = <String, String>{}; // operationId -> "METHOD path"
    paths.forEach((path, item) {
      (item as Map<String, dynamic>).forEach((method, op) {
        final id = (op as Map<String, dynamic>)['operationId'] as String;
        operations[id] = '${method.toUpperCase()} $path';
      });
    });
    expect(operations, hasLength(46), reason: 'the API has exactly 46 operations (24 Phase 1 + 7 password-auth + 9 invitations, join and unlink + 2 member lifecycle (leave, transfer) + 3 settlement v2 (confirm, dispute, cancel) - 1 removed delete + 2 payment handles (get, update; B14))');

    final generated = Directory('packages/qesma_api/lib/src/api')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');

    final missing = <String>[];
    operations.forEach((id, description) {
      // The generator emits: Future<Response<...>> operationId({ ...
      if (!RegExp('Future<Response<[^\\n]*>> $id\\(').hasMatch(generated)) missing.add('$id ($description)');
    });
    expect(missing, isEmpty, reason: 'operations without a generated method');
  });

  test('every API operation the app calls is in docs/openapi.json', () {
    final paths = (jsonDecode(_normalizedContract()) as Map<String, dynamic>)['paths'] as Map<String, dynamic>;
    final contractIds = <String>{};
    paths.forEach((_, item) {
      (item as Map<String, dynamic>).forEach((_, op) => contractIds.add((op as Map<String, dynamic>)['operationId'] as String));
    });

    // The app reaches the generated client only as `api.getXxxApi().operation(` or `...Api().operation(`.
    final call = RegExp(r'get\w+Api\(\)\s*\.(\w+)\(');
    final used = <String, String>{}; // operationId -> first file
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in call.allMatches(file.readAsStringSync())) {
        used.putIfAbsent(m.group(1)!, () => file.path);
      }
    }
    expect(used, isNotEmpty, reason: 'the pattern found no API call: the check itself is broken');
    final unknown = used.entries.where((e) => !contractIds.contains(e.key)).map((e) => '${e.key} (${e.value})').toList();
    expect(unknown, isEmpty, reason: 'the app calls operations that are not in the contract');
  });
}
