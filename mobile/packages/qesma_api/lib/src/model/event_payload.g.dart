// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EventPayloadPreviousRoleEnum _$eventPayloadPreviousRoleEnum_OWNER =
    const EventPayloadPreviousRoleEnum._('OWNER');
const EventPayloadPreviousRoleEnum _$eventPayloadPreviousRoleEnum_ADMIN =
    const EventPayloadPreviousRoleEnum._('ADMIN');
const EventPayloadPreviousRoleEnum _$eventPayloadPreviousRoleEnum_MEMBER =
    const EventPayloadPreviousRoleEnum._('MEMBER');

EventPayloadPreviousRoleEnum _$eventPayloadPreviousRoleEnumValueOf(
    String name) {
  switch (name) {
    case 'OWNER':
      return _$eventPayloadPreviousRoleEnum_OWNER;
    case 'ADMIN':
      return _$eventPayloadPreviousRoleEnum_ADMIN;
    case 'MEMBER':
      return _$eventPayloadPreviousRoleEnum_MEMBER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<EventPayloadPreviousRoleEnum>
    _$eventPayloadPreviousRoleEnumValues =
    BuiltSet<EventPayloadPreviousRoleEnum>(const <EventPayloadPreviousRoleEnum>[
  _$eventPayloadPreviousRoleEnum_OWNER,
  _$eventPayloadPreviousRoleEnum_ADMIN,
  _$eventPayloadPreviousRoleEnum_MEMBER,
]);

const EventPayloadRoleEnum _$eventPayloadRoleEnum_OWNER =
    const EventPayloadRoleEnum._('OWNER');
const EventPayloadRoleEnum _$eventPayloadRoleEnum_ADMIN =
    const EventPayloadRoleEnum._('ADMIN');
const EventPayloadRoleEnum _$eventPayloadRoleEnum_MEMBER =
    const EventPayloadRoleEnum._('MEMBER');

EventPayloadRoleEnum _$eventPayloadRoleEnumValueOf(String name) {
  switch (name) {
    case 'OWNER':
      return _$eventPayloadRoleEnum_OWNER;
    case 'ADMIN':
      return _$eventPayloadRoleEnum_ADMIN;
    case 'MEMBER':
      return _$eventPayloadRoleEnum_MEMBER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<EventPayloadRoleEnum> _$eventPayloadRoleEnumValues =
    BuiltSet<EventPayloadRoleEnum>(const <EventPayloadRoleEnum>[
  _$eventPayloadRoleEnum_OWNER,
  _$eventPayloadRoleEnum_ADMIN,
  _$eventPayloadRoleEnum_MEMBER,
]);

Serializer<EventPayloadPreviousRoleEnum>
    _$eventPayloadPreviousRoleEnumSerializer =
    _$EventPayloadPreviousRoleEnumSerializer();
Serializer<EventPayloadRoleEnum> _$eventPayloadRoleEnumSerializer =
    _$EventPayloadRoleEnumSerializer();

class _$EventPayloadPreviousRoleEnumSerializer
    implements PrimitiveSerializer<EventPayloadPreviousRoleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OWNER': 'OWNER',
    'ADMIN': 'ADMIN',
    'MEMBER': 'MEMBER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OWNER': 'OWNER',
    'ADMIN': 'ADMIN',
    'MEMBER': 'MEMBER',
  };

  @override
  final Iterable<Type> types = const <Type>[EventPayloadPreviousRoleEnum];
  @override
  final String wireName = 'EventPayloadPreviousRoleEnum';

  @override
  Object serialize(Serializers serializers, EventPayloadPreviousRoleEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EventPayloadPreviousRoleEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EventPayloadPreviousRoleEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$EventPayloadRoleEnumSerializer
    implements PrimitiveSerializer<EventPayloadRoleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OWNER': 'OWNER',
    'ADMIN': 'ADMIN',
    'MEMBER': 'MEMBER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OWNER': 'OWNER',
    'ADMIN': 'ADMIN',
    'MEMBER': 'MEMBER',
  };

  @override
  final Iterable<Type> types = const <Type>[EventPayloadRoleEnum];
  @override
  final String wireName = 'EventPayloadRoleEnum';

  @override
  Object serialize(Serializers serializers, EventPayloadRoleEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EventPayloadRoleEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EventPayloadRoleEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$EventPayload extends EventPayload {
  @override
  final int? amountMinor;
  @override
  final String? expenseId;
  @override
  final String? fromMemberId;
  @override
  final String? inviteId;
  @override
  final String? memberId;
  @override
  final EventPayloadPreviousRoleEnum? previousRole;
  @override
  final String? requestId;
  @override
  final EventPayloadRoleEnum? role;
  @override
  final String? settlementId;
  @override
  final String? toMemberId;
  @override
  final int? totalMinor;
  @override
  final int? version;

  factory _$EventPayload([void Function(EventPayloadBuilder)? updates]) =>
      (EventPayloadBuilder()..update(updates))._build();

  _$EventPayload._(
      {this.amountMinor,
      this.expenseId,
      this.fromMemberId,
      this.inviteId,
      this.memberId,
      this.previousRole,
      this.requestId,
      this.role,
      this.settlementId,
      this.toMemberId,
      this.totalMinor,
      this.version})
      : super._();
  @override
  EventPayload rebuild(void Function(EventPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EventPayloadBuilder toBuilder() => EventPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EventPayload &&
        amountMinor == other.amountMinor &&
        expenseId == other.expenseId &&
        fromMemberId == other.fromMemberId &&
        inviteId == other.inviteId &&
        memberId == other.memberId &&
        previousRole == other.previousRole &&
        requestId == other.requestId &&
        role == other.role &&
        settlementId == other.settlementId &&
        toMemberId == other.toMemberId &&
        totalMinor == other.totalMinor &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, expenseId.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, inviteId.hashCode);
    _$hash = $jc(_$hash, memberId.hashCode);
    _$hash = $jc(_$hash, previousRole.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, settlementId.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jc(_$hash, totalMinor.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EventPayload')
          ..add('amountMinor', amountMinor)
          ..add('expenseId', expenseId)
          ..add('fromMemberId', fromMemberId)
          ..add('inviteId', inviteId)
          ..add('memberId', memberId)
          ..add('previousRole', previousRole)
          ..add('requestId', requestId)
          ..add('role', role)
          ..add('settlementId', settlementId)
          ..add('toMemberId', toMemberId)
          ..add('totalMinor', totalMinor)
          ..add('version', version))
        .toString();
  }
}

class EventPayloadBuilder
    implements Builder<EventPayload, EventPayloadBuilder> {
  _$EventPayload? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  String? _expenseId;
  String? get expenseId => _$this._expenseId;
  set expenseId(String? expenseId) => _$this._expenseId = expenseId;

  String? _fromMemberId;
  String? get fromMemberId => _$this._fromMemberId;
  set fromMemberId(String? fromMemberId) => _$this._fromMemberId = fromMemberId;

  String? _inviteId;
  String? get inviteId => _$this._inviteId;
  set inviteId(String? inviteId) => _$this._inviteId = inviteId;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  EventPayloadPreviousRoleEnum? _previousRole;
  EventPayloadPreviousRoleEnum? get previousRole => _$this._previousRole;
  set previousRole(EventPayloadPreviousRoleEnum? previousRole) =>
      _$this._previousRole = previousRole;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  EventPayloadRoleEnum? _role;
  EventPayloadRoleEnum? get role => _$this._role;
  set role(EventPayloadRoleEnum? role) => _$this._role = role;

  String? _settlementId;
  String? get settlementId => _$this._settlementId;
  set settlementId(String? settlementId) => _$this._settlementId = settlementId;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  int? _totalMinor;
  int? get totalMinor => _$this._totalMinor;
  set totalMinor(int? totalMinor) => _$this._totalMinor = totalMinor;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  EventPayloadBuilder() {
    EventPayload._defaults(this);
  }

  EventPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _expenseId = $v.expenseId;
      _fromMemberId = $v.fromMemberId;
      _inviteId = $v.inviteId;
      _memberId = $v.memberId;
      _previousRole = $v.previousRole;
      _requestId = $v.requestId;
      _role = $v.role;
      _settlementId = $v.settlementId;
      _toMemberId = $v.toMemberId;
      _totalMinor = $v.totalMinor;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EventPayload other) {
    _$v = other as _$EventPayload;
  }

  @override
  void update(void Function(EventPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EventPayload build() => _build();

  _$EventPayload _build() {
    final _$result = _$v ??
        _$EventPayload._(
          amountMinor: amountMinor,
          expenseId: expenseId,
          fromMemberId: fromMemberId,
          inviteId: inviteId,
          memberId: memberId,
          previousRole: previousRole,
          requestId: requestId,
          role: role,
          settlementId: settlementId,
          toMemberId: toMemberId,
          totalMinor: totalMinor,
          version: version,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
