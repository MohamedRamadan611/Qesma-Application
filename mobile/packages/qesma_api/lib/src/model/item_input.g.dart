// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ItemInput extends ItemInput {
  @override
  final int amountMinor;
  @override
  final BuiltList<String> assigneeMemberIds;
  @override
  final String name;

  factory _$ItemInput([void Function(ItemInputBuilder)? updates]) =>
      (ItemInputBuilder()..update(updates))._build();

  _$ItemInput._(
      {required this.amountMinor,
      required this.assigneeMemberIds,
      required this.name})
      : super._();
  @override
  ItemInput rebuild(void Function(ItemInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemInputBuilder toBuilder() => ItemInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ItemInput &&
        amountMinor == other.amountMinor &&
        assigneeMemberIds == other.assigneeMemberIds &&
        name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, assigneeMemberIds.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ItemInput')
          ..add('amountMinor', amountMinor)
          ..add('assigneeMemberIds', assigneeMemberIds)
          ..add('name', name))
        .toString();
  }
}

class ItemInputBuilder implements Builder<ItemInput, ItemInputBuilder> {
  _$ItemInput? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  ListBuilder<String>? _assigneeMemberIds;
  ListBuilder<String> get assigneeMemberIds =>
      _$this._assigneeMemberIds ??= ListBuilder<String>();
  set assigneeMemberIds(ListBuilder<String>? assigneeMemberIds) =>
      _$this._assigneeMemberIds = assigneeMemberIds;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ItemInputBuilder() {
    ItemInput._defaults(this);
  }

  ItemInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _assigneeMemberIds = $v.assigneeMemberIds.toBuilder();
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ItemInput other) {
    _$v = other as _$ItemInput;
  }

  @override
  void update(void Function(ItemInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ItemInput build() => _build();

  _$ItemInput _build() {
    _$ItemInput _$result;
    try {
      _$result = _$v ??
          _$ItemInput._(
            amountMinor: BuiltValueNullFieldError.checkNotNull(
                amountMinor, r'ItemInput', 'amountMinor'),
            assigneeMemberIds: assigneeMemberIds.build(),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'ItemInput', 'name'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'assigneeMemberIds';
        assigneeMemberIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ItemInput', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
