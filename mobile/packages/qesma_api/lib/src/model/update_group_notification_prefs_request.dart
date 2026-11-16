//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_group_notification_prefs_request.g.dart';

/// UpdateGroupNotificationPrefsRequest
///
/// Properties:
/// * [muted] 
@BuiltValue()
abstract class UpdateGroupNotificationPrefsRequest implements Built<UpdateGroupNotificationPrefsRequest, UpdateGroupNotificationPrefsRequestBuilder> {
  @BuiltValueField(wireName: r'muted')
  bool get muted;

  UpdateGroupNotificationPrefsRequest._();

  factory UpdateGroupNotificationPrefsRequest([void updates(UpdateGroupNotificationPrefsRequestBuilder b)]) = _$UpdateGroupNotificationPrefsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateGroupNotificationPrefsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateGroupNotificationPrefsRequest> get serializer => _$UpdateGroupNotificationPrefsRequestSerializer();
}

class _$UpdateGroupNotificationPrefsRequestSerializer implements PrimitiveSerializer<UpdateGroupNotificationPrefsRequest> {
  @override
  final Iterable<Type> types = const [UpdateGroupNotificationPrefsRequest, _$UpdateGroupNotificationPrefsRequest];

  @override
  final String wireName = r'UpdateGroupNotificationPrefsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateGroupNotificationPrefsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'muted';
    yield serializers.serialize(
      object.muted,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateGroupNotificationPrefsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateGroupNotificationPrefsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'muted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.muted = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateGroupNotificationPrefsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateGroupNotificationPrefsRequestBuilder();
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

