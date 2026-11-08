//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'net.g.dart';

/// Net
///
/// Properties:
/// * [memberId] 
/// * [netMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
@BuiltValue()
abstract class Net implements Built<Net, NetBuilder> {
  @BuiltValueField(wireName: r'memberId')
  String get memberId;

  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'netMinor')
  int get netMinor;

  Net._();

  factory Net([void updates(NetBuilder b)]) = _$Net;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NetBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Net> get serializer => _$NetSerializer();
}

class _$NetSerializer implements PrimitiveSerializer<Net> {
  @override
  final Iterable<Type> types = const [Net, _$Net];

  @override
  final String wireName = r'Net';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Net object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'memberId';
    yield serializers.serialize(
      object.memberId,
      specifiedType: const FullType(String),
    );
    yield r'netMinor';
    yield serializers.serialize(
      object.netMinor,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Net object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NetBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'memberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.memberId = valueDes;
          break;
        case r'netMinor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.netMinor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Net deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NetBuilder();
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

