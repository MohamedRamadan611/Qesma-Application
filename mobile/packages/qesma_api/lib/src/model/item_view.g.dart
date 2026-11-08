// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ItemView extends ItemView {
  @override
  final int amountMinor;
  @override
  final BuiltList<String> assigneeMemberIds;
  @override
  final String id;
  @override
  final String name;

  factory _$ItemView([void Function(ItemViewBuilder)? updates]) =>
      (ItemViewBuilder()..update(updates))._build();

  _$ItemView._(
      {required this.amountMinor,
      required this.assigneeMemberIds,
      required this.id,
      required this.name})
      : super._();
  @override
  ItemView rebuild(void Function(ItemViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemViewBuilder toBuilder() => ItemViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ItemView &&
        amountMinor == other.amountMinor &&
        assigneeMemberIds == other.assigneeMemberIds &&
        id == other.id &&
        name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, assigneeMemberIds.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ItemView')
          ..add('amountMinor', amountMinor)
          ..add('assigneeMemberIds', assigneeMemberIds)
          ..add('id', id)
          ..add('name', name))
        .toString();
  }
}

class ItemViewBuilder implements Builder<ItemView, ItemViewBuilder> {
  _$ItemView? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  ListBuilder<String>? _assigneeMemberIds;
  ListBuilder<String> get assigneeMemberIds =>
      _$this._assigneeMemberIds ??= ListBuilder<String>();
  set assigneeMemberIds(ListBuilder<String>? assigneeMemberIds) =>
      _$this._assigneeMemberIds = assigneeMemberIds;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ItemViewBuilder() {
    ItemView._defaults(this);
  }

  ItemViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _assigneeMemberIds = $v.assigneeMemberIds.toBuilder();
      _id = $v.id;
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ItemView other) {
    _$v = other as _$ItemView;
  }

  @override
  void update(void Function(ItemViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ItemView build() => _build();

  _$ItemView _build() {
    _$ItemView _$result;
    try {
      _$result = _$v ??
          _$ItemView._(
            amountMinor: BuiltValueNullFieldError.checkNotNull(
                amountMinor, r'ItemView', 'amountMinor'),
            assigneeMemberIds: assigneeMemberIds.build(),
            id: BuiltValueNullFieldError.checkNotNull(id, r'ItemView', 'id'),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'ItemView', 'name'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'assigneeMemberIds';
        assigneeMemberIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ItemView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
