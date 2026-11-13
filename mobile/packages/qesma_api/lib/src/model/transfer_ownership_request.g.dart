// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_ownership_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransferOwnershipRequest extends TransferOwnershipRequest {
  @override
  final String? toMemberId;

  factory _$TransferOwnershipRequest(
          [void Function(TransferOwnershipRequestBuilder)? updates]) =>
      (TransferOwnershipRequestBuilder()..update(updates))._build();

  _$TransferOwnershipRequest._({this.toMemberId}) : super._();
  @override
  TransferOwnershipRequest rebuild(
          void Function(TransferOwnershipRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransferOwnershipRequestBuilder toBuilder() =>
      TransferOwnershipRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransferOwnershipRequest && toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TransferOwnershipRequest')
          ..add('toMemberId', toMemberId))
        .toString();
  }
}

class TransferOwnershipRequestBuilder
    implements
        Builder<TransferOwnershipRequest, TransferOwnershipRequestBuilder> {
  _$TransferOwnershipRequest? _$v;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  TransferOwnershipRequestBuilder() {
    TransferOwnershipRequest._defaults(this);
  }

  TransferOwnershipRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _toMemberId = $v.toMemberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransferOwnershipRequest other) {
    _$v = other as _$TransferOwnershipRequest;
  }

  @override
  void update(void Function(TransferOwnershipRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransferOwnershipRequest build() => _build();

  _$TransferOwnershipRequest _build() {
    final _$result = _$v ??
        _$TransferOwnershipRequest._(
          toMemberId: toMemberId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
