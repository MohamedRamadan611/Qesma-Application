import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/receipt_scan/application/firebase_receipt_reader.dart';
import 'package:qesma/features/receipt_scan/application/ocr_settings_store.dart';
import 'package:qesma/features/receipt_scan/application/receipt_reader.dart';
import 'package:qesma/features/receipt_scan/application/receipt_scan_service.dart';

import 'support/fakes.dart';

/// SA12: consent, the daily cap (A145), every failure kind, the permission-error hiding, and that the photo goes
/// nowhere but to the reader.
const _day = 1789000000000; // some instant in 2026 (UTC ms)

void main() {
  late MemoryOcrStore store;
  late DateTime clock;
  ReceiptScanService make(FakeReceiptReader reader) => ReceiptScanService(reader: reader, store: store, now: () => clock);
  Future<ReceiptScanFailure> failureOf(ReceiptScanService s) async {
    try {
      await s.scan(fakeJpeg());
    } on ReceiptScanException catch (e) {
      return e.failure;
    }
    fail('expected a failure');
  }

  setUp(() {
    store = MemoryOcrStore(const OcrSettings(consentAt: 1));
    clock = DateTime.fromMillisecondsSinceEpoch(_day, isUtc: true);
  });

  test('a good scan returns the proposal, strips the EXIF before the reader, and counts one scan today', () async {
    final reader = FakeReceiptReader([goodJson]);
    final parsed = await make(reader).scan(fakeJpeg());
    expect(parsed.items.map((i) => i.amountText), ['12.50', '30']);
    expect(parsed.printedTotalMinor, 4250);
    expect(reader.received.single.length, lessThan(fakeJpeg().length));
    expect(String.fromCharCodes(reader.received.single), isNot(contains('Exif')));
    expect(store.value.scanCount, 1);
  });

  test('without consent nothing is sent', () async {
    store.value = const OcrSettings();
    final reader = FakeReceiptReader([goodJson]);
    expect(await failureOf(make(reader)), ReceiptScanFailure.unavailable);
    expect(reader.received, isEmpty);
  });

  test('consent can be given and revoked; revoking makes the next scan need consent again', () async {
    store.value = const OcrSettings();
    final service = make(FakeReceiptReader([goodJson]));
    await service.giveConsent();
    expect(store.value.consented, isTrue);
    await service.revokeConsent();
    expect(store.value.consented, isFalse);
    expect(await failureOf(service), ReceiptScanFailure.unavailable);
  });

  test('the 21st scan of a Cairo day is refused and never sent; the next Cairo day starts again at 0', () async {
    final reader = FakeReceiptReader([goodJson]);
    final service = make(reader);
    for (var i = 0; i < kDailyScanCap; i++) {
      await service.scan(fakeJpeg());
    }
    expect(await failureOf(service), ReceiptScanFailure.dailyCapReached);
    expect(reader.received.length, kDailyScanCap);

    clock = clock.add(const Duration(days: 1));
    await service.scan(fakeJpeg());
    expect(store.value.scanCount, 1);
  });

  test('an attempt counts when it is sent, even if it fails', () async {
    final service = make(FakeReceiptReader([const SocketException('x')]));
    expect(await failureOf(service), ReceiptScanFailure.offline);
    expect(store.value.scanCount, 1);
  });

  test('every failure kind surfaces as its own kind', () async {
    final cases = <Object, ReceiptScanFailure>{
      const SocketException('Failed host lookup'): ReceiptScanFailure.offline,
      TimeoutException('slow'): ReceiptScanFailure.timeout,
      QuotaExceeded('You exceeded your current quota'): ReceiptScanFailure.quotaExhausted,
      ServerException('PERMISSION_DENIED: To access this model, you must enforce Firebase App Check.'): ReceiptScanFailure.permissionDenied,
      '{"items":[]}': ReceiptScanFailure.unreadablePhoto,
      'not json at all': ReceiptScanFailure.invalidResponse,
    };
    for (final entry in cases.entries) {
      store.value = const OcrSettings(consentAt: 1);
      final failure = await failureOf(make(FakeReceiptReader([entry.key])));
      expect(failure, entry.value, reason: '${entry.key}');
    }
  });

  test('a reader that throws something unknown is "unavailable", not a crash', () async {
    expect(await failureOf(make(FakeReceiptReader([StateError('boom')]))), ReceiptScanFailure.unavailable);
  });

  test('a photo that is not a JPEG is "unreadable" and is not sent or counted', () async {
    final reader = FakeReceiptReader([goodJson]);
    try {
      await make(reader).scan(Uint8List.fromList([1, 2, 3, 4]));
      fail('expected a failure');
    } on ReceiptScanException catch (e) {
      expect(e.failure, ReceiptScanFailure.unreadablePhoto);
    }
    expect(reader.received, isEmpty);
    expect(store.value.scanCount, 0);
  });

  group('hiding after repeated permission errors (decision Q1)', () {
    final denied = ServerException('PERMISSION_DENIED: App Check');

    test('three in a row hide the feature for seven days; a scan while hidden is refused without sending', () async {
      final reader = FakeReceiptReader([denied]);
      final service = make(reader);
      for (var i = 0; i < kPermissionErrorsToHide; i++) {
        expect(await failureOf(service), ReceiptScanFailure.permissionDenied);
      }
      final nowMs = clock.millisecondsSinceEpoch;
      expect(store.value.isHidden(nowMs), isTrue);
      expect(store.value.hiddenUntil, nowMs + kHiddenFor.inMilliseconds);
      final sent = reader.received.length;
      expect(await failureOf(service), ReceiptScanFailure.permissionDenied);
      expect(reader.received.length, sent);

      clock = clock.add(kHiddenFor + const Duration(minutes: 1));
      expect(store.value.isHidden(clock.millisecondsSinceEpoch), isFalse);
    });

    test('a success, or any answer from the server, resets the streak; offline and timeout leave it', () async {
      final service = make(FakeReceiptReader([denied, denied, goodJson, denied, denied, QuotaExceeded('q'), denied]));
      await failureOf(service);
      await failureOf(service);
      expect(store.value.permissionErrors, 2);
      await service.scan(fakeJpeg());
      expect(store.value.permissionErrors, 0);
      await failureOf(service);
      await failureOf(service);
      expect(store.value.permissionErrors, 2);
      await failureOf(service); // quota: the server answered, so the app is accepted
      expect(store.value.permissionErrors, 0);

      final offline = make(FakeReceiptReader([denied, const SocketException('x')]));
      store.value = const OcrSettings(consentAt: 1);
      await failureOf(offline);
      await failureOf(offline);
      expect(store.value.permissionErrors, 1);
    });
  });

  group('classifyScanError reads the exception class and, for a 403 with no class, the message', () {
    test('mapping', () {
      expect(classifyScanError(QuotaExceeded('x')).failure, ReceiptScanFailure.quotaExhausted);
      expect(classifyScanError(InvalidApiKey('x')).failure, ReceiptScanFailure.permissionDenied);
      expect(classifyScanError(ServiceApiNotEnabled('x')).failure, ReceiptScanFailure.permissionDenied);
      expect(classifyScanError(ServerException('Resource exhausted, please try again later')).failure, ReceiptScanFailure.quotaExhausted);
      expect(classifyScanError(ServerException('PERMISSION_DENIED: The caller does not have permission')).failure, ReceiptScanFailure.permissionDenied);
      expect(classifyScanError(const HandshakeException('x')).failure, ReceiptScanFailure.offline);
      expect(classifyScanError(Exception('Failed host lookup: firebasevertexai.googleapis.com')).failure, ReceiptScanFailure.offline);
      expect(classifyScanError(const FormatException('x')).failure, ReceiptScanFailure.invalidResponse);
      expect(classifyScanError(StateError('x')).failure, ReceiptScanFailure.unavailable);
    });
  });

  test('a scan creates no file anywhere: the photo stays in memory (nothing outside the temp directory)', () async {
    final attempts = <String>[];
    final reader = FakeReceiptReader([goodJson]);
    await IOOverrides.runZoned(
      () => make(reader).scan(fakeJpeg()),
      createFile: (path) {
        attempts.add(path);
        throw StateError('the scan must not create files');
      },
      createDirectory: (path) {
        attempts.add(path);
        throw StateError('the scan must not create directories');
      },
    );
    expect(attempts, isEmpty);
  });
}
