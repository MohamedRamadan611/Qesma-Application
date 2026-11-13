//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'payment_handles_view.g.dart';

/// PaymentHandlesView
///
/// Properties:
/// * [instapay] 
/// * [wallet] 
@BuiltValue()
abstract class PaymentHandlesView implements Built<PaymentHandlesView, PaymentHandlesViewBuilder> {
  @BuiltValueField(wireName: r'instapay')
  String? get instapay;

  @BuiltValueField(wireName: r'wallet')
  String? get wallet;

  PaymentHandlesView._();

  factory PaymentHandlesView([void updates(PaymentHandlesViewBuilder b)]) = _$PaymentHandlesView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PaymentHandlesViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PaymentHandlesView> get serializer => _$PaymentHandlesViewSerializer();
}

class _$PaymentHandlesViewSerializer implements PrimitiveSerializer<PaymentHandlesView> {
  @override
  final Iterable<Type> types = const [PaymentHandlesView, _$PaymentHandlesView];

  @override
  final String wireName = r'PaymentHandlesView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PaymentHandlesView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.instapay != null) {
      yield r'instapay';
      yield serializers.serialize(
        object.instapay,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.wallet != null) {
      yield r'wallet';
      yield serializers.serialize(
        object.wallet,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PaymentHandlesView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PaymentHandlesViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'instapay':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.instapay = valueDes;
          break;
        case r'wallet':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  PaymentHandlesView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PaymentHandlesViewBuilder();
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

