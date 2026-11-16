// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_groups_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProblemGroupsInner extends ProblemGroupsInner {
  @override
  final String id;
  @override
  final String name;

  factory _$ProblemGroupsInner(
          [void Function(ProblemGroupsInnerBuilder)? updates]) =>
      (ProblemGroupsInnerBuilder()..update(updates))._build();

  _$ProblemGroupsInner._({required this.id, required this.name}) : super._();
  @override
  ProblemGroupsInner rebuild(
          void Function(ProblemGroupsInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProblemGroupsInnerBuilder toBuilder() =>
      ProblemGroupsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProblemGroupsInner && id == other.id && name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProblemGroupsInner')
          ..add('id', id)
          ..add('name', name))
        .toString();
  }
}

class ProblemGroupsInnerBuilder
    implements Builder<ProblemGroupsInner, ProblemGroupsInnerBuilder> {
  _$ProblemGroupsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ProblemGroupsInnerBuilder() {
    ProblemGroupsInner._defaults(this);
  }

  ProblemGroupsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProblemGroupsInner other) {
    _$v = other as _$ProblemGroupsInner;
  }

  @override
  void update(void Function(ProblemGroupsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProblemGroupsInner build() => _build();

  _$ProblemGroupsInner _build() {
    final _$result = _$v ??
        _$ProblemGroupsInner._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ProblemGroupsInner', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'ProblemGroupsInner', 'name'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
