//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/problem_groups_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/problem.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'version_conflict_problem.g.dart';

/// 409 VERSION_CONFLICT of a stale If-Match: the problem plus the latest version and state.
///
/// Properties:
/// * [code] - Stable machine-readable error code.
/// * [detail] 
/// * [groups] - Only with OWNER_MUST_TRANSFER on DELETE /me: your groups that still depend on you as Owner.
/// * [instance] 
/// * [nextAllowedAt] - Only with REMIND_RATE_LIMITED: the earliest time a reminder for this member may be sent again (UTC).
/// * [requestId] - Echoes the X-Request-Id response header.
/// * [status] 
/// * [title] 
/// * [type] 
/// * [current] - The latest state the caller may GET: an ExpenseView (expense operations) or a GroupDto (PATCH group). Absent if it could not be read at the moment of the conflict.
/// * [currentVersion] - The version now stored; re-send the edit with If-Match set to it to re-apply.
@BuiltValue()
abstract class VersionConflictProblem implements Problem, Built<VersionConflictProblem, VersionConflictProblemBuilder> {
  /// The latest state the caller may GET: an ExpenseView (expense operations) or a GroupDto (PATCH group). Absent if it could not be read at the moment of the conflict.
  @BuiltValueField(wireName: r'current')
  JsonObject? get current;

  /// The version now stored; re-send the edit with If-Match set to it to re-apply.
  @BuiltValueField(wireName: r'currentVersion')
  int get currentVersion;

  VersionConflictProblem._();

  factory VersionConflictProblem([void updates(VersionConflictProblemBuilder b)]) = _$VersionConflictProblem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VersionConflictProblemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VersionConflictProblem> get serializer => _$VersionConflictProblemSerializer();
}

class _$VersionConflictProblemSerializer implements PrimitiveSerializer<VersionConflictProblem> {
  @override
  final Iterable<Type> types = const [VersionConflictProblem, _$VersionConflictProblem];

  @override
  final String wireName = r'VersionConflictProblem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VersionConflictProblem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.current != null) {
      yield r'current';
      yield serializers.serialize(
        object.current,
        specifiedType: const FullType(JsonObject),
      );
    }
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(ProblemCodeEnum),
    );
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
    if (object.groups != null) {
      yield r'groups';
      yield serializers.serialize(
        object.groups,
        specifiedType: const FullType(BuiltList, [FullType(ProblemGroupsInner)]),
      );
    }
    if (object.detail != null) {
      yield r'detail';
      yield serializers.serialize(
        object.detail,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.nextAllowedAt != null) {
      yield r'nextAllowedAt';
      yield serializers.serialize(
        object.nextAllowedAt,
        specifiedType: const FullType(DateTime),
      );
    }
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
    yield r'currentVersion';
    yield serializers.serialize(
      object.currentVersion,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VersionConflictProblem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VersionConflictProblemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'current':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.current = valueDes;
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProblemCodeEnum),
          ) as ProblemCodeEnum;
          result.code = valueDes;
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
        case r'groups':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProblemGroupsInner)]),
          ) as BuiltList<ProblemGroupsInner>;
          result.groups.replace(valueDes);
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.detail = valueDes;
          break;
        case r'nextAllowedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.nextAllowedAt = valueDes;
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
        case r'currentVersion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.currentVersion = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
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
  VersionConflictProblem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VersionConflictProblemBuilder();
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

