//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'settlement_view.g.dart';

/// SettlementView
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [cancelledAt] 
/// * [confirmedAt] 
/// * [createdAt] 
/// * [createdByMemberId] 
/// * [declaredAt] 
/// * [disputedAt] 
/// * [fromMemberId] 
/// * [groupId] 
/// * [id] 
/// * [note] 
/// * [recordedByAdmin] 
/// * [settledOn] 
/// * [status] 
/// * [toMemberId] 
@BuiltValue()
abstract class SettlementView implements Built<SettlementView, SettlementViewBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  @BuiltValueField(wireName: r'cancelledAt')
  DateTime? get cancelledAt;

  @BuiltValueField(wireName: r'confirmedAt')
  DateTime? get confirmedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'createdByMemberId')
  String? get createdByMemberId;

  @BuiltValueField(wireName: r'declaredAt')
  DateTime get declaredAt;

  @BuiltValueField(wireName: r'disputedAt')
  DateTime? get disputedAt;

  @BuiltValueField(wireName: r'fromMemberId')
  String get fromMemberId;

  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'recordedByAdmin')
  bool get recordedByAdmin;

  @BuiltValueField(wireName: r'settledOn')
  Date get settledOn;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'toMemberId')
  String get toMemberId;

  SettlementView._();

  factory SettlementView([void updates(SettlementViewBuilder b)]) = _$SettlementView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SettlementViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SettlementView> get serializer => _$SettlementViewSerializer();
}

class _$SettlementViewSerializer implements PrimitiveSerializer<SettlementView> {
  @override
  final Iterable<Type> types = const [SettlementView, _$SettlementView];

  @override
  final String wireName = r'SettlementView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SettlementView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    if (object.cancelledAt != null) {
      yield r'cancelledAt';
      yield serializers.serialize(
        object.cancelledAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.confirmedAt != null) {
      yield r'confirmedAt';
      yield serializers.serialize(
        object.confirmedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.createdByMemberId != null) {
      yield r'createdByMemberId';
      yield serializers.serialize(
        object.createdByMemberId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'declaredAt';
    yield serializers.serialize(
      object.declaredAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.disputedAt != null) {
      yield r'disputedAt';
      yield serializers.serialize(
        object.disputedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'fromMemberId';
    yield serializers.serialize(
      object.fromMemberId,
      specifiedType: const FullType(String),
    );
    yield r'groupId';
    yield serializers.serialize(
      object.groupId,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'recordedByAdmin';
    yield serializers.serialize(
      object.recordedByAdmin,
      specifiedType: const FullType(bool),
    );
    yield r'settledOn';
    yield serializers.serialize(
      object.settledOn,
      specifiedType: const FullType(Date),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'toMemberId';
    yield serializers.serialize(
      object.toMemberId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SettlementView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SettlementViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amountMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.amountMinor = valueDes;
          break;
        case r'cancelledAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.cancelledAt = valueDes;
          break;
        case r'confirmedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.confirmedAt = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'createdByMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.createdByMemberId = valueDes;
          break;
        case r'declaredAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.declaredAt = valueDes;
          break;
        case r'disputedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.disputedAt = valueDes;
          break;
        case r'fromMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fromMemberId = valueDes;
          break;
        case r'groupId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.groupId = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        case r'recordedByAdmin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.recordedByAdmin = valueDes;
          break;
        case r'settledOn':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.settledOn = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'toMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.toMemberId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SettlementView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SettlementViewBuilder();
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

