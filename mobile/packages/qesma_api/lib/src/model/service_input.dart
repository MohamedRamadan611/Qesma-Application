//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'service_input.g.dart';

/// ServiceInput
///
/// Properties:
/// * [bps] - Integer basis points: 1200 = 12.00%.
@BuiltValue()
abstract class ServiceInput implements Built<ServiceInput, ServiceInputBuilder> {
  /// Integer basis points: 1200 = 12.00%.
  @BuiltValueField(wireName: r'bps')
  int get bps;

  ServiceInput._();

  factory ServiceInput([void updates(ServiceInputBuilder b)]) = _$ServiceInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ServiceInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ServiceInput> get serializer => _$ServiceInputSerializer();
}

class _$ServiceInputSerializer implements PrimitiveSerializer<ServiceInput> {
  @override
  final Iterable<Type> types = const [ServiceInput, _$ServiceInput];

  @override
  final String wireName = r'ServiceInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ServiceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'bps';
    yield serializers.serialize(
      object.bps,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ServiceInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ServiceInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'bps':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.bps = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ServiceInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ServiceInputBuilder();
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

