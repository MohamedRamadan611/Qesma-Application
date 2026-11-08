// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ServiceInput extends ServiceInput {
  @override
  final int bps;

  factory _$ServiceInput([void Function(ServiceInputBuilder)? updates]) =>
      (ServiceInputBuilder()..update(updates))._build();

  _$ServiceInput._({required this.bps}) : super._();
  @override
  ServiceInput rebuild(void Function(ServiceInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ServiceInputBuilder toBuilder() => ServiceInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ServiceInput && bps == other.bps;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, bps.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ServiceInput')..add('bps', bps))
        .toString();
  }
}

class ServiceInputBuilder
    implements Builder<ServiceInput, ServiceInputBuilder> {
  _$ServiceInput? _$v;

  int? _bps;
  int? get bps => _$this._bps;
  set bps(int? bps) => _$this._bps = bps;

  ServiceInputBuilder() {
    ServiceInput._defaults(this);
  }

  ServiceInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _bps = $v.bps;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ServiceInput other) {
    _$v = other as _$ServiceInput;
  }

  @override
  void update(void Function(ServiceInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ServiceInput build() => _build();

  _$ServiceInput _build() {
    final _$result = _$v ??
        _$ServiceInput._(
          bps: BuiltValueNullFieldError.checkNotNull(
              bps, r'ServiceInput', 'bps'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
