// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_read_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MarkReadResult extends MarkReadResult {
  @override
  final int marked;
  @override
  final int unreadCount;

  factory _$MarkReadResult([void Function(MarkReadResultBuilder)? updates]) =>
      (MarkReadResultBuilder()..update(updates))._build();

  _$MarkReadResult._({required this.marked, required this.unreadCount})
      : super._();
  @override
  MarkReadResult rebuild(void Function(MarkReadResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MarkReadResultBuilder toBuilder() => MarkReadResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MarkReadResult &&
        marked == other.marked &&
        unreadCount == other.unreadCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, marked.hashCode);
    _$hash = $jc(_$hash, unreadCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MarkReadResult')
          ..add('marked', marked)
          ..add('unreadCount', unreadCount))
        .toString();
  }
}

class MarkReadResultBuilder
    implements Builder<MarkReadResult, MarkReadResultBuilder> {
  _$MarkReadResult? _$v;

  int? _marked;
  int? get marked => _$this._marked;
  set marked(int? marked) => _$this._marked = marked;

  int? _unreadCount;
  int? get unreadCount => _$this._unreadCount;
  set unreadCount(int? unreadCount) => _$this._unreadCount = unreadCount;

  MarkReadResultBuilder() {
    MarkReadResult._defaults(this);
  }

  MarkReadResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _marked = $v.marked;
      _unreadCount = $v.unreadCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MarkReadResult other) {
    _$v = other as _$MarkReadResult;
  }

  @override
  void update(void Function(MarkReadResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MarkReadResult build() => _build();

  _$MarkReadResult _build() {
    final _$result = _$v ??
        _$MarkReadResult._(
          marked: BuiltValueNullFieldError.checkNotNull(
              marked, r'MarkReadResult', 'marked'),
          unreadCount: BuiltValueNullFieldError.checkNotNull(
              unreadCount, r'MarkReadResult', 'unreadCount'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
