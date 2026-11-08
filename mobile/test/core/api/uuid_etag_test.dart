import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/etag_store.dart';
import 'package:qesma/core/api/uuid_v4.dart';

void main() {
  group('newUuidV4', () {
    final pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

    test('has the v4 layout (the backend rejects anything that is not a UUID)', () {
      for (var i = 0; i < 1000; i++) {
        expect(newUuidV4(), matches(pattern));
      }
    });

    test('is unique across many calls', () {
      expect({for (var i = 0; i < 5000; i++) newUuidV4()}.length, 5000);
    });

    test('is deterministic for a seeded generator (so tests can pin keys)', () {
      expect(newUuidV4(Random(7)), newUuidV4(Random(7)));
    });
  });

  group('ETagStore', () {
    test('parses what Spring sends: a quoted integer', () {
      expect(ETagStore.parseVersion('"1"'), 1);
      expect(ETagStore.parseVersion('"42"'), 42);
      expect(ETagStore.parseVersion('W/"3"'), 3);
    });

    test('rejects values that are not a version', () {
      for (final bad in [null, '', '1', '"x"', '""', '"1.5"', '"-1"', '"1234567890"']) {
        expect(ETagStore.parseVersion(bad), isNull, reason: '$bad');
      }
    });

    test('builds If-Match from the remembered version, and null when never read', () {
      final store = ETagStore();
      expect(store.ifMatchFor('g1'), isNull);
      store.remember('g1', '"4"');
      expect(store.versionOf('g1'), 4);
      expect(store.ifMatchFor('g1'), '"4"');
      store.remember('g1', 'garbage'); // keeps the last good value
      expect(store.ifMatchFor('g1'), '"4"');
      store.forget('g1');
      expect(store.ifMatchFor('g1'), isNull);
    });
  });
}
