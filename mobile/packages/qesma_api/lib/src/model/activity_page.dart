//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/activity_item.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'activity_page.g.dart';

/// ActivityPage
///
/// Properties:
/// * [items] 
/// * [nextBefore] 
@BuiltValue()
abstract class ActivityPage implements Built<ActivityPage, ActivityPageBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<ActivityItem> get items;

  @BuiltValueField(wireName: r'nextBefore')
  String? get nextBefore;

  ActivityPage._();

  factory ActivityPage([void updates(ActivityPageBuilder b)]) = _$ActivityPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ActivityPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ActivityPage> get serializer => _$ActivityPageSerializer();
}

class _$ActivityPageSerializer implements PrimitiveSerializer<ActivityPage> {
  @override
  final Iterable<Type> types = const [ActivityPage, _$ActivityPage];

  @override
  final String wireName = r'ActivityPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ActivityPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(ActivityItem)]),
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
    ActivityPage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ActivityPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ActivityItem)]),
          ) as BuiltList<ActivityItem>;
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
  ActivityPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ActivityPageBuilder();
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

