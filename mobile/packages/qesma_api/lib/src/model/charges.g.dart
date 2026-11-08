// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charges.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Charges extends Charges {
  @override
  final int adjustmentMinor;
  @override
  final ServiceCharge? service;
  @override
  final int subtotalMinor;
  @override
  final TaxCharge? tax;

  factory _$Charges([void Function(ChargesBuilder)? updates]) =>
      (ChargesBuilder()..update(updates))._build();

  _$Charges._(
      {required this.adjustmentMinor,
      this.service,
      required this.subtotalMinor,
      this.tax})
      : super._();
  @override
  Charges rebuild(void Function(ChargesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChargesBuilder toBuilder() => ChargesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Charges &&
        adjustmentMinor == other.adjustmentMinor &&
        service == other.service &&
        subtotalMinor == other.subtotalMinor &&
        tax == other.tax;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adjustmentMinor.hashCode);
    _$hash = $jc(_$hash, service.hashCode);
    _$hash = $jc(_$hash, subtotalMinor.hashCode);
    _$hash = $jc(_$hash, tax.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Charges')
          ..add('adjustmentMinor', adjustmentMinor)
          ..add('service', service)
          ..add('subtotalMinor', subtotalMinor)
          ..add('tax', tax))
        .toString();
  }
}

class ChargesBuilder implements Builder<Charges, ChargesBuilder> {
  _$Charges? _$v;

  int? _adjustmentMinor;
  int? get adjustmentMinor => _$this._adjustmentMinor;
  set adjustmentMinor(int? adjustmentMinor) =>
      _$this._adjustmentMinor = adjustmentMinor;

  ServiceChargeBuilder? _service;
  ServiceChargeBuilder get service =>
      _$this._service ??= ServiceChargeBuilder();
  set service(ServiceChargeBuilder? service) => _$this._service = service;

  int? _subtotalMinor;
  int? get subtotalMinor => _$this._subtotalMinor;
  set subtotalMinor(int? subtotalMinor) =>
      _$this._subtotalMinor = subtotalMinor;

  TaxChargeBuilder? _tax;
  TaxChargeBuilder get tax => _$this._tax ??= TaxChargeBuilder();
  set tax(TaxChargeBuilder? tax) => _$this._tax = tax;

  ChargesBuilder() {
    Charges._defaults(this);
  }

  ChargesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adjustmentMinor = $v.adjustmentMinor;
      _service = $v.service?.toBuilder();
      _subtotalMinor = $v.subtotalMinor;
      _tax = $v.tax?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Charges other) {
    _$v = other as _$Charges;
  }

  @override
  void update(void Function(ChargesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Charges build() => _build();

  _$Charges _build() {
    _$Charges _$result;
    try {
      _$result = _$v ??
          _$Charges._(
            adjustmentMinor: BuiltValueNullFieldError.checkNotNull(
                adjustmentMinor, r'Charges', 'adjustmentMinor'),
            service: _service?.build(),
            subtotalMinor: BuiltValueNullFieldError.checkNotNull(
                subtotalMinor, r'Charges', 'subtotalMinor'),
            tax: _tax?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'service';
        _service?.build();

        _$failedField = 'tax';
        _tax?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Charges', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
