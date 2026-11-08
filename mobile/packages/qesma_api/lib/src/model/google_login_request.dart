//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'google_login_request.g.dart';

/// GoogleLoginRequest
///
/// Properties:
/// * [idToken] 
@BuiltValue()
abstract class GoogleLoginRequest implements Built<GoogleLoginRequest, GoogleLoginRequestBuilder> {
  @BuiltValueField(wireName: r'idToken')
  String get idToken;

  GoogleLoginRequest._();

  factory GoogleLoginRequest([void updates(GoogleLoginRequestBuilder b)]) = _$GoogleLoginRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GoogleLoginRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GoogleLoginRequest> get serializer => _$GoogleLoginRequestSerializer();
}

class _$GoogleLoginRequestSerializer implements PrimitiveSerializer<GoogleLoginRequest> {
  @override
  final Iterable<Type> types = const [GoogleLoginRequest, _$GoogleLoginRequest];

  @override
  final String wireName = r'GoogleLoginRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GoogleLoginRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'idToken';
    yield serializers.serialize(
      object.idToken,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GoogleLoginRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GoogleLoginRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'idToken':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.idToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GoogleLoginRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GoogleLoginRequestBuilder();
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

