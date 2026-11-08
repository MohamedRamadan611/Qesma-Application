//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/service_charge.dart';
import 'package:qesma_api/src/model/tax_charge.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'charges.g.dart';

/// Charges
///
/// Properties:
/// * [adjustmentMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [service] 
/// * [subtotalMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [tax] 
@BuiltValue()
abstract class Charges implements Built<Charges, ChargesBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'adjustmentMinor')
  int get adjustmentMinor;

  @BuiltValueField(wireName: r'service')
  ServiceCharge? get service;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'subtotalMinor')
  int get subtotalMinor;

  @BuiltValueField(wireName: r'tax')
  TaxCharge? get tax;

  Charges._();

  factory Charges([void updates(ChargesBuilder b)]) = _$Charges;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ChargesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Charges> get serializer => _$ChargesSerializer();
}

class _$ChargesSerializer implements PrimitiveSerializer<Charges> {
  @override
  final Iterable<Type> types = const [Charges, _$Charges];

  @override
  final String wireName = r'Charges';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Charges object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'adjustmentMinor';
    yield serializers.serialize(
      object.adjustmentMinor,
      specifiedType: const FullType(int),
    );
    if (object.service != null) {
      yield r'service';
      yield serializers.serialize(
        object.service,
        specifiedType: const FullType(ServiceCharge),
      );
    }
    yield r'subtotalMinor';
    yield serializers.serialize(
      object.subtotalMinor,
      specifiedType: const FullType(int),
    );
    if (object.tax != null) {
      yield r'tax';
      yield serializers.serialize(
        object.tax,
        specifiedType: const FullType(TaxCharge),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Charges object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ChargesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'adjustmentMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.adjustmentMinor = valueDes;
          break;
        case r'service':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ServiceCharge),
          ) as ServiceCharge;
          result.service.replace(valueDes);
          break;
        case r'subtotalMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.subtotalMinor = valueDes;
          break;
        case r'tax':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TaxCharge),
          ) as TaxCharge;
          result.tax.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Charges deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ChargesBuilder();
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

