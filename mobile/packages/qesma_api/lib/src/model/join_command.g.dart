// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JoinCommand extends JoinCommand {
  @override
  final String? claimMemberId;
  @override
  final String? newMemberName;

  factory _$JoinCommand([void Function(JoinCommandBuilder)? updates]) =>
      (JoinCommandBuilder()..update(updates))._build();

  _$JoinCommand._({this.claimMemberId, this.newMemberName}) : super._();
  @override
  JoinCommand rebuild(void Function(JoinCommandBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JoinCommandBuilder toBuilder() => JoinCommandBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JoinCommand &&
        claimMemberId == other.claimMemberId &&
        newMemberName == other.newMemberName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, claimMemberId.hashCode);
    _$hash = $jc(_$hash, newMemberName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JoinCommand')
          ..add('claimMemberId', claimMemberId)
          ..add('newMemberName', newMemberName))
        .toString();
  }
}

class JoinCommandBuilder implements Builder<JoinCommand, JoinCommandBuilder> {
  _$JoinCommand? _$v;

  String? _claimMemberId;
  String? get claimMemberId => _$this._claimMemberId;
  set claimMemberId(String? claimMemberId) =>
      _$this._claimMemberId = claimMemberId;

  String? _newMemberName;
  String? get newMemberName => _$this._newMemberName;
  set newMemberName(String? newMemberName) =>
      _$this._newMemberName = newMemberName;

  JoinCommandBuilder() {
    JoinCommand._defaults(this);
  }

  JoinCommandBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _claimMemberId = $v.claimMemberId;
      _newMemberName = $v.newMemberName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JoinCommand other) {
    _$v = other as _$JoinCommand;
  }

  @override
  void update(void Function(JoinCommandBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JoinCommand build() => _build();

  _$JoinCommand _build() {
    final _$result = _$v ??
        _$JoinCommand._(
          claimMemberId: claimMemberId,
          newMemberName: newMemberName,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
