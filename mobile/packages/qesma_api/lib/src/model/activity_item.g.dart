// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ActivityItemTypeEnum _$activityItemTypeEnum_EXPENSE_ADDED =
    const ActivityItemTypeEnum._('EXPENSE_ADDED');
const ActivityItemTypeEnum _$activityItemTypeEnum_EXPENSE_EDITED =
    const ActivityItemTypeEnum._('EXPENSE_EDITED');
const ActivityItemTypeEnum _$activityItemTypeEnum_EXPENSE_DELETED =
    const ActivityItemTypeEnum._('EXPENSE_DELETED');
const ActivityItemTypeEnum _$activityItemTypeEnum_SETTLEMENT_PENDING =
    const ActivityItemTypeEnum._('SETTLEMENT_PENDING');
const ActivityItemTypeEnum _$activityItemTypeEnum_SETTLEMENT_CONFIRMED =
    const ActivityItemTypeEnum._('SETTLEMENT_CONFIRMED');
const ActivityItemTypeEnum _$activityItemTypeEnum_SETTLEMENT_DISPUTED =
    const ActivityItemTypeEnum._('SETTLEMENT_DISPUTED');
const ActivityItemTypeEnum _$activityItemTypeEnum_SETTLEMENT_CANCELLED =
    const ActivityItemTypeEnum._('SETTLEMENT_CANCELLED');
const ActivityItemTypeEnum _$activityItemTypeEnum_INVITE_ACCEPTED =
    const ActivityItemTypeEnum._('INVITE_ACCEPTED');
const ActivityItemTypeEnum _$activityItemTypeEnum_JOIN_REQUESTED =
    const ActivityItemTypeEnum._('JOIN_REQUESTED');
const ActivityItemTypeEnum _$activityItemTypeEnum_MEMBER_JOINED =
    const ActivityItemTypeEnum._('MEMBER_JOINED');
const ActivityItemTypeEnum _$activityItemTypeEnum_MEMBER_LEFT =
    const ActivityItemTypeEnum._('MEMBER_LEFT');
const ActivityItemTypeEnum _$activityItemTypeEnum_MEMBER_REACTIVATED =
    const ActivityItemTypeEnum._('MEMBER_REACTIVATED');
const ActivityItemTypeEnum _$activityItemTypeEnum_MEMBER_UNLINKED =
    const ActivityItemTypeEnum._('MEMBER_UNLINKED');
const ActivityItemTypeEnum _$activityItemTypeEnum_ROLE_CHANGED =
    const ActivityItemTypeEnum._('ROLE_CHANGED');
const ActivityItemTypeEnum _$activityItemTypeEnum_OWNERSHIP_TRANSFERRED =
    const ActivityItemTypeEnum._('OWNERSHIP_TRANSFERRED');
const ActivityItemTypeEnum _$activityItemTypeEnum_REMINDER =
    const ActivityItemTypeEnum._('REMINDER');

