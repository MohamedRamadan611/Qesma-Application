//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_notification_prefs_request.g.dart';

/// UpdateNotificationPrefsRequest
///
/// Properties:
/// * [enabled] 
@BuiltValue()
abstract class UpdateNotificationPrefsRequest implements Built<UpdateNotificationPrefsRequest, UpdateNotificationPrefsRequestBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool get enabled;

  UpdateNotificationPrefsRequest._();

  factory UpdateNotificationPrefsRequest([void updates(UpdateNotificationPrefsRequestBuilder b)]) = _$UpdateNotificationPrefsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateNotificationPrefsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateNotificationPrefsRequest> get serializer => _$UpdateNotificationPrefsRequestSerializer();
}

class _$UpdateNotificationPrefsRequestSerializer implements PrimitiveSerializer<UpdateNotificationPrefsRequest> {
  @override
  final Iterable<Type> types = const [UpdateNotificationPrefsRequest, _$UpdateNotificationPrefsRequest];

  @override
  final String wireName = r'UpdateNotificationPrefsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateNotificationPrefsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'enabled';
    yield serializers.serialize(
      object.enabled,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateNotificationPrefsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateNotificationPrefsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enabled = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateNotificationPrefsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateNotificationPrefsRequestBuilder();
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

