//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/payment_handles_view.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transfer_view.g.dart';

/// TransferView
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [fromMemberId] 
/// * [hasDispute] 
/// * [openSettlementIds] 
/// * [pendingMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [receiverHandles] 
/// * [toMemberId] 
@BuiltValue()
abstract class TransferView implements Built<TransferView, TransferViewBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  @BuiltValueField(wireName: r'fromMemberId')
  String get fromMemberId;

  @BuiltValueField(wireName: r'hasDispute')
  bool get hasDispute;

  @BuiltValueField(wireName: r'openSettlementIds')
  BuiltList<String> get openSettlementIds;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'pendingMinor')
  int get pendingMinor;

  @BuiltValueField(wireName: r'receiverHandles')
  PaymentHandlesView? get receiverHandles;

  @BuiltValueField(wireName: r'toMemberId')
  String get toMemberId;

  TransferView._();

  factory TransferView([void updates(TransferViewBuilder b)]) = _$TransferView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransferViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransferView> get serializer => _$TransferViewSerializer();
}

class _$TransferViewSerializer implements PrimitiveSerializer<TransferView> {
  @override
  final Iterable<Type> types = const [TransferView, _$TransferView];

  @override
  final String wireName = r'TransferView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransferView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'fromMemberId';
    yield serializers.serialize(
      object.fromMemberId,
      specifiedType: const FullType(String),
    );
    yield r'hasDispute';
    yield serializers.serialize(
      object.hasDispute,
      specifiedType: const FullType(bool),
    );
    yield r'openSettlementIds';
    yield serializers.serialize(
      object.openSettlementIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'pendingMinor';
    yield serializers.serialize(
      object.pendingMinor,
      specifiedType: const FullType(int),
    );
    if (object.receiverHandles != null) {
      yield r'receiverHandles';
      yield serializers.serialize(
        object.receiverHandles,
        specifiedType: const FullType(PaymentHandlesView),
      );
    }
    yield r'toMemberId';
    yield serializers.serialize(
      object.toMemberId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TransferView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TransferViewBuilder result,
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
        case r'fromMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fromMemberId = valueDes;
          break;
        case r'hasDispute':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasDispute = valueDes;
          break;
        case r'openSettlementIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.openSettlementIds.replace(valueDes);
          break;
        case r'pendingMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.pendingMinor = valueDes;
          break;
        case r'receiverHandles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PaymentHandlesView),
          ) as PaymentHandlesView;
          result.receiverHandles.replace(valueDes);
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
  TransferView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransferViewBuilder();
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

