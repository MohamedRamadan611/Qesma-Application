// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpenseCommand extends ExpenseCommand {
  @override
  final int? adjustmentMinor;
  @override
  final Date expenseDate;
  @override
  final BuiltList<ItemInput>? items;
  @override
  final BuiltList<String>? participantMemberIds;
  @override
  final BuiltList<PayerInput>? payers;
  @override
  final ServiceInput? service;
  @override
  final BuiltList<ShareInput>? shares;
  @override
  final String splitType;
  @override
  final TaxInput? tax;
  @override
  final String title;
  @override
  final int? totalMinor;

  factory _$ExpenseCommand([void Function(ExpenseCommandBuilder)? updates]) =>
      (ExpenseCommandBuilder()..update(updates))._build();

  _$ExpenseCommand._(
      {this.adjustmentMinor,
      required this.expenseDate,
      this.items,
      this.participantMemberIds,
      this.payers,
      this.service,
      this.shares,
      required this.splitType,
      this.tax,
      required this.title,
      this.totalMinor})
      : super._();
  @override
  ExpenseCommand rebuild(void Function(ExpenseCommandBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpenseCommandBuilder toBuilder() => ExpenseCommandBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpenseCommand &&
        adjustmentMinor == other.adjustmentMinor &&
        expenseDate == other.expenseDate &&
        items == other.items &&
        participantMemberIds == other.participantMemberIds &&
        payers == other.payers &&
        service == other.service &&
        shares == other.shares &&
        splitType == other.splitType &&
        tax == other.tax &&
        title == other.title &&
        totalMinor == other.totalMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adjustmentMinor.hashCode);
    _$hash = $jc(_$hash, expenseDate.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, participantMemberIds.hashCode);
    _$hash = $jc(_$hash, payers.hashCode);
    _$hash = $jc(_$hash, service.hashCode);
    _$hash = $jc(_$hash, shares.hashCode);
    _$hash = $jc(_$hash, splitType.hashCode);
    _$hash = $jc(_$hash, tax.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, totalMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpenseCommand')
          ..add('adjustmentMinor', adjustmentMinor)
          ..add('expenseDate', expenseDate)
          ..add('items', items)
          ..add('participantMemberIds', participantMemberIds)
          ..add('payers', payers)
          ..add('service', service)
          ..add('shares', shares)
          ..add('splitType', splitType)
          ..add('tax', tax)
          ..add('title', title)
          ..add('totalMinor', totalMinor))
        .toString();
  }
}

class ExpenseCommandBuilder
    implements Builder<ExpenseCommand, ExpenseCommandBuilder> {
  _$ExpenseCommand? _$v;

  int? _adjustmentMinor;
  int? get adjustmentMinor => _$this._adjustmentMinor;
  set adjustmentMinor(int? adjustmentMinor) =>
      _$this._adjustmentMinor = adjustmentMinor;

  Date? _expenseDate;
  Date? get expenseDate => _$this._expenseDate;
  set expenseDate(Date? expenseDate) => _$this._expenseDate = expenseDate;

  ListBuilder<ItemInput>? _items;
  ListBuilder<ItemInput> get items =>
      _$this._items ??= ListBuilder<ItemInput>();
  set items(ListBuilder<ItemInput>? items) => _$this._items = items;

  ListBuilder<String>? _participantMemberIds;
  ListBuilder<String> get participantMemberIds =>
      _$this._participantMemberIds ??= ListBuilder<String>();
  set participantMemberIds(ListBuilder<String>? participantMemberIds) =>
      _$this._participantMemberIds = participantMemberIds;

  ListBuilder<PayerInput>? _payers;
  ListBuilder<PayerInput> get payers =>
      _$this._payers ??= ListBuilder<PayerInput>();
  set payers(ListBuilder<PayerInput>? payers) => _$this._payers = payers;

  ServiceInputBuilder? _service;
  ServiceInputBuilder get service => _$this._service ??= ServiceInputBuilder();
  set service(ServiceInputBuilder? service) => _$this._service = service;

  ListBuilder<ShareInput>? _shares;
  ListBuilder<ShareInput> get shares =>
      _$this._shares ??= ListBuilder<ShareInput>();
  set shares(ListBuilder<ShareInput>? shares) => _$this._shares = shares;

  String? _splitType;
  String? get splitType => _$this._splitType;
  set splitType(String? splitType) => _$this._splitType = splitType;

  TaxInputBuilder? _tax;
  TaxInputBuilder get tax => _$this._tax ??= TaxInputBuilder();
  set tax(TaxInputBuilder? tax) => _$this._tax = tax;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  int? _totalMinor;
  int? get totalMinor => _$this._totalMinor;
  set totalMinor(int? totalMinor) => _$this._totalMinor = totalMinor;

  ExpenseCommandBuilder() {
    ExpenseCommand._defaults(this);
  }

  ExpenseCommandBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adjustmentMinor = $v.adjustmentMinor;
      _expenseDate = $v.expenseDate;
      _items = $v.items?.toBuilder();
      _participantMemberIds = $v.participantMemberIds?.toBuilder();
      _payers = $v.payers?.toBuilder();
      _service = $v.service?.toBuilder();
      _shares = $v.shares?.toBuilder();
      _splitType = $v.splitType;
      _tax = $v.tax?.toBuilder();
      _title = $v.title;
      _totalMinor = $v.totalMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpenseCommand other) {
    _$v = other as _$ExpenseCommand;
  }

  @override
  void update(void Function(ExpenseCommandBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpenseCommand build() => _build();

  _$ExpenseCommand _build() {
    _$ExpenseCommand _$result;
    try {
      _$result = _$v ??
          _$ExpenseCommand._(
            adjustmentMinor: adjustmentMinor,
            expenseDate: BuiltValueNullFieldError.checkNotNull(
                expenseDate, r'ExpenseCommand', 'expenseDate'),
            items: _items?.build(),
            participantMemberIds: _participantMemberIds?.build(),
            payers: _payers?.build(),
            service: _service?.build(),
            shares: _shares?.build(),
            splitType: BuiltValueNullFieldError.checkNotNull(
                splitType, r'ExpenseCommand', 'splitType'),
            tax: _tax?.build(),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'ExpenseCommand', 'title'),
            totalMinor: totalMinor,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        _items?.build();
        _$failedField = 'participantMemberIds';
        _participantMemberIds?.build();
        _$failedField = 'payers';
        _payers?.build();
        _$failedField = 'service';
        _service?.build();
        _$failedField = 'shares';
        _shares?.build();

        _$failedField = 'tax';
        _tax?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ExpenseCommand', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
