// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_preview.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpensePreview extends ExpensePreview {
  @override
  final int? adjustmentMinor;
  @override
  final int? deliveryMinor;
  @override
  final int? discountMinor;
  @override
  final BuiltList<ShareView> members;
  @override
  final bool payersTotalMatches;
  @override
  final Date? periodFrom;
  @override
  final Date? periodTo;
  @override
  final int? serviceMinor;
  @override
  final int? subtotalMinor;
  @override
  final int? taxMinor;
  @override
  final int totalMinor;

  factory _$ExpensePreview([void Function(ExpensePreviewBuilder)? updates]) =>
      (ExpensePreviewBuilder()..update(updates))._build();

  _$ExpensePreview._(
      {this.adjustmentMinor,
      this.deliveryMinor,
      this.discountMinor,
      required this.members,
      required this.payersTotalMatches,
      this.periodFrom,
      this.periodTo,
      this.serviceMinor,
      this.subtotalMinor,
      this.taxMinor,
      required this.totalMinor})
      : super._();
  @override
  ExpensePreview rebuild(void Function(ExpensePreviewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpensePreviewBuilder toBuilder() => ExpensePreviewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpensePreview &&
        adjustmentMinor == other.adjustmentMinor &&
        deliveryMinor == other.deliveryMinor &&
        discountMinor == other.discountMinor &&
        members == other.members &&
        payersTotalMatches == other.payersTotalMatches &&
        periodFrom == other.periodFrom &&
        periodTo == other.periodTo &&
        serviceMinor == other.serviceMinor &&
        subtotalMinor == other.subtotalMinor &&
        taxMinor == other.taxMinor &&
        totalMinor == other.totalMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adjustmentMinor.hashCode);
    _$hash = $jc(_$hash, deliveryMinor.hashCode);
    _$hash = $jc(_$hash, discountMinor.hashCode);
    _$hash = $jc(_$hash, members.hashCode);
    _$hash = $jc(_$hash, payersTotalMatches.hashCode);
    _$hash = $jc(_$hash, periodFrom.hashCode);
    _$hash = $jc(_$hash, periodTo.hashCode);
    _$hash = $jc(_$hash, serviceMinor.hashCode);
    _$hash = $jc(_$hash, subtotalMinor.hashCode);
    _$hash = $jc(_$hash, taxMinor.hashCode);
    _$hash = $jc(_$hash, totalMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpensePreview')
          ..add('adjustmentMinor', adjustmentMinor)
          ..add('deliveryMinor', deliveryMinor)
          ..add('discountMinor', discountMinor)
          ..add('members', members)
          ..add('payersTotalMatches', payersTotalMatches)
          ..add('periodFrom', periodFrom)
          ..add('periodTo', periodTo)
          ..add('serviceMinor', serviceMinor)
          ..add('subtotalMinor', subtotalMinor)
          ..add('taxMinor', taxMinor)
          ..add('totalMinor', totalMinor))
        .toString();
  }
}

class ExpensePreviewBuilder
    implements Builder<ExpensePreview, ExpensePreviewBuilder> {
  _$ExpensePreview? _$v;

  int? _adjustmentMinor;
  int? get adjustmentMinor => _$this._adjustmentMinor;
  set adjustmentMinor(int? adjustmentMinor) =>
      _$this._adjustmentMinor = adjustmentMinor;

  int? _deliveryMinor;
  int? get deliveryMinor => _$this._deliveryMinor;
  set deliveryMinor(int? deliveryMinor) =>
      _$this._deliveryMinor = deliveryMinor;

  int? _discountMinor;
  int? get discountMinor => _$this._discountMinor;
  set discountMinor(int? discountMinor) =>
      _$this._discountMinor = discountMinor;

  ListBuilder<ShareView>? _members;
  ListBuilder<ShareView> get members =>
      _$this._members ??= ListBuilder<ShareView>();
  set members(ListBuilder<ShareView>? members) => _$this._members = members;

  bool? _payersTotalMatches;
  bool? get payersTotalMatches => _$this._payersTotalMatches;
  set payersTotalMatches(bool? payersTotalMatches) =>
      _$this._payersTotalMatches = payersTotalMatches;

  Date? _periodFrom;
  Date? get periodFrom => _$this._periodFrom;
  set periodFrom(Date? periodFrom) => _$this._periodFrom = periodFrom;

  Date? _periodTo;
  Date? get periodTo => _$this._periodTo;
  set periodTo(Date? periodTo) => _$this._periodTo = periodTo;

  int? _serviceMinor;
  int? get serviceMinor => _$this._serviceMinor;
  set serviceMinor(int? serviceMinor) => _$this._serviceMinor = serviceMinor;

  int? _subtotalMinor;
  int? get subtotalMinor => _$this._subtotalMinor;
  set subtotalMinor(int? subtotalMinor) =>
      _$this._subtotalMinor = subtotalMinor;

  int? _taxMinor;
  int? get taxMinor => _$this._taxMinor;
  set taxMinor(int? taxMinor) => _$this._taxMinor = taxMinor;

  int? _totalMinor;
  int? get totalMinor => _$this._totalMinor;
  set totalMinor(int? totalMinor) => _$this._totalMinor = totalMinor;

  ExpensePreviewBuilder() {
    ExpensePreview._defaults(this);
  }

  ExpensePreviewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adjustmentMinor = $v.adjustmentMinor;
      _deliveryMinor = $v.deliveryMinor;
      _discountMinor = $v.discountMinor;
      _members = $v.members.toBuilder();
      _payersTotalMatches = $v.payersTotalMatches;
      _periodFrom = $v.periodFrom;
      _periodTo = $v.periodTo;
      _serviceMinor = $v.serviceMinor;
      _subtotalMinor = $v.subtotalMinor;
      _taxMinor = $v.taxMinor;
      _totalMinor = $v.totalMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpensePreview other) {
    _$v = other as _$ExpensePreview;
  }

  @override
  void update(void Function(ExpensePreviewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpensePreview build() => _build();

  _$ExpensePreview _build() {
    _$ExpensePreview _$result;
    try {
      _$result = _$v ??
          _$ExpensePreview._(
            adjustmentMinor: adjustmentMinor,
            deliveryMinor: deliveryMinor,
            discountMinor: discountMinor,
            members: members.build(),
            payersTotalMatches: BuiltValueNullFieldError.checkNotNull(
                payersTotalMatches, r'ExpensePreview', 'payersTotalMatches'),
            periodFrom: periodFrom,
            periodTo: periodTo,
            serviceMinor: serviceMinor,
            subtotalMinor: subtotalMinor,
            taxMinor: taxMinor,
            totalMinor: BuiltValueNullFieldError.checkNotNull(
                totalMinor, r'ExpensePreview', 'totalMinor'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'members';
        members.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ExpensePreview', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
