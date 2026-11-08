//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/net.dart';
import 'package:qesma_api/src/model/transfer_view.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'balance_view.g.dart';

/// BalanceView
///
/// Properties:
/// * [nets] 
/// * [transfers] 
@BuiltValue()
abstract class BalanceView implements Built<BalanceView, BalanceViewBuilder> {
  @BuiltValueField(wireName: r'nets')
  BuiltList<Net> get nets;

  @BuiltValueField(wireName: r'transfers')
  BuiltList<TransferView> get transfers;

  BalanceView._();

  factory BalanceView([void updates(BalanceViewBuilder b)]) = _$BalanceView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BalanceViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BalanceView> get serializer => _$BalanceViewSerializer();
}

class _$BalanceViewSerializer implements PrimitiveSerializer<BalanceView> {
  @override
  final Iterable<Type> types = const [BalanceView, _$BalanceView];

  @override
  final String wireName = r'BalanceView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BalanceView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'nets';
    yield serializers.serialize(
      object.nets,
      specifiedType: const FullType(BuiltList, [FullType(Net)]),
    );
    yield r'transfers';
    yield serializers.serialize(
      object.transfers,
      specifiedType: const FullType(BuiltList, [FullType(TransferView)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BalanceView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BalanceViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'nets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Net)]),
          ) as BuiltList<Net>;
          result.nets.replace(valueDes);
          break;
        case r'transfers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TransferView)]),
          ) as BuiltList<TransferView>;
          result.transfers.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BalanceView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BalanceViewBuilder();
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

