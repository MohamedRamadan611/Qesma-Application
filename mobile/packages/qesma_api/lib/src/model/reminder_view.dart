//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reminder_view.g.dart';

/// ReminderView
///
/// Properties:
/// * [amountMinor] - Integer minor units (piasters: 1 EGP = 100). Never a decimal.
/// * [canRemindAt] 
/// * [fromMemberId] 
/// * [remindedAt] 
/// * [toMemberId] 
@BuiltValue()
abstract class ReminderView implements Built<ReminderView, ReminderViewBuilder> {
  /// Integer minor units (piasters: 1 EGP = 100). Never a decimal.
  @BuiltValueField(wireName: r'amountMinor')
  int get amountMinor;

  @BuiltValueField(wireName: r'canRemindAt')
  DateTime get canRemindAt;

  @BuiltValueField(wireName: r'fromMemberId')
  String get fromMemberId;

  @BuiltValueField(wireName: r'remindedAt')
  DateTime get remindedAt;

  @BuiltValueField(wireName: r'toMemberId')
  String get toMemberId;

  ReminderView._();

  factory ReminderView([void updates(ReminderViewBuilder b)]) = _$ReminderView;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReminderViewBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ReminderView> get serializer => _$ReminderViewSerializer();
}

class _$ReminderViewSerializer implements PrimitiveSerializer<ReminderView> {
  @override
  final Iterable<Type> types = const [ReminderView, _$ReminderView];

  @override
  final String wireName = r'ReminderView';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ReminderView object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amountMinor';
    yield serializers.serialize(
      object.amountMinor,
      specifiedType: const FullType(int),
    );
    yield r'canRemindAt';
    yield serializers.serialize(
      object.canRemindAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'fromMemberId';
    yield serializers.serialize(
      object.fromMemberId,
      specifiedType: const FullType(String),
    );
    yield r'remindedAt';
    yield serializers.serialize(
      object.remindedAt,
      specifiedType: const FullType(DateTime),
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
    ReminderView object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ReminderViewBuilder result,
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
        case r'canRemindAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.canRemindAt = valueDes;
          break;
        case r'fromMemberId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.fromMemberId = valueDes;
          break;
        case r'remindedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.remindedAt = valueDes;
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
  ReminderView deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReminderViewBuilder();
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

