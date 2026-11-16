// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_prefs_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationPrefsView extends NotificationPrefsView {
  @override
  final bool enabled;

  factory _$NotificationPrefsView(
          [void Function(NotificationPrefsViewBuilder)? updates]) =>
      (NotificationPrefsViewBuilder()..update(updates))._build();

  _$NotificationPrefsView._({required this.enabled}) : super._();
  @override
  NotificationPrefsView rebuild(
          void Function(NotificationPrefsViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotificationPrefsViewBuilder toBuilder() =>
      NotificationPrefsViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationPrefsView && enabled == other.enabled;
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
    return (newBuiltValueToStringHelper(r'NotificationPrefsView')
          ..add('enabled', enabled))
        .toString();
  }
}

class NotificationPrefsViewBuilder
    implements Builder<NotificationPrefsView, NotificationPrefsViewBuilder> {
  _$NotificationPrefsView? _$v;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  NotificationPrefsViewBuilder() {
    NotificationPrefsView._defaults(this);
  }

  NotificationPrefsViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enabled = $v.enabled;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotificationPrefsView other) {
    _$v = other as _$NotificationPrefsView;
  }

  @override
  void update(void Function(NotificationPrefsViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotificationPrefsView build() => _build();

  _$NotificationPrefsView _build() {
    final _$result = _$v ??
        _$NotificationPrefsView._(
          enabled: BuiltValueNullFieldError.checkNotNull(
              enabled, r'NotificationPrefsView', 'enabled'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
