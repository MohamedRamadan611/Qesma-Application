//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_group_request.g.dart';

/// UpdateGroupRequest
///
/// Properties:
/// * [budgetMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [clearBudget] 
/// * [clearTripEndDate] 
/// * [clearTripStartDate] 
/// * [name] 
/// * [treasurerMemberId] 
/// * [tripEndDate] 
/// * [tripStartDate] 
/// * [type] 
@BuiltValue()
abstract class UpdateGroupRequest implements Built<UpdateGroupRequest, UpdateGroupRequestBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'budgetMinor')
  int? get budgetMinor;

  @BuiltValueField(wireName: r'clearBudget')
  bool? get clearBudget;

  @BuiltValueField(wireName: r'clearTripEndDate')
  bool? get clearTripEndDate;

  @BuiltValueField(wireName: r'clearTripStartDate')
  bool? get clearTripStartDate;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'treasurerMemberId')
  String? get treasurerMemberId;

  @BuiltValueField(wireName: r'tripEndDate')
  Date? get tripEndDate;

  @BuiltValueField(wireName: r'tripStartDate')
  Date? get tripStartDate;

  @BuiltValueField(wireName: r'type')
  String? get type;

  UpdateGroupRequest._();

  factory UpdateGroupRequest([void updates(UpdateGroupRequestBuilder b)]) = _$UpdateGroupRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateGroupRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateGroupRequest> get serializer => _$UpdateGroupRequestSerializer();
}

class _$UpdateGroupRequestSerializer implements PrimitiveSerializer<UpdateGroupRequest> {
  @override
  final Iterable<Type> types = const [UpdateGroupRequest, _$UpdateGroupRequest];

  @override
  final String wireName = r'UpdateGroupRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateGroupRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.budgetMinor != null) {
      yield r'budgetMinor';
      yield serializers.serialize(
        object.budgetMinor,
        specifiedType: const FullType(int),
      );
    }
    if (object.clearBudget != null) {
      yield r'clearBudget';
      yield serializers.serialize(
        object.clearBudget,
        specifiedType: const FullType(bool),
      );
    }
    if (object.clearTripEndDate != null) {
      yield r'clearTripEndDate';
      yield serializers.serialize(
        object.clearTripEndDate,
        specifiedType: const FullType(bool),
      );
    }
    if (object.clearTripStartDate != null) {
      yield r'clearTripStartDate';
      yield serializers.serialize(
        object.clearTripStartDate,
        specifiedType: const FullType(bool),
      );
    }
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.treasurerMemberId != null) {
      yield r'treasurerMemberId';
      yield serializers.serialize(
        object.treasurerMemberId,
        specifiedType: const FullType(String),
      );
    }
    if (object.tripEndDate != null) {
      yield r'tripEndDate';
      yield serializers.serialize(
        object.tripEndDate,
        specifiedType: const FullType(Date),
      );
    }
    if (object.tripStartDate != null) {
      yield r'tripStartDate';
      yield serializers.serialize(
        object.tripStartDate,
        specifiedType: const FullType(Date),
      );
    }
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateGroupRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateGroupRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'budgetMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.budgetMinor = valueDes;
          break;
        case r'clearBudget':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.clearBudget = valueDes;
          break;
        case r'clearTripEndDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.clearTripEndDate = valueDes;
          break;
        case r'clearTripStartDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.clearTripStartDate = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'treasurerMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.treasurerMemberId = valueDes;
          break;
        case r'tripEndDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.tripEndDate = valueDes;
          break;
        case r'tripStartDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.tripStartDate = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  UpdateGroupRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateGroupRequestBuilder();
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

