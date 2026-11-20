//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'discount_charge.g.dart';

/// DiscountCharge
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [bps] - Integer basis points: 1200 = 12.00%.
@BuiltValue()
abstract class DiscountCharge implements Built<DiscountCharge, DiscountChargeBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  /// Integer basis points: 1200 = 12.00%.
  @BuiltValueField(wireName: r'bps')
  int? get bps;

  DiscountCharge._();

  factory DiscountCharge([void updates(DiscountChargeBuilder b)]) = _$DiscountCharge;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DiscountChargeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DiscountCharge> get serializer => _$DiscountChargeSerializer();
}

class _$DiscountChargeSerializer implements PrimitiveSerializer<DiscountCharge> {
  @override
  final Iterable<Type> types = const [DiscountCharge, _$DiscountCharge];

  @override
  final String wireName = r'DiscountCharge';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DiscountCharge object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    if (object.bps != null) {
      yield r'bps';
      yield serializers.serialize(
        object.bps,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DiscountCharge object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DiscountChargeBuilder result,
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
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
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
  DiscountCharge deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DiscountChargeBuilder();
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

