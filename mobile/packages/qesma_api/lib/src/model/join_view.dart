//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/joined_member.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'join_view.g.dart';

/// JoinView
///
/// Properties:
/// * [groupId] 
/// * [member] 
/// * [requestId] 
/// * [status] 
@BuiltValue()
abstract class JoinView implements Built<JoinView, JoinViewBuilder> {
  @BuiltValueField(wireName: r'groupId')
  String? get groupId;

  @BuiltValueField(wireName: r'member')
  JoinedMember? get member;

  @BuiltValueField(wireName: r'requestId')
  String? get requestId;

  @BuiltValueField(wireName: r'status')
  String? get status;

  JoinView._();

  factory JoinView([void updates(JoinViewBuilder b)]) = _$JoinView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JoinViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JoinView> get serializer => _$JoinViewSerializer();
}

class _$JoinViewSerializer implements PrimitiveSerializer<JoinView> {
  @override
  final Iterable<Type> types = const [JoinView, _$JoinView];

  @override
  final String wireName = r'JoinView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JoinView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.groupId != null) {
      yield r'groupId';
      yield serializers.serialize(
        object.groupId,
        specifiedType: const FullType(String),
      );
    }
    if (object.member != null) {
      yield r'member';
      yield serializers.serialize(
        object.member,
        specifiedType: const FullType(JoinedMember),
      );
    }
    if (object.requestId != null) {
      yield r'requestId';
      yield serializers.serialize(
        object.requestId,
        specifiedType: const FullType(String),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JoinView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JoinViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'groupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupId = valueDes;
          break;
        case r'member':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JoinedMember),
          ) as JoinedMember;
          result.member.replace(valueDes);
          break;
        case r'requestId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requestId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JoinView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JoinViewBuilder();
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

