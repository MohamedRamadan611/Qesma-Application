// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransferView extends TransferView {
  @override
  final int amountMinor;
  @override
  final String fromMemberId;
  @override
  final String toMemberId;

  factory _$TransferView([void Function(TransferViewBuilder)? updates]) =>
      (TransferViewBuilder()..update(updates))._build();

  _$TransferView._(
      {required this.amountMinor,
      required this.fromMemberId,
      required this.toMemberId})
      : super._();
  @override
  TransferView rebuild(void Function(TransferViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransferViewBuilder toBuilder() => TransferViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransferView &&
        amountMinor == other.amountMinor &&
        fromMemberId == other.fromMemberId &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TransferView')
          ..add('amountMinor', amountMinor)
          ..add('fromMemberId', fromMemberId)
          ..add('toMemberId', toMemberId))
        .toString();
  }
}

class TransferViewBuilder
    implements Builder<TransferView, TransferViewBuilder> {
  _$TransferView? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _fromMemberId;
  String? get fromMemberId => _$this._fromMemberId;
  set fromMemberId(String? fromMemberId) => _$this._fromMemberId = fromMemberId;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  TransferViewBuilder() {
    TransferView._defaults(this);
  }

  TransferViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _fromMemberId = $v.fromMemberId;
      _toMemberId = $v.toMemberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransferView other) {
    _$v = other as _$TransferView;
  }

  @override
  void update(void Function(TransferViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransferView build() => _build();

  _$TransferView _build() {
    final _$result = _$v ??
        _$TransferView._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'TransferView', 'amountMinor'),
          fromMemberId: BuiltValueNullFieldError.checkNotNull(
              fromMemberId, r'TransferView', 'fromMemberId'),
          toMemberId: BuiltValueNullFieldError.checkNotNull(
              toMemberId, r'TransferView', 'toMemberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
