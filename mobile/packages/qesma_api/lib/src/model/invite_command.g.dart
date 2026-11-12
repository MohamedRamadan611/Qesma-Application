// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InviteCommand extends InviteCommand {
  @override
  final int? expiresInDays;
  @override
  final int? maxUses;
  @override
  final bool? requiresApproval;

  factory _$InviteCommand([void Function(InviteCommandBuilder)? updates]) =>
      (InviteCommandBuilder()..update(updates))._build();

  _$InviteCommand._({this.expiresInDays, this.maxUses, this.requiresApproval})
      : super._();
  @override
  InviteCommand rebuild(void Function(InviteCommandBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InviteCommandBuilder toBuilder() => InviteCommandBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InviteCommand &&
        expiresInDays == other.expiresInDays &&
        maxUses == other.maxUses &&
        requiresApproval == other.requiresApproval;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, expiresInDays.hashCode);
    _$hash = $jc(_$hash, maxUses.hashCode);
    _$hash = $jc(_$hash, requiresApproval.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InviteCommand')
          ..add('expiresInDays', expiresInDays)
          ..add('maxUses', maxUses)
          ..add('requiresApproval', requiresApproval))
        .toString();
  }
}

class InviteCommandBuilder
    implements Builder<InviteCommand, InviteCommandBuilder> {
  _$InviteCommand? _$v;

  int? _expiresInDays;
  int? get expiresInDays => _$this._expiresInDays;
  set expiresInDays(int? expiresInDays) =>
      _$this._expiresInDays = expiresInDays;

  int? _maxUses;
  int? get maxUses => _$this._maxUses;
  set maxUses(int? maxUses) => _$this._maxUses = maxUses;

  bool? _requiresApproval;
  bool? get requiresApproval => _$this._requiresApproval;
  set requiresApproval(bool? requiresApproval) =>
      _$this._requiresApproval = requiresApproval;

  InviteCommandBuilder() {
    InviteCommand._defaults(this);
  }

  InviteCommandBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _expiresInDays = $v.expiresInDays;
      _maxUses = $v.maxUses;
      _requiresApproval = $v.requiresApproval;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InviteCommand other) {
    _$v = other as _$InviteCommand;
  }

  @override
  void update(void Function(InviteCommandBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InviteCommand build() => _build();

  _$InviteCommand _build() {
    final _$result = _$v ??
        _$InviteCommand._(
          expiresInDays: expiresInDays,
          maxUses: maxUses,
          requiresApproval: requiresApproval,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
