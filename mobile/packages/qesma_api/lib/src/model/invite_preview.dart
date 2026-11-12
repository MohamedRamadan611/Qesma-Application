//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/unclaimed.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'invite_preview.g.dart';

/// InvitePreview
///
/// Properties:
/// * [callerState] 
/// * [expiresAt] 
/// * [groupName] 
/// * [groupType] 
/// * [inviterName] 
/// * [memberCount] 
/// * [requiresApproval] 
/// * [unclaimedMembers] 
@BuiltValue()
abstract class InvitePreview implements Built<InvitePreview, InvitePreviewBuilder> {
  @BuiltValueField(wireName: r'callerState')
  String? get callerState;

  @BuiltValueField(wireName: r'expiresAt')
  DateTime? get expiresAt;

  @BuiltValueField(wireName: r'groupName')
  String? get groupName;

  @BuiltValueField(wireName: r'groupType')
  String? get groupType;

  @BuiltValueField(wireName: r'inviterName')
  String? get inviterName;

  @BuiltValueField(wireName: r'memberCount')
  int? get memberCount;

  @BuiltValueField(wireName: r'requiresApproval')
  bool? get requiresApproval;

  @BuiltValueField(wireName: r'unclaimedMembers')
  BuiltList<Unclaimed>? get unclaimedMembers;

  InvitePreview._();

  factory InvitePreview([void updates(InvitePreviewBuilder b)]) = _$InvitePreview;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InvitePreviewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InvitePreview> get serializer => _$InvitePreviewSerializer();
}

class _$InvitePreviewSerializer implements PrimitiveSerializer<InvitePreview> {
  @override
  final Iterable<Type> types = const [InvitePreview, _$InvitePreview];

  @override
  final String wireName = r'InvitePreview';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InvitePreview object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.callerState != null) {
      yield r'callerState';
      yield serializers.serialize(
        object.callerState,
        specifiedType: const FullType(String),
      );
    }
    if (object.expiresAt != null) {
      yield r'expiresAt';
      yield serializers.serialize(
        object.expiresAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.groupName != null) {
      yield r'groupName';
      yield serializers.serialize(
        object.groupName,
        specifiedType: const FullType(String),
      );
    }
    if (object.groupType != null) {
      yield r'groupType';
      yield serializers.serialize(
        object.groupType,
        specifiedType: const FullType(String),
      );
    }
    if (object.inviterName != null) {
      yield r'inviterName';
      yield serializers.serialize(
        object.inviterName,
        specifiedType: const FullType(String),
      );
    }
    if (object.memberCount != null) {
      yield r'memberCount';
      yield serializers.serialize(
        object.memberCount,
        specifiedType: const FullType(int),
      );
    }
    if (object.requiresApproval != null) {
      yield r'requiresApproval';
      yield serializers.serialize(
        object.requiresApproval,
        specifiedType: const FullType(bool),
      );
    }
    if (object.unclaimedMembers != null) {
      yield r'unclaimedMembers';
      yield serializers.serialize(
        object.unclaimedMembers,
        specifiedType: const FullType(BuiltList, [FullType(Unclaimed)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    InvitePreview object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required InvitePreviewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'callerState':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.callerState = valueDes;
          break;
        case r'expiresAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.expiresAt = valueDes;
          break;
        case r'groupName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupName = valueDes;
          break;
        case r'groupType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupType = valueDes;
          break;
        case r'inviterName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.inviterName = valueDes;
          break;
        case r'memberCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.memberCount = valueDes;
          break;
        case r'requiresApproval':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.requiresApproval = valueDes;
          break;
        case r'unclaimedMembers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Unclaimed)]),
          ) as BuiltList<Unclaimed>;
          result.unclaimedMembers.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  InvitePreview deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InvitePreviewBuilder();
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

