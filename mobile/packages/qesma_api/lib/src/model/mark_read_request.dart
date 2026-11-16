//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mark_read_request.g.dart';

/// MarkReadRequest
///
/// Properties:
/// * [all] 
/// * [ids] 
@BuiltValue()
abstract class MarkReadRequest implements Built<MarkReadRequest, MarkReadRequestBuilder> {
  @BuiltValueField(wireName: r'all')
  bool? get all;

  @BuiltValueField(wireName: r'ids')
  BuiltList<String>? get ids;

  MarkReadRequest._();

  factory MarkReadRequest([void updates(MarkReadRequestBuilder b)]) = _$MarkReadRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MarkReadRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MarkReadRequest> get serializer => _$MarkReadRequestSerializer();
}

class _$MarkReadRequestSerializer implements PrimitiveSerializer<MarkReadRequest> {
  @override
  final Iterable<Type> types = const [MarkReadRequest, _$MarkReadRequest];

  @override
  final String wireName = r'MarkReadRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MarkReadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.all != null) {
      yield r'all';
      yield serializers.serialize(
        object.all,
        specifiedType: const FullType(bool),
      );
    }
    if (object.ids != null) {
      yield r'ids';
      yield serializers.serialize(
        object.ids,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MarkReadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MarkReadRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'all':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.all = valueDes;
          break;
        case r'ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.ids.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MarkReadRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MarkReadRequestBuilder();
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

