// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_account_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeleteAccountRequest extends DeleteAccountRequest {
  @override
  final String? confirm;
  @override
  final String? password;

  factory _$DeleteAccountRequest(
          [void Function(DeleteAccountRequestBuilder)? updates]) =>
      (DeleteAccountRequestBuilder()..update(updates))._build();

  _$DeleteAccountRequest._({this.confirm, this.password}) : super._();
  @override
  DeleteAccountRequest rebuild(
          void Function(DeleteAccountRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeleteAccountRequestBuilder toBuilder() =>
      DeleteAccountRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeleteAccountRequest &&
        confirm == other.confirm &&
        password == other.password;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, confirm.hashCode);
    _$hash = $jc(_$hash, password.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeleteAccountRequest')
          ..add('confirm', confirm)
          ..add('password', password))
        .toString();
  }
}

class DeleteAccountRequestBuilder
    implements Builder<DeleteAccountRequest, DeleteAccountRequestBuilder> {
  _$DeleteAccountRequest? _$v;

  String? _confirm;
  String? get confirm => _$this._confirm;
  set confirm(String? confirm) => _$this._confirm = confirm;

  String? _password;
  String? get password => _$this._password;
  set password(String? password) => _$this._password = password;

  DeleteAccountRequestBuilder() {
    DeleteAccountRequest._defaults(this);
  }

  DeleteAccountRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _confirm = $v.confirm;
      _password = $v.password;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeleteAccountRequest other) {
    _$v = other as _$DeleteAccountRequest;
  }

  @override
  void update(void Function(DeleteAccountRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeleteAccountRequest build() => _build();

  _$DeleteAccountRequest _build() {
    final _$result = _$v ??
        _$DeleteAccountRequest._(
          confirm: confirm,
          password: password,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
