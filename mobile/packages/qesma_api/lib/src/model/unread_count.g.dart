// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unread_count.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UnreadCount extends UnreadCount {
  @override
  final int count;

  factory _$UnreadCount([void Function(UnreadCountBuilder)? updates]) =>
      (UnreadCountBuilder()..update(updates))._build();

  _$UnreadCount._({required this.count}) : super._();
  @override
  UnreadCount rebuild(void Function(UnreadCountBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UnreadCountBuilder toBuilder() => UnreadCountBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UnreadCount && count == other.count;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, count.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UnreadCount')..add('count', count))
        .toString();
  }
}

class UnreadCountBuilder implements Builder<UnreadCount, UnreadCountBuilder> {
  _$UnreadCount? _$v;

  int? _count;
  int? get count => _$this._count;
  set count(int? count) => _$this._count = count;

  UnreadCountBuilder() {
    UnreadCount._defaults(this);
  }

  UnreadCountBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _count = $v.count;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UnreadCount other) {
    _$v = other as _$UnreadCount;
  }

  @override
  void update(void Function(UnreadCountBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UnreadCount build() => _build();

  _$UnreadCount _build() {
    final _$result = _$v ??
        _$UnreadCount._(
          count: BuiltValueNullFieldError.checkNotNull(
              count, r'UnreadCount', 'count'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
