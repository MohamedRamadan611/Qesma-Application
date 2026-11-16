// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_notification_prefs_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupNotificationPrefsView extends GroupNotificationPrefsView {
  @override
  final bool muted;

  factory _$GroupNotificationPrefsView(
          [void Function(GroupNotificationPrefsViewBuilder)? updates]) =>
      (GroupNotificationPrefsViewBuilder()..update(updates))._build();

  _$GroupNotificationPrefsView._({required this.muted}) : super._();
  @override
  GroupNotificationPrefsView rebuild(
          void Function(GroupNotificationPrefsViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupNotificationPrefsViewBuilder toBuilder() =>
      GroupNotificationPrefsViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupNotificationPrefsView && muted == other.muted;
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
    return (newBuiltValueToStringHelper(r'GroupNotificationPrefsView')
          ..add('muted', muted))
        .toString();
  }
}

class GroupNotificationPrefsViewBuilder
    implements
        Builder<GroupNotificationPrefsView, GroupNotificationPrefsViewBuilder> {
  _$GroupNotificationPrefsView? _$v;

  bool? _muted;
  bool? get muted => _$this._muted;
  set muted(bool? muted) => _$this._muted = muted;

  GroupNotificationPrefsViewBuilder() {
    GroupNotificationPrefsView._defaults(this);
  }

  GroupNotificationPrefsViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _muted = $v.muted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupNotificationPrefsView other) {
    _$v = other as _$GroupNotificationPrefsView;
  }

  @override
  void update(void Function(GroupNotificationPrefsViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupNotificationPrefsView build() => _build();

  _$GroupNotificationPrefsView _build() {
    final _$result = _$v ??
        _$GroupNotificationPrefsView._(
          muted: BuiltValueNullFieldError.checkNotNull(
              muted, r'GroupNotificationPrefsView', 'muted'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
