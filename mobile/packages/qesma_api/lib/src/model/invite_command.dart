//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'invite_command.g.dart';

/// InviteCommand
///
/// Properties:
/// * [expiresInDays] 
/// * [maxUses] 
/// * [requiresApproval] 
@BuiltValue()
abstract class InviteCommand implements Built<InviteCommand, InviteCommandBuilder> {
  @BuiltValueField(wireName: r'expiresInDays')
  int? get expiresInDays;

  @BuiltValueField(wireName: r'maxUses')
  int? get maxUses;

  @BuiltValueField(wireName: r'requiresApproval')
  bool? get requiresApproval;

  InviteCommand._();

  factory InviteCommand([void updates(InviteCommandBuilder b)]) = _$InviteCommand;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InviteCommandBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InviteCommand> get serializer => _$InviteCommandSerializer();
}

class _$InviteCommandSerializer implements PrimitiveSerializer<InviteCommand> {
  @override
  final Iterable<Type> types = const [InviteCommand, _$InviteCommand];

  @override
  final String wireName = r'InviteCommand';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InviteCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.expiresInDays != null) {
      yield r'expiresInDays';
      yield serializers.serialize(
        object.expiresInDays,
        specifiedType: const FullType(int),
      );
    }
    if (object.maxUses != null) {
      yield r'maxUses';
      yield serializers.serialize(
        object.maxUses,
        specifiedType: const FullType(int),
      );
    }
    if (object.requiresApproval != null) {
      yield r'requiresApproval';
      yield serializers.serialize(
        object.requiresApproval,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    InviteCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required InviteCommandBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'expiresInDays':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.expiresInDays = valueDes;
          break;
        case r'maxUses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.maxUses = valueDes;
          break;
        case r'requiresApproval':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.requiresApproval = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  InviteCommand deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InviteCommandBuilder();
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

