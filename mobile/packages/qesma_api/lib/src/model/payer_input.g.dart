// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PayerInput extends PayerInput {
  @override
  final int amountMinor;
  @override
  final String memberId;

  factory _$PayerInput([void Function(PayerInputBuilder)? updates]) =>
      (PayerInputBuilder()..update(updates))._build();

  _$PayerInput._({required this.amountMinor, required this.memberId})
      : super._();
  @override
  PayerInput rebuild(void Function(PayerInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PayerInputBuilder toBuilder() => PayerInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PayerInput &&
        amountMinor == other.amountMinor &&
        memberId == other.memberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, memberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PayerInput')
          ..add('amountMinor', amountMinor)
          ..add('memberId', memberId))
        .toString();
  }
}

class PayerInputBuilder implements Builder<PayerInput, PayerInputBuilder> {
  _$PayerInput? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  PayerInputBuilder() {
    PayerInput._defaults(this);
  }

  PayerInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _memberId = $v.memberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PayerInput other) {
    _$v = other as _$PayerInput;
  }

  @override
  void update(void Function(PayerInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PayerInput build() => _build();

  _$PayerInput _build() {
    final _$result = _$v ??
        _$PayerInput._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'PayerInput', 'amountMinor'),
          memberId: BuiltValueNullFieldError.checkNotNull(
              memberId, r'PayerInput', 'memberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
