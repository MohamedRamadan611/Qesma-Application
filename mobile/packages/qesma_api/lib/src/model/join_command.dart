//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'join_command.g.dart';

/// JoinCommand
///
/// Properties:
/// * [claimMemberId] 
/// * [newMemberName] 
@BuiltValue()
abstract class JoinCommand implements Built<JoinCommand, JoinCommandBuilder> {
  @BuiltValueField(wireName: r'claimMemberId')
  String? get claimMemberId;

  @BuiltValueField(wireName: r'newMemberName')
  String? get newMemberName;

  JoinCommand._();

  factory JoinCommand([void updates(JoinCommandBuilder b)]) = _$JoinCommand;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JoinCommandBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JoinCommand> get serializer => _$JoinCommandSerializer();
}

class _$JoinCommandSerializer implements PrimitiveSerializer<JoinCommand> {
  @override
  final Iterable<Type> types = const [JoinCommand, _$JoinCommand];

  @override
  final String wireName = r'JoinCommand';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JoinCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.claimMemberId != null) {
      yield r'claimMemberId';
      yield serializers.serialize(
        object.claimMemberId,
        specifiedType: const FullType(String),
      );
    }
    if (object.newMemberName != null) {
      yield r'newMemberName';
      yield serializers.serialize(
        object.newMemberName,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JoinCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JoinCommandBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'claimMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.claimMemberId = valueDes;
          break;
        case r'newMemberName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.newMemberName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JoinCommand deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JoinCommandBuilder();
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

