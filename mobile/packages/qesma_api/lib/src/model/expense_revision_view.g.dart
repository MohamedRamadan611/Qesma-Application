// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_revision_view.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpenseRevisionView extends ExpenseRevisionView {
  @override
  final String changeType;
  @override
  final DateTime changedAt;
  @override
  final String changedByUserId;
  @override
  final ExpenseView snapshot;
  @override
  final int version;

  factory _$ExpenseRevisionView(
          [void Function(ExpenseRevisionViewBuilder)? updates]) =>
      (ExpenseRevisionViewBuilder()..update(updates))._build();

  _$ExpenseRevisionView._(
      {required this.changeType,
      required this.changedAt,
      required this.changedByUserId,
      required this.snapshot,
      required this.version})
      : super._();
  @override
  ExpenseRevisionView rebuild(
          void Function(ExpenseRevisionViewBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpenseRevisionViewBuilder toBuilder() =>
      ExpenseRevisionViewBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpenseRevisionView &&
        changeType == other.changeType &&
        changedAt == other.changedAt &&
        changedByUserId == other.changedByUserId &&
        snapshot == other.snapshot &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, changeType.hashCode);
    _$hash = $jc(_$hash, changedAt.hashCode);
    _$hash = $jc(_$hash, changedByUserId.hashCode);
    _$hash = $jc(_$hash, snapshot.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpenseRevisionView')
          ..add('changeType', changeType)
          ..add('changedAt', changedAt)
          ..add('changedByUserId', changedByUserId)
          ..add('snapshot', snapshot)
          ..add('version', version))
        .toString();
  }
}

class ExpenseRevisionViewBuilder
    implements Builder<ExpenseRevisionView, ExpenseRevisionViewBuilder> {
  _$ExpenseRevisionView? _$v;

  String? _changeType;
  String? get changeType => _$this._changeType;
  set changeType(String? changeType) => _$this._changeType = changeType;

  DateTime? _changedAt;
  DateTime? get changedAt => _$this._changedAt;
  set changedAt(DateTime? changedAt) => _$this._changedAt = changedAt;

  String? _changedByUserId;
  String? get changedByUserId => _$this._changedByUserId;
  set changedByUserId(String? changedByUserId) =>
      _$this._changedByUserId = changedByUserId;

  ExpenseViewBuilder? _snapshot;
  ExpenseViewBuilder get snapshot => _$this._snapshot ??= ExpenseViewBuilder();
  set snapshot(ExpenseViewBuilder? snapshot) => _$this._snapshot = snapshot;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  ExpenseRevisionViewBuilder() {
    ExpenseRevisionView._defaults(this);
  }

  ExpenseRevisionViewBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _changeType = $v.changeType;
      _changedAt = $v.changedAt;
      _changedByUserId = $v.changedByUserId;
      _snapshot = $v.snapshot.toBuilder();
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpenseRevisionView other) {
    _$v = other as _$ExpenseRevisionView;
  }

  @override
  void update(void Function(ExpenseRevisionViewBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpenseRevisionView build() => _build();

  _$ExpenseRevisionView _build() {
    _$ExpenseRevisionView _$result;
    try {
      _$result = _$v ??
          _$ExpenseRevisionView._(
            changeType: BuiltValueNullFieldError.checkNotNull(
                changeType, r'ExpenseRevisionView', 'changeType'),
            changedAt: BuiltValueNullFieldError.checkNotNull(
                changedAt, r'ExpenseRevisionView', 'changedAt'),
            changedByUserId: BuiltValueNullFieldError.checkNotNull(
                changedByUserId, r'ExpenseRevisionView', 'changedByUserId'),
            snapshot: snapshot.build(),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'ExpenseRevisionView', 'version'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'snapshot';
        snapshot.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ExpenseRevisionView', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
