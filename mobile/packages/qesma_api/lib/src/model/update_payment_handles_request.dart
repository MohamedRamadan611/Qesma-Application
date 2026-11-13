//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_payment_handles_request.g.dart';

/// UpdatePaymentHandlesRequest
///
/// Properties:
/// * [instapay] 
/// * [wallet] 
@BuiltValue()
abstract class UpdatePaymentHandlesRequest implements Built<UpdatePaymentHandlesRequest, UpdatePaymentHandlesRequestBuilder> {
  @BuiltValueField(wireName: r'instapay')
  String? get instapay;

  @BuiltValueField(wireName: r'wallet')
  String? get wallet;

  UpdatePaymentHandlesRequest._();

  factory UpdatePaymentHandlesRequest([void updates(UpdatePaymentHandlesRequestBuilder b)]) = _$UpdatePaymentHandlesRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdatePaymentHandlesRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdatePaymentHandlesRequest> get serializer => _$UpdatePaymentHandlesRequestSerializer();
}

class _$UpdatePaymentHandlesRequestSerializer implements PrimitiveSerializer<UpdatePaymentHandlesRequest> {
  @override
  final Iterable<Type> types = const [UpdatePaymentHandlesRequest, _$UpdatePaymentHandlesRequest];

  @override
  final String wireName = r'UpdatePaymentHandlesRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdatePaymentHandlesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.instapay != null) {
      yield r'instapay';
      yield serializers.serialize(
        object.instapay,
        specifiedType: const FullType(String),
      );
    }
    if (object.wallet != null) {
      yield r'wallet';
      yield serializers.serialize(
        object.wallet,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdatePaymentHandlesRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdatePaymentHandlesRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'instapay':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.instapay = valueDes;
          break;
        case r'wallet':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.wallet = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdatePaymentHandlesRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdatePaymentHandlesRequestBuilder();
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

