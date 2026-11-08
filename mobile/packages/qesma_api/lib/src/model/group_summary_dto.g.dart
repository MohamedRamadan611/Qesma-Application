// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_summary_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupSummaryDto extends GroupSummaryDto {
  @override
  final String currencyCode;
  @override
  final String id;
  @override
  final DateTime? lastExpenseAt;
  @override
  final int memberCount;
  @override
  final String name;
  @override
  final int totalSpentMinor;
  @override
  final String type;
  @override
  final int yourNetMinor;

  factory _$GroupSummaryDto([void Function(GroupSummaryDtoBuilder)? updates]) =>
      (GroupSummaryDtoBuilder()..update(updates))._build();

  _$GroupSummaryDto._(
      {required this.currencyCode,
      required this.id,
      this.lastExpenseAt,
      required this.memberCount,
      required this.name,
      required this.totalSpentMinor,
      required this.type,
      required this.yourNetMinor})
      : super._();
  @override
  GroupSummaryDto rebuild(void Function(GroupSummaryDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupSummaryDtoBuilder toBuilder() => GroupSummaryDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupSummaryDto &&
        currencyCode == other.currencyCode &&
        id == other.id &&
        lastExpenseAt == other.lastExpenseAt &&
        memberCount == other.memberCount &&
        name == other.name &&
        totalSpentMinor == other.totalSpentMinor &&
        type == other.type &&
        yourNetMinor == other.yourNetMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currencyCode.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, lastExpenseAt.hashCode);
    _$hash = $jc(_$hash, memberCount.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, totalSpentMinor.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, yourNetMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupSummaryDto')
          ..add('currencyCode', currencyCode)
          ..add('id', id)
          ..add('lastExpenseAt', lastExpenseAt)
          ..add('memberCount', memberCount)
          ..add('name', name)
          ..add('totalSpentMinor', totalSpentMinor)
          ..add('type', type)
          ..add('yourNetMinor', yourNetMinor))
        .toString();
  }
}

class GroupSummaryDtoBuilder
    implements Builder<GroupSummaryDto, GroupSummaryDtoBuilder> {
  _$GroupSummaryDto? _$v;

  String? _currencyCode;
  String? get currencyCode => _$this._currencyCode;
  set currencyCode(String? currencyCode) => _$this._currencyCode = currencyCode;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _lastExpenseAt;
  DateTime? get lastExpenseAt => _$this._lastExpenseAt;
  set lastExpenseAt(DateTime? lastExpenseAt) =>
      _$this._lastExpenseAt = lastExpenseAt;

  int? _memberCount;
  int? get memberCount => _$this._memberCount;
  set memberCount(int? memberCount) => _$this._memberCount = memberCount;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _totalSpentMinor;
  int? get totalSpentMinor => _$this._totalSpentMinor;
  set totalSpentMinor(int? totalSpentMinor) =>
      _$this._totalSpentMinor = totalSpentMinor;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  int? _yourNetMinor;
  int? get yourNetMinor => _$this._yourNetMinor;
  set yourNetMinor(int? yourNetMinor) => _$this._yourNetMinor = yourNetMinor;

  GroupSummaryDtoBuilder() {
    GroupSummaryDto._defaults(this);
  }

  GroupSummaryDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currencyCode = $v.currencyCode;
      _id = $v.id;
      _lastExpenseAt = $v.lastExpenseAt;
      _memberCount = $v.memberCount;
      _name = $v.name;
      _totalSpentMinor = $v.totalSpentMinor;
      _type = $v.type;
      _yourNetMinor = $v.yourNetMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupSummaryDto other) {
    _$v = other as _$GroupSummaryDto;
  }

  @override
  void update(void Function(GroupSummaryDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupSummaryDto build() => _build();

  _$GroupSummaryDto _build() {
    final _$result = _$v ??
        _$GroupSummaryDto._(
          currencyCode: BuiltValueNullFieldError.checkNotNull(
              currencyCode, r'GroupSummaryDto', 'currencyCode'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'GroupSummaryDto', 'id'),
          lastExpenseAt: lastExpenseAt,
          memberCount: BuiltValueNullFieldError.checkNotNull(
              memberCount, r'GroupSummaryDto', 'memberCount'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'GroupSummaryDto', 'name'),
          totalSpentMinor: BuiltValueNullFieldError.checkNotNull(
              totalSpentMinor, r'GroupSummaryDto', 'totalSpentMinor'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'GroupSummaryDto', 'type'),
          yourNetMinor: BuiltValueNullFieldError.checkNotNull(
              yourNetMinor, r'GroupSummaryDto', 'yourNetMinor'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
