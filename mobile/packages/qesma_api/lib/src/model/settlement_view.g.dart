// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SettlementView extends SettlementView {
  @override
  final int amountMinor;
  @override
  final DateTime createdAt;
  @override
  final String fromMemberId;
  @override
  final String groupId;
  @override
  final String id;
  @override
  final String? note;
  @override
  final Date settledOn;
  @override
  final String toMemberId;

  factory _$SettlementView([void Function(SettlementViewBuilder)? updates]) =>
      (SettlementViewBuilder()..update(updates))._build();

  _$SettlementView._(
      {required this.amountMinor,
      required this.createdAt,
      required this.fromMemberId,
      required this.groupId,
      required this.id,
      this.note,
      required this.settledOn,
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
        createdAt == other.createdAt &&
        fromMemberId == other.fromMemberId &&
        groupId == other.groupId &&
        id == other.id &&
        note == other.note &&
        settledOn == other.settledOn &&
        toMemberId == other.toMemberId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amountMinor.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, fromMemberId.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, settledOn.hashCode);
    _$hash = $jc(_$hash, toMemberId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SettlementView')
          ..add('amountMinor', amountMinor)
          ..add('createdAt', createdAt)
          ..add('fromMemberId', fromMemberId)
          ..add('groupId', groupId)
          ..add('id', id)
          ..add('note', note)
          ..add('settledOn', settledOn)
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

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

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

  Date? _settledOn;
  Date? get settledOn => _$this._settledOn;
  set settledOn(Date? settledOn) => _$this._settledOn = settledOn;

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
      _createdAt = $v.createdAt;
      _fromMemberId = $v.fromMemberId;
      _groupId = $v.groupId;
      _id = $v.id;
      _note = $v.note;
      _settledOn = $v.settledOn;
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
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'SettlementView', 'createdAt'),
          fromMemberId: BuiltValueNullFieldError.checkNotNull(
              fromMemberId, r'SettlementView', 'fromMemberId'),
          groupId: BuiltValueNullFieldError.checkNotNull(
              groupId, r'SettlementView', 'groupId'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'SettlementView', 'id'),
          note: note,
          settledOn: BuiltValueNullFieldError.checkNotNull(
              settledOn, r'SettlementView', 'settledOn'),
          toMemberId: BuiltValueNullFieldError.checkNotNull(
              toMemberId, r'SettlementView', 'toMemberId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
