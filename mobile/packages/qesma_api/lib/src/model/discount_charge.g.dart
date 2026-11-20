// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discount_charge.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DiscountCharge extends DiscountCharge {
  @override
  final int amountMinor;
  @override
  final int? bps;

  factory _$DiscountCharge([void Function(DiscountChargeBuilder)? updates]) =>
      (DiscountChargeBuilder()..update(updates))._build();

  _$DiscountCharge._({required this.amountMinor, this.bps}) : super._();
  @override
  DiscountCharge rebuild(void Function(DiscountChargeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DiscountChargeBuilder toBuilder() => DiscountChargeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DiscountCharge &&
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
    return (newBuiltValueToStringHelper(r'DiscountCharge')
          ..add('amountMinor', amountMinor)
          ..add('bps', bps))
        .toString();
  }
}

class DiscountChargeBuilder
    implements Builder<DiscountCharge, DiscountChargeBuilder> {
  _$DiscountCharge? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  int? _bps;
  int? get bps => _$this._bps;
  set bps(int? bps) => _$this._bps = bps;

  DiscountChargeBuilder() {
    DiscountCharge._defaults(this);
  }

  DiscountChargeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _bps = $v.bps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DiscountCharge other) {
    _$v = other as _$DiscountCharge;
  }

  @override
  void update(void Function(DiscountChargeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DiscountCharge build() => _build();

  _$DiscountCharge _build() {
    final _$result = _$v ??
        _$DiscountCharge._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'DiscountCharge', 'amountMinor'),
          bps: bps,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