ActivityItemTypeEnum _$activityItemTypeEnumValueOf(String name) {
  switch (name) {
    case 'EXPENSE_ADDED':
      return _$activityItemTypeEnum_EXPENSE_ADDED;
    case 'EXPENSE_EDITED':
      return _$activityItemTypeEnum_EXPENSE_EDITED;
    case 'EXPENSE_DELETED':
      return _$activityItemTypeEnum_EXPENSE_DELETED;
    case 'SETTLEMENT_PENDING':
      return _$activityItemTypeEnum_SETTLEMENT_PENDING;
    case 'SETTLEMENT_CONFIRMED':
      return _$activityItemTypeEnum_SETTLEMENT_CONFIRMED;
    case 'SETTLEMENT_DISPUTED':
      return _$activityItemTypeEnum_SETTLEMENT_DISPUTED;
    case 'SETTLEMENT_CANCELLED':
      return _$activityItemTypeEnum_SETTLEMENT_CANCELLED;
    case 'INVITE_ACCEPTED':
      return _$activityItemTypeEnum_INVITE_ACCEPTED;
    case 'JOIN_REQUESTED':
      return _$activityItemTypeEnum_JOIN_REQUESTED;
    case 'MEMBER_JOINED':
      return _$activityItemTypeEnum_MEMBER_JOINED;
    case 'MEMBER_LEFT':
      return _$activityItemTypeEnum_MEMBER_LEFT;
    case 'MEMBER_REACTIVATED':
      return _$activityItemTypeEnum_MEMBER_REACTIVATED;
    case 'MEMBER_UNLINKED':
      return _$activityItemTypeEnum_MEMBER_UNLINKED;
    case 'ROLE_CHANGED':
      return _$activityItemTypeEnum_ROLE_CHANGED;
    case 'OWNERSHIP_TRANSFERRED':
      return _$activityItemTypeEnum_OWNERSHIP_TRANSFERRED;
    case 'REMINDER':
      return _$activityItemTypeEnum_REMINDER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ActivityItemTypeEnum> _$activityItemTypeEnumValues =
    BuiltSet<ActivityItemTypeEnum>(const <ActivityItemTypeEnum>[
  _$activityItemTypeEnum_EXPENSE_ADDED,
  _$activityItemTypeEnum_EXPENSE_EDITED,
  _$activityItemTypeEnum_EXPENSE_DELETED,
  _$activityItemTypeEnum_SETTLEMENT_PENDING,
  _$activityItemTypeEnum_SETTLEMENT_CONFIRMED,
  _$activityItemTypeEnum_SETTLEMENT_DISPUTED,
  _$activityItemTypeEnum_SETTLEMENT_CANCELLED,
  _$activityItemTypeEnum_INVITE_ACCEPTED,
  _$activityItemTypeEnum_JOIN_REQUESTED,
  _$activityItemTypeEnum_MEMBER_JOINED,
  _$activityItemTypeEnum_MEMBER_LEFT,
  _$activityItemTypeEnum_MEMBER_REACTIVATED,
  _$activityItemTypeEnum_MEMBER_UNLINKED,
  _$activityItemTypeEnum_ROLE_CHANGED,
  _$activityItemTypeEnum_OWNERSHIP_TRANSFERRED,
  _$activityItemTypeEnum_REMINDER,
]);

Serializer<ActivityItemTypeEnum> _$activityItemTypeEnumSerializer =
    _$ActivityItemTypeEnumSerializer();

class _$ActivityItemTypeEnumSerializer
    implements PrimitiveSerializer<ActivityItemTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'EXPENSE_ADDED': 'EXPENSE_ADDED',
    'EXPENSE_EDITED': 'EXPENSE_EDITED',
    'EXPENSE_DELETED': 'EXPENSE_DELETED',
    'SETTLEMENT_PENDING': 'SETTLEMENT_PENDING',
    'SETTLEMENT_CONFIRMED': 'SETTLEMENT_CONFIRMED',
    'SETTLEMENT_DISPUTED': 'SETTLEMENT_DISPUTED',
    'SETTLEMENT_CANCELLED': 'SETTLEMENT_CANCELLED',
    'INVITE_ACCEPTED': 'INVITE_ACCEPTED',
    'JOIN_REQUESTED': 'JOIN_REQUESTED',
    'MEMBER_JOINED': 'MEMBER_JOINED',
    'MEMBER_LEFT': 'MEMBER_LEFT',
    'MEMBER_REACTIVATED': 'MEMBER_REACTIVATED',
    'MEMBER_UNLINKED': 'MEMBER_UNLINKED',
    'ROLE_CHANGED': 'ROLE_CHANGED',
    'OWNERSHIP_TRANSFERRED': 'OWNERSHIP_TRANSFERRED',
    'REMINDER': 'REMINDER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'EXPENSE_ADDED': 'EXPENSE_ADDED',
    'EXPENSE_EDITED': 'EXPENSE_EDITED',
    'EXPENSE_DELETED': 'EXPENSE_DELETED',
    'SETTLEMENT_PENDING': 'SETTLEMENT_PENDING',
    'SETTLEMENT_CONFIRMED': 'SETTLEMENT_CONFIRMED',
    'SETTLEMENT_DISPUTED': 'SETTLEMENT_DISPUTED',
    'SETTLEMENT_CANCELLED': 'SETTLEMENT_CANCELLED',
    'INVITE_ACCEPTED': 'INVITE_ACCEPTED',
    'JOIN_REQUESTED': 'JOIN_REQUESTED',
    'MEMBER_JOINED': 'MEMBER_JOINED',
    'MEMBER_LEFT': 'MEMBER_LEFT',
    'MEMBER_REACTIVATED': 'MEMBER_REACTIVATED',
    'MEMBER_UNLINKED': 'MEMBER_UNLINKED',
    'ROLE_CHANGED': 'ROLE_CHANGED',
    'OWNERSHIP_TRANSFERRED': 'OWNERSHIP_TRANSFERRED',
    'REMINDER': 'REMINDER',
  };

  @override
  final Iterable<Type> types = const <Type>[ActivityItemTypeEnum];
  @override
  final String wireName = 'ActivityItemTypeEnum';

  @override
  Object serialize(Serializers serializers, ActivityItemTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ActivityItemTypeEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ActivityItemTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ActivityItem extends ActivityItem {
  @override
  final String? actorMemberId;
  @override
  final DateTime createdAt;
  @override
  final String id;
  @override
  final EventPayload payload;
  @override
  final String? subject;
  @override
  final ActivityItemTypeEnum type;

  factory _$ActivityItem([void Function(ActivityItemBuilder)? updates]) =>
      (ActivityItemBuilder()..update(updates))._build();

  _$ActivityItem._(
      {this.actorMemberId,
      required this.createdAt,
      required this.id,
      required this.payload,
      this.subject,
      required this.type})
      : super._();
  @override
  ActivityItem rebuild(void Function(ActivityItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ActivityItemBuilder toBuilder() => ActivityItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ActivityItem &&
        actorMemberId == other.actorMemberId &&
        createdAt == other.createdAt &&
        id == other.id &&
        payload == other.payload &&
        subject == other.subject &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, actorMemberId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, subject.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ActivityItem')
          ..add('actorMemberId', actorMemberId)
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('payload', payload)
          ..add('subject', subject)
          ..add('type', type))
        .toString();
  }
}

class ActivityItemBuilder
    implements Builder<ActivityItem, ActivityItemBuilder> {
  _$ActivityItem? _$v;

  String? _actorMemberId;
  String? get actorMemberId => _$this._actorMemberId;
  set actorMemberId(String? actorMemberId) =>
      _$this._actorMemberId = actorMemberId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  EventPayloadBuilder? _payload;
  EventPayloadBuilder get payload => _$this._payload ??= EventPayloadBuilder();
  set payload(EventPayloadBuilder? payload) => _$this._payload = payload;

  String? _subject;
  String? get subject => _$this._subject;
  set subject(String? subject) => _$this._subject = subject;

  ActivityItemTypeEnum? _type;
  ActivityItemTypeEnum? get type => _$this._type;
  set type(ActivityItemTypeEnum? type) => _$this._type = type;

  ActivityItemBuilder() {
    ActivityItem._defaults(this);
  }

  ActivityItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actorMemberId = $v.actorMemberId;
      _createdAt = $v.createdAt;
      _id = $v.id;
      _payload = $v.payload.toBuilder();
      _subject = $v.subject;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ActivityItem other) {
    _$v = other as _$ActivityItem;
  }

  @override
  void update(void Function(ActivityItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ActivityItem build() => _build();

  _$ActivityItem _build() {
    _$ActivityItem _$result;
    try {
      _$result = _$v ??
          _$ActivityItem._(
            actorMemberId: actorMemberId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'ActivityItem', 'createdAt'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'ActivityItem', 'id'),
            payload: payload.build(),
            subject: subject,
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'ActivityItem', 'type'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ActivityItem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
