// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_member_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateMemberRequest extends CreateMemberRequest {
  @override
  final String displayName;

  factory _$CreateMemberRequest(
          [void Function(CreateMemberRequestBuilder)? updates]) =>
      (CreateMemberRequestBuilder()..update(updates))._build();

  _$CreateMemberRequest._({required this.displayName}) : super._();
  @override
  CreateMemberRequest rebuild(
          void Function(CreateMemberRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateMemberRequestBuilder toBuilder() =>
      CreateMemberRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateMemberRequest && displayName == other.displayName;
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
    return (newBuiltValueToStringHelper(r'CreateMemberRequest')
          ..add('displayName', displayName))
        .toString();
  }
}

class CreateMemberRequestBuilder
    implements Builder<CreateMemberRequest, CreateMemberRequestBuilder> {
  _$CreateMemberRequest? _$v;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  CreateMemberRequestBuilder() {
    CreateMemberRequest._defaults(this);
  }

  CreateMemberRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _displayName = $v.displayName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateMemberRequest other) {
    _$v = other as _$CreateMemberRequest;
  }

  @override
  void update(void Function(CreateMemberRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateMemberRequest build() => _build();

  _$CreateMemberRequest _build() {
    final _$result = _$v ??
        _$CreateMemberRequest._(
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'CreateMemberRequest', 'displayName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
