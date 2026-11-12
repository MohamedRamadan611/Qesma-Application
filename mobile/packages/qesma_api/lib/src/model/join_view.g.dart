// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JoinView extends JoinView {
  @override
  final String? groupId;
  @override
  final JoinedMember? member;
  @override
  final String? requestId;
  @override
  final String? status;

  factory _$JoinView([void Function(JoinViewBuilder)? updates]) =>
      (JoinViewBuilder()..update(updates))._build();

  _$JoinView._({this.groupId, this.member, this.requestId, this.status})
      : super._();
  @override
  JoinView rebuild(void Function(JoinViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JoinViewBuilder toBuilder() => JoinViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JoinView &&
        groupId == other.groupId &&
        member == other.member &&
        requestId == other.requestId &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, member.hashCode);
    _$hash = $jc(_$hash, requestId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JoinView')
          ..add('groupId', groupId)
          ..add('member', member)
          ..add('requestId', requestId)
          ..add('status', status))
        .toString();
  }
}

class JoinViewBuilder implements Builder<JoinView, JoinViewBuilder> {
  _$JoinView? _$v;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  JoinedMemberBuilder? _member;
  JoinedMemberBuilder get member => _$this._member ??= JoinedMemberBuilder();
  set member(JoinedMemberBuilder? member) => _$this._member = member;

  String? _requestId;
  String? get requestId => _$this._requestId;
  set requestId(String? requestId) => _$this._requestId = requestId;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  JoinViewBuilder() {
    JoinView._defaults(this);
  }

  JoinViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _groupId = $v.groupId;
      _member = $v.member?.toBuilder();
      _requestId = $v.requestId;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JoinView other) {
    _$v = other as _$JoinView;
  }

  @override
  void update(void Function(JoinViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JoinView build() => _build();

  _$JoinView _build() {
    _$JoinView _$result;
    try {
      _$result = _$v ??
          _$JoinView._(
            groupId: groupId,
            member: _member?.build(),
            requestId: requestId,
            status: status,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'member';
        _member?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'JoinView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
