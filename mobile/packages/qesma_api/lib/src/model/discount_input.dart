//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'discount_input.g.dart';

/// DiscountInput
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [bps] - Integer basis points: 1200 = 12.00%.
@BuiltValue()
abstract class DiscountInput implements Built<DiscountInput, DiscountInputBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int? get amountMinor;

  /// Integer basis points: 1200 = 12.00%.
  @BuiltValueField(wireName: r'bps')
  int? get bps;

  DiscountInput._();

  factory DiscountInput([void updates(DiscountInputBuilder b)]) = _$DiscountInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DiscountInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DiscountInput> get serializer => _$DiscountInputSerializer();
}

class _$DiscountInputSerializer implements PrimitiveSerializer<DiscountInput> {
  @override
  final Iterable<Type> types = const [DiscountInput, _$DiscountInput];

  @override
  final String wireName = r'DiscountInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DiscountInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.amountMinor != null) {
      yield r'amountMinor';
      yield serializers.serialize(
        object.amountMinor,
        specifiedType: const FullType(int),
      );
    }
    if (object.bps != null) {
      yield r'bps';
      yield serializers.serialize(
        object.bps,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DiscountInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DiscountInputBuilder result,
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
  DiscountInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DiscountInputBuilder();
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

