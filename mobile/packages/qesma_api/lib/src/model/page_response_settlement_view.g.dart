// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_response_settlement_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageResponseSettlementView extends PageResponseSettlementView {
  @override
  final BuiltList<SettlementView> items;
  @override
  final int page;
  @override
  final int size;
  @override
  final int totalElements;
  @override
  final int totalPages;

  factory _$PageResponseSettlementView(
          [void Function(PageResponseSettlementViewBuilder)? updates]) =>
      (PageResponseSettlementViewBuilder()..update(updates))._build();

  _$PageResponseSettlementView._(
      {required this.items,
      required this.page,
      required this.size,
      required this.totalElements,
      required this.totalPages})
      : super._();
  @override
  PageResponseSettlementView rebuild(
          void Function(PageResponseSettlementViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageResponseSettlementViewBuilder toBuilder() =>
      PageResponseSettlementViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageResponseSettlementView &&
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
    return (newBuiltValueToStringHelper(r'PageResponseSettlementView')
          ..add('items', items)
          ..add('page', page)
          ..add('size', size)
          ..add('totalElements', totalElements)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class PageResponseSettlementViewBuilder
    implements
        Builder<PageResponseSettlementView, PageResponseSettlementViewBuilder> {
  _$PageResponseSettlementView? _$v;

  ListBuilder<SettlementView>? _items;
  ListBuilder<SettlementView> get items =>
      _$this._items ??= ListBuilder<SettlementView>();
  set items(ListBuilder<SettlementView>? items) => _$this._items = items;

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

  PageResponseSettlementViewBuilder() {
    PageResponseSettlementView._defaults(this);
  }

  PageResponseSettlementViewBuilder get _$this {
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
  void replace(PageResponseSettlementView other) {
    _$v = other as _$PageResponseSettlementView;
  }

  @override
  void update(void Function(PageResponseSettlementViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageResponseSettlementView build() => _build();

  _$PageResponseSettlementView _build() {
    _$PageResponseSettlementView _$result;
    try {
      _$result = _$v ??
          _$PageResponseSettlementView._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'PageResponseSettlementView', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'PageResponseSettlementView', 'size'),
            totalElements: BuiltValueNullFieldError.checkNotNull(
                totalElements, r'PageResponseSettlementView', 'totalElements'),
            totalPages: BuiltValueNullFieldError.checkNotNull(
                totalPages, r'PageResponseSettlementView', 'totalPages'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PageResponseSettlementView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
