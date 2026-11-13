// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_handles_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaymentHandlesView extends PaymentHandlesView {
  @override
  final String? instapay;
  @override
  final String? wallet;

  factory _$PaymentHandlesView(
          [void Function(PaymentHandlesViewBuilder)? updates]) =>
      (PaymentHandlesViewBuilder()..update(updates))._build();

  _$PaymentHandlesView._({this.instapay, this.wallet}) : super._();
  @override
  PaymentHandlesView rebuild(
          void Function(PaymentHandlesViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaymentHandlesViewBuilder toBuilder() =>
      PaymentHandlesViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaymentHandlesView &&
        instapay == other.instapay &&
        wallet == other.wallet;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, instapay.hashCode);
    _$hash = $jc(_$hash, wallet.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaymentHandlesView')
          ..add('instapay', instapay)
          ..add('wallet', wallet))
        .toString();
  }
}

class PaymentHandlesViewBuilder
    implements Builder<PaymentHandlesView, PaymentHandlesViewBuilder> {
  _$PaymentHandlesView? _$v;

  String? _instapay;
  String? get instapay => _$this._instapay;
  set instapay(String? instapay) => _$this._instapay = instapay;

  String? _wallet;
  String? get wallet => _$this._wallet;
  set wallet(String? wallet) => _$this._wallet = wallet;

  PaymentHandlesViewBuilder() {
    PaymentHandlesView._defaults(this);
  }

  PaymentHandlesViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _instapay = $v.instapay;
      _wallet = $v.wallet;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaymentHandlesView other) {
    _$v = other as _$PaymentHandlesView;
  }

  @override
  void update(void Function(PaymentHandlesViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaymentHandlesView build() => _build();

  _$PaymentHandlesView _build() {
    final _$result = _$v ??
        _$PaymentHandlesView._(
          instapay: instapay,
          wallet: wallet,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
