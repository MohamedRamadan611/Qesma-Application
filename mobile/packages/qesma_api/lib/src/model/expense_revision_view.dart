//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/expense_view.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expense_revision_view.g.dart';

/// ExpenseRevisionView
///
/// Properties:
/// * [changeType] 
/// * [changedAt] 
/// * [changedByUserId] 
/// * [snapshot] 
/// * [version] 
@BuiltValue()
abstract class ExpenseRevisionView implements Built<ExpenseRevisionView, ExpenseRevisionViewBuilder> {
  @BuiltValueField(wireName: r'changeType')
  String get changeType;

  @BuiltValueField(wireName: r'changedAt')
  DateTime get changedAt;

  @BuiltValueField(wireName: r'changedByUserId')
  String get changedByUserId;

  @BuiltValueField(wireName: r'snapshot')
  ExpenseView get snapshot;

  @BuiltValueField(wireName: r'version')
  int get version;

  ExpenseRevisionView._();

  factory ExpenseRevisionView([void updates(ExpenseRevisionViewBuilder b)]) = _$ExpenseRevisionView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpenseRevisionViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpenseRevisionView> get serializer => _$ExpenseRevisionViewSerializer();
}

class _$ExpenseRevisionViewSerializer implements PrimitiveSerializer<ExpenseRevisionView> {
  @override
  final Iterable<Type> types = const [ExpenseRevisionView, _$ExpenseRevisionView];

  @override
  final String wireName = r'ExpenseRevisionView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpenseRevisionView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'changeType';
    yield serializers.serialize(
      object.changeType,
      specifiedType: const FullType(String),
    );
    yield r'changedAt';
    yield serializers.serialize(
      object.changedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'changedByUserId';
    yield serializers.serialize(
      object.changedByUserId,
      specifiedType: const FullType(String),
    );
    yield r'snapshot';
    yield serializers.serialize(
      object.snapshot,
      specifiedType: const FullType(ExpenseView),
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
    ExpenseRevisionView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExpenseRevisionViewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'changeType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.changeType = valueDes;
          break;
        case r'changedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.changedAt = valueDes;
          break;
        case r'changedByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.changedByUserId = valueDes;
          break;
        case r'snapshot':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ExpenseView),
          ) as ExpenseView;
          result.snapshot.replace(valueDes);
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
  ExpenseRevisionView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpenseRevisionViewBuilder();
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

