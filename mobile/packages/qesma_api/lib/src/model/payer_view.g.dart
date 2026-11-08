// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payer_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PayerView extends PayerView {
  @override
  final int amountMinor;
  @override
  final String memberId;

  factory _$PayerView([void Function(PayerViewBuilder)? updates]) =>
      (PayerViewBuilder()..update(updates))._build();

  _$PayerView._({required this.amountMinor, required this.memberId})
      : super._();
  @override
  PayerView rebuild(void Function(PayerViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PayerViewBuilder toBuilder() => PayerViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PayerView &&
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
    return (newBuiltValueToStringHelper(r'PayerView')
          ..add('amountMinor', amountMinor)
          ..add('memberId', memberId))
        .toString();
  }
}

class PayerViewBuilder implements Builder<PayerView, PayerViewBuilder> {
  _$PayerView? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  PayerViewBuilder() {
    PayerView._defaults(this);
  }

  PayerViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _memberId = $v.memberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PayerView other) {
    _$v = other as _$PayerView;
  }

  @override
  void update(void Function(PayerViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PayerView build() => _build();

  _$PayerView _build() {
    final _$result = _$v ??
        _$PayerView._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'PayerView', 'amountMinor'),
          memberId: BuiltValueNullFieldError.checkNotNull(
              memberId, r'PayerView', 'memberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
