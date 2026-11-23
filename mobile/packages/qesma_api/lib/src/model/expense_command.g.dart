// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_command.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpenseCommand extends ExpenseCommand {
  @override
  final int? adjustmentMinor;
  @override
  final String? category;
  @override
  final int? deliveryMinor;
  @override
  final DiscountInput? discount;
  @override
  final Date expenseDate;
  @override
  final BuiltList<ItemInput>? items;
  @override
  final bool? paidFromPool;
  @override
  final BuiltList<String>? participantMemberIds;
  @override
  final BuiltList<PayerInput>? payers;
  @override
  final Date? periodFrom;
  @override
  final Date? periodTo;
  @override
  final ServiceInput? service;
  @override
  final BuiltList<ShareParticipantInput>? shareParticipants;
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
      this.category,
      this.deliveryMinor,
      this.discount,
      required this.expenseDate,
      this.items,
      this.paidFromPool,
      this.participantMemberIds,
      this.payers,
      this.periodFrom,
      this.periodTo,
      this.service,
      this.shareParticipants,
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
        category == other.category &&
        deliveryMinor == other.deliveryMinor &&
        discount == other.discount &&
        expenseDate == other.expenseDate &&
        items == other.items &&
        paidFromPool == other.paidFromPool &&
        participantMemberIds == other.participantMemberIds &&
        payers == other.payers &&
        periodFrom == other.periodFrom &&
        periodTo == other.periodTo &&
        service == other.service &&
        shareParticipants == other.shareParticipants &&
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
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, deliveryMinor.hashCode);
    _$hash = $jc(_$hash, discount.hashCode);
    _$hash = $jc(_$hash, expenseDate.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, paidFromPool.hashCode);
    _$hash = $jc(_$hash, participantMemberIds.hashCode);
    _$hash = $jc(_$hash, payers.hashCode);
    _$hash = $jc(_$hash, periodFrom.hashCode);
    _$hash = $jc(_$hash, periodTo.hashCode);
    _$hash = $jc(_$hash, service.hashCode);
    _$hash = $jc(_$hash, shareParticipants.hashCode);
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
          ..add('category', category)
          ..add('deliveryMinor', deliveryMinor)
          ..add('discount', discount)
          ..add('expenseDate', expenseDate)
          ..add('items', items)
          ..add('paidFromPool', paidFromPool)
          ..add('participantMemberIds', participantMemberIds)
          ..add('payers', payers)
          ..add('periodFrom', periodFrom)
          ..add('periodTo', periodTo)
          ..add('service', service)
          ..add('shareParticipants', shareParticipants)
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

  String? _category;
  String? get category => _$this._category;
  set category(String? category) => _$this._category = category;

  int? _deliveryMinor;
  int? get deliveryMinor => _$this._deliveryMinor;
  set deliveryMinor(int? deliveryMinor) =>
      _$this._deliveryMinor = deliveryMinor;

  DiscountInputBuilder? _discount;
  DiscountInputBuilder get discount =>
      _$this._discount ??= DiscountInputBuilder();
  set discount(DiscountInputBuilder? discount) => _$this._discount = discount;

  Date? _expenseDate;
  Date? get expenseDate => _$this._expenseDate;
  set expenseDate(Date? expenseDate) => _$this._expenseDate = expenseDate;

  ListBuilder<ItemInput>? _items;
  ListBuilder<ItemInput> get items =>
      _$this._items ??= ListBuilder<ItemInput>();
  set items(ListBuilder<ItemInput>? items) => _$this._items = items;

  bool? _paidFromPool;
  bool? get paidFromPool => _$this._paidFromPool;
  set paidFromPool(bool? paidFromPool) => _$this._paidFromPool = paidFromPool;

  ListBuilder<String>? _participantMemberIds;
  ListBuilder<String> get participantMemberIds =>
      _$this._participantMemberIds ??= ListBuilder<String>();
  set participantMemberIds(ListBuilder<String>? participantMemberIds) =>
      _$this._participantMemberIds = participantMemberIds;

  ListBuilder<PayerInput>? _payers;
  ListBuilder<PayerInput> get payers =>
      _$this._payers ??= ListBuilder<PayerInput>();
  set payers(ListBuilder<PayerInput>? payers) => _$this._payers = payers;

  Date? _periodFrom;
  Date? get periodFrom => _$this._periodFrom;
  set periodFrom(Date? periodFrom) => _$this._periodFrom = periodFrom;

  Date? _periodTo;
  Date? get periodTo => _$this._periodTo;
  set periodTo(Date? periodTo) => _$this._periodTo = periodTo;

  ServiceInputBuilder? _service;
  ServiceInputBuilder get service => _$this._service ??= ServiceInputBuilder();
  set service(ServiceInputBuilder? service) => _$this._service = service;

  ListBuilder<ShareParticipantInput>? _shareParticipants;
  ListBuilder<ShareParticipantInput> get shareParticipants =>
      _$this._shareParticipants ??= ListBuilder<ShareParticipantInput>();
  set shareParticipants(
          ListBuilder<ShareParticipantInput>? shareParticipants) =>
      _$this._shareParticipants = shareParticipants;

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
      _category = $v.category;
      _deliveryMinor = $v.deliveryMinor;
      _discount = $v.discount?.toBuilder();
      _expenseDate = $v.expenseDate;
      _items = $v.items?.toBuilder();
      _paidFromPool = $v.paidFromPool;
      _participantMemberIds = $v.participantMemberIds?.toBuilder();
      _payers = $v.payers?.toBuilder();
      _periodFrom = $v.periodFrom;
      _periodTo = $v.periodTo;
      _service = $v.service?.toBuilder();
      _shareParticipants = $v.shareParticipants?.toBuilder();
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
            category: category,
            deliveryMinor: deliveryMinor,
            discount: _discount?.build(),
            expenseDate: BuiltValueNullFieldError.checkNotNull(
                expenseDate, r'ExpenseCommand', 'expenseDate'),
            items: _items?.build(),
            paidFromPool: paidFromPool,
            participantMemberIds: _participantMemberIds?.build(),
            payers: _payers?.build(),
            periodFrom: periodFrom,
            periodTo: periodTo,
            service: _service?.build(),
            shareParticipants: _shareParticipants?.build(),
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
        _$failedField = 'discount';
        _discount?.build();

        _$failedField = 'items';
        _items?.build();

        _$failedField = 'participantMemberIds';
        _participantMemberIds?.build();
        _$failedField = 'payers';
        _payers?.build();

        _$failedField = 'service';
        _service?.build();
        _$failedField = 'shareParticipants';
        _shareParticipants?.build();
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
