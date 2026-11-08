// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_charge.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ServiceCharge extends ServiceCharge {
  @override
  final int amountMinor;
  @override
  final int bps;

  factory _$ServiceCharge([void Function(ServiceChargeBuilder)? updates]) =>
      (ServiceChargeBuilder()..update(updates))._build();

  _$ServiceCharge._({required this.amountMinor, required this.bps}) : super._();
  @override
  ServiceCharge rebuild(void Function(ServiceChargeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ServiceChargeBuilder toBuilder() => ServiceChargeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ServiceCharge &&
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
    return (newBuiltValueToStringHelper(r'ServiceCharge')
          ..add('amountMinor', amountMinor)
          ..add('bps', bps))
        .toString();
  }
}

class ServiceChargeBuilder
    implements Builder<ServiceCharge, ServiceChargeBuilder> {
  _$ServiceCharge? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  int? _bps;
  int? get bps => _$this._bps;
  set bps(int? bps) => _$this._bps = bps;

  ServiceChargeBuilder() {
    ServiceCharge._defaults(this);
  }

  ServiceChargeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _bps = $v.bps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ServiceCharge other) {
    _$v = other as _$ServiceCharge;
  }

  @override
  void update(void Function(ServiceChargeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ServiceCharge build() => _build();

  _$ServiceCharge _build() {
    final _$result = _$v ??
        _$ServiceCharge._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'ServiceCharge', 'amountMinor'),
          bps: BuiltValueNullFieldError.checkNotNull(
              bps, r'ServiceCharge', 'bps'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
