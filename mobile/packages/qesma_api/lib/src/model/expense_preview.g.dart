// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_preview.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpensePreview extends ExpensePreview {
  @override
  final int? adjustmentMinor;
  @override
  final BuiltList<ShareView> members;
  @override
  final bool payersTotalMatches;
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
      required this.members,
      required this.payersTotalMatches,
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
        members == other.members &&
        payersTotalMatches == other.payersTotalMatches &&
        serviceMinor == other.serviceMinor &&
        subtotalMinor == other.subtotalMinor &&
        taxMinor == other.taxMinor &&
        totalMinor == other.totalMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adjustmentMinor.hashCode);
    _$hash = $jc(_$hash, members.hashCode);
    _$hash = $jc(_$hash, payersTotalMatches.hashCode);
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
          ..add('members', members)
          ..add('payersTotalMatches', payersTotalMatches)
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

  ListBuilder<ShareView>? _members;
  ListBuilder<ShareView> get members =>
      _$this._members ??= ListBuilder<ShareView>();
  set members(ListBuilder<ShareView>? members) => _$this._members = members;

  bool? _payersTotalMatches;
  bool? get payersTotalMatches => _$this._payersTotalMatches;
  set payersTotalMatches(bool? payersTotalMatches) =>
      _$this._payersTotalMatches = payersTotalMatches;

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
      _members = $v.members.toBuilder();
      _payersTotalMatches = $v.payersTotalMatches;
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
            members: members.build(),
            payersTotalMatches: BuiltValueNullFieldError.checkNotNull(
                payersTotalMatches, r'ExpensePreview', 'payersTotalMatches'),
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
