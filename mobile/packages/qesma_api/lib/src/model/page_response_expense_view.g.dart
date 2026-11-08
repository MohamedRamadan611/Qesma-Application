// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_response_expense_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageResponseExpenseView extends PageResponseExpenseView {
  @override
  final BuiltList<ExpenseView> items;
  @override
  final int page;
  @override
  final int size;
  @override
  final int totalElements;
  @override
  final int totalPages;

  factory _$PageResponseExpenseView(
          [void Function(PageResponseExpenseViewBuilder)? updates]) =>
      (PageResponseExpenseViewBuilder()..update(updates))._build();

  _$PageResponseExpenseView._(
      {required this.items,
      required this.page,
      required this.size,
      required this.totalElements,
      required this.totalPages})
      : super._();
  @override
  PageResponseExpenseView rebuild(
          void Function(PageResponseExpenseViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageResponseExpenseViewBuilder toBuilder() =>
      PageResponseExpenseViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageResponseExpenseView &&
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
    return (newBuiltValueToStringHelper(r'PageResponseExpenseView')
          ..add('items', items)
          ..add('page', page)
          ..add('size', size)
          ..add('totalElements', totalElements)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class PageResponseExpenseViewBuilder
    implements
        Builder<PageResponseExpenseView, PageResponseExpenseViewBuilder> {
  _$PageResponseExpenseView? _$v;

  ListBuilder<ExpenseView>? _items;
  ListBuilder<ExpenseView> get items =>
      _$this._items ??= ListBuilder<ExpenseView>();
  set items(ListBuilder<ExpenseView>? items) => _$this._items = items;

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

  PageResponseExpenseViewBuilder() {
    PageResponseExpenseView._defaults(this);
  }

  PageResponseExpenseViewBuilder get _$this {
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
  void replace(PageResponseExpenseView other) {
    _$v = other as _$PageResponseExpenseView;
  }

  @override
  void update(void Function(PageResponseExpenseViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageResponseExpenseView build() => _build();

  _$PageResponseExpenseView _build() {
    _$PageResponseExpenseView _$result;
    try {
      _$result = _$v ??
          _$PageResponseExpenseView._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'PageResponseExpenseView', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'PageResponseExpenseView', 'size'),
            totalElements: BuiltValueNullFieldError.checkNotNull(
                totalElements, r'PageResponseExpenseView', 'totalElements'),
            totalPages: BuiltValueNullFieldError.checkNotNull(
                totalPages, r'PageResponseExpenseView', 'totalPages'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PageResponseExpenseView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
