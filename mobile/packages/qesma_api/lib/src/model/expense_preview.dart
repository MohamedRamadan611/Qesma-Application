//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/src/model/share_view.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expense_preview.g.dart';

/// ExpensePreview
///
/// Properties:
/// * [adjustmentMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [members] 
/// * [payersTotalMatches] 
/// * [serviceMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [subtotalMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [taxMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [totalMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
@BuiltValue()
abstract class ExpensePreview implements Built<ExpensePreview, ExpensePreviewBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'adjustmentMinor')
  int? get adjustmentMinor;

  @BuiltValueField(wireName: r'members')
  BuiltList<ShareView> get members;

  @BuiltValueField(wireName: r'payersTotalMatches')
  bool get payersTotalMatches;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'serviceMinor')
  int? get serviceMinor;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'subtotalMinor')
  int? get subtotalMinor;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'taxMinor')
  int? get taxMinor;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'totalMinor')
  int get totalMinor;

  ExpensePreview._();

  factory ExpensePreview([void updates(ExpensePreviewBuilder b)]) = _$ExpensePreview;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpensePreviewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpensePreview> get serializer => _$ExpensePreviewSerializer();
}

class _$ExpensePreviewSerializer implements PrimitiveSerializer<ExpensePreview> {
  @override
  final Iterable<Type> types = const [ExpensePreview, _$ExpensePreview];

  @override
  final String wireName = r'ExpensePreview';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpensePreview object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.adjustmentMinor != null) {
      yield r'adjustmentMinor';
      yield serializers.serialize(
        object.adjustmentMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'members';
    yield serializers.serialize(
      object.members,
      specifiedType: const FullType(BuiltList, [FullType(ShareView)]),
    );
    yield r'payersTotalMatches';
    yield serializers.serialize(
      object.payersTotalMatches,
      specifiedType: const FullType(bool),
    );
    if (object.serviceMinor != null) {
      yield r'serviceMinor';
      yield serializers.serialize(
        object.serviceMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.subtotalMinor != null) {
      yield r'subtotalMinor';
      yield serializers.serialize(
        object.subtotalMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.taxMinor != null) {
      yield r'taxMinor';
      yield serializers.serialize(
        object.taxMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'totalMinor';
    yield serializers.serialize(
      object.totalMinor,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ExpensePreview object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExpensePreviewBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'adjustmentMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.adjustmentMinor = valueDes;
          break;
        case r'members':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ShareView)]),
          ) as BuiltList<ShareView>;
          result.members.replace(valueDes);
          break;
        case r'payersTotalMatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.payersTotalMatches = valueDes;
          break;
        case r'serviceMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.serviceMinor = valueDes;
          break;
        case r'subtotalMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.subtotalMinor = valueDes;
          break;
        case r'taxMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.taxMinor = valueDes;
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
  ExpensePreview deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpensePreviewBuilder();
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

