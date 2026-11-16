// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ActivityPage extends ActivityPage {
  @override
  final BuiltList<ActivityItem> items;
  @override
  final String? nextBefore;

  factory _$ActivityPage([void Function(ActivityPageBuilder)? updates]) =>
      (ActivityPageBuilder()..update(updates))._build();

  _$ActivityPage._({required this.items, this.nextBefore}) : super._();
  @override
  ActivityPage rebuild(void Function(ActivityPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ActivityPageBuilder toBuilder() => ActivityPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ActivityPage &&
        items == other.items &&
        nextBefore == other.nextBefore;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, nextBefore.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ActivityPage')
          ..add('items', items)
          ..add('nextBefore', nextBefore))
        .toString();
  }
}

class ActivityPageBuilder
    implements Builder<ActivityPage, ActivityPageBuilder> {
  _$ActivityPage? _$v;

  ListBuilder<ActivityItem>? _items;
  ListBuilder<ActivityItem> get items =>
      _$this._items ??= ListBuilder<ActivityItem>();
  set items(ListBuilder<ActivityItem>? items) => _$this._items = items;

  String? _nextBefore;
  String? get nextBefore => _$this._nextBefore;
  set nextBefore(String? nextBefore) => _$this._nextBefore = nextBefore;

  ActivityPageBuilder() {
    ActivityPage._defaults(this);
  }

  ActivityPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _nextBefore = $v.nextBefore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ActivityPage other) {
    _$v = other as _$ActivityPage;
  }

  @override
  void update(void Function(ActivityPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ActivityPage build() => _build();

  _$ActivityPage _build() {
    _$ActivityPage _$result;
    try {
      _$result = _$v ??
          _$ActivityPage._(
            items: items.build(),
            nextBefore: nextBefore,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ActivityPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
