// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TaxInput extends TaxInput {
  @override
  final String? base_;
  @override
  final int bps;

  factory _$TaxInput([void Function(TaxInputBuilder)? updates]) =>
      (TaxInputBuilder()..update(updates))._build();

  _$TaxInput._({this.base_, required this.bps}) : super._();
  @override
  TaxInput rebuild(void Function(TaxInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TaxInputBuilder toBuilder() => TaxInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TaxInput && base_ == other.base_ && bps == other.bps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, base_.hashCode);
    _$hash = $jc(_$hash, bps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TaxInput')
          ..add('base_', base_)
          ..add('bps', bps))
        .toString();
  }
}

class TaxInputBuilder implements Builder<TaxInput, TaxInputBuilder> {
  _$TaxInput? _$v;

  String? _base_;
  String? get base_ => _$this._base_;
  set base_(String? base_) => _$this._base_ = base_;

  int? _bps;
  int? get bps => _$this._bps;
  set bps(int? bps) => _$this._bps = bps;

  TaxInputBuilder() {
    TaxInput._defaults(this);
  }

  TaxInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _base_ = $v.base_;
      _bps = $v.bps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TaxInput other) {
    _$v = other as _$TaxInput;
  }

  @override
  void update(void Function(TaxInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TaxInput build() => _build();

  _$TaxInput _build() {
    final _$result = _$v ??
        _$TaxInput._(
          base_: base_,
          bps: BuiltValueNullFieldError.checkNotNull(bps, r'TaxInput', 'bps'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
