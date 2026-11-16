// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReminderView extends ReminderView {
  @override
  final int amountMinor;
  @override
  final DateTime canRemindAt;
  @override
  final String fromMemberId;
  @override
  final DateTime remindedAt;
  @override
  final String toMemberId;

  factory _$ReminderView([void Function(ReminderViewBuilder)? updates]) =>
      (ReminderViewBuilder()..update(updates))._build();

  _$ReminderView._(
      {required this.amountMinor,
      required this.canRemindAt,
      required this.fromMemberId,
      required this.remindedAt,
      required this.toMemberId})
      : super._();
  @override
  ReminderView rebuild(void Function(ReminderViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReminderViewBuilder toBuilder() => ReminderViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReminderView &&
        amountMinor == other.amountMinor &&
        canRemindAt == other.canRemindAt &&
        fromMemberId == other.fromMemberId &&
        remindedAt == other.remindedAt &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, canRemindAt.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, remindedAt.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReminderView')
          ..add('amountMinor', amountMinor)
          ..add('canRemindAt', canRemindAt)
          ..add('fromMemberId', fromMemberId)
          ..add('remindedAt', remindedAt)
          ..add('toMemberId', toMemberId))
        .toString();
  }
}

class ReminderViewBuilder
    implements Builder<ReminderView, ReminderViewBuilder> {
  _$ReminderView? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  DateTime? _canRemindAt;
  DateTime? get canRemindAt => _$this._canRemindAt;
  set canRemindAt(DateTime? canRemindAt) => _$this._canRemindAt = canRemindAt;

  String? _fromMemberId;
  String? get fromMemberId => _$this._fromMemberId;
  set fromMemberId(String? fromMemberId) => _$this._fromMemberId = fromMemberId;

  DateTime? _remindedAt;
  DateTime? get remindedAt => _$this._remindedAt;
  set remindedAt(DateTime? remindedAt) => _$this._remindedAt = remindedAt;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  ReminderViewBuilder() {
    ReminderView._defaults(this);
  }

  ReminderViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _canRemindAt = $v.canRemindAt;
      _fromMemberId = $v.fromMemberId;
      _remindedAt = $v.remindedAt;
      _toMemberId = $v.toMemberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReminderView other) {
    _$v = other as _$ReminderView;
  }

  @override
  void update(void Function(ReminderViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReminderView build() => _build();

  _$ReminderView _build() {
    final _$result = _$v ??
        _$ReminderView._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'ReminderView', 'amountMinor'),
          canRemindAt: BuiltValueNullFieldError.checkNotNull(
              canRemindAt, r'ReminderView', 'canRemindAt'),
          fromMemberId: BuiltValueNullFieldError.checkNotNull(
              fromMemberId, r'ReminderView', 'fromMemberId'),
          remindedAt: BuiltValueNullFieldError.checkNotNull(
              remindedAt, r'ReminderView', 'remindedAt'),
          toMemberId: BuiltValueNullFieldError.checkNotNull(
              toMemberId, r'ReminderView', 'toMemberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
