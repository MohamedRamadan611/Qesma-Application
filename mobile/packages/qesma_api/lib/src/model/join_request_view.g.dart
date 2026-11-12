// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_request_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JoinRequestView extends JoinRequestView {
  @override
  final String? claimMemberId;
  @override
  final String? claimMemberName;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? decidedAt;
  @override
  final String? id;
  @override
  final String? newMemberName;
  @override
  final String? requesterName;
  @override
  final String? status;

  factory _$JoinRequestView([void Function(JoinRequestViewBuilder)? updates]) =>
      (JoinRequestViewBuilder()..update(updates))._build();

  _$JoinRequestView._(
      {this.claimMemberId,
      this.claimMemberName,
      this.createdAt,
      this.decidedAt,
      this.id,
      this.newMemberName,
      this.requesterName,
      this.status})
      : super._();
  @override
  JoinRequestView rebuild(void Function(JoinRequestViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JoinRequestViewBuilder toBuilder() => JoinRequestViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JoinRequestView &&
        claimMemberId == other.claimMemberId &&
        claimMemberName == other.claimMemberName &&
        createdAt == other.createdAt &&
        decidedAt == other.decidedAt &&
        id == other.id &&
        newMemberName == other.newMemberName &&
        requesterName == other.requesterName &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, claimMemberId.hashCode);
    _$hash = $jc(_$hash, claimMemberName.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, decidedAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, newMemberName.hashCode);
    _$hash = $jc(_$hash, requesterName.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JoinRequestView')
          ..add('claimMemberId', claimMemberId)
          ..add('claimMemberName', claimMemberName)
          ..add('createdAt', createdAt)
          ..add('decidedAt', decidedAt)
          ..add('id', id)
          ..add('newMemberName', newMemberName)
          ..add('requesterName', requesterName)
          ..add('status', status))
        .toString();
  }
}

class JoinRequestViewBuilder
    implements Builder<JoinRequestView, JoinRequestViewBuilder> {
  _$JoinRequestView? _$v;

  String? _claimMemberId;
  String? get claimMemberId => _$this._claimMemberId;
  set claimMemberId(String? claimMemberId) =>
      _$this._claimMemberId = claimMemberId;

  String? _claimMemberName;
  String? get claimMemberName => _$this._claimMemberName;
  set claimMemberName(String? claimMemberName) =>
      _$this._claimMemberName = claimMemberName;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _decidedAt;
  DateTime? get decidedAt => _$this._decidedAt;
  set decidedAt(DateTime? decidedAt) => _$this._decidedAt = decidedAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _newMemberName;
  String? get newMemberName => _$this._newMemberName;
  set newMemberName(String? newMemberName) =>
      _$this._newMemberName = newMemberName;

  String? _requesterName;
  String? get requesterName => _$this._requesterName;
  set requesterName(String? requesterName) =>
      _$this._requesterName = requesterName;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  JoinRequestViewBuilder() {
    JoinRequestView._defaults(this);
  }

  JoinRequestViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _claimMemberId = $v.claimMemberId;
      _claimMemberName = $v.claimMemberName;
      _createdAt = $v.createdAt;
      _decidedAt = $v.decidedAt;
      _id = $v.id;
      _newMemberName = $v.newMemberName;
      _requesterName = $v.requesterName;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JoinRequestView other) {
    _$v = other as _$JoinRequestView;
  }

  @override
  void update(void Function(JoinRequestViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JoinRequestView build() => _build();

  _$JoinRequestView _build() {
    final _$result = _$v ??
        _$JoinRequestView._(
          claimMemberId: claimMemberId,
          claimMemberName: claimMemberName,
          createdAt: createdAt,
          decidedAt: decidedAt,
          id: id,
          newMemberName: newMemberName,
          requesterName: requesterName,
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
