//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/notification_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'notification_page.g.dart';

/// NotificationPage
///
/// Properties:
/// * [items] 
/// * [nextBefore] 
@BuiltValue()
abstract class NotificationPage implements Built<NotificationPage, NotificationPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<NotificationItem> get items;

  @BuiltValueField(wireName: r'nextBefore')
  String? get nextBefore;

  NotificationPage._();

  factory NotificationPage([void updates(NotificationPageBuilder b)]) = _$NotificationPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationPage> get serializer => _$NotificationPageSerializer();
}

class _$NotificationPageSerializer implements PrimitiveSerializer<NotificationPage> {
  @override
  final Iterable<Type> types = const [NotificationPage, _$NotificationPage];

  @override
  final String wireName = r'NotificationPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(NotificationItem)]),
    );
    if (object.nextBefore != null) {
      yield r'nextBefore';
      yield serializers.serialize(
        object.nextBefore,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    NotificationPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(NotificationItem)]),
          ) as BuiltList<NotificationItem>;
          result.items.replace(valueDes);
          break;
        case r'nextBefore':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextBefore = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotificationPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationPageBuilder();
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

