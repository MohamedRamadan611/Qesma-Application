//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:qesma_api/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'share_participant_input.g.dart';

/// ShareParticipantInput
///
/// Properties:
/// * [memberId] 
/// * [presentFrom] 
/// * [presentTo] 
/// * [shareUnits] 
@BuiltValue()
abstract class ShareParticipantInput implements Built<ShareParticipantInput, ShareParticipantInputBuilder> {
  @BuiltValueField(wireName: r'memberId')
  String get memberId;

  @BuiltValueField(wireName: r'presentFrom')
  Date? get presentFrom;

  @BuiltValueField(wireName: r'presentTo')
  Date? get presentTo;

  @BuiltValueField(wireName: r'shareUnits')
  int get shareUnits;

  ShareParticipantInput._();

  factory ShareParticipantInput([void updates(ShareParticipantInputBuilder b)]) = _$ShareParticipantInput;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ShareParticipantInputBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ShareParticipantInput> get serializer => _$ShareParticipantInputSerializer();
}

class _$ShareParticipantInputSerializer implements PrimitiveSerializer<ShareParticipantInput> {
  @override
  final Iterable<Type> types = const [ShareParticipantInput, _$ShareParticipantInput];

  @override
  final String wireName = r'ShareParticipantInput';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ShareParticipantInput object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'memberId';
    yield serializers.serialize(
      object.memberId,
      specifiedType: const FullType(String),
    );
    if (object.presentFrom != null) {
      yield r'presentFrom';
      yield serializers.serialize(
        object.presentFrom,
        specifiedType: const FullType(Date),
      );
    }
    if (object.presentTo != null) {
      yield r'presentTo';
      yield serializers.serialize(
        object.presentTo,
        specifiedType: const FullType(Date),
      );
    }
    yield r'shareUnits';
    yield serializers.serialize(
      object.shareUnits,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ShareParticipantInput object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ShareParticipantInputBuilder result,
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
        case r'presentFrom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.presentFrom = valueDes;
          break;
        case r'presentTo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.presentTo = valueDes;
          break;
        case r'shareUnits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.shareUnits = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ShareParticipantInput deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ShareParticipantInputBuilder();
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

