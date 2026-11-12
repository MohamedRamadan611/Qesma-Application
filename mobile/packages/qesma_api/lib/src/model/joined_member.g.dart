// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'joined_member.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JoinedMember extends JoinedMember {
  @override
  final String? displayName;
  @override
  final String? id;
  @override
  final String? role;

  factory _$JoinedMember([void Function(JoinedMemberBuilder)? updates]) =>
      (JoinedMemberBuilder()..update(updates))._build();

  _$JoinedMember._({this.displayName, this.id, this.role}) : super._();
  @override
  JoinedMember rebuild(void Function(JoinedMemberBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JoinedMemberBuilder toBuilder() => JoinedMemberBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JoinedMember &&
        displayName == other.displayName &&
        id == other.id &&
        role == other.role;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JoinedMember')
          ..add('displayName', displayName)
          ..add('id', id)
          ..add('role', role))
        .toString();
  }
}

class JoinedMemberBuilder
    implements Builder<JoinedMember, JoinedMemberBuilder> {
  _$JoinedMember? _$v;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  JoinedMemberBuilder() {
    JoinedMember._defaults(this);
  }

  JoinedMemberBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _displayName = $v.displayName;
      _id = $v.id;
      _role = $v.role;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JoinedMember other) {
    _$v = other as _$JoinedMember;
  }

  @override
  void update(void Function(JoinedMemberBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JoinedMember build() => _build();

  _$JoinedMember _build() {
    final _$result = _$v ??
        _$JoinedMember._(
          displayName: displayName,
          id: id,
          role: role,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
