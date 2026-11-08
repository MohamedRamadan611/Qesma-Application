//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'share_view.g.dart';

/// ShareView
///
/// Properties:
/// * [adjustmentMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [itemsMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [memberId] 
/// * [owedMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [serviceMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [taxMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
@BuiltValue()
abstract class ShareView implements Built<ShareView, ShareViewBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'adjustmentMinor')
  int? get adjustmentMinor;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'itemsMinor')
  int? get itemsMinor;

  @BuiltValueField(wireName: r'memberId')
  String get memberId;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'owedMinor')
  int get owedMinor;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'serviceMinor')
  int? get serviceMinor;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'taxMinor')
  int? get taxMinor;

  ShareView._();

  factory ShareView([void updates(ShareViewBuilder b)]) = _$ShareView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ShareViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ShareView> get serializer => _$ShareViewSerializer();
}

class _$ShareViewSerializer implements PrimitiveSerializer<ShareView> {
  @override
  final Iterable<Type> types = const [ShareView, _$ShareView];

  @override
  final String wireName = r'ShareView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ShareView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.adjustmentMinor != null) {
      yield r'adjustmentMinor';
      yield serializers.serialize(
        object.adjustmentMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.itemsMinor != null) {
      yield r'itemsMinor';
      yield serializers.serialize(
        object.itemsMinor,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'memberId';
    yield serializers.serialize(
      object.memberId,
      specifiedType: const FullType(String),
    );
    yield r'owedMinor';
    yield serializers.serialize(
      object.owedMinor,
      specifiedType: const FullType(int),
    );
    if (object.serviceMinor != null) {
      yield r'serviceMinor';
      yield serializers.serialize(
        object.serviceMinor,
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
  }

  @override
  Object serialize(
    Serializers serializers,
    ShareView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ShareViewBuilder result,
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
        case r'itemsMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.itemsMinor = valueDes;
          break;
        case r'memberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.memberId = valueDes;
          break;
        case r'owedMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.owedMinor = valueDes;
          break;
        case r'serviceMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.serviceMinor = valueDes;
          break;
        case r'taxMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.taxMinor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ShareView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ShareViewBuilder();
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

