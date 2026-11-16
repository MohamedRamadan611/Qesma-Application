// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationPage extends NotificationPage {
  @override
  final BuiltList<NotificationItem> items;
  @override
  final String? nextBefore;

  factory _$NotificationPage(
          [void Function(NotificationPageBuilder)? updates]) =>
      (NotificationPageBuilder()..update(updates))._build();

  _$NotificationPage._({required this.items, this.nextBefore}) : super._();
  @override
  NotificationPage rebuild(void Function(NotificationPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationPageBuilder toBuilder() =>
      NotificationPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationPage &&
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
    return (newBuiltValueToStringHelper(r'NotificationPage')
          ..add('items', items)
          ..add('nextBefore', nextBefore))
        .toString();
  }
}

class NotificationPageBuilder
    implements Builder<NotificationPage, NotificationPageBuilder> {
  _$NotificationPage? _$v;

  ListBuilder<NotificationItem>? _items;
  ListBuilder<NotificationItem> get items =>
      _$this._items ??= ListBuilder<NotificationItem>();
  set items(ListBuilder<NotificationItem>? items) => _$this._items = items;

  String? _nextBefore;
  String? get nextBefore => _$this._nextBefore;
  set nextBefore(String? nextBefore) => _$this._nextBefore = nextBefore;

  NotificationPageBuilder() {
    NotificationPage._defaults(this);
  }

  NotificationPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _nextBefore = $v.nextBefore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationPage other) {
    _$v = other as _$NotificationPage;
  }

  @override
  void update(void Function(NotificationPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationPage build() => _build();

  _$NotificationPage _build() {
    _$NotificationPage _$result;
    try {
      _$result = _$v ??
          _$NotificationPage._(
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
            r'NotificationPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
