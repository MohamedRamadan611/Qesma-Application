//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/event_payload.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'activity_item.g.dart';

/// ActivityItem
///
/// Properties:
/// * [actorMemberId] 
/// * [createdAt] 
/// * [id] 
/// * [payload] 
/// * [subject] 
/// * [type] 
@BuiltValue()
abstract class ActivityItem implements Built<ActivityItem, ActivityItemBuilder> {
  @BuiltValueField(wireName: r'actorMemberId')
  String? get actorMemberId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'payload')
  EventPayload get payload;

  @BuiltValueField(wireName: r'subject')
  String? get subject;

  @BuiltValueField(wireName: r'type')
  ActivityItemTypeEnum get type;
  // enum typeEnum {  EXPENSE_ADDED,  EXPENSE_EDITED,  EXPENSE_DELETED,  SETTLEMENT_PENDING,  SETTLEMENT_CONFIRMED,  SETTLEMENT_DISPUTED,  SETTLEMENT_CANCELLED,  INVITE_ACCEPTED,  JOIN_REQUESTED,  MEMBER_JOINED,  MEMBER_LEFT,  MEMBER_REACTIVATED,  MEMBER_UNLINKED,  ROLE_CHANGED,  OWNERSHIP_TRANSFERRED,  REMINDER,  };

  ActivityItem._();

  factory ActivityItem([void updates(ActivityItemBuilder b)]) = _$ActivityItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ActivityItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ActivityItem> get serializer => _$ActivityItemSerializer();
}

class _$ActivityItemSerializer implements PrimitiveSerializer<ActivityItem> {
  @override
  final Iterable<Type> types = const [ActivityItem, _$ActivityItem];

  @override
  final String wireName = r'ActivityItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ActivityItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.actorMemberId != null) {
      yield r'actorMemberId';
      yield serializers.serialize(
        object.actorMemberId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'payload';
    yield serializers.serialize(
      object.payload,
      specifiedType: const FullType(EventPayload),
    );
    if (object.subject != null) {
      yield r'subject';
      yield serializers.serialize(
        object.subject,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(ActivityItemTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ActivityItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ActivityItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'actorMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.actorMemberId = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EventPayload),
          ) as EventPayload;
          result.payload.replace(valueDes);
          break;
        case r'subject':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.subject = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ActivityItemTypeEnum),
          ) as ActivityItemTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ActivityItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ActivityItemBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class ActivityItemTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'EXPENSE_ADDED')
  static const ActivityItemTypeEnum EXPENSE_ADDED = _$activityItemTypeEnum_EXPENSE_ADDED;
  @BuiltValueEnumConst(wireName: r'EXPENSE_EDITED')
  static const ActivityItemTypeEnum EXPENSE_EDITED = _$activityItemTypeEnum_EXPENSE_EDITED;
  @BuiltValueEnumConst(wireName: r'EXPENSE_DELETED')
  static const ActivityItemTypeEnum EXPENSE_DELETED = _$activityItemTypeEnum_EXPENSE_DELETED;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_PENDING')
  static const ActivityItemTypeEnum SETTLEMENT_PENDING = _$activityItemTypeEnum_SETTLEMENT_PENDING;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_CONFIRMED')
  static const ActivityItemTypeEnum SETTLEMENT_CONFIRMED = _$activityItemTypeEnum_SETTLEMENT_CONFIRMED;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_DISPUTED')
  static const ActivityItemTypeEnum SETTLEMENT_DISPUTED = _$activityItemTypeEnum_SETTLEMENT_DISPUTED;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_CANCELLED')
  static const ActivityItemTypeEnum SETTLEMENT_CANCELLED = _$activityItemTypeEnum_SETTLEMENT_CANCELLED;
  @BuiltValueEnumConst(wireName: r'INVITE_ACCEPTED')
  static const ActivityItemTypeEnum INVITE_ACCEPTED = _$activityItemTypeEnum_INVITE_ACCEPTED;
  @BuiltValueEnumConst(wireName: r'JOIN_REQUESTED')
  static const ActivityItemTypeEnum JOIN_REQUESTED = _$activityItemTypeEnum_JOIN_REQUESTED;
  @BuiltValueEnumConst(wireName: r'MEMBER_JOINED')
  static const ActivityItemTypeEnum MEMBER_JOINED = _$activityItemTypeEnum_MEMBER_JOINED;
  @BuiltValueEnumConst(wireName: r'MEMBER_LEFT')
  static const ActivityItemTypeEnum MEMBER_LEFT = _$activityItemTypeEnum_MEMBER_LEFT;
  @BuiltValueEnumConst(wireName: r'MEMBER_REACTIVATED')
  static const ActivityItemTypeEnum MEMBER_REACTIVATED = _$activityItemTypeEnum_MEMBER_REACTIVATED;
  @BuiltValueEnumConst(wireName: r'MEMBER_UNLINKED')
  static const ActivityItemTypeEnum MEMBER_UNLINKED = _$activityItemTypeEnum_MEMBER_UNLINKED;
  @BuiltValueEnumConst(wireName: r'ROLE_CHANGED')
  static const ActivityItemTypeEnum ROLE_CHANGED = _$activityItemTypeEnum_ROLE_CHANGED;
  @BuiltValueEnumConst(wireName: r'OWNERSHIP_TRANSFERRED')
  static const ActivityItemTypeEnum OWNERSHIP_TRANSFERRED = _$activityItemTypeEnum_OWNERSHIP_TRANSFERRED;
  @BuiltValueEnumConst(wireName: r'REMINDER')
  static const ActivityItemTypeEnum REMINDER = _$activityItemTypeEnum_REMINDER;

  static Serializer<ActivityItemTypeEnum> get serializer => _$activityItemTypeEnumSerializer;

  const ActivityItemTypeEnum._(String name): super(name);

  static BuiltSet<ActivityItemTypeEnum> get values => _$activityItemTypeEnumValues;
  static ActivityItemTypeEnum valueOf(String name) => _$activityItemTypeEnumValueOf(name);
}

