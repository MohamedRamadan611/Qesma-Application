// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_group_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateGroupRequest extends UpdateGroupRequest {
  @override
  final String? name;
  @override
  final String? type;

  factory _$UpdateGroupRequest(
          [void Function(UpdateGroupRequestBuilder)? updates]) =>
      (UpdateGroupRequestBuilder()..update(updates))._build();

  _$UpdateGroupRequest._({this.name, this.type}) : super._();
  @override
  UpdateGroupRequest rebuild(
          void Function(UpdateGroupRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateGroupRequestBuilder toBuilder() =>
      UpdateGroupRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateGroupRequest &&
        name == other.name &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateGroupRequest')
          ..add('name', name)
          ..add('type', type))
        .toString();
  }
}

class UpdateGroupRequestBuilder
    implements Builder<UpdateGroupRequest, UpdateGroupRequestBuilder> {
  _$UpdateGroupRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  UpdateGroupRequestBuilder() {
    UpdateGroupRequest._defaults(this);
  }

  UpdateGroupRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateGroupRequest other) {
    _$v = other as _$UpdateGroupRequest;
  }

  @override
  void update(void Function(UpdateGroupRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateGroupRequest build() => _build();

  _$UpdateGroupRequest _build() {
    final _$result = _$v ??
        _$UpdateGroupRequest._(
          name: name,
          type: type,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
