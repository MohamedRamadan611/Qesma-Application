//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'join_request_view.g.dart';

/// JoinRequestView
///
/// Properties:
/// * [claimMemberId] 
/// * [claimMemberName] 
/// * [createdAt] 
/// * [decidedAt] 
/// * [id] 
/// * [newMemberName] 
/// * [requesterName] 
/// * [status] 
@BuiltValue()
abstract class JoinRequestView implements Built<JoinRequestView, JoinRequestViewBuilder> {
  @BuiltValueField(wireName: r'claimMemberId')
  String? get claimMemberId;

  @BuiltValueField(wireName: r'claimMemberName')
  String? get claimMemberName;

  @BuiltValueField(wireName: r'createdAt')
  DateTime? get createdAt;

  @BuiltValueField(wireName: r'decidedAt')
  DateTime? get decidedAt;

  @BuiltValueField(wireName: r'id')
  String? get id;

  @BuiltValueField(wireName: r'newMemberName')
  String? get newMemberName;

  @BuiltValueField(wireName: r'requesterName')
  String? get requesterName;

  @BuiltValueField(wireName: r'status')
  String? get status;

  JoinRequestView._();

  factory JoinRequestView([void updates(JoinRequestViewBuilder b)]) = _$JoinRequestView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JoinRequestViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JoinRequestView> get serializer => _$JoinRequestViewSerializer();
}

class _$JoinRequestViewSerializer implements PrimitiveSerializer<JoinRequestView> {
  @override
  final Iterable<Type> types = const [JoinRequestView, _$JoinRequestView];

  @override
  final String wireName = r'JoinRequestView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JoinRequestView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.claimMemberId != null) {
      yield r'claimMemberId';
      yield serializers.serialize(
        object.claimMemberId,
        specifiedType: const FullType(String),
      );
    }
    if (object.claimMemberName != null) {
      yield r'claimMemberName';
      yield serializers.serialize(
        object.claimMemberName,
        specifiedType: const FullType(String),
      );
    }
    if (object.createdAt != null) {
      yield r'createdAt';
      yield serializers.serialize(
        object.createdAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.decidedAt != null) {
      yield r'decidedAt';
      yield serializers.serialize(
        object.decidedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.id != null) {
      yield r'id';
      yield serializers.serialize(
        object.id,
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
    if (object.requesterName != null) {
      yield r'requesterName';
      yield serializers.serialize(
        object.requesterName,
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
    JoinRequestView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JoinRequestViewBuilder result,
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
        case r'claimMemberName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.claimMemberName = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'decidedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.decidedAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'newMemberName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.newMemberName = valueDes;
          break;
        case r'requesterName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.requesterName = valueDes;
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
  JoinRequestView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JoinRequestViewBuilder();
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

