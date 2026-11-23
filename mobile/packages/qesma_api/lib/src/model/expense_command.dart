//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/item_input.dart';
import 'package:qesma_api/src/model/share_participant_input.dart';
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/payer_input.dart';
import 'package:qesma_api/src/model/service_input.dart';
import 'package:qesma_api/src/model/share_input.dart';
import 'package:qesma_api/src/model/tax_input.dart';
import 'package:qesma_api/src/model/date.dart';
import 'package:qesma_api/src/model/discount_input.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expense_command.g.dart';

/// ExpenseCommand
///
/// Properties:
/// * [adjustmentMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [category] 
/// * [deliveryMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [discount] 
/// * [expenseDate] 
/// * [items] 
/// * [paidFromPool] 
/// * [participantMemberIds] 
/// * [payers] 
/// * [periodFrom] 
/// * [periodTo] 
/// * [service] 
/// * [shareParticipants] 
/// * [shares] 
/// * [splitType] 
/// * [tax] 
/// * [title] 
/// * [totalMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
@BuiltValue()
abstract class ExpenseCommand implements Built<ExpenseCommand, ExpenseCommandBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'adjustmentMinor')
  int? get adjustmentMinor;

  @BuiltValueField(wireName: r'category')
  String? get category;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'deliveryMinor')
  int? get deliveryMinor;

  @BuiltValueField(wireName: r'discount')
  DiscountInput? get discount;

  @BuiltValueField(wireName: r'expenseDate')
  Date get expenseDate;

  @BuiltValueField(wireName: r'items')
  BuiltList<ItemInput>? get items;

  @BuiltValueField(wireName: r'paidFromPool')
  bool? get paidFromPool;

  @BuiltValueField(wireName: r'participantMemberIds')
  BuiltList<String>? get participantMemberIds;

  @BuiltValueField(wireName: r'payers')
  BuiltList<PayerInput>? get payers;

  @BuiltValueField(wireName: r'periodFrom')
  Date? get periodFrom;

  @BuiltValueField(wireName: r'periodTo')
  Date? get periodTo;

  @BuiltValueField(wireName: r'service')
  ServiceInput? get service;

  @BuiltValueField(wireName: r'shareParticipants')
  BuiltList<ShareParticipantInput>? get shareParticipants;

  @BuiltValueField(wireName: r'shares')
  BuiltList<ShareInput>? get shares;

  @BuiltValueField(wireName: r'splitType')
  String get splitType;

  @BuiltValueField(wireName: r'tax')
  TaxInput? get tax;

  @BuiltValueField(wireName: r'title')
  String get title;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'totalMinor')
  int? get totalMinor;

  ExpenseCommand._();

  factory ExpenseCommand([void updates(ExpenseCommandBuilder b)]) = _$ExpenseCommand;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpenseCommandBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpenseCommand> get serializer => _$ExpenseCommandSerializer();
}

class _$ExpenseCommandSerializer implements PrimitiveSerializer<ExpenseCommand> {
  @override
  final Iterable<Type> types = const [ExpenseCommand, _$ExpenseCommand];

  @override
  final String wireName = r'ExpenseCommand';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpenseCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.adjustmentMinor != null) {
      yield r'adjustmentMinor';
      yield serializers.serialize(
        object.adjustmentMinor,
        specifiedType: const FullType(int),
      );
    }
    if (object.category != null) {
      yield r'category';
      yield serializers.serialize(
        object.category,
        specifiedType: const FullType(String),
      );
    }
    if (object.deliveryMinor != null) {
      yield r'deliveryMinor';
      yield serializers.serialize(
        object.deliveryMinor,
        specifiedType: const FullType(int),
      );
    }
    if (object.discount != null) {
      yield r'discount';
      yield serializers.serialize(
        object.discount,
        specifiedType: const FullType(DiscountInput),
      );
    }
    yield r'expenseDate';
    yield serializers.serialize(
      object.expenseDate,
      specifiedType: const FullType(Date),
    );
    if (object.items != null) {
      yield r'items';
      yield serializers.serialize(
        object.items,
        specifiedType: const FullType(BuiltList, [FullType(ItemInput)]),
      );
    }
    if (object.paidFromPool != null) {
      yield r'paidFromPool';
      yield serializers.serialize(
        object.paidFromPool,
        specifiedType: const FullType(bool),
      );
    }
    if (object.participantMemberIds != null) {
      yield r'participantMemberIds';
      yield serializers.serialize(
        object.participantMemberIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
    if (object.payers != null) {
      yield r'payers';
      yield serializers.serialize(
        object.payers,
        specifiedType: const FullType(BuiltList, [FullType(PayerInput)]),
      );
    }
    if (object.periodFrom != null) {
      yield r'periodFrom';
      yield serializers.serialize(
        object.periodFrom,
        specifiedType: const FullType(Date),
      );
    }
    if (object.periodTo != null) {
      yield r'periodTo';
      yield serializers.serialize(
        object.periodTo,
        specifiedType: const FullType(Date),
      );
    }
    if (object.service != null) {
      yield r'service';
      yield serializers.serialize(
        object.service,
        specifiedType: const FullType(ServiceInput),
      );
    }
    if (object.shareParticipants != null) {
      yield r'shareParticipants';
      yield serializers.serialize(
        object.shareParticipants,
        specifiedType: const FullType(BuiltList, [FullType(ShareParticipantInput)]),
      );
    }
    if (object.shares != null) {
      yield r'shares';
      yield serializers.serialize(
        object.shares,
        specifiedType: const FullType(BuiltList, [FullType(ShareInput)]),
      );
    }
    yield r'splitType';
    yield serializers.serialize(
      object.splitType,
      specifiedType: const FullType(String),
    );
    if (object.tax != null) {
      yield r'tax';
      yield serializers.serialize(
        object.tax,
        specifiedType: const FullType(TaxInput),
      );
    }
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    if (object.totalMinor != null) {
      yield r'totalMinor';
      yield serializers.serialize(
        object.totalMinor,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ExpenseCommand object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExpenseCommandBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'adjustmentMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.adjustmentMinor = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.category = valueDes;
          break;
        case r'deliveryMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.deliveryMinor = valueDes;
          break;
        case r'discount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DiscountInput),
          ) as DiscountInput;
          result.discount.replace(valueDes);
          break;
        case r'expenseDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.expenseDate = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ItemInput)]),
          ) as BuiltList<ItemInput>;
          result.items.replace(valueDes);
          break;
        case r'paidFromPool':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.paidFromPool = valueDes;
          break;
        case r'participantMemberIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.participantMemberIds.replace(valueDes);
          break;
        case r'payers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PayerInput)]),
          ) as BuiltList<PayerInput>;
          result.payers.replace(valueDes);
          break;
        case r'periodFrom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodFrom = valueDes;
          break;
        case r'periodTo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodTo = valueDes;
          break;
        case r'service':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ServiceInput),
          ) as ServiceInput;
          result.service.replace(valueDes);
          break;
        case r'shareParticipants':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ShareParticipantInput)]),
          ) as BuiltList<ShareParticipantInput>;
          result.shareParticipants.replace(valueDes);
          break;
        case r'shares':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ShareInput)]),
          ) as BuiltList<ShareInput>;
          result.shares.replace(valueDes);
          break;
        case r'splitType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.splitType = valueDes;
          break;
        case r'tax':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TaxInput),
          ) as TaxInput;
          result.tax.replace(valueDes);
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'totalMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalMinor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExpenseCommand deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpenseCommandBuilder();
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

