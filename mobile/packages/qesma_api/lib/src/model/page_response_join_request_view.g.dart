// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_response_join_request_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageResponseJoinRequestView extends PageResponseJoinRequestView {
  @override
  final BuiltList<JoinRequestView> items;
  @override
  final int page;
  @override
  final int size;
  @override
  final int totalElements;
  @override
  final int totalPages;

  factory _$PageResponseJoinRequestView(
          [void Function(PageResponseJoinRequestViewBuilder)? updates]) =>
      (PageResponseJoinRequestViewBuilder()..update(updates))._build();

  _$PageResponseJoinRequestView._(
      {required this.items,
      required this.page,
      required this.size,
      required this.totalElements,
      required this.totalPages})
      : super._();
  @override
  PageResponseJoinRequestView rebuild(
          void Function(PageResponseJoinRequestViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageResponseJoinRequestViewBuilder toBuilder() =>
      PageResponseJoinRequestViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageResponseJoinRequestView &&
        items == other.items &&
        page == other.page &&
        size == other.size &&
        totalElements == other.totalElements &&
        totalPages == other.totalPages;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, page.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jc(_$hash, totalElements.hashCode);
    _$hash = $jc(_$hash, totalPages.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PageResponseJoinRequestView')
          ..add('items', items)
          ..add('page', page)
          ..add('size', size)
          ..add('totalElements', totalElements)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class PageResponseJoinRequestViewBuilder
    implements
        Builder<PageResponseJoinRequestView,
            PageResponseJoinRequestViewBuilder> {
  _$PageResponseJoinRequestView? _$v;

  ListBuilder<JoinRequestView>? _items;
  ListBuilder<JoinRequestView> get items =>
      _$this._items ??= ListBuilder<JoinRequestView>();
  set items(ListBuilder<JoinRequestView>? items) => _$this._items = items;

  int? _page;
  int? get page => _$this._page;
  set page(int? page) => _$this._page = page;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  int? _totalElements;
  int? get totalElements => _$this._totalElements;
  set totalElements(int? totalElements) =>
      _$this._totalElements = totalElements;

  int? _totalPages;
  int? get totalPages => _$this._totalPages;
  set totalPages(int? totalPages) => _$this._totalPages = totalPages;

  PageResponseJoinRequestViewBuilder() {
    PageResponseJoinRequestView._defaults(this);
  }

  PageResponseJoinRequestViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _page = $v.page;
      _size = $v.size;
      _totalElements = $v.totalElements;
      _totalPages = $v.totalPages;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PageResponseJoinRequestView other) {
    _$v = other as _$PageResponseJoinRequestView;
  }

  @override
  void update(void Function(PageResponseJoinRequestViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageResponseJoinRequestView build() => _build();

  _$PageResponseJoinRequestView _build() {
    _$PageResponseJoinRequestView _$result;
    try {
      _$result = _$v ??
          _$PageResponseJoinRequestView._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'PageResponseJoinRequestView', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'PageResponseJoinRequestView', 'size'),
            totalElements: BuiltValueNullFieldError.checkNotNull(
                totalElements, r'PageResponseJoinRequestView', 'totalElements'),
            totalPages: BuiltValueNullFieldError.checkNotNull(
                totalPages, r'PageResponseJoinRequestView', 'totalPages'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PageResponseJoinRequestView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
