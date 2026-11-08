//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_member_request.g.dart';

/// CreateMemberRequest
///
/// Properties:
/// * [displayName] 
@BuiltValue()
abstract class CreateMemberRequest implements Built<CreateMemberRequest, CreateMemberRequestBuilder> {
  @BuiltValueField(wireName: r'displayName')
  String get displayName;

  CreateMemberRequest._();

  factory CreateMemberRequest([void updates(CreateMemberRequestBuilder b)]) = _$CreateMemberRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateMemberRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateMemberRequest> get serializer => _$CreateMemberRequestSerializer();
}

class _$CreateMemberRequestSerializer implements PrimitiveSerializer<CreateMemberRequest> {
  @override
  final Iterable<Type> types = const [CreateMemberRequest, _$CreateMemberRequest];

  @override
  final String wireName = r'CreateMemberRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateMemberRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'displayName';
    yield serializers.serialize(
      object.displayName,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateMemberRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateMemberRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'displayName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateMemberRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateMemberRequestBuilder();
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

