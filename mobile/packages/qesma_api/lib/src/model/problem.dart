//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'problem.g.dart';

/// RFC 7807 problem details (application/problem+json).
///
/// Properties:
/// * [code] - Stable machine-readable error code.
/// * [detail] 
/// * [instance] 
/// * [requestId] - Echoes the X-Request-Id response header.
/// * [status] 
/// * [title] 
/// * [type] 
@BuiltValue()
abstract class Problem implements Built<Problem, ProblemBuilder> {
  /// Stable machine-readable error code.
  @BuiltValueField(wireName: r'code')
  ProblemCodeEnum get code;
  // enum codeEnum {  VALIDATION_ERROR,  PAYERS_TOTAL_MISMATCH,  SPLIT_TOTAL_MISMATCH,  MEMBER_NOT_IN_GROUP,  IDEMPOTENCY_KEY_REUSED,  DUPLICATE_MEMBER_NAME,  MEMBER_HAS_TRANSACTIONS,  OWNER_MEMBER_PROTECTED,  VERSION_CONFLICT,  GROUP_NOT_EMPTY,  NOT_FOUND,  UNAUTHORIZED,  INTERNAL_ERROR,  RATE_LIMITED,  AUTH_PROVIDER_UNAVAILABLE,  USERNAME_TAKEN,  };

  @BuiltValueField(wireName: r'detail')
  String? get detail;

  @BuiltValueField(wireName: r'instance')
  String? get instance;

  /// Echoes the X-Request-Id response header.
  @BuiltValueField(wireName: r'requestId')
  String? get requestId;

  @BuiltValueField(wireName: r'status')
  int get status;

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'type')
  String get type;

  Problem._();

  factory Problem([void updates(ProblemBuilder b)]) = _$Problem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProblemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Problem> get serializer => _$ProblemSerializer();
}

class _$ProblemSerializer implements PrimitiveSerializer<Problem> {
  @override
  final Iterable<Type> types = const [Problem, _$Problem];

  @override
  final String wireName = r'Problem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Problem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(ProblemCodeEnum),
    );
    if (object.detail != null) {
      yield r'detail';
      yield serializers.serialize(
        object.detail,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.instance != null) {
      yield r'instance';
      yield serializers.serialize(
        object.instance,
        specifiedType: const FullType(String),
      );
    }
    if (object.requestId != null) {
      yield r'requestId';
      yield serializers.serialize(
        object.requestId,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(int),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Problem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProblemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProblemCodeEnum),
          ) as ProblemCodeEnum;
          result.code = valueDes;
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.detail = valueDes;
          break;
        case r'instance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.instance = valueDes;
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
            specifiedType: const FullType(int),
          ) as int;
          result.status = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Problem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProblemBuilder();
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

class ProblemCodeEnum extends EnumClass {

  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'VALIDATION_ERROR')
  static const ProblemCodeEnum VALIDATION_ERROR = _$problemCodeEnum_VALIDATION_ERROR;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'PAYERS_TOTAL_MISMATCH')
  static const ProblemCodeEnum PAYERS_TOTAL_MISMATCH = _$problemCodeEnum_PAYERS_TOTAL_MISMATCH;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'SPLIT_TOTAL_MISMATCH')
  static const ProblemCodeEnum SPLIT_TOTAL_MISMATCH = _$problemCodeEnum_SPLIT_TOTAL_MISMATCH;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'MEMBER_NOT_IN_GROUP')
  static const ProblemCodeEnum MEMBER_NOT_IN_GROUP = _$problemCodeEnum_MEMBER_NOT_IN_GROUP;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'IDEMPOTENCY_KEY_REUSED')
  static const ProblemCodeEnum IDEMPOTENCY_KEY_REUSED = _$problemCodeEnum_IDEMPOTENCY_KEY_REUSED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'DUPLICATE_MEMBER_NAME')
  static const ProblemCodeEnum DUPLICATE_MEMBER_NAME = _$problemCodeEnum_DUPLICATE_MEMBER_NAME;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'MEMBER_HAS_TRANSACTIONS')
  static const ProblemCodeEnum MEMBER_HAS_TRANSACTIONS = _$problemCodeEnum_MEMBER_HAS_TRANSACTIONS;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'OWNER_MEMBER_PROTECTED')
  static const ProblemCodeEnum OWNER_MEMBER_PROTECTED = _$problemCodeEnum_OWNER_MEMBER_PROTECTED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'VERSION_CONFLICT')
  static const ProblemCodeEnum VERSION_CONFLICT = _$problemCodeEnum_VERSION_CONFLICT;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'GROUP_NOT_EMPTY')
  static const ProblemCodeEnum GROUP_NOT_EMPTY = _$problemCodeEnum_GROUP_NOT_EMPTY;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'NOT_FOUND')
  static const ProblemCodeEnum NOT_FOUND = _$problemCodeEnum_NOT_FOUND;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'UNAUTHORIZED')
  static const ProblemCodeEnum UNAUTHORIZED = _$problemCodeEnum_UNAUTHORIZED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'INTERNAL_ERROR')
  static const ProblemCodeEnum INTERNAL_ERROR = _$problemCodeEnum_INTERNAL_ERROR;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'RATE_LIMITED')
  static const ProblemCodeEnum RATE_LIMITED = _$problemCodeEnum_RATE_LIMITED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'AUTH_PROVIDER_UNAVAILABLE')
  static const ProblemCodeEnum AUTH_PROVIDER_UNAVAILABLE = _$problemCodeEnum_AUTH_PROVIDER_UNAVAILABLE;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'USERNAME_TAKEN')
  static const ProblemCodeEnum USERNAME_TAKEN = _$problemCodeEnum_USERNAME_TAKEN;

  static Serializer<ProblemCodeEnum> get serializer => _$problemCodeEnumSerializer;

  const ProblemCodeEnum._(String name): super(name);

  static BuiltSet<ProblemCodeEnum> get values => _$problemCodeEnumValues;
  static ProblemCodeEnum valueOf(String name) => _$problemCodeEnumValueOf(name);
}

