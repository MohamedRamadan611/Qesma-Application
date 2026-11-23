// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShareView extends ShareView {
  @override
  final int? adjustmentMinor;
  @override
  final int? deliveryMinor;
  @override
  final int? discountMinor;
  @override
  final int? itemsMinor;
  @override
  final String memberId;
  @override
  final int owedMinor;
  @override
  final Date? presentFrom;
  @override
  final Date? presentTo;
  @override
  final int? serviceMinor;
  @override
  final int? shareUnits;
  @override
  final int? taxMinor;

  factory _$ShareView([void Function(ShareViewBuilder)? updates]) =>
      (ShareViewBuilder()..update(updates))._build();

  _$ShareView._(
      {this.adjustmentMinor,
      this.deliveryMinor,
      this.discountMinor,
      this.itemsMinor,
      required this.memberId,
      required this.owedMinor,
      this.presentFrom,
      this.presentTo,
      this.serviceMinor,
      this.shareUnits,
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
        deliveryMinor == other.deliveryMinor &&
        discountMinor == other.discountMinor &&
        itemsMinor == other.itemsMinor &&
        memberId == other.memberId &&
        owedMinor == other.owedMinor &&
        presentFrom == other.presentFrom &&
        presentTo == other.presentTo &&
        serviceMinor == other.serviceMinor &&
        shareUnits == other.shareUnits &&
        taxMinor == other.taxMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adjustmentMinor.hashCode);
    _$hash = $jc(_$hash, deliveryMinor.hashCode);
    _$hash = $jc(_$hash, discountMinor.hashCode);
    _$hash = $jc(_$hash, itemsMinor.hashCode);
    _$hash = $jc(_$hash, memberId.hashCode);
    _$hash = $jc(_$hash, owedMinor.hashCode);
    _$hash = $jc(_$hash, presentFrom.hashCode);
    _$hash = $jc(_$hash, presentTo.hashCode);
    _$hash = $jc(_$hash, serviceMinor.hashCode);
    _$hash = $jc(_$hash, shareUnits.hashCode);
    _$hash = $jc(_$hash, taxMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShareView')
          ..add('adjustmentMinor', adjustmentMinor)
          ..add('deliveryMinor', deliveryMinor)
          ..add('discountMinor', discountMinor)
          ..add('itemsMinor', itemsMinor)
          ..add('memberId', memberId)
          ..add('owedMinor', owedMinor)
          ..add('presentFrom', presentFrom)
          ..add('presentTo', presentTo)
          ..add('serviceMinor', serviceMinor)
          ..add('shareUnits', shareUnits)
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

  int? _deliveryMinor;
  int? get deliveryMinor => _$this._deliveryMinor;
  set deliveryMinor(int? deliveryMinor) =>
      _$this._deliveryMinor = deliveryMinor;

  int? _discountMinor;
  int? get discountMinor => _$this._discountMinor;
  set discountMinor(int? discountMinor) =>
      _$this._discountMinor = discountMinor;

  int? _itemsMinor;
  int? get itemsMinor => _$this._itemsMinor;
  set itemsMinor(int? itemsMinor) => _$this._itemsMinor = itemsMinor;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  int? _owedMinor;
  int? get owedMinor => _$this._owedMinor;
  set owedMinor(int? owedMinor) => _$this._owedMinor = owedMinor;

  Date? _presentFrom;
  Date? get presentFrom => _$this._presentFrom;
  set presentFrom(Date? presentFrom) => _$this._presentFrom = presentFrom;

  Date? _presentTo;
  Date? get presentTo => _$this._presentTo;
  set presentTo(Date? presentTo) => _$this._presentTo = presentTo;

  int? _serviceMinor;
  int? get serviceMinor => _$this._serviceMinor;
  set serviceMinor(int? serviceMinor) => _$this._serviceMinor = serviceMinor;

  int? _shareUnits;
  int? get shareUnits => _$this._shareUnits;
  set shareUnits(int? shareUnits) => _$this._shareUnits = shareUnits;

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
      _deliveryMinor = $v.deliveryMinor;
      _discountMinor = $v.discountMinor;
      _itemsMinor = $v.itemsMinor;
      _memberId = $v.memberId;
      _owedMinor = $v.owedMinor;
      _presentFrom = $v.presentFrom;
      _presentTo = $v.presentTo;
      _serviceMinor = $v.serviceMinor;
      _shareUnits = $v.shareUnits;
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
          deliveryMinor: deliveryMinor,
          discountMinor: discountMinor,
          itemsMinor: itemsMinor,
          memberId: BuiltValueNullFieldError.checkNotNull(
              memberId, r'ShareView', 'memberId'),
          owedMinor: BuiltValueNullFieldError.checkNotNull(
              owedMinor, r'ShareView', 'owedMinor'),
          presentFrom: presentFrom,
          presentTo: presentTo,
          serviceMinor: serviceMinor,
          shareUnits: shareUnits,
          taxMinor: taxMinor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
