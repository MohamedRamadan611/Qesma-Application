// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShareView extends ShareView {
  @override
  final int? adjustmentMinor;
  @override
  final int? itemsMinor;
  @override
  final String memberId;
  @override
  final int owedMinor;
  @override
  final int? serviceMinor;
  @override
  final int? taxMinor;

  factory _$ShareView([void Function(ShareViewBuilder)? updates]) =>
      (ShareViewBuilder()..update(updates))._build();

  _$ShareView._(
      {this.adjustmentMinor,
      this.itemsMinor,
      required this.memberId,
      required this.owedMinor,
      this.serviceMinor,
      this.taxMinor})
      : super._();
  @override
  ShareView rebuild(void Function(ShareViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShareViewBuilder toBuilder() => ShareViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShareView &&
        adjustmentMinor == other.adjustmentMinor &&
        itemsMinor == other.itemsMinor &&
        memberId == other.memberId &&
        owedMinor == other.owedMinor &&
        serviceMinor == other.serviceMinor &&
        taxMinor == other.taxMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adjustmentMinor.hashCode);
    _$hash = $jc(_$hash, itemsMinor.hashCode);
    _$hash = $jc(_$hash, memberId.hashCode);
    _$hash = $jc(_$hash, owedMinor.hashCode);
    _$hash = $jc(_$hash, serviceMinor.hashCode);
    _$hash = $jc(_$hash, taxMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShareView')
          ..add('adjustmentMinor', adjustmentMinor)
          ..add('itemsMinor', itemsMinor)
          ..add('memberId', memberId)
          ..add('owedMinor', owedMinor)
          ..add('serviceMinor', serviceMinor)
          ..add('taxMinor', taxMinor))
        .toString();
  }
}

class ShareViewBuilder implements Builder<ShareView, ShareViewBuilder> {
  _$ShareView? _$v;

  int? _adjustmentMinor;
  int? get adjustmentMinor => _$this._adjustmentMinor;
  set adjustmentMinor(int? adjustmentMinor) =>
      _$this._adjustmentMinor = adjustmentMinor;

  int? _itemsMinor;
  int? get itemsMinor => _$this._itemsMinor;
  set itemsMinor(int? itemsMinor) => _$this._itemsMinor = itemsMinor;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  int? _owedMinor;
  int? get owedMinor => _$this._owedMinor;
  set owedMinor(int? owedMinor) => _$this._owedMinor = owedMinor;

  int? _serviceMinor;
  int? get serviceMinor => _$this._serviceMinor;
  set serviceMinor(int? serviceMinor) => _$this._serviceMinor = serviceMinor;

  int? _taxMinor;
  int? get taxMinor => _$this._taxMinor;
  set taxMinor(int? taxMinor) => _$this._taxMinor = taxMinor;

  ShareViewBuilder() {
    ShareView._defaults(this);
  }

  ShareViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adjustmentMinor = $v.adjustmentMinor;
      _itemsMinor = $v.itemsMinor;
      _memberId = $v.memberId;
      _owedMinor = $v.owedMinor;
      _serviceMinor = $v.serviceMinor;
      _taxMinor = $v.taxMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShareView other) {
    _$v = other as _$ShareView;
  }

  @override
  void update(void Function(ShareViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShareView build() => _build();

  _$ShareView _build() {
    final _$result = _$v ??
        _$ShareView._(
          adjustmentMinor: adjustmentMinor,
          itemsMinor: itemsMinor,
          memberId: BuiltValueNullFieldError.checkNotNull(
              memberId, r'ShareView', 'memberId'),
          owedMinor: BuiltValueNullFieldError.checkNotNull(
              owedMinor, r'ShareView', 'owedMinor'),
          serviceMinor: serviceMinor,
          taxMinor: taxMinor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
