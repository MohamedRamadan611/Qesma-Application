// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_response_group_summary_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageResponseGroupSummaryDto extends PageResponseGroupSummaryDto {
  @override
  final BuiltList<GroupSummaryDto> items;
  @override
  final int page;
  @override
  final int size;
  @override
  final int totalElements;
  @override
  final int totalPages;

  factory _$PageResponseGroupSummaryDto(
          [void Function(PageResponseGroupSummaryDtoBuilder)? updates]) =>
      (PageResponseGroupSummaryDtoBuilder()..update(updates))._build();

  _$PageResponseGroupSummaryDto._(
      {required this.items,
      required this.page,
      required this.size,
      required this.totalElements,
      required this.totalPages})
      : super._();
  @override
  PageResponseGroupSummaryDto rebuild(
          void Function(PageResponseGroupSummaryDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageResponseGroupSummaryDtoBuilder toBuilder() =>
      PageResponseGroupSummaryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageResponseGroupSummaryDto &&
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
    return (newBuiltValueToStringHelper(r'PageResponseGroupSummaryDto')
          ..add('items', items)
          ..add('page', page)
          ..add('size', size)
          ..add('totalElements', totalElements)
          ..add('totalPages', totalPages))
        .toString();
  }
}

class PageResponseGroupSummaryDtoBuilder
    implements
        Builder<PageResponseGroupSummaryDto,
            PageResponseGroupSummaryDtoBuilder> {
  _$PageResponseGroupSummaryDto? _$v;

  ListBuilder<GroupSummaryDto>? _items;
  ListBuilder<GroupSummaryDto> get items =>
      _$this._items ??= ListBuilder<GroupSummaryDto>();
  set items(ListBuilder<GroupSummaryDto>? items) => _$this._items = items;

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

  PageResponseGroupSummaryDtoBuilder() {
    PageResponseGroupSummaryDto._defaults(this);
  }

  PageResponseGroupSummaryDtoBuilder get _$this {
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
  void replace(PageResponseGroupSummaryDto other) {
    _$v = other as _$PageResponseGroupSummaryDto;
  }

  @override
  void update(void Function(PageResponseGroupSummaryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageResponseGroupSummaryDto build() => _build();

  _$PageResponseGroupSummaryDto _build() {
    _$PageResponseGroupSummaryDto _$result;
    try {
      _$result = _$v ??
          _$PageResponseGroupSummaryDto._(
            items: items.build(),
            page: BuiltValueNullFieldError.checkNotNull(
                page, r'PageResponseGroupSummaryDto', 'page'),
            size: BuiltValueNullFieldError.checkNotNull(
                size, r'PageResponseGroupSummaryDto', 'size'),
            totalElements: BuiltValueNullFieldError.checkNotNull(
                totalElements, r'PageResponseGroupSummaryDto', 'totalElements'),
            totalPages: BuiltValueNullFieldError.checkNotNull(
                totalPages, r'PageResponseGroupSummaryDto', 'totalPages'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PageResponseGroupSummaryDto', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
