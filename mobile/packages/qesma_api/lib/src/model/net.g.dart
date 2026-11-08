// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Net extends Net {
  @override
  final String memberId;
  @override
  final int netMinor;

  factory _$Net([void Function(NetBuilder)? updates]) =>
      (NetBuilder()..update(updates))._build();

  _$Net._({required this.memberId, required this.netMinor}) : super._();
  @override
  Net rebuild(void Function(NetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NetBuilder toBuilder() => NetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Net &&
        memberId == other.memberId &&
        netMinor == other.netMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, memberId.hashCode);
    _$hash = $jc(_$hash, netMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Net')
          ..add('memberId', memberId)
          ..add('netMinor', netMinor))
        .toString();
  }
}

class NetBuilder implements Builder<Net, NetBuilder> {
  _$Net? _$v;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  int? _netMinor;
  int? get netMinor => _$this._netMinor;
  set netMinor(int? netMinor) => _$this._netMinor = netMinor;

  NetBuilder() {
    Net._defaults(this);
  }

  NetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _memberId = $v.memberId;
      _netMinor = $v.netMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Net other) {
    _$v = other as _$Net;
  }

  @override
  void update(void Function(NetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Net build() => _build();

  _$Net _build() {
    final _$result = _$v ??
        _$Net._(
          memberId: BuiltValueNullFieldError.checkNotNull(
              memberId, r'Net', 'memberId'),
          netMinor: BuiltValueNullFieldError.checkNotNull(
              netMinor, r'Net', 'netMinor'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
