// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_response_invite_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageResponseInviteView extends PageResponseInviteView {
  @override
  final BuiltList<InviteView> items;
  @override
  final int page;
  @override
  final int size;
  @override
  final int totalElements;
  @override
  final int totalPages;

  factory _$PageResponseInviteView(
          [void Function(PageResponseInviteViewBuilder)? updates]) =>
      (PageResponseInviteViewBuilder()..update(updates))._build();

  _$PageResponseInviteView._(
      {required this.items,
      required this.page,
      required this.size,
      required this.totalElements,
      required this.totalPages})
      : super._();
  @override
  PageResponseInviteView rebuild(
          void Function(PageResponseInviteViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageResponseInviteViewBuilder toBuilder() =>
      PageResponseInviteViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageResponseInviteView &&
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
    return (newBuiltValueToStringHelper(r'PageResponseInviteView')
          ..add('items', items)
          ..add('page', page)
          ..add('size', size)
          ..add('totalElements', totalElements)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class PageResponseInviteViewBuilder
    implements Builder<PageResponseInviteView, PageResponseInviteViewBuilder> {
  _$PageResponseInviteView? _$v;

  ListBuilder<InviteView>? _items;
  ListBuilder<InviteView> get items =>
      _$this._items ??= ListBuilder<InviteView>();
  set items(ListBuilder<InviteView>? items) => _$this._items = items;

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

  PageResponseInviteViewBuilder() {
    PageResponseInviteView._defaults(this);
  }

  PageResponseInviteViewBuilder get _$this {
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
  void replace(PageResponseInviteView other) {
    _$v = other as _$PageResponseInviteView;
  }

  @override
  void update(void Function(PageResponseInviteViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageResponseInviteView build() => _build();

  _$PageResponseInviteView _build() {
    _$PageResponseInviteView _$result;
    try {
      _$result = _$v ??
          _$PageResponseInviteView._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'PageResponseInviteView', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'PageResponseInviteView', 'size'),
            totalElements: BuiltValueNullFieldError.checkNotNull(
                totalElements, r'PageResponseInviteView', 'totalElements'),
            totalPages: BuiltValueNullFieldError.checkNotNull(
                totalPages, r'PageResponseInviteView', 'totalPages'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PageResponseInviteView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
