//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/event_payload.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notification_item.g.dart';

/// NotificationItem
///
/// Properties:
/// * [actorMemberId] 
/// * [actorName] 
/// * [createdAt] 
/// * [groupId] 
/// * [groupName] 
/// * [id] 
/// * [payload] 
/// * [readAt] 
/// * [subject] 
/// * [type] 
@BuiltValue()
abstract class NotificationItem implements Built<NotificationItem, NotificationItemBuilder> {
  @BuiltValueField(wireName: r'actorMemberId')
  String? get actorMemberId;

  @BuiltValueField(wireName: r'actorName')
  String? get actorName;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  @BuiltValueField(wireName: r'groupName')
  String get groupName;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'payload')
  EventPayload get payload;

  @BuiltValueField(wireName: r'readAt')
  DateTime? get readAt;

  @BuiltValueField(wireName: r'subject')
  String? get subject;

  @BuiltValueField(wireName: r'type')
  NotificationItemTypeEnum get type;
  // enum typeEnum {  EXPENSE_ADDED,  EXPENSE_EDITED,  EXPENSE_DELETED,  SETTLEMENT_PENDING,  SETTLEMENT_CONFIRMED,  SETTLEMENT_DISPUTED,  SETTLEMENT_CANCELLED,  INVITE_ACCEPTED,  JOIN_REQUESTED,  MEMBER_JOINED,  MEMBER_LEFT,  MEMBER_REACTIVATED,  MEMBER_UNLINKED,  ROLE_CHANGED,  OWNERSHIP_TRANSFERRED,  REMINDER,  };

  NotificationItem._();

  factory NotificationItem([void updates(NotificationItemBuilder b)]) = _$NotificationItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationItem> get serializer => _$NotificationItemSerializer();
}

class _$NotificationItemSerializer implements PrimitiveSerializer<NotificationItem> {
  @override
  final Iterable<Type> types = const [NotificationItem, _$NotificationItem];

  @override
  final String wireName = r'NotificationItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.actorMemberId != null) {
      yield r'actorMemberId';
      yield serializers.serialize(
        object.actorMemberId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.actorName != null) {
      yield r'actorName';
      yield serializers.serialize(
        object.actorName,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'groupName';
    yield serializers.serialize(
      object.groupName,
      specifiedType: const FullType(String),
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
    if (object.readAt != null) {
      yield r'readAt';
      yield serializers.serialize(
        object.readAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
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
      specifiedType: const FullType(NotificationItemTypeEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotificationItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationItemBuilder result,
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
        case r'actorName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.actorName = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'groupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupId = valueDes;
          break;
        case r'groupName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupName = valueDes;
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
        case r'readAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.readAt = valueDes;
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
            specifiedType: const FullType(NotificationItemTypeEnum),
          ) as NotificationItemTypeEnum;
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
  NotificationItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationItemBuilder();
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

class NotificationItemTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'EXPENSE_ADDED')
  static const NotificationItemTypeEnum EXPENSE_ADDED = _$notificationItemTypeEnum_EXPENSE_ADDED;
  @BuiltValueEnumConst(wireName: r'EXPENSE_EDITED')
  static const NotificationItemTypeEnum EXPENSE_EDITED = _$notificationItemTypeEnum_EXPENSE_EDITED;
  @BuiltValueEnumConst(wireName: r'EXPENSE_DELETED')
  static const NotificationItemTypeEnum EXPENSE_DELETED = _$notificationItemTypeEnum_EXPENSE_DELETED;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_PENDING')
  static const NotificationItemTypeEnum SETTLEMENT_PENDING = _$notificationItemTypeEnum_SETTLEMENT_PENDING;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_CONFIRMED')
  static const NotificationItemTypeEnum SETTLEMENT_CONFIRMED = _$notificationItemTypeEnum_SETTLEMENT_CONFIRMED;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_DISPUTED')
  static const NotificationItemTypeEnum SETTLEMENT_DISPUTED = _$notificationItemTypeEnum_SETTLEMENT_DISPUTED;
  @BuiltValueEnumConst(wireName: r'SETTLEMENT_CANCELLED')
  static const NotificationItemTypeEnum SETTLEMENT_CANCELLED = _$notificationItemTypeEnum_SETTLEMENT_CANCELLED;
  @BuiltValueEnumConst(wireName: r'INVITE_ACCEPTED')
  static const NotificationItemTypeEnum INVITE_ACCEPTED = _$notificationItemTypeEnum_INVITE_ACCEPTED;
  @BuiltValueEnumConst(wireName: r'JOIN_REQUESTED')
  static const NotificationItemTypeEnum JOIN_REQUESTED = _$notificationItemTypeEnum_JOIN_REQUESTED;
  @BuiltValueEnumConst(wireName: r'MEMBER_JOINED')
  static const NotificationItemTypeEnum MEMBER_JOINED = _$notificationItemTypeEnum_MEMBER_JOINED;
  @BuiltValueEnumConst(wireName: r'MEMBER_LEFT')
  static const NotificationItemTypeEnum MEMBER_LEFT = _$notificationItemTypeEnum_MEMBER_LEFT;
  @BuiltValueEnumConst(wireName: r'MEMBER_REACTIVATED')
  static const NotificationItemTypeEnum MEMBER_REACTIVATED = _$notificationItemTypeEnum_MEMBER_REACTIVATED;
  @BuiltValueEnumConst(wireName: r'MEMBER_UNLINKED')
  static const NotificationItemTypeEnum MEMBER_UNLINKED = _$notificationItemTypeEnum_MEMBER_UNLINKED;
  @BuiltValueEnumConst(wireName: r'ROLE_CHANGED')
  static const NotificationItemTypeEnum ROLE_CHANGED = _$notificationItemTypeEnum_ROLE_CHANGED;
  @BuiltValueEnumConst(wireName: r'OWNERSHIP_TRANSFERRED')
  static const NotificationItemTypeEnum OWNERSHIP_TRANSFERRED = _$notificationItemTypeEnum_OWNERSHIP_TRANSFERRED;
  @BuiltValueEnumConst(wireName: r'REMINDER')
  static const NotificationItemTypeEnum REMINDER = _$notificationItemTypeEnum_REMINDER;

  static Serializer<NotificationItemTypeEnum> get serializer => _$notificationItemTypeEnumSerializer;

  const NotificationItemTypeEnum._(String name): super(name);

  static BuiltSet<NotificationItemTypeEnum> get values => _$notificationItemTypeEnumValues;
  static NotificationItemTypeEnum valueOf(String name) => _$notificationItemTypeEnumValueOf(name);
}

