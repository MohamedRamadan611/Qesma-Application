// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_read_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MarkReadRequest extends MarkReadRequest {
  @override
  final bool? all;
  @override
  final BuiltList<String>? ids;

  factory _$MarkReadRequest([void Function(MarkReadRequestBuilder)? updates]) =>
      (MarkReadRequestBuilder()..update(updates))._build();

  _$MarkReadRequest._({this.all, this.ids}) : super._();
  @override
  MarkReadRequest rebuild(void Function(MarkReadRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MarkReadRequestBuilder toBuilder() => MarkReadRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MarkReadRequest && all == other.all && ids == other.ids;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, all.hashCode);
    _$hash = $jc(_$hash, ids.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MarkReadRequest')
          ..add('all', all)
          ..add('ids', ids))
        .toString();
  }
}

class MarkReadRequestBuilder
    implements Builder<MarkReadRequest, MarkReadRequestBuilder> {
  _$MarkReadRequest? _$v;

  bool? _all;
  bool? get all => _$this._all;
  set all(bool? all) => _$this._all = all;

  ListBuilder<String>? _ids;
  ListBuilder<String> get ids => _$this._ids ??= ListBuilder<String>();
  set ids(ListBuilder<String>? ids) => _$this._ids = ids;

  MarkReadRequestBuilder() {
    MarkReadRequest._defaults(this);
  }

  MarkReadRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _all = $v.all;
      _ids = $v.ids?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MarkReadRequest other) {
    _$v = other as _$MarkReadRequest;
  }

  @override
  void update(void Function(MarkReadRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MarkReadRequest build() => _build();

  _$MarkReadRequest _build() {
    _$MarkReadRequest _$result;
    try {
      _$result = _$v ??
          _$MarkReadRequest._(
            all: all,
            ids: _ids?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        _ids?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MarkReadRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
