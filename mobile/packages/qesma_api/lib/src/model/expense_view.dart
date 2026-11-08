//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/item_view.dart';
import 'package:qesma_api/src/model/charges.dart';
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/share_view.dart';
import 'package:qesma_api/src/model/payer_view.dart';
import 'package:qesma_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expense_view.g.dart';

/// ExpenseView
///
/// Properties:
/// * [charges] 
/// * [createdAt] 
/// * [expenseDate] 
/// * [groupId] 
/// * [id] 
/// * [items] 
/// * [payers] 
/// * [shares] 
/// * [splitType] 
/// * [title] 
/// * [totalMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [version] 
@BuiltValue()
abstract class ExpenseView implements Built<ExpenseView, ExpenseViewBuilder> {
  @BuiltValueField(wireName: r'charges')
  Charges? get charges;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'expenseDate')
  Date get expenseDate;

  @BuiltValueField(wireName: r'groupId')
  String get groupId;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'items')
  BuiltList<ItemView>? get items;

  @BuiltValueField(wireName: r'payers')
  BuiltList<PayerView> get payers;

  @BuiltValueField(wireName: r'shares')
  BuiltList<ShareView> get shares;

  @BuiltValueField(wireName: r'splitType')
  String get splitType;

  @BuiltValueField(wireName: r'title')
  String get title;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'totalMinor')
  int get totalMinor;

  @BuiltValueField(wireName: r'version')
  int get version;

  ExpenseView._();

  factory ExpenseView([void updates(ExpenseViewBuilder b)]) = _$ExpenseView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpenseViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpenseView> get serializer => _$ExpenseViewSerializer();
}

class _$ExpenseViewSerializer implements PrimitiveSerializer<ExpenseView> {
  @override
  final Iterable<Type> types = const [ExpenseView, _$ExpenseView];

  @override
  final String wireName = r'ExpenseView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpenseView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.charges != null) {
      yield r'charges';
      yield serializers.serialize(
        object.charges,
        specifiedType: const FullType(Charges),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'expenseDate';
    yield serializers.serialize(
      object.expenseDate,
      specifiedType: const FullType(Date),
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
    if (object.items != null) {
      yield r'items';
      yield serializers.serialize(
        object.items,
        specifiedType: const FullType.nullable(BuiltList, [FullType(ItemView)]),
      );
    }
    yield r'payers';
    yield serializers.serialize(
      object.payers,
      specifiedType: const FullType(BuiltList, [FullType(PayerView)]),
    );
    yield r'shares';
    yield serializers.serialize(
      object.shares,
      specifiedType: const FullType(BuiltList, [FullType(ShareView)]),
    );
    yield r'splitType';
    yield serializers.serialize(
      object.splitType,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'totalMinor';
    yield serializers.serialize(
      object.totalMinor,
      specifiedType: const FullType(int),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ExpenseView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExpenseViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'charges':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Charges),
          ) as Charges;
          result.charges.replace(valueDes);
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'expenseDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.expenseDate = valueDes;
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
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(ItemView)]),
          ) as BuiltList<ItemView>?;
          if (valueDes == null) continue;
          result.items.replace(valueDes);
          break;
        case r'payers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PayerView)]),
          ) as BuiltList<PayerView>;
          result.payers.replace(valueDes);
          break;
        case r'shares':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ShareView)]),
          ) as BuiltList<ShareView>;
          result.shares.replace(valueDes);
          break;
        case r'splitType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.splitType = valueDes;
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
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExpenseView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpenseViewBuilder();
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

