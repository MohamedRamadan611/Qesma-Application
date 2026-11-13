// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SettlementView extends SettlementView {
  @override
  final int amountMinor;
  @override
  final DateTime? cancelledAt;
  @override
  final DateTime? confirmedAt;
  @override
  final DateTime createdAt;
  @override
  final String? createdByMemberId;
  @override
  final DateTime declaredAt;
  @override
  final DateTime? disputedAt;
  @override
  final String fromMemberId;
  @override
  final String groupId;
  @override
  final String id;
  @override
  final String? note;
  @override
  final bool recordedByAdmin;
  @override
  final Date settledOn;
  @override
  final String status;
  @override
  final String toMemberId;

  factory _$SettlementView([void Function(SettlementViewBuilder)? updates]) =>
      (SettlementViewBuilder()..update(updates))._build();

  _$SettlementView._(
      {required this.amountMinor,
      this.cancelledAt,
      this.confirmedAt,
      required this.createdAt,
      this.createdByMemberId,
      required this.declaredAt,
      this.disputedAt,
      required this.fromMemberId,
      required this.groupId,
      required this.id,
      this.note,
      required this.recordedByAdmin,
      required this.settledOn,
      required this.status,
      required this.toMemberId})
      : super._();
  @override
  SettlementView rebuild(void Function(SettlementViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SettlementViewBuilder toBuilder() => SettlementViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SettlementView &&
        amountMinor == other.amountMinor &&
        cancelledAt == other.cancelledAt &&
        confirmedAt == other.confirmedAt &&
        createdAt == other.createdAt &&
        createdByMemberId == other.createdByMemberId &&
        declaredAt == other.declaredAt &&
        disputedAt == other.disputedAt &&
        fromMemberId == other.fromMemberId &&
        groupId == other.groupId &&
        id == other.id &&
        note == other.note &&
        recordedByAdmin == other.recordedByAdmin &&
        settledOn == other.settledOn &&
        status == other.status &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, cancelledAt.hashCode);
    _$hash = $jc(_$hash, confirmedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, createdByMemberId.hashCode);
    _$hash = $jc(_$hash, declaredAt.hashCode);
    _$hash = $jc(_$hash, disputedAt.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, recordedByAdmin.hashCode);
    _$hash = $jc(_$hash, settledOn.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SettlementView')
          ..add('amountMinor', amountMinor)
          ..add('cancelledAt', cancelledAt)
          ..add('confirmedAt', confirmedAt)
          ..add('createdAt', createdAt)
          ..add('createdByMemberId', createdByMemberId)
          ..add('declaredAt', declaredAt)
          ..add('disputedAt', disputedAt)
          ..add('fromMemberId', fromMemberId)
          ..add('groupId', groupId)
          ..add('id', id)
          ..add('note', note)
          ..add('recordedByAdmin', recordedByAdmin)
          ..add('settledOn', settledOn)
          ..add('status', status)
          ..add('toMemberId', toMemberId))
        .toString();
  }
}

class SettlementViewBuilder
    implements Builder<SettlementView, SettlementViewBuilder> {
  _$SettlementView? _$v;

  int? _amountMinor;
  int? get amountMinor => _$this._amountMinor;
  set amountMinor(int? amountMinor) => _$this._amountMinor = amountMinor;

  DateTime? _cancelledAt;
  DateTime? get cancelledAt => _$this._cancelledAt;
  set cancelledAt(DateTime? cancelledAt) => _$this._cancelledAt = cancelledAt;

  DateTime? _confirmedAt;
  DateTime? get confirmedAt => _$this._confirmedAt;
  set confirmedAt(DateTime? confirmedAt) => _$this._confirmedAt = confirmedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _createdByMemberId;
  String? get createdByMemberId => _$this._createdByMemberId;
  set createdByMemberId(String? createdByMemberId) =>
      _$this._createdByMemberId = createdByMemberId;

  DateTime? _declaredAt;
  DateTime? get declaredAt => _$this._declaredAt;
  set declaredAt(DateTime? declaredAt) => _$this._declaredAt = declaredAt;

  DateTime? _disputedAt;
  DateTime? get disputedAt => _$this._disputedAt;
  set disputedAt(DateTime? disputedAt) => _$this._disputedAt = disputedAt;

  String? _fromMemberId;
  String? get fromMemberId => _$this._fromMemberId;
  set fromMemberId(String? fromMemberId) => _$this._fromMemberId = fromMemberId;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  bool? _recordedByAdmin;
  bool? get recordedByAdmin => _$this._recordedByAdmin;
  set recordedByAdmin(bool? recordedByAdmin) =>
      _$this._recordedByAdmin = recordedByAdmin;

  Date? _settledOn;
  Date? get settledOn => _$this._settledOn;
  set settledOn(Date? settledOn) => _$this._settledOn = settledOn;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _toMemberId;
  String? get toMemberId => _$this._toMemberId;
  set toMemberId(String? toMemberId) => _$this._toMemberId = toMemberId;

  SettlementViewBuilder() {
    SettlementView._defaults(this);
  }

  SettlementViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amountMinor = $v.amountMinor;
      _cancelledAt = $v.cancelledAt;
      _confirmedAt = $v.confirmedAt;
      _createdAt = $v.createdAt;
      _createdByMemberId = $v.createdByMemberId;
      _declaredAt = $v.declaredAt;
      _disputedAt = $v.disputedAt;
      _fromMemberId = $v.fromMemberId;
      _groupId = $v.groupId;
      _id = $v.id;
      _note = $v.note;
      _recordedByAdmin = $v.recordedByAdmin;
      _settledOn = $v.settledOn;
      _status = $v.status;
      _toMemberId = $v.toMemberId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SettlementView other) {
    _$v = other as _$SettlementView;
  }

  @override
  void update(void Function(SettlementViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SettlementView build() => _build();

  _$SettlementView _build() {
    final _$result = _$v ??
        _$SettlementView._(
          amountMinor: BuiltValueNullFieldError.checkNotNull(
              amountMinor, r'SettlementView', 'amountMinor'),
          cancelledAt: cancelledAt,
          confirmedAt: confirmedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'SettlementView', 'createdAt'),
          createdByMemberId: createdByMemberId,
          declaredAt: BuiltValueNullFieldError.checkNotNull(
              declaredAt, r'SettlementView', 'declaredAt'),
          disputedAt: disputedAt,
          fromMemberId: BuiltValueNullFieldError.checkNotNull(
              fromMemberId, r'SettlementView', 'fromMemberId'),
          groupId: BuiltValueNullFieldError.checkNotNull(
              groupId, r'SettlementView', 'groupId'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'SettlementView', 'id'),
          note: note,
          recordedByAdmin: BuiltValueNullFieldError.checkNotNull(
              recordedByAdmin, r'SettlementView', 'recordedByAdmin'),
          settledOn: BuiltValueNullFieldError.checkNotNull(
              settledOn, r'SettlementView', 'settledOn'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'SettlementView', 'status'),
          toMemberId: BuiltValueNullFieldError.checkNotNull(
              toMemberId, r'SettlementView', 'toMemberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
