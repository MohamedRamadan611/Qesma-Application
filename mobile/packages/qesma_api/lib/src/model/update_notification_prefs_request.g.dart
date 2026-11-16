// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_notification_prefs_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateNotificationPrefsRequest extends UpdateNotificationPrefsRequest {
  @override
  final bool enabled;

  factory _$UpdateNotificationPrefsRequest(
          [void Function(UpdateNotificationPrefsRequestBuilder)? updates]) =>
      (UpdateNotificationPrefsRequestBuilder()..update(updates))._build();

  _$UpdateNotificationPrefsRequest._({required this.enabled}) : super._();
  @override
  UpdateNotificationPrefsRequest rebuild(
          void Function(UpdateNotificationPrefsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateNotificationPrefsRequestBuilder toBuilder() =>
      UpdateNotificationPrefsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateNotificationPrefsRequest && enabled == other.enabled;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateNotificationPrefsRequest')
          ..add('enabled', enabled))
        .toString();
  }
}

class UpdateNotificationPrefsRequestBuilder
    implements
        Builder<UpdateNotificationPrefsRequest,
            UpdateNotificationPrefsRequestBuilder> {
  _$UpdateNotificationPrefsRequest? _$v;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  UpdateNotificationPrefsRequestBuilder() {
    UpdateNotificationPrefsRequest._defaults(this);
  }

  UpdateNotificationPrefsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enabled = $v.enabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateNotificationPrefsRequest other) {
    _$v = other as _$UpdateNotificationPrefsRequest;
  }

  @override
  void update(void Function(UpdateNotificationPrefsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateNotificationPrefsRequest build() => _build();

  _$UpdateNotificationPrefsRequest _build() {
    final _$result = _$v ??
        _$UpdateNotificationPrefsRequest._(
          enabled: BuiltValueNullFieldError.checkNotNull(
              enabled, r'UpdateNotificationPrefsRequest', 'enabled'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
