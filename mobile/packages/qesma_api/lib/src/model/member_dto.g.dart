// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MemberDto extends MemberDto {
  @override
  final DateTime createdAt;
  @override
  final String displayName;
  @override
  final bool hasAccount;
  @override
  final String id;
  @override
  final bool isYou;
  @override
  final String role;
  @override
  final int sortOrder;
  @override
  final String status;

  factory _$MemberDto([void Function(MemberDtoBuilder)? updates]) =>
      (MemberDtoBuilder()..update(updates))._build();

  _$MemberDto._(
      {required this.createdAt,
      required this.displayName,
      required this.hasAccount,
      required this.id,
      required this.isYou,
      required this.role,
      required this.sortOrder,
      required this.status})
      : super._();
  @override
  MemberDto rebuild(void Function(MemberDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MemberDtoBuilder toBuilder() => MemberDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MemberDto &&
        createdAt == other.createdAt &&
        displayName == other.displayName &&
        hasAccount == other.hasAccount &&
        id == other.id &&
        isYou == other.isYou &&
        role == other.role &&
        sortOrder == other.sortOrder &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, displayName.hashCode);
    _$hash = $jc(_$hash, hasAccount.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, isYou.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MemberDto')
          ..add('createdAt', createdAt)
          ..add('displayName', displayName)
          ..add('hasAccount', hasAccount)
          ..add('id', id)
          ..add('isYou', isYou)
          ..add('role', role)
          ..add('sortOrder', sortOrder)
          ..add('status', status))
        .toString();
  }
}

class MemberDtoBuilder implements Builder<MemberDto, MemberDtoBuilder> {
  _$MemberDto? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _displayName;
  String? get displayName => _$this._displayName;
  set displayName(String? displayName) => _$this._displayName = displayName;

  bool? _hasAccount;
  bool? get hasAccount => _$this._hasAccount;
  set hasAccount(bool? hasAccount) => _$this._hasAccount = hasAccount;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  bool? _isYou;
  bool? get isYou => _$this._isYou;
  set isYou(bool? isYou) => _$this._isYou = isYou;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  int? _sortOrder;
  int? get sortOrder => _$this._sortOrder;
  set sortOrder(int? sortOrder) => _$this._sortOrder = sortOrder;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  MemberDtoBuilder() {
    MemberDto._defaults(this);
  }

  MemberDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _displayName = $v.displayName;
      _hasAccount = $v.hasAccount;
      _id = $v.id;
      _isYou = $v.isYou;
      _role = $v.role;
      _sortOrder = $v.sortOrder;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MemberDto other) {
    _$v = other as _$MemberDto;
  }

  @override
  void update(void Function(MemberDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MemberDto build() => _build();

  _$MemberDto _build() {
    final _$result = _$v ??
        _$MemberDto._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'MemberDto', 'createdAt'),
          displayName: BuiltValueNullFieldError.checkNotNull(
              displayName, r'MemberDto', 'displayName'),
          hasAccount: BuiltValueNullFieldError.checkNotNull(
              hasAccount, r'MemberDto', 'hasAccount'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'MemberDto', 'id'),
          isYou: BuiltValueNullFieldError.checkNotNull(
              isYou, r'MemberDto', 'isYou'),
          role:
              BuiltValueNullFieldError.checkNotNull(role, r'MemberDto', 'role'),
          sortOrder: BuiltValueNullFieldError.checkNotNull(
              sortOrder, r'MemberDto', 'sortOrder'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'MemberDto', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
