// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_charge.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TaxCharge extends TaxCharge {
  @override
  final int amountMinor;
  @override
  final String base_;
  @override
  final int bps;

  factory _$TaxCharge([void Function(TaxChargeBuilder)? updates]) =>
      (TaxChargeBuilder()..update(updates))._build();

  _$TaxCharge._(
      {required this.amountMinor, required this.base_, required this.bps})
      : super._();
  @override
  TaxCharge rebuild(void Function(TaxChargeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TaxChargeBuilder toBuilder() => TaxChargeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TaxCharge &&
        amountMinor == other.amountMinor &&
        base_ == other.base_ &&
        bps == other.bps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, base_.hashCode);
    _$hash = $jc(_$hash, bps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TaxCharge')
          ..add('amountMinor', amountMinor)
          ..add('base_', base_)
          ..add('bps', bps))
        .toString();
  }
}

class TaxChargeBuilder implements Builder<TaxCharge, TaxChargeBuilder> {
  _$TaxCharge? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _base_;
  String? get base_ => _$this._base_;
  set base_(String? base_) => _$this._base_ = base_;

  int? _bps;
  int? get bps => _$this._bps;
  set bps(int? bps) => _$this._bps = bps;

  TaxChargeBuilder() {
    TaxCharge._defaults(this);
  }

  TaxChargeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _base_ = $v.base_;
      _bps = $v.bps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TaxCharge other) {
    _$v = other as _$TaxCharge;
  }

  @override
  void update(void Function(TaxChargeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TaxCharge build() => _build();

  _$TaxCharge _build() {
    final _$result = _$v ??
        _$TaxCharge._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'TaxCharge', 'amountMinor'),
          base_: BuiltValueNullFieldError.checkNotNull(
              base_, r'TaxCharge', 'base_'),
          bps: BuiltValueNullFieldError.checkNotNull(bps, r'TaxCharge', 'bps'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
