import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'invite_code.dart';

/// Where a code waits while a signed-out person signs in (the process may be killed during the Google picker).
abstract interface class PendingInviteStorage {
  Future<String?> read();
  Future<void> write(String code);

  /// Never throws.
  Future<void> clear();
}

class SecurePendingInviteStorage implements PendingInviteStorage {
  SecurePendingInviteStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'qesma.pending_invite';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      final value = await _storage.read(key: _key);
      return value == null ? null : normaliseInviteCode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String code) async {
    try {
      await _storage.write(key: _key, value: code);
    } catch (_) {
      // Memory still holds it; only a killed process loses the invite.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

class InMemoryPendingInviteStorage implements PendingInviteStorage {
  InMemoryPendingInviteStorage([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String code) async => value = code;

  @override
  Future<void> clear() async => value = null;
}

final pendingInviteStorageProvider = Provider<PendingInviteStorage>((ref) => SecurePendingInviteStorage());

/// The invite a signed-out person opened. [code] is a secret: it lives in memory and secure storage only until
/// it is used (joined, awaiting approval, already a member) or found to be dead (expired, revoked, unknown),
/// and `toString` never prints it.
class PendingInviteState {
  const PendingInviteState({this.code, this.delivered = false});

  final String? code;

  /// The sign-in return already sent the person to the join screen once; do not do it again (no loop).
  final bool delivered;

  @override
  String toString() => 'PendingInviteState(${code == null ? 'none' : 'set'}, delivered: $delivered)';
}

class PendingInvite extends Notifier<PendingInviteState> {
  @override
  PendingInviteState build() => const PendingInviteState();

  PendingInviteStorage get _storage => ref.read(pendingInviteStorageProvider);

  /// Remembers a validated code. An invalid one is ignored (nothing is stored).
  Future<void> remember(String? raw) async {
    final code = normaliseInviteCode(raw);
    if (code == null || state.code == code) return;
    state = PendingInviteState(code: code);
    await _storage.write(code);
  }

  /// Loads what a killed process left behind (called once at startup).
  Future<void> restore() async {
    if (state.code != null) return;
    final stored = await _storage.read();
    if (stored != null && ref.mounted && state.code == null) state = PendingInviteState(code: stored);
  }

  /// The join screen is showing this code, so a sign-in return must not open it a second time.
  void markDelivered(String code) {
    if (state.code == code && !state.delivered) state = PendingInviteState(code: code, delivered: true);
  }

  /// Used or dead: forget it.
  Future<void> clear() async {
    state = const PendingInviteState();
    await _storage.clear();
  }
}

final pendingInviteProvider = NotifierProvider<PendingInvite, PendingInviteState>(PendingInvite.new);
