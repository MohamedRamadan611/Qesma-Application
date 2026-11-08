//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'service_charge.g.dart';

/// ServiceCharge
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [bps] - Integer basis points: 1200 = 12.00%.
@BuiltValue()
abstract class ServiceCharge implements Built<ServiceCharge, ServiceChargeBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// Integer basis points: 1200 = 12.00%.
  @BuiltValueField(wireName: r'bps')
  int get bps;

  ServiceCharge._();

  factory ServiceCharge([void updates(ServiceChargeBuilder b)]) = _$ServiceCharge;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ServiceChargeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ServiceCharge> get serializer => _$ServiceChargeSerializer();
}

class _$ServiceChargeSerializer implements PrimitiveSerializer<ServiceCharge> {
  @override
  final Iterable<Type> types = const [ServiceCharge, _$ServiceCharge];

  @override
  final String wireName = r'ServiceCharge';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ServiceCharge object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'bps';
    yield serializers.serialize(
      object.bps,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ServiceCharge object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ServiceChargeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
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
  ServiceCharge deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ServiceChargeBuilder();
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

