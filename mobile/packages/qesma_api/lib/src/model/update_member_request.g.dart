// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_member_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMemberRequest extends UpdateMemberRequest {
  @override
  final bool? clearDefaultShareUnits;
  @override
  final int? defaultShareUnits;
  @override
  final String? displayName;
  @override
  final String? role;
  @override
  final String? status;

  factory _$UpdateMemberRequest(
          [void Function(UpdateMemberRequestBuilder)? updates]) =>
      (UpdateMemberRequestBuilder()..update(updates))._build();

  _$UpdateMemberRequest._(
      {this.clearDefaultShareUnits,
      this.defaultShareUnits,
      this.displayName,
      this.role,
      this.status})
      : super._();
  @override
  UpdateMemberRequest rebuild(
          void Function(UpdateMemberRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateMemberRequestBuilder toBuilder() =>
      UpdateMemberRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateMemberRequest &&
        clearDefaultShareUnits == other.clearDefaultShareUnits &&
        defaultShareUnits == other.defaultShareUnits &&
        displayName == other.displayName &&
        role == other.role &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, clearDefaultShareUnits.hashCode);
    _$hash = $jc(_$hash, defaultShareUnits.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateMemberRequest')
          ..add('clearDefaultShareUnits', clearDefaultShareUnits)
          ..add('defaultShareUnits', defaultShareUnits)
          ..add('displayName', displayName)
          ..add('role', role)
          ..add('status', status))
        .toString();
  }
}

class UpdateMemberRequestBuilder
    implements Builder<UpdateMemberRequest, UpdateMemberRequestBuilder> {
  _$UpdateMemberRequest? _$v;

  bool? _clearDefaultShareUnits;
  bool? get clearDefaultShareUnits => _$this._clearDefaultShareUnits;
  set clearDefaultShareUnits(bool? clearDefaultShareUnits) =>
      _$this._clearDefaultShareUnits = clearDefaultShareUnits;

  int? _defaultShareUnits;
  int? get defaultShareUnits => _$this._defaultShareUnits;
  set defaultShareUnits(int? defaultShareUnits) =>
      _$this._defaultShareUnits = defaultShareUnits;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  UpdateMemberRequestBuilder() {
    UpdateMemberRequest._defaults(this);
  }

  UpdateMemberRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _clearDefaultShareUnits = $v.clearDefaultShareUnits;
      _defaultShareUnits = $v.defaultShareUnits;
      _displayName = $v.displayName;
      _role = $v.role;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateMemberRequest other) {
    _$v = other as _$UpdateMemberRequest;
  }

  @override
  void update(void Function(UpdateMemberRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateMemberRequest build() => _build();

  _$UpdateMemberRequest _build() {
    final _$result = _$v ??
        _$UpdateMemberRequest._(
          clearDefaultShareUnits: clearDefaultShareUnits,
          defaultShareUnits: defaultShareUnits,
          displayName: displayName,
          role: role,
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
