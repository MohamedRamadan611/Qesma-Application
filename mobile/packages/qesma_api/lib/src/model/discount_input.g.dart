// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discount_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DiscountInput extends DiscountInput {
  @override
  final int? amountMinor;
  @override
  final int? bps;

  factory _$DiscountInput([void Function(DiscountInputBuilder)? updates]) =>
      (DiscountInputBuilder()..update(updates))._build();

  _$DiscountInput._({this.amountMinor, this.bps}) : super._();
  @override
  DiscountInput rebuild(void Function(DiscountInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DiscountInputBuilder toBuilder() => DiscountInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DiscountInput &&
        amountMinor == other.amountMinor &&
        bps == other.bps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, bps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DiscountInput')
          ..add('amountMinor', amountMinor)
          ..add('bps', bps))
        .toString();
  }
}

class DiscountInputBuilder
    implements Builder<DiscountInput, DiscountInputBuilder> {
  _$DiscountInput? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  int? _bps;
  int? get bps => _$this._bps;
  set bps(int? bps) => _$this._bps = bps;

  DiscountInputBuilder() {
    DiscountInput._defaults(this);
  }

  DiscountInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _bps = $v.bps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DiscountInput other) {
    _$v = other as _$DiscountInput;
  }

  @override
  void update(void Function(DiscountInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DiscountInput build() => _build();

  _$DiscountInput _build() {
    final _$result = _$v ??
        _$DiscountInput._(
          amountMinor: amountMinor,
          bps: bps,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
