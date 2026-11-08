// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_group_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateGroupRequest extends CreateGroupRequest {
  @override
  final String? currencyCode;
  @override
  final String name;
  @override
  final String type;

  factory _$CreateGroupRequest(
          [void Function(CreateGroupRequestBuilder)? updates]) =>
      (CreateGroupRequestBuilder()..update(updates))._build();

  _$CreateGroupRequest._(
      {this.currencyCode, required this.name, required this.type})
      : super._();
  @override
  CreateGroupRequest rebuild(
          void Function(CreateGroupRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateGroupRequestBuilder toBuilder() =>
      CreateGroupRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateGroupRequest &&
        currencyCode == other.currencyCode &&
        name == other.name &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currencyCode.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateGroupRequest')
          ..add('currencyCode', currencyCode)
          ..add('name', name)
          ..add('type', type))
        .toString();
  }
}

class CreateGroupRequestBuilder
    implements Builder<CreateGroupRequest, CreateGroupRequestBuilder> {
  _$CreateGroupRequest? _$v;

  String? _currencyCode;
  String? get currencyCode => _$this._currencyCode;
  set currencyCode(String? currencyCode) => _$this._currencyCode = currencyCode;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  CreateGroupRequestBuilder() {
    CreateGroupRequest._defaults(this);
  }

  CreateGroupRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currencyCode = $v.currencyCode;
      _name = $v.name;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateGroupRequest other) {
    _$v = other as _$CreateGroupRequest;
  }

  @override
  void update(void Function(CreateGroupRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateGroupRequest build() => _build();

  _$CreateGroupRequest _build() {
    final _$result = _$v ??
        _$CreateGroupRequest._(
          currencyCode: currencyCode,
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'CreateGroupRequest', 'name'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'CreateGroupRequest', 'type'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
