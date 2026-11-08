// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpenseView extends ExpenseView {
  @override
  final Charges? charges;
  @override
  final DateTime createdAt;
  @override
  final Date expenseDate;
  @override
  final String groupId;
  @override
  final String id;
  @override
  final BuiltList<ItemView>? items;
  @override
  final BuiltList<PayerView> payers;
  @override
  final BuiltList<ShareView> shares;
  @override
  final String splitType;
  @override
  final String title;
  @override
  final int totalMinor;
  @override
  final int version;

  factory _$ExpenseView([void Function(ExpenseViewBuilder)? updates]) =>
      (ExpenseViewBuilder()..update(updates))._build();

  _$ExpenseView._(
      {this.charges,
      required this.createdAt,
      required this.expenseDate,
      required this.groupId,
      required this.id,
      this.items,
      required this.payers,
      required this.shares,
      required this.splitType,
      required this.title,
      required this.totalMinor,
      required this.version})
      : super._();
  @override
  ExpenseView rebuild(void Function(ExpenseViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpenseViewBuilder toBuilder() => ExpenseViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpenseView &&
        charges == other.charges &&
        createdAt == other.createdAt &&
        expenseDate == other.expenseDate &&
        groupId == other.groupId &&
        id == other.id &&
        items == other.items &&
        payers == other.payers &&
        shares == other.shares &&
        splitType == other.splitType &&
        title == other.title &&
        totalMinor == other.totalMinor &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, charges.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, expenseDate.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, payers.hashCode);
    _$hash = $jc(_$hash, shares.hashCode);
    _$hash = $jc(_$hash, splitType.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, totalMinor.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpenseView')
          ..add('charges', charges)
          ..add('createdAt', createdAt)
          ..add('expenseDate', expenseDate)
          ..add('groupId', groupId)
          ..add('id', id)
          ..add('items', items)
          ..add('payers', payers)
          ..add('shares', shares)
          ..add('splitType', splitType)
          ..add('title', title)
          ..add('totalMinor', totalMinor)
          ..add('version', version))
        .toString();
  }
}

class ExpenseViewBuilder implements Builder<ExpenseView, ExpenseViewBuilder> {
  _$ExpenseView? _$v;

  ChargesBuilder? _charges;
  ChargesBuilder get charges => _$this._charges ??= ChargesBuilder();
  set charges(ChargesBuilder? charges) => _$this._charges = charges;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  Date? _expenseDate;
  Date? get expenseDate => _$this._expenseDate;
  set expenseDate(Date? expenseDate) => _$this._expenseDate = expenseDate;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListBuilder<ItemView>? _items;
  ListBuilder<ItemView> get items => _$this._items ??= ListBuilder<ItemView>();
  set items(ListBuilder<ItemView>? items) => _$this._items = items;

  ListBuilder<PayerView>? _payers;
  ListBuilder<PayerView> get payers =>
      _$this._payers ??= ListBuilder<PayerView>();
  set payers(ListBuilder<PayerView>? payers) => _$this._payers = payers;

  ListBuilder<ShareView>? _shares;
  ListBuilder<ShareView> get shares =>
      _$this._shares ??= ListBuilder<ShareView>();
  set shares(ListBuilder<ShareView>? shares) => _$this._shares = shares;

  String? _splitType;
  String? get splitType => _$this._splitType;
  set splitType(String? splitType) => _$this._splitType = splitType;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  int? _totalMinor;
  int? get totalMinor => _$this._totalMinor;
  set totalMinor(int? totalMinor) => _$this._totalMinor = totalMinor;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  ExpenseViewBuilder() {
    ExpenseView._defaults(this);
  }

  ExpenseViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _charges = $v.charges?.toBuilder();
      _createdAt = $v.createdAt;
      _expenseDate = $v.expenseDate;
      _groupId = $v.groupId;
      _id = $v.id;
      _items = $v.items?.toBuilder();
      _payers = $v.payers.toBuilder();
      _shares = $v.shares.toBuilder();
      _splitType = $v.splitType;
      _title = $v.title;
      _totalMinor = $v.totalMinor;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpenseView other) {
    _$v = other as _$ExpenseView;
  }

  @override
  void update(void Function(ExpenseViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpenseView build() => _build();

  _$ExpenseView _build() {
    _$ExpenseView _$result;
    try {
      _$result = _$v ??
          _$ExpenseView._(
            charges: _charges?.build(),
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'ExpenseView', 'createdAt'),
            expenseDate: BuiltValueNullFieldError.checkNotNull(
                expenseDate, r'ExpenseView', 'expenseDate'),
            groupId: BuiltValueNullFieldError.checkNotNull(
                groupId, r'ExpenseView', 'groupId'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'ExpenseView', 'id'),
            items: _items?.build(),
            payers: payers.build(),
            shares: shares.build(),
            splitType: BuiltValueNullFieldError.checkNotNull(
                splitType, r'ExpenseView', 'splitType'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'ExpenseView', 'title'),
            totalMinor: BuiltValueNullFieldError.checkNotNull(
                totalMinor, r'ExpenseView', 'totalMinor'),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'ExpenseView', 'version'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'charges';
        _charges?.build();

        _$failedField = 'items';
        _items?.build();
        _$failedField = 'payers';
        payers.build();
        _$failedField = 'shares';
        shares.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ExpenseView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
