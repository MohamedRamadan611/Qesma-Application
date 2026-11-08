// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupDto extends GroupDto {
  @override
  final DateTime createdAt;
  @override
  final String currencyCode;
  @override
  final String id;
  @override
  final DateTime? lastExpenseAt;
  @override
  final BuiltList<MemberDto> members;
  @override
  final String name;
  @override
  final int totalSpentMinor;
  @override
  final String type;
  @override
  final DateTime updatedAt;
  @override
  final int version;
  @override
  final String yourMemberId;
  @override
  final int yourNetMinor;

  factory _$GroupDto([void Function(GroupDtoBuilder)? updates]) =>
      (GroupDtoBuilder()..update(updates))._build();

  _$GroupDto._(
      {required this.createdAt,
      required this.currencyCode,
      required this.id,
      this.lastExpenseAt,
      required this.members,
      required this.name,
      required this.totalSpentMinor,
      required this.type,
      required this.updatedAt,
      required this.version,
      required this.yourMemberId,
      required this.yourNetMinor})
      : super._();
  @override
  GroupDto rebuild(void Function(GroupDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupDtoBuilder toBuilder() => GroupDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupDto &&
        createdAt == other.createdAt &&
        currencyCode == other.currencyCode &&
        id == other.id &&
        lastExpenseAt == other.lastExpenseAt &&
        members == other.members &&
        name == other.name &&
        totalSpentMinor == other.totalSpentMinor &&
        type == other.type &&
        updatedAt == other.updatedAt &&
        version == other.version &&
        yourMemberId == other.yourMemberId &&
        yourNetMinor == other.yourNetMinor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, currencyCode.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, lastExpenseAt.hashCode);
    _$hash = $jc(_$hash, members.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, totalSpentMinor.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, yourMemberId.hashCode);
    _$hash = $jc(_$hash, yourNetMinor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupDto')
          ..add('createdAt', createdAt)
          ..add('currencyCode', currencyCode)
          ..add('id', id)
          ..add('lastExpenseAt', lastExpenseAt)
          ..add('members', members)
          ..add('name', name)
          ..add('totalSpentMinor', totalSpentMinor)
          ..add('type', type)
          ..add('updatedAt', updatedAt)
          ..add('version', version)
          ..add('yourMemberId', yourMemberId)
          ..add('yourNetMinor', yourNetMinor))
        .toString();
  }
}

class GroupDtoBuilder implements Builder<GroupDto, GroupDtoBuilder> {
  _$GroupDto? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

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

  ListBuilder<MemberDto>? _members;
  ListBuilder<MemberDto> get members =>
      _$this._members ??= ListBuilder<MemberDto>();
  set members(ListBuilder<MemberDto>? members) => _$this._members = members;

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

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  String? _yourMemberId;
  String? get yourMemberId => _$this._yourMemberId;
  set yourMemberId(String? yourMemberId) => _$this._yourMemberId = yourMemberId;

  int? _yourNetMinor;
  int? get yourNetMinor => _$this._yourNetMinor;
  set yourNetMinor(int? yourNetMinor) => _$this._yourNetMinor = yourNetMinor;

  GroupDtoBuilder() {
    GroupDto._defaults(this);
  }

  GroupDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _currencyCode = $v.currencyCode;
      _id = $v.id;
      _lastExpenseAt = $v.lastExpenseAt;
      _members = $v.members.toBuilder();
      _name = $v.name;
      _totalSpentMinor = $v.totalSpentMinor;
      _type = $v.type;
      _updatedAt = $v.updatedAt;
      _version = $v.version;
      _yourMemberId = $v.yourMemberId;
      _yourNetMinor = $v.yourNetMinor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupDto other) {
    _$v = other as _$GroupDto;
  }

  @override
  void update(void Function(GroupDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupDto build() => _build();

  _$GroupDto _build() {
    _$GroupDto _$result;
    try {
      _$result = _$v ??
          _$GroupDto._(
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'GroupDto', 'createdAt'),
            currencyCode: BuiltValueNullFieldError.checkNotNull(
                currencyCode, r'GroupDto', 'currencyCode'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'GroupDto', 'id'),
            lastExpenseAt: lastExpenseAt,
            members: members.build(),
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'GroupDto', 'name'),
            totalSpentMinor: BuiltValueNullFieldError.checkNotNull(
                totalSpentMinor, r'GroupDto', 'totalSpentMinor'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'GroupDto', 'type'),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
                updatedAt, r'GroupDto', 'updatedAt'),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'GroupDto', 'version'),
            yourMemberId: BuiltValueNullFieldError.checkNotNull(
                yourMemberId, r'GroupDto', 'yourMemberId'),
            yourNetMinor: BuiltValueNullFieldError.checkNotNull(
                yourNetMinor, r'GroupDto', 'yourNetMinor'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'members';
        members.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'GroupDto', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
