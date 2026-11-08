// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SettlementCommand extends SettlementCommand {
  @override
  final int amountMinor;
  @override
  final String fromMemberId;
  @override
  final String? note;
  @override
  final Date settledOn;
  @override
  final String toMemberId;

  factory _$SettlementCommand(
          [void Function(SettlementCommandBuilder)? updates]) =>
      (SettlementCommandBuilder()..update(updates))._build();

  _$SettlementCommand._(
      {required this.amountMinor,
      required this.fromMemberId,
      this.note,
      required this.settledOn,
      required this.toMemberId})
      : super._();
  @override
  SettlementCommand rebuild(void Function(SettlementCommandBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SettlementCommandBuilder toBuilder() =>
      SettlementCommandBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SettlementCommand &&
        amountMinor == other.amountMinor &&
        fromMemberId == other.fromMemberId &&
        note == other.note &&
        settledOn == other.settledOn &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, settledOn.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SettlementCommand')
          ..add('amountMinor', amountMinor)
          ..add('fromMemberId', fromMemberId)
          ..add('note', note)
          ..add('settledOn', settledOn)
          ..add('toMemberId', toMemberId))
        .toString();
  }
}

class SettlementCommandBuilder
    implements Builder<SettlementCommand, SettlementCommandBuilder> {
  _$SettlementCommand? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _fromMemberId;
  String? get fromMemberId => _$this._fromMemberId;
  set fromMemberId(String? fromMemberId) => _$this._fromMemberId = fromMemberId;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  Date? _settledOn;
  Date? get settledOn => _$this._settledOn;
  set settledOn(Date? settledOn) => _$this._settledOn = settledOn;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  SettlementCommandBuilder() {
    SettlementCommand._defaults(this);
  }

  SettlementCommandBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _fromMemberId = $v.fromMemberId;
      _note = $v.note;
      _settledOn = $v.settledOn;
      _toMemberId = $v.toMemberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SettlementCommand other) {
    _$v = other as _$SettlementCommand;
  }

  @override
  void update(void Function(SettlementCommandBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SettlementCommand build() => _build();

  _$SettlementCommand _build() {
    final _$result = _$v ??
        _$SettlementCommand._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'SettlementCommand', 'amountMinor'),
          fromMemberId: BuiltValueNullFieldError.checkNotNull(
              fromMemberId, r'SettlementCommand', 'fromMemberId'),
          note: note,
          settledOn: BuiltValueNullFieldError.checkNotNull(
              settledOn, r'SettlementCommand', 'settledOn'),
          toMemberId: BuiltValueNullFieldError.checkNotNull(
              toMemberId, r'SettlementCommand', 'toMemberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
