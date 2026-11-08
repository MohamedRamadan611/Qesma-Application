// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BalanceView extends BalanceView {
  @override
  final BuiltList<Net> nets;
  @override
  final BuiltList<TransferView> transfers;

  factory _$BalanceView([void Function(BalanceViewBuilder)? updates]) =>
      (BalanceViewBuilder()..update(updates))._build();

  _$BalanceView._({required this.nets, required this.transfers}) : super._();
  @override
  BalanceView rebuild(void Function(BalanceViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BalanceViewBuilder toBuilder() => BalanceViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BalanceView &&
        nets == other.nets &&
        transfers == other.transfers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, nets.hashCode);
    _$hash = $jc(_$hash, transfers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BalanceView')
          ..add('nets', nets)
          ..add('transfers', transfers))
        .toString();
  }
}

class BalanceViewBuilder implements Builder<BalanceView, BalanceViewBuilder> {
  _$BalanceView? _$v;

  ListBuilder<Net>? _nets;
  ListBuilder<Net> get nets => _$this._nets ??= ListBuilder<Net>();
  set nets(ListBuilder<Net>? nets) => _$this._nets = nets;

  ListBuilder<TransferView>? _transfers;
  ListBuilder<TransferView> get transfers =>
      _$this._transfers ??= ListBuilder<TransferView>();
  set transfers(ListBuilder<TransferView>? transfers) =>
      _$this._transfers = transfers;

  BalanceViewBuilder() {
    BalanceView._defaults(this);
  }

  BalanceViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _nets = $v.nets.toBuilder();
      _transfers = $v.transfers.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BalanceView other) {
    _$v = other as _$BalanceView;
  }

  @override
  void update(void Function(BalanceViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BalanceView build() => _build();

  _$BalanceView _build() {
    _$BalanceView _$result;
    try {
      _$result = _$v ??
          _$BalanceView._(
            nets: nets.build(),
            transfers: transfers.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'nets';
        nets.build();
        _$failedField = 'transfers';
        transfers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BalanceView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
