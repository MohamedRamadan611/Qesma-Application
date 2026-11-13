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
  final bool hasDispute;
  @override
  final BuiltList<String> openSettlementIds;
  @override
  final int pendingMinor;
  @override
  final PaymentHandlesView? receiverHandles;
  @override
  final String toMemberId;

  factory _$TransferView([void Function(TransferViewBuilder)? updates]) =>
      (TransferViewBuilder()..update(updates))._build();

  _$TransferView._(
      {required this.amountMinor,
      required this.fromMemberId,
      required this.hasDispute,
      required this.openSettlementIds,
      required this.pendingMinor,
      this.receiverHandles,
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
        hasDispute == other.hasDispute &&
        openSettlementIds == other.openSettlementIds &&
        pendingMinor == other.pendingMinor &&
        receiverHandles == other.receiverHandles &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, hasDispute.hashCode);
    _$hash = $jc(_$hash, openSettlementIds.hashCode);
    _$hash = $jc(_$hash, pendingMinor.hashCode);
    _$hash = $jc(_$hash, receiverHandles.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TransferView')
          ..add('amountMinor', amountMinor)
          ..add('fromMemberId', fromMemberId)
          ..add('hasDispute', hasDispute)
          ..add('openSettlementIds', openSettlementIds)
          ..add('pendingMinor', pendingMinor)
          ..add('receiverHandles', receiverHandles)
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

  bool? _hasDispute;
  bool? get hasDispute => _$this._hasDispute;
  set hasDispute(bool? hasDispute) => _$this._hasDispute = hasDispute;

  ListBuilder<String>? _openSettlementIds;
  ListBuilder<String> get openSettlementIds =>
      _$this._openSettlementIds ??= ListBuilder<String>();
  set openSettlementIds(ListBuilder<String>? openSettlementIds) =>
      _$this._openSettlementIds = openSettlementIds;

  int? _pendingMinor;
  int? get pendingMinor => _$this._pendingMinor;
  set pendingMinor(int? pendingMinor) => _$this._pendingMinor = pendingMinor;

  PaymentHandlesViewBuilder? _receiverHandles;
  PaymentHandlesViewBuilder get receiverHandles =>
      _$this._receiverHandles ??= PaymentHandlesViewBuilder();
  set receiverHandles(PaymentHandlesViewBuilder? receiverHandles) =>
      _$this._receiverHandles = receiverHandles;

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
      _hasDispute = $v.hasDispute;
      _openSettlementIds = $v.openSettlementIds.toBuilder();
      _pendingMinor = $v.pendingMinor;
      _receiverHandles = $v.receiverHandles?.toBuilder();
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
    _$TransferView _$result;
    try {
      _$result = _$v ??
          _$TransferView._(
            amountMinor: BuiltValueNullFieldError.checkNotNull(
                amountMinor, r'TransferView', 'amountMinor'),
            fromMemberId: BuiltValueNullFieldError.checkNotNull(
                fromMemberId, r'TransferView', 'fromMemberId'),
            hasDispute: BuiltValueNullFieldError.checkNotNull(
                hasDispute, r'TransferView', 'hasDispute'),
            openSettlementIds: openSettlementIds.build(),
            pendingMinor: BuiltValueNullFieldError.checkNotNull(
                pendingMinor, r'TransferView', 'pendingMinor'),
            receiverHandles: _receiverHandles?.build(),
            toMemberId: BuiltValueNullFieldError.checkNotNull(
                toMemberId, r'TransferView', 'toMemberId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'openSettlementIds';
        openSettlementIds.build();

        _$failedField = 'receiverHandles';
        _receiverHandles?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'TransferView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
