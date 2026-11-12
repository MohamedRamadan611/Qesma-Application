//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/join_request_view.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_response_join_request_view.g.dart';

/// PageResponseJoinRequestView
///
/// Properties:
/// * [items] 
/// * [page] 
/// * [size] 
/// * [totalElements] 
/// * [totalPages] 
@BuiltValue()
abstract class PageResponseJoinRequestView implements Built<PageResponseJoinRequestView, PageResponseJoinRequestViewBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<JoinRequestView> get items;

  @BuiltValueField(wireName: r'page')
  int get page;

  @BuiltValueField(wireName: r'size')
  int get size;

  @BuiltValueField(wireName: r'totalElements')
  int get totalElements;

  @BuiltValueField(wireName: r'totalPages')
  int get totalPages;

  PageResponseJoinRequestView._();

  factory PageResponseJoinRequestView([void updates(PageResponseJoinRequestViewBuilder b)]) = _$PageResponseJoinRequestView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageResponseJoinRequestViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageResponseJoinRequestView> get serializer => _$PageResponseJoinRequestViewSerializer();
}

class _$PageResponseJoinRequestViewSerializer implements PrimitiveSerializer<PageResponseJoinRequestView> {
  @override
  final Iterable<Type> types = const [PageResponseJoinRequestView, _$PageResponseJoinRequestView];

  @override
  final String wireName = r'PageResponseJoinRequestView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageResponseJoinRequestView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(JoinRequestView)]),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(int),
    );
    yield r'size';
    yield serializers.serialize(
      object.size,
      specifiedType: const FullType(int),
    );
    yield r'totalElements';
    yield serializers.serialize(
      object.totalElements,
      specifiedType: const FullType(int),
    );
    yield r'totalPages';
    yield serializers.serialize(
      object.totalPages,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PageResponseJoinRequestView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PageResponseJoinRequestViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(JoinRequestView)]),
          ) as BuiltList<JoinRequestView>;
          result.items.replace(valueDes);
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.page = valueDes;
          break;
        case r'size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.size = valueDes;
          break;
        case r'totalElements':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalElements = valueDes;
          break;
        case r'totalPages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalPages = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PageResponseJoinRequestView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageResponseJoinRequestViewBuilder();
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

