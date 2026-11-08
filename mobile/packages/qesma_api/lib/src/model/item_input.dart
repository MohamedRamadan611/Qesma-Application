//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'item_input.g.dart';

/// ItemInput
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [assigneeMemberIds] 
/// * [name] 
@BuiltValue()
abstract class ItemInput implements Built<ItemInput, ItemInputBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  @BuiltValueField(wireName: r'assigneeMemberIds')
  BuiltList<String> get assigneeMemberIds;

  @BuiltValueField(wireName: r'name')
  String get name;

  ItemInput._();

  factory ItemInput([void updates(ItemInputBuilder b)]) = _$ItemInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ItemInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ItemInput> get serializer => _$ItemInputSerializer();
}

class _$ItemInputSerializer implements PrimitiveSerializer<ItemInput> {
  @override
  final Iterable<Type> types = const [ItemInput, _$ItemInput];

  @override
  final String wireName = r'ItemInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ItemInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'assigneeMemberIds';
    yield serializers.serialize(
      object.assigneeMemberIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ItemInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ItemInputBuilder result,
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
        case r'assigneeMemberIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.assigneeMemberIds.replace(valueDes);
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ItemInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ItemInputBuilder();
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

