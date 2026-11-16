//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_payload.g.dart';

/// EventPayload
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [expenseId] 
/// * [fromMemberId] 
/// * [inviteId] 
/// * [memberId] 
/// * [previousRole] 
/// * [requestId] 
/// * [role] 
/// * [settlementId] 
/// * [toMemberId] 
/// * [totalMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [version] 
@BuiltValue()
abstract class EventPayload implements Built<EventPayload, EventPayloadBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int? get amountMinor;

  @BuiltValueField(wireName: r'expenseId')
  String? get expenseId;

  @BuiltValueField(wireName: r'fromMemberId')
  String? get fromMemberId;

  @BuiltValueField(wireName: r'inviteId')
  String? get inviteId;

  @BuiltValueField(wireName: r'memberId')
  String? get memberId;

  @BuiltValueField(wireName: r'previousRole')
  EventPayloadPreviousRoleEnum? get previousRole;
  // enum previousRoleEnum {  OWNER,  ADMIN,  MEMBER,  };

  @BuiltValueField(wireName: r'requestId')
  String? get requestId;

  @BuiltValueField(wireName: r'role')
  EventPayloadRoleEnum? get role;
  // enum roleEnum {  OWNER,  ADMIN,  MEMBER,  };

  @BuiltValueField(wireName: r'settlementId')
  String? get settlementId;

  @BuiltValueField(wireName: r'toMemberId')
  String? get toMemberId;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'totalMinor')
  int? get totalMinor;

  @BuiltValueField(wireName: r'version')
  int? get version;

  EventPayload._();

  factory EventPayload([void updates(EventPayloadBuilder b)]) = _$EventPayload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventPayloadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventPayload> get serializer => _$EventPayloadSerializer();
}

class _$EventPayloadSerializer implements PrimitiveSerializer<EventPayload> {
  @override
  final Iterable<Type> types = const [EventPayload, _$EventPayload];

  @override
  final String wireName = r'EventPayload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.amountMinor != null) {
      yield r'amountMinor';
      yield serializers.serialize(
        object.amountMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.expenseId != null) {
      yield r'expenseId';
      yield serializers.serialize(
        object.expenseId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.fromMemberId != null) {
      yield r'fromMemberId';
      yield serializers.serialize(
        object.fromMemberId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.inviteId != null) {
      yield r'inviteId';
      yield serializers.serialize(
        object.inviteId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.memberId != null) {
      yield r'memberId';
      yield serializers.serialize(
        object.memberId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.previousRole != null) {
      yield r'previousRole';
      yield serializers.serialize(
        object.previousRole,
        specifiedType: const FullType.nullable(EventPayloadPreviousRoleEnum),
      );
    }
    if (object.requestId != null) {
      yield r'requestId';
      yield serializers.serialize(
        object.requestId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.role != null) {
      yield r'role';
      yield serializers.serialize(
        object.role,
        specifiedType: const FullType.nullable(EventPayloadRoleEnum),
      );
    }
    if (object.settlementId != null) {
      yield r'settlementId';
      yield serializers.serialize(
        object.settlementId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.toMemberId != null) {
      yield r'toMemberId';
      yield serializers.serialize(
        object.toMemberId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.totalMinor != null) {
      yield r'totalMinor';
      yield serializers.serialize(
        object.totalMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.version != null) {
      yield r'version';
      yield serializers.serialize(
        object.version,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EventPayload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventPayloadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.amountMinor = valueDes;
          break;
        case r'expenseId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.expenseId = valueDes;
          break;
        case r'fromMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.fromMemberId = valueDes;
          break;
        case r'inviteId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.inviteId = valueDes;
          break;
        case r'memberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.memberId = valueDes;
          break;
        case r'previousRole':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(EventPayloadPreviousRoleEnum),
          ) as EventPayloadPreviousRoleEnum?;
          if (valueDes == null) continue;
          result.previousRole = valueDes;
          break;
        case r'requestId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.requestId = valueDes;
          break;
        case r'role':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(EventPayloadRoleEnum),
          ) as EventPayloadRoleEnum?;
          if (valueDes == null) continue;
          result.role = valueDes;
          break;
        case r'settlementId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.settlementId = valueDes;
          break;
        case r'toMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.toMemberId = valueDes;
          break;
        case r'totalMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.totalMinor = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventPayload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventPayloadBuilder();
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

class EventPayloadPreviousRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const EventPayloadPreviousRoleEnum OWNER = _$eventPayloadPreviousRoleEnum_OWNER;
  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const EventPayloadPreviousRoleEnum ADMIN = _$eventPayloadPreviousRoleEnum_ADMIN;
  @BuiltValueEnumConst(wireName: r'MEMBER')
  static const EventPayloadPreviousRoleEnum MEMBER = _$eventPayloadPreviousRoleEnum_MEMBER;

  static Serializer<EventPayloadPreviousRoleEnum> get serializer => _$eventPayloadPreviousRoleEnumSerializer;

  const EventPayloadPreviousRoleEnum._(String name): super(name);

  static BuiltSet<EventPayloadPreviousRoleEnum> get values => _$eventPayloadPreviousRoleEnumValues;
  static EventPayloadPreviousRoleEnum valueOf(String name) => _$eventPayloadPreviousRoleEnumValueOf(name);
}

class EventPayloadRoleEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OWNER')
  static const EventPayloadRoleEnum OWNER = _$eventPayloadRoleEnum_OWNER;
  @BuiltValueEnumConst(wireName: r'ADMIN')
  static const EventPayloadRoleEnum ADMIN = _$eventPayloadRoleEnum_ADMIN;
  @BuiltValueEnumConst(wireName: r'MEMBER')
  static const EventPayloadRoleEnum MEMBER = _$eventPayloadRoleEnum_MEMBER;

  static Serializer<EventPayloadRoleEnum> get serializer => _$eventPayloadRoleEnumSerializer;

  const EventPayloadRoleEnum._(String name): super(name);

  static BuiltSet<EventPayloadRoleEnum> get values => _$eventPayloadRoleEnumValues;
  static EventPayloadRoleEnum valueOf(String name) => _$eventPayloadRoleEnumValueOf(name);
}

