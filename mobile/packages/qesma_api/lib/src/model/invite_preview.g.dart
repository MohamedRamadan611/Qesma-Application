// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_preview.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InvitePreview extends InvitePreview {
  @override
  final String? callerState;
  @override
  final DateTime? expiresAt;
  @override
  final String? groupName;
  @override
  final String? groupType;
  @override
  final String? inviterName;
  @override
  final int? memberCount;
  @override
  final bool? requiresApproval;
  @override
  final BuiltList<Unclaimed>? unclaimedMembers;

  factory _$InvitePreview([void Function(InvitePreviewBuilder)? updates]) =>
      (InvitePreviewBuilder()..update(updates))._build();

  _$InvitePreview._(
      {this.callerState,
      this.expiresAt,
      this.groupName,
      this.groupType,
      this.inviterName,
      this.memberCount,
      this.requiresApproval,
      this.unclaimedMembers})
      : super._();
  @override
  InvitePreview rebuild(void Function(InvitePreviewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InvitePreviewBuilder toBuilder() => InvitePreviewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InvitePreview &&
        callerState == other.callerState &&
        expiresAt == other.expiresAt &&
        groupName == other.groupName &&
        groupType == other.groupType &&
        inviterName == other.inviterName &&
        memberCount == other.memberCount &&
        requiresApproval == other.requiresApproval &&
        unclaimedMembers == other.unclaimedMembers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, callerState.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, groupName.hashCode);
    _$hash = $jc(_$hash, groupType.hashCode);
    _$hash = $jc(_$hash, inviterName.hashCode);
    _$hash = $jc(_$hash, memberCount.hashCode);
    _$hash = $jc(_$hash, requiresApproval.hashCode);
    _$hash = $jc(_$hash, unclaimedMembers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InvitePreview')
          ..add('callerState', callerState)
          ..add('expiresAt', expiresAt)
          ..add('groupName', groupName)
          ..add('groupType', groupType)
          ..add('inviterName', inviterName)
          ..add('memberCount', memberCount)
          ..add('requiresApproval', requiresApproval)
          ..add('unclaimedMembers', unclaimedMembers))
        .toString();
  }
}

class InvitePreviewBuilder
    implements Builder<InvitePreview, InvitePreviewBuilder> {
  _$InvitePreview? _$v;

  String? _callerState;
  String? get callerState => _$this._callerState;
  set callerState(String? callerState) => _$this._callerState = callerState;

  DateTime? _expiresAt;
  DateTime? get expiresAt => _$this._expiresAt;
  set expiresAt(DateTime? expiresAt) => _$this._expiresAt = expiresAt;

  String? _groupName;
  String? get groupName => _$this._groupName;
  set groupName(String? groupName) => _$this._groupName = groupName;

  String? _groupType;
  String? get groupType => _$this._groupType;
  set groupType(String? groupType) => _$this._groupType = groupType;

  String? _inviterName;
  String? get inviterName => _$this._inviterName;
  set inviterName(String? inviterName) => _$this._inviterName = inviterName;

  int? _memberCount;
  int? get memberCount => _$this._memberCount;
  set memberCount(int? memberCount) => _$this._memberCount = memberCount;

  bool? _requiresApproval;
  bool? get requiresApproval => _$this._requiresApproval;
  set requiresApproval(bool? requiresApproval) =>
      _$this._requiresApproval = requiresApproval;

  ListBuilder<Unclaimed>? _unclaimedMembers;
  ListBuilder<Unclaimed> get unclaimedMembers =>
      _$this._unclaimedMembers ??= ListBuilder<Unclaimed>();
  set unclaimedMembers(ListBuilder<Unclaimed>? unclaimedMembers) =>
      _$this._unclaimedMembers = unclaimedMembers;

  InvitePreviewBuilder() {
    InvitePreview._defaults(this);
  }

  InvitePreviewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _callerState = $v.callerState;
      _expiresAt = $v.expiresAt;
      _groupName = $v.groupName;
      _groupType = $v.groupType;
      _inviterName = $v.inviterName;
      _memberCount = $v.memberCount;
      _requiresApproval = $v.requiresApproval;
      _unclaimedMembers = $v.unclaimedMembers?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InvitePreview other) {
    _$v = other as _$InvitePreview;
  }

  @override
  void update(void Function(InvitePreviewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InvitePreview build() => _build();

  _$InvitePreview _build() {
    _$InvitePreview _$result;
    try {
      _$result = _$v ??
          _$InvitePreview._(
            callerState: callerState,
            expiresAt: expiresAt,
            groupName: groupName,
            groupType: groupType,
            inviterName: inviterName,
            memberCount: memberCount,
            requiresApproval: requiresApproval,
            unclaimedMembers: _unclaimedMembers?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'unclaimedMembers';
        _unclaimedMembers?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'InvitePreview', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
