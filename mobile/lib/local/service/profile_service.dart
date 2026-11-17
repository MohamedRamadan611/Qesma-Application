import 'package:qesma_api/qesma_api.dart';

import '../db/local_database.dart';
import '../errors.dart';
import 'field_rules.dart';
import 'local_context.dart';
import 'views.dart';

/// The one local user (STANDALONE_SPEC 3.6): `GET/PATCH /me` over `local_profile`, and the user's own payment
/// handles (`GET/PUT /me/payment-handles`, rules of Java `PaymentHandleRules`).
final class ProfileService {
  ProfileService(this._ctx);

  final LocalContext _ctx;

  LocalDatabase get _db => _ctx.db;

  /// Creates the profile on first use (local onboarding, SA4) and returns it; an existing profile is kept as is.
  Future<UserDto> ensureProfile(String displayName) => _db.transaction(() async {
        final existing = await _db.profileDao.find();
        if (existing != null) return userDto(existing);
        final name = _displayName(displayName);
        final now = _ctx.clock();
        await _db.profileDao.insertProfile(
          LocalProfileCompanion.insert(id: _ctx.newId(), displayName: name, createdAt: now, updatedAt: now),
        );
        return userDto((await _db.profileDao.find())!);
      });

  Future<UserDto> me() => _db.transaction(() async => userDto(await _ctx.profile()));

  /// Renames the user (1..60 code points); group member names are not changed.
  Future<UserDto> updateMe(String? displayName) => _db.transaction(() async {
        // First run: no profile yet, so this PATCH is the onboarding and creates it (SA4).
        if (await _db.profileDao.find() == null) return ensureProfile(_displayName(displayName));
        final me = await _ctx.profile();
        await _db.profileDao.rename(me.id, _displayName(displayName), _ctx.clock());
        return userDto((await _db.profileDao.find())!);
      });

  Future<PaymentHandlesView> handles() => _db.transaction(() async => handlesOf((await _ctx.profile()).id));

  /// Replaces both handles; null or blank removes that handle.
  Future<PaymentHandlesView> replaceHandles({String? instapay, String? wallet}) => _db.transaction(() async {
        final validInstapay = HandleRules.instapay(instapay);
        final validWallet = HandleRules.wallet(wallet);
        final me = await _ctx.profile();
        await _apply(me.id, 'INSTAPAY', validInstapay);
        await _apply(me.id, 'WALLET', validWallet);
        return handlesOf(me.id);
      });

  Future<PaymentHandlesView> handlesOf(String userId) async {
    final rows = await _db.paymentHandlesDao.listForUser(userId);
    String? valueOf(String type) {
      for (final r in rows) {
        if (r.type == type) return r.value;
      }
      return null;
    }

    return PaymentHandlesView((b) => b
      ..instapay = valueOf('INSTAPAY')
      ..wallet = valueOf('WALLET'));
  }

  Future<void> _apply(String userId, String type, String? value) async {
    if (value == null) {
      await _db.paymentHandlesDao.deleteType(userId, type);
      return;
    }
    final now = _ctx.clock();
    await _db.paymentHandlesDao.upsert(
      PaymentHandleRow(id: _ctx.newId(), userId: userId, type: type, value: value, createdAt: now, updatedAt: now),
    );
  }

  static String _displayName(String? raw) {
    final name = javaStrip(raw ?? '');
    if (name.isEmpty) throw LocalApiException.validation('displayName must not be blank');
    if (codePoints(name) > FieldRules.profileNameMax) {
      throw LocalApiException.validation('displayName must be at most ${FieldRules.profileNameMax} characters');
    }
    return name;
  }
}

/// Port of Java `PaymentHandleRules`: normalization and validation of the user's own handles.
abstract final class HandleRules {
  static final RegExp _wallet = RegExp(r'^01[0125][0-9]{8}$');
  static final RegExp _instapay = RegExp(r'^[a-z0-9._-]+@[a-z0-9.-]+$');

  /// Egyptian mobile wallet: Arabic-Indic digits mapped, spaces/dashes dropped, `+20`/`0020` -> `0`.
  static String? wallet(String? raw) {
    if (raw == null || javaStrip(raw).isEmpty) return null;
    final sb = StringBuffer();
    for (final c in raw.codeUnits) {
      if (c >= 0x0660 && c <= 0x0669) {
        sb.writeCharCode(0x30 + (c - 0x0660));
      } else if (c >= 0x06F0 && c <= 0x06F9) {
        sb.writeCharCode(0x30 + (c - 0x06F0));
      } else if (c == 0x20 || c == 0xA0 || c == 0x2D || c == 0x2010 || c == 0x2011 || c == 0x09) {
        continue;
      } else {
        sb.writeCharCode(c);
      }
    }
    var s = sb.toString();
    if (s.startsWith('+20')) {
      s = '0${s.substring(3)}';
    } else if (s.startsWith('0020')) {
      s = '0${s.substring(4)}';
    }
    if (!_wallet.hasMatch(s)) {
      throw LocalApiException.validation('wallet must be an Egyptian mobile number such as 01012345678');
    }
    return s;
  }

  /// InstaPay address: ASCII only (checked before lower-casing), 3..60 characters, `name@bank`, one `@`.
  static String? instapay(String? raw) {
    if (raw == null || javaStrip(raw).isEmpty) return null;
    var s = javaStrip(raw);
    if (s.codeUnits.any((c) => c > 127) || s.length < 3 || s.length > 60) throw _bad();
    s = s.toLowerCase();
    if (!_instapay.hasMatch(s) || s.indexOf('@') != s.lastIndexOf('@')) throw _bad();
    return s;
  }

  static LocalApiException _bad() =>
      LocalApiException.validation('instapay must look like name@bank (3 to 60 letters, digits, dots, dashes)');
}
