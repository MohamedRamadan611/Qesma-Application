//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'remind_command.g.dart';

/// RemindCommand
///
/// Properties:
/// * [fromMemberId] 
/// * [toMemberId] 
@BuiltValue()
abstract class RemindCommand implements Built<RemindCommand, RemindCommandBuilder> {
  @BuiltValueField(wireName: r'fromMemberId')
  String get fromMemberId;

  @BuiltValueField(wireName: r'toMemberId')
  String get toMemberId;

  RemindCommand._();

  factory RemindCommand([void updates(RemindCommandBuilder b)]) = _$RemindCommand;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RemindCommandBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RemindCommand> get serializer => _$RemindCommandSerializer();
}

class _$RemindCommandSerializer implements PrimitiveSerializer<RemindCommand> {
  @override
  final Iterable<Type> types = const [RemindCommand, _$RemindCommand];

  @override
  final String wireName = r'RemindCommand';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RemindCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'fromMemberId';
    yield serializers.serialize(
      object.fromMemberId,
      specifiedType: const FullType(String),
    );
    yield r'toMemberId';
    yield serializers.serialize(
      object.toMemberId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RemindCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RemindCommandBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'fromMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fromMemberId = valueDes;
          break;
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
  RemindCommand deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RemindCommandBuilder();
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

