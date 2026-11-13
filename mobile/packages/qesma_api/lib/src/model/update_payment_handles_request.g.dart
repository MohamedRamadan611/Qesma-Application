// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_payment_handles_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdatePaymentHandlesRequest extends UpdatePaymentHandlesRequest {
  @override
  final String? instapay;
  @override
  final String? wallet;

  factory _$UpdatePaymentHandlesRequest(
          [void Function(UpdatePaymentHandlesRequestBuilder)? updates]) =>
      (UpdatePaymentHandlesRequestBuilder()..update(updates))._build();

  _$UpdatePaymentHandlesRequest._({this.instapay, this.wallet}) : super._();
  @override
  UpdatePaymentHandlesRequest rebuild(
          void Function(UpdatePaymentHandlesRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdatePaymentHandlesRequestBuilder toBuilder() =>
      UpdatePaymentHandlesRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePaymentHandlesRequest &&
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
    return (newBuiltValueToStringHelper(r'UpdatePaymentHandlesRequest')
          ..add('instapay', instapay)
          ..add('wallet', wallet))
        .toString();
  }
}

class UpdatePaymentHandlesRequestBuilder
    implements
        Builder<UpdatePaymentHandlesRequest,
            UpdatePaymentHandlesRequestBuilder> {
  _$UpdatePaymentHandlesRequest? _$v;

  String? _instapay;
  String? get instapay => _$this._instapay;
  set instapay(String? instapay) => _$this._instapay = instapay;

  String? _wallet;
  String? get wallet => _$this._wallet;
  set wallet(String? wallet) => _$this._wallet = wallet;

  UpdatePaymentHandlesRequestBuilder() {
    UpdatePaymentHandlesRequest._defaults(this);
  }

  UpdatePaymentHandlesRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _instapay = $v.instapay;
      _wallet = $v.wallet;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePaymentHandlesRequest other) {
    _$v = other as _$UpdatePaymentHandlesRequest;
  }

  @override
  void update(void Function(UpdatePaymentHandlesRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePaymentHandlesRequest build() => _build();

  _$UpdatePaymentHandlesRequest _build() {
    final _$result = _$v ??
        _$UpdatePaymentHandlesRequest._(
          instapay: instapay,
          wallet: wallet,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