class VersionConflictProblemCodeEnum extends EnumClass {

  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'VALIDATION_ERROR')
  static const VersionConflictProblemCodeEnum VALIDATION_ERROR = _$versionConflictProblemCodeEnum_VALIDATION_ERROR;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'PAYERS_TOTAL_MISMATCH')
  static const VersionConflictProblemCodeEnum PAYERS_TOTAL_MISMATCH = _$versionConflictProblemCodeEnum_PAYERS_TOTAL_MISMATCH;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'SPLIT_TOTAL_MISMATCH')
  static const VersionConflictProblemCodeEnum SPLIT_TOTAL_MISMATCH = _$versionConflictProblemCodeEnum_SPLIT_TOTAL_MISMATCH;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'MEMBER_NOT_IN_GROUP')
  static const VersionConflictProblemCodeEnum MEMBER_NOT_IN_GROUP = _$versionConflictProblemCodeEnum_MEMBER_NOT_IN_GROUP;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'IDEMPOTENCY_KEY_REUSED')
  static const VersionConflictProblemCodeEnum IDEMPOTENCY_KEY_REUSED = _$versionConflictProblemCodeEnum_IDEMPOTENCY_KEY_REUSED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'DUPLICATE_MEMBER_NAME')
  static const VersionConflictProblemCodeEnum DUPLICATE_MEMBER_NAME = _$versionConflictProblemCodeEnum_DUPLICATE_MEMBER_NAME;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'MEMBER_HAS_TRANSACTIONS')
  static const VersionConflictProblemCodeEnum MEMBER_HAS_TRANSACTIONS = _$versionConflictProblemCodeEnum_MEMBER_HAS_TRANSACTIONS;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'OWNER_MEMBER_PROTECTED')
  static const VersionConflictProblemCodeEnum OWNER_MEMBER_PROTECTED = _$versionConflictProblemCodeEnum_OWNER_MEMBER_PROTECTED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'VERSION_CONFLICT')
  static const VersionConflictProblemCodeEnum VERSION_CONFLICT = _$versionConflictProblemCodeEnum_VERSION_CONFLICT;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'INVITE_EXPIRED')
  static const VersionConflictProblemCodeEnum INVITE_EXPIRED = _$versionConflictProblemCodeEnum_INVITE_EXPIRED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'INVITE_REVOKED')
  static const VersionConflictProblemCodeEnum INVITE_REVOKED = _$versionConflictProblemCodeEnum_INVITE_REVOKED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'ALREADY_MEMBER')
  static const VersionConflictProblemCodeEnum ALREADY_MEMBER = _$versionConflictProblemCodeEnum_ALREADY_MEMBER;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'MEMBER_ALREADY_CLAIMED')
  static const VersionConflictProblemCodeEnum MEMBER_ALREADY_CLAIMED = _$versionConflictProblemCodeEnum_MEMBER_ALREADY_CLAIMED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'MEMBER_INACTIVE')
  static const VersionConflictProblemCodeEnum MEMBER_INACTIVE = _$versionConflictProblemCodeEnum_MEMBER_INACTIVE;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'OWNER_MUST_TRANSFER')
  static const VersionConflictProblemCodeEnum OWNER_MUST_TRANSFER = _$versionConflictProblemCodeEnum_OWNER_MUST_TRANSFER;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'GROUP_NOT_EMPTY')
  static const VersionConflictProblemCodeEnum GROUP_NOT_EMPTY = _$versionConflictProblemCodeEnum_GROUP_NOT_EMPTY;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'NOT_FOUND')
  static const VersionConflictProblemCodeEnum NOT_FOUND = _$versionConflictProblemCodeEnum_NOT_FOUND;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'FORBIDDEN')
  static const VersionConflictProblemCodeEnum FORBIDDEN = _$versionConflictProblemCodeEnum_FORBIDDEN;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'INVALID_STATE_TRANSITION')
  static const VersionConflictProblemCodeEnum INVALID_STATE_TRANSITION = _$versionConflictProblemCodeEnum_INVALID_STATE_TRANSITION;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'UNAUTHORIZED')
  static const VersionConflictProblemCodeEnum UNAUTHORIZED = _$versionConflictProblemCodeEnum_UNAUTHORIZED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'INTERNAL_ERROR')
  static const VersionConflictProblemCodeEnum INTERNAL_ERROR = _$versionConflictProblemCodeEnum_INTERNAL_ERROR;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'RATE_LIMITED')
  static const VersionConflictProblemCodeEnum RATE_LIMITED = _$versionConflictProblemCodeEnum_RATE_LIMITED;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'AUTH_PROVIDER_UNAVAILABLE')
  static const VersionConflictProblemCodeEnum AUTH_PROVIDER_UNAVAILABLE = _$versionConflictProblemCodeEnum_AUTH_PROVIDER_UNAVAILABLE;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'USERNAME_TAKEN')
  static const VersionConflictProblemCodeEnum USERNAME_TAKEN = _$versionConflictProblemCodeEnum_USERNAME_TAKEN;
  /// Stable machine-readable error code.
  @BuiltValueEnumConst(wireName: r'REMIND_RATE_LIMITED')
  static const VersionConflictProblemCodeEnum REMIND_RATE_LIMITED = _$versionConflictProblemCodeEnum_REMIND_RATE_LIMITED;

  static Serializer<VersionConflictProblemCodeEnum> get serializer => _$versionConflictProblemCodeEnumSerializer;

  const VersionConflictProblemCodeEnum._(String name): super(name);

  static BuiltSet<VersionConflictProblemCodeEnum> get values => _$versionConflictProblemCodeEnumValues;
  static VersionConflictProblemCodeEnum valueOf(String name) => _$versionConflictProblemCodeEnumValueOf(name);
}

