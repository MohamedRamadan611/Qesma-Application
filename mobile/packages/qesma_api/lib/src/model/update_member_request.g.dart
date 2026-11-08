// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_member_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateMemberRequest extends UpdateMemberRequest {
  @override
  final String displayName;

  factory _$UpdateMemberRequest(
          [void Function(UpdateMemberRequestBuilder)? updates]) =>
      (UpdateMemberRequestBuilder()..update(updates))._build();

  _$UpdateMemberRequest._({required this.displayName}) : super._();
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
    return other is UpdateMemberRequest && displayName == other.displayName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateMemberRequest')
          ..add('displayName', displayName))
        .toString();
  }
}

class UpdateMemberRequestBuilder
    implements Builder<UpdateMemberRequest, UpdateMemberRequestBuilder> {
  _$UpdateMemberRequest? _$v;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  UpdateMemberRequestBuilder() {
    UpdateMemberRequest._defaults(this);
  }

  UpdateMemberRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _displayName = $v.displayName;
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
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'UpdateMemberRequest', 'displayName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
