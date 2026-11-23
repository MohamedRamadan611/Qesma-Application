// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_participant_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ShareParticipantInput extends ShareParticipantInput {
  @override
  final String memberId;
  @override
  final Date? presentFrom;
  @override
  final Date? presentTo;
  @override
  final int shareUnits;

  factory _$ShareParticipantInput(
          [void Function(ShareParticipantInputBuilder)? updates]) =>
      (ShareParticipantInputBuilder()..update(updates))._build();

  _$ShareParticipantInput._(
      {required this.memberId,
      this.presentFrom,
      this.presentTo,
      required this.shareUnits})
      : super._();
  @override
  ShareParticipantInput rebuild(
          void Function(ShareParticipantInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShareParticipantInputBuilder toBuilder() =>
      ShareParticipantInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShareParticipantInput &&
        memberId == other.memberId &&
        presentFrom == other.presentFrom &&
        presentTo == other.presentTo &&
        shareUnits == other.shareUnits;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, memberId.hashCode);
    _$hash = $jc(_$hash, presentFrom.hashCode);
    _$hash = $jc(_$hash, presentTo.hashCode);
    _$hash = $jc(_$hash, shareUnits.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShareParticipantInput')
          ..add('memberId', memberId)
          ..add('presentFrom', presentFrom)
          ..add('presentTo', presentTo)
          ..add('shareUnits', shareUnits))
        .toString();
  }
}

class ShareParticipantInputBuilder
    implements Builder<ShareParticipantInput, ShareParticipantInputBuilder> {
  _$ShareParticipantInput? _$v;

  String? _memberId;
  String? get memberId => _$this._memberId;
  set memberId(String? memberId) => _$this._memberId = memberId;

  Date? _presentFrom;
  Date? get presentFrom => _$this._presentFrom;
  set presentFrom(Date? presentFrom) => _$this._presentFrom = presentFrom;

  Date? _presentTo;
  Date? get presentTo => _$this._presentTo;
  set presentTo(Date? presentTo) => _$this._presentTo = presentTo;

  int? _shareUnits;
  int? get shareUnits => _$this._shareUnits;
  set shareUnits(int? shareUnits) => _$this._shareUnits = shareUnits;

  ShareParticipantInputBuilder() {
    ShareParticipantInput._defaults(this);
  }

  ShareParticipantInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _memberId = $v.memberId;
      _presentFrom = $v.presentFrom;
      _presentTo = $v.presentTo;
      _shareUnits = $v.shareUnits;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShareParticipantInput other) {
    _$v = other as _$ShareParticipantInput;
  }

  @override
  void update(void Function(ShareParticipantInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShareParticipantInput build() => _build();

  _$ShareParticipantInput _build() {
    final _$result = _$v ??
        _$ShareParticipantInput._(
          memberId: BuiltValueNullFieldError.checkNotNull(
              memberId, r'ShareParticipantInput', 'memberId'),
          presentFrom: presentFrom,
          presentTo: presentTo,
          shareUnits: BuiltValueNullFieldError.checkNotNull(
              shareUnits, r'ShareParticipantInput', 'shareUnits'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
