//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transfer_ownership_request.g.dart';

/// TransferOwnershipRequest
///
/// Properties:
/// * [toMemberId] 
@BuiltValue()
abstract class TransferOwnershipRequest implements Built<TransferOwnershipRequest, TransferOwnershipRequestBuilder> {
  @BuiltValueField(wireName: r'toMemberId')
  String? get toMemberId;

  TransferOwnershipRequest._();

  factory TransferOwnershipRequest([void updates(TransferOwnershipRequestBuilder b)]) = _$TransferOwnershipRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransferOwnershipRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransferOwnershipRequest> get serializer => _$TransferOwnershipRequestSerializer();
}

class _$TransferOwnershipRequestSerializer implements PrimitiveSerializer<TransferOwnershipRequest> {
  @override
  final Iterable<Type> types = const [TransferOwnershipRequest, _$TransferOwnershipRequest];

  @override
  final String wireName = r'TransferOwnershipRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransferOwnershipRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.toMemberId != null) {
      yield r'toMemberId';
      yield serializers.serialize(
        object.toMemberId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TransferOwnershipRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TransferOwnershipRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'toMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.toMemberId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TransferOwnershipRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransferOwnershipRequestBuilder();
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

