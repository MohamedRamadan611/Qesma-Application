//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/group_summary_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_response_group_summary_dto.g.dart';

/// PageResponseGroupSummaryDto
///
/// Properties:
/// * [items] 
/// * [page] 
/// * [size] 
/// * [totalElements] 
/// * [totalPages] 
@BuiltValue()
abstract class PageResponseGroupSummaryDto implements Built<PageResponseGroupSummaryDto, PageResponseGroupSummaryDtoBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<GroupSummaryDto> get items;

  @BuiltValueField(wireName: r'page')
  int get page;

  @BuiltValueField(wireName: r'size')
  int get size;

  @BuiltValueField(wireName: r'totalElements')
  int get totalElements;

  @BuiltValueField(wireName: r'totalPages')
  int get totalPages;

  PageResponseGroupSummaryDto._();

  factory PageResponseGroupSummaryDto([void updates(PageResponseGroupSummaryDtoBuilder b)]) = _$PageResponseGroupSummaryDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageResponseGroupSummaryDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageResponseGroupSummaryDto> get serializer => _$PageResponseGroupSummaryDtoSerializer();
}

class _$PageResponseGroupSummaryDtoSerializer implements PrimitiveSerializer<PageResponseGroupSummaryDto> {
  @override
  final Iterable<Type> types = const [PageResponseGroupSummaryDto, _$PageResponseGroupSummaryDto];

  @override
  final String wireName = r'PageResponseGroupSummaryDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageResponseGroupSummaryDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(GroupSummaryDto)]),
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
    PageResponseGroupSummaryDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PageResponseGroupSummaryDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(GroupSummaryDto)]),
          ) as BuiltList<GroupSummaryDto>;
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
  PageResponseGroupSummaryDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageResponseGroupSummaryDtoBuilder();
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

