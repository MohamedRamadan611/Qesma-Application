//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/member_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'group_dto.g.dart';

/// GroupDto
///
/// Properties:
/// * [createdAt] 
/// * [currencyCode] 
/// * [id] 
/// * [lastExpenseAt] 
/// * [members] 
/// * [name] 
/// * [totalSpentMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [type] 
/// * [updatedAt] 
/// * [version] 
/// * [yourMemberId] 
/// * [yourNetMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [yourRole] 
@BuiltValue()
abstract class GroupDto implements Built<GroupDto, GroupDtoBuilder> {
  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'currencyCode')
  String get currencyCode;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'lastExpenseAt')
  DateTime? get lastExpenseAt;

  @BuiltValueField(wireName: r'members')
  BuiltList<MemberDto> get members;

  @BuiltValueField(wireName: r'name')
  String get name;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'totalSpentMinor')
  int get totalSpentMinor;

  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'version')
  int get version;

  @BuiltValueField(wireName: r'yourMemberId')
  String get yourMemberId;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'yourNetMinor')
  int get yourNetMinor;

  @BuiltValueField(wireName: r'yourRole')
  String get yourRole;

  GroupDto._();

  factory GroupDto([void updates(GroupDtoBuilder b)]) = _$GroupDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupDto> get serializer => _$GroupDtoSerializer();
}

class _$GroupDtoSerializer implements PrimitiveSerializer<GroupDto> {
  @override
  final Iterable<Type> types = const [GroupDto, _$GroupDto];

  @override
  final String wireName = r'GroupDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'currencyCode';
    yield serializers.serialize(
      object.currencyCode,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.lastExpenseAt != null) {
      yield r'lastExpenseAt';
      yield serializers.serialize(
        object.lastExpenseAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'members';
    yield serializers.serialize(
      object.members,
      specifiedType: const FullType(BuiltList, [FullType(MemberDto)]),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'totalSpentMinor';
    yield serializers.serialize(
      object.totalSpentMinor,
      specifiedType: const FullType(int),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
    yield r'yourMemberId';
    yield serializers.serialize(
      object.yourMemberId,
      specifiedType: const FullType(String),
    );
    yield r'yourNetMinor';
    yield serializers.serialize(
      object.yourNetMinor,
      specifiedType: const FullType(int),
    );
    yield r'yourRole';
    yield serializers.serialize(
      object.yourRole,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GroupDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'currencyCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currencyCode = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'lastExpenseAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastExpenseAt = valueDes;
          break;
        case r'members':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(MemberDto)]),
          ) as BuiltList<MemberDto>;
          result.members.replace(valueDes);
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'totalSpentMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalSpentMinor = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.version = valueDes;
          break;
        case r'yourMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.yourMemberId = valueDes;
          break;
        case r'yourNetMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.yourNetMinor = valueDes;
          break;
        case r'yourRole':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.yourRole = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupDtoBuilder();
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

