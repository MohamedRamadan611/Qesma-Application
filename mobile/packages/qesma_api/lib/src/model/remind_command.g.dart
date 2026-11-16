// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remind_command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RemindCommand extends RemindCommand {
  @override
  final String fromMemberId;
  @override
  final String toMemberId;

  factory _$RemindCommand([void Function(RemindCommandBuilder)? updates]) =>
      (RemindCommandBuilder()..update(updates))._build();

  _$RemindCommand._({required this.fromMemberId, required this.toMemberId})
      : super._();
  @override
  RemindCommand rebuild(void Function(RemindCommandBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RemindCommandBuilder toBuilder() => RemindCommandBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RemindCommand &&
        fromMemberId == other.fromMemberId &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RemindCommand')
          ..add('fromMemberId', fromMemberId)
          ..add('toMemberId', toMemberId))
        .toString();
  }
}

class RemindCommandBuilder
    implements Builder<RemindCommand, RemindCommandBuilder> {
  _$RemindCommand? _$v;

  String? _fromMemberId;
  String? get fromMemberId => _$this._fromMemberId;
  set fromMemberId(String? fromMemberId) => _$this._fromMemberId = fromMemberId;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  RemindCommandBuilder() {
    RemindCommand._defaults(this);
  }

  RemindCommandBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _fromMemberId = $v.fromMemberId;
      _toMemberId = $v.toMemberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RemindCommand other) {
    _$v = other as _$RemindCommand;
  }

  @override
  void update(void Function(RemindCommandBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RemindCommand build() => _build();

  _$RemindCommand _build() {
    final _$result = _$v ??
        _$RemindCommand._(
          fromMemberId: BuiltValueNullFieldError.checkNotNull(
              fromMemberId, r'RemindCommand', 'fromMemberId'),
          toMemberId: BuiltValueNullFieldError.checkNotNull(
              toMemberId, r'RemindCommand', 'toMemberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
