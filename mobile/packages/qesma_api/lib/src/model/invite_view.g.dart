// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InviteView extends InviteView {
  @override
  final String? code;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? expiresAt;
  @override
  final String? groupId;
  @override
  final String? id;
  @override
  final String? link;
  @override
  final int? maxUses;
  @override
  final bool? requiresApproval;
  @override
  final DateTime? revokedAt;
  @override
  final String? status;
  @override
  final int? useCount;

  factory _$InviteView([void Function(InviteViewBuilder)? updates]) =>
      (InviteViewBuilder()..update(updates))._build();

  _$InviteView._(
      {this.code,
      this.createdAt,
      this.expiresAt,
      this.groupId,
      this.id,
      this.link,
      this.maxUses,
      this.requiresApproval,
      this.revokedAt,
      this.status,
      this.useCount})
      : super._();
  @override
  InviteView rebuild(void Function(InviteViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InviteViewBuilder toBuilder() => InviteViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InviteView &&
        code == other.code &&
        createdAt == other.createdAt &&
        expiresAt == other.expiresAt &&
        groupId == other.groupId &&
        id == other.id &&
        link == other.link &&
        maxUses == other.maxUses &&
        requiresApproval == other.requiresApproval &&
        revokedAt == other.revokedAt &&
        status == other.status &&
        useCount == other.useCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, link.hashCode);
    _$hash = $jc(_$hash, maxUses.hashCode);
    _$hash = $jc(_$hash, requiresApproval.hashCode);
    _$hash = $jc(_$hash, revokedAt.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, useCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InviteView')
          ..add('code', code)
          ..add('createdAt', createdAt)
          ..add('expiresAt', expiresAt)
          ..add('groupId', groupId)
          ..add('id', id)
          ..add('link', link)
          ..add('maxUses', maxUses)
          ..add('requiresApproval', requiresApproval)
          ..add('revokedAt', revokedAt)
          ..add('status', status)
          ..add('useCount', useCount))
        .toString();
  }
}

class InviteViewBuilder implements Builder<InviteView, InviteViewBuilder> {
  _$InviteView? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _expiresAt;
  DateTime? get expiresAt => _$this._expiresAt;
  set expiresAt(DateTime? expiresAt) => _$this._expiresAt = expiresAt;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _link;
  String? get link => _$this._link;
  set link(String? link) => _$this._link = link;

  int? _maxUses;
  int? get maxUses => _$this._maxUses;
  set maxUses(int? maxUses) => _$this._maxUses = maxUses;

  bool? _requiresApproval;
  bool? get requiresApproval => _$this._requiresApproval;
  set requiresApproval(bool? requiresApproval) =>
      _$this._requiresApproval = requiresApproval;

  DateTime? _revokedAt;
  DateTime? get revokedAt => _$this._revokedAt;
  set revokedAt(DateTime? revokedAt) => _$this._revokedAt = revokedAt;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  int? _useCount;
  int? get useCount => _$this._useCount;
  set useCount(int? useCount) => _$this._useCount = useCount;

  InviteViewBuilder() {
    InviteView._defaults(this);
  }

  InviteViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _createdAt = $v.createdAt;
      _expiresAt = $v.expiresAt;
      _groupId = $v.groupId;
      _id = $v.id;
      _link = $v.link;
      _maxUses = $v.maxUses;
      _requiresApproval = $v.requiresApproval;
      _revokedAt = $v.revokedAt;
      _status = $v.status;
      _useCount = $v.useCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InviteView other) {
    _$v = other as _$InviteView;
  }

  @override
  void update(void Function(InviteViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InviteView build() => _build();

  _$InviteView _build() {
    final _$result = _$v ??
        _$InviteView._(
          code: code,
          createdAt: createdAt,
          expiresAt: expiresAt,
          groupId: groupId,
          id: id,
          link: link,
          maxUses: maxUses,
          requiresApproval: requiresApproval,
          revokedAt: revokedAt,
          status: status,
          useCount: useCount,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
