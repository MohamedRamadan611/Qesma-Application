// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_group_notification_prefs_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateGroupNotificationPrefsRequest
    extends UpdateGroupNotificationPrefsRequest {
  @override
  final bool muted;

  factory _$UpdateGroupNotificationPrefsRequest(
          [void Function(UpdateGroupNotificationPrefsRequestBuilder)?
              updates]) =>
      (UpdateGroupNotificationPrefsRequestBuilder()..update(updates))._build();

  _$UpdateGroupNotificationPrefsRequest._({required this.muted}) : super._();
  @override
  UpdateGroupNotificationPrefsRequest rebuild(
          void Function(UpdateGroupNotificationPrefsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateGroupNotificationPrefsRequestBuilder toBuilder() =>
      UpdateGroupNotificationPrefsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateGroupNotificationPrefsRequest && muted == other.muted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, muted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateGroupNotificationPrefsRequest')
          ..add('muted', muted))
        .toString();
  }
}

class UpdateGroupNotificationPrefsRequestBuilder
    implements
        Builder<UpdateGroupNotificationPrefsRequest,
            UpdateGroupNotificationPrefsRequestBuilder> {
  _$UpdateGroupNotificationPrefsRequest? _$v;

  bool? _muted;
  bool? get muted => _$this._muted;
  set muted(bool? muted) => _$this._muted = muted;

  UpdateGroupNotificationPrefsRequestBuilder() {
    UpdateGroupNotificationPrefsRequest._defaults(this);
  }

  UpdateGroupNotificationPrefsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _muted = $v.muted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateGroupNotificationPrefsRequest other) {
    _$v = other as _$UpdateGroupNotificationPrefsRequest;
  }

  @override
  void update(
      void Function(UpdateGroupNotificationPrefsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateGroupNotificationPrefsRequest build() => _build();

  _$UpdateGroupNotificationPrefsRequest _build() {
    final _$result = _$v ??
        _$UpdateGroupNotificationPrefsRequest._(
          muted: BuiltValueNullFieldError.checkNotNull(
              muted, r'UpdateGroupNotificationPrefsRequest', 'muted'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
