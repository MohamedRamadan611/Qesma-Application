//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'tax_input.g.dart';

/// TaxInput
///
/// Properties:
/// * [base_] 
/// * [bps] - Integer basis points: 1200 = 12.00%.
@BuiltValue()
abstract class TaxInput implements Built<TaxInput, TaxInputBuilder> {
  @BuiltValueField(wireName: r'base')
  String? get base_;

  /// Integer basis points: 1200 = 12.00%.
  @BuiltValueField(wireName: r'bps')
  int get bps;

  TaxInput._();

  factory TaxInput([void updates(TaxInputBuilder b)]) = _$TaxInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TaxInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TaxInput> get serializer => _$TaxInputSerializer();
}

class _$TaxInputSerializer implements PrimitiveSerializer<TaxInput> {
  @override
  final Iterable<Type> types = const [TaxInput, _$TaxInput];

  @override
  final String wireName = r'TaxInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TaxInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.base_ != null) {
      yield r'base';
      yield serializers.serialize(
        object.base_,
        specifiedType: const FullType(String),
      );
    }
    yield r'bps';
    yield serializers.serialize(
      object.bps,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TaxInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TaxInputBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'base':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.base_ = valueDes;
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
  TaxInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TaxInputBuilder();
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

