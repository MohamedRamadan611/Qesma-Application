//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mark_read_result.g.dart';

/// MarkReadResult
///
/// Properties:
/// * [marked] 
/// * [unreadCount] 
@BuiltValue()
abstract class MarkReadResult implements Built<MarkReadResult, MarkReadResultBuilder> {
  @BuiltValueField(wireName: r'marked')
  int get marked;

  @BuiltValueField(wireName: r'unreadCount')
  int get unreadCount;

  MarkReadResult._();

  factory MarkReadResult([void updates(MarkReadResultBuilder b)]) = _$MarkReadResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MarkReadResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MarkReadResult> get serializer => _$MarkReadResultSerializer();
}

class _$MarkReadResultSerializer implements PrimitiveSerializer<MarkReadResult> {
  @override
  final Iterable<Type> types = const [MarkReadResult, _$MarkReadResult];

  @override
  final String wireName = r'MarkReadResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MarkReadResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'marked';
    yield serializers.serialize(
      object.marked,
      specifiedType: const FullType(int),
    );
    yield r'unreadCount';
    yield serializers.serialize(
      object.unreadCount,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MarkReadResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MarkReadResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'marked':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.marked = valueDes;
          break;
        case r'unreadCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.unreadCount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MarkReadResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MarkReadResultBuilder();
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

