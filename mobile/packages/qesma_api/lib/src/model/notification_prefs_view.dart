//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notification_prefs_view.g.dart';

/// NotificationPrefsView
///
/// Properties:
/// * [enabled] 
@BuiltValue()
abstract class NotificationPrefsView implements Built<NotificationPrefsView, NotificationPrefsViewBuilder> {
  @BuiltValueField(wireName: r'enabled')
  bool get enabled;

  NotificationPrefsView._();

  factory NotificationPrefsView([void updates(NotificationPrefsViewBuilder b)]) = _$NotificationPrefsView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationPrefsViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationPrefsView> get serializer => _$NotificationPrefsViewSerializer();
}

class _$NotificationPrefsViewSerializer implements PrimitiveSerializer<NotificationPrefsView> {
  @override
  final Iterable<Type> types = const [NotificationPrefsView, _$NotificationPrefsView];

  @override
  final String wireName = r'NotificationPrefsView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationPrefsView object, {
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
    NotificationPrefsView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationPrefsViewBuilder result,
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
  NotificationPrefsView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationPrefsViewBuilder();
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

