// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_group_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateGroupRequest extends UpdateGroupRequest {
  @override
  final int? budgetMinor;
  @override
  final bool? clearBudget;
  @override
  final bool? clearTripEndDate;
  @override
  final bool? clearTripStartDate;
  @override
  final String? name;
  @override
  final String? treasurerMemberId;
  @override
  final Date? tripEndDate;
  @override
  final Date? tripStartDate;
  @override
  final String? type;

  factory _$UpdateGroupRequest(
          [void Function(UpdateGroupRequestBuilder)? updates]) =>
      (UpdateGroupRequestBuilder()..update(updates))._build();

  _$UpdateGroupRequest._(
      {this.budgetMinor,
      this.clearBudget,
      this.clearTripEndDate,
      this.clearTripStartDate,
      this.name,
      this.treasurerMemberId,
      this.tripEndDate,
      this.tripStartDate,
      this.type})
      : super._();
  @override
  UpdateGroupRequest rebuild(
          void Function(UpdateGroupRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateGroupRequestBuilder toBuilder() =>
      UpdateGroupRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateGroupRequest &&
        budgetMinor == other.budgetMinor &&
        clearBudget == other.clearBudget &&
        clearTripEndDate == other.clearTripEndDate &&
        clearTripStartDate == other.clearTripStartDate &&
        name == other.name &&
        treasurerMemberId == other.treasurerMemberId &&
        tripEndDate == other.tripEndDate &&
        tripStartDate == other.tripStartDate &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, budgetMinor.hashCode);
    _$hash = $jc(_$hash, clearBudget.hashCode);
    _$hash = $jc(_$hash, clearTripEndDate.hashCode);
    _$hash = $jc(_$hash, clearTripStartDate.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, treasurerMemberId.hashCode);
    _$hash = $jc(_$hash, tripEndDate.hashCode);
    _$hash = $jc(_$hash, tripStartDate.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateGroupRequest')
          ..add('budgetMinor', budgetMinor)
          ..add('clearBudget', clearBudget)
          ..add('clearTripEndDate', clearTripEndDate)
          ..add('clearTripStartDate', clearTripStartDate)
          ..add('name', name)
          ..add('treasurerMemberId', treasurerMemberId)
          ..add('tripEndDate', tripEndDate)
          ..add('tripStartDate', tripStartDate)
          ..add('type', type))
        .toString();
  }
}

class UpdateGroupRequestBuilder
    implements Builder<UpdateGroupRequest, UpdateGroupRequestBuilder> {
  _$UpdateGroupRequest? _$v;

  int? _budgetMinor;
  int? get budgetMinor => _$this._budgetMinor;
  set budgetMinor(int? budgetMinor) => _$this._budgetMinor = budgetMinor;

  bool? _clearBudget;
  bool? get clearBudget => _$this._clearBudget;
  set clearBudget(bool? clearBudget) => _$this._clearBudget = clearBudget;

  bool? _clearTripEndDate;
  bool? get clearTripEndDate => _$this._clearTripEndDate;
  set clearTripEndDate(bool? clearTripEndDate) =>
      _$this._clearTripEndDate = clearTripEndDate;

  bool? _clearTripStartDate;
  bool? get clearTripStartDate => _$this._clearTripStartDate;
  set clearTripStartDate(bool? clearTripStartDate) =>
      _$this._clearTripStartDate = clearTripStartDate;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _treasurerMemberId;
  String? get treasurerMemberId => _$this._treasurerMemberId;
  set treasurerMemberId(String? treasurerMemberId) =>
      _$this._treasurerMemberId = treasurerMemberId;

  Date? _tripEndDate;
  Date? get tripEndDate => _$this._tripEndDate;
  set tripEndDate(Date? tripEndDate) => _$this._tripEndDate = tripEndDate;

  Date? _tripStartDate;
  Date? get tripStartDate => _$this._tripStartDate;
  set tripStartDate(Date? tripStartDate) =>
      _$this._tripStartDate = tripStartDate;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  UpdateGroupRequestBuilder() {
    UpdateGroupRequest._defaults(this);
  }

  UpdateGroupRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _budgetMinor = $v.budgetMinor;
      _clearBudget = $v.clearBudget;
      _clearTripEndDate = $v.clearTripEndDate;
      _clearTripStartDate = $v.clearTripStartDate;
      _name = $v.name;
      _treasurerMemberId = $v.treasurerMemberId;
      _tripEndDate = $v.tripEndDate;
      _tripStartDate = $v.tripStartDate;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateGroupRequest other) {
    _$v = other as _$UpdateGroupRequest;
  }

  @override
  void update(void Function(UpdateGroupRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateGroupRequest build() => _build();

  _$UpdateGroupRequest _build() {
    final _$result = _$v ??
        _$UpdateGroupRequest._(
          budgetMinor: budgetMinor,
          clearBudget: clearBudget,
          clearTripEndDate: clearTripEndDate,
          clearTripStartDate: clearTripStartDate,
          name: name,
          treasurerMemberId: treasurerMemberId,
          tripEndDate: tripEndDate,
          tripStartDate: tripStartDate,
          type: type,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
