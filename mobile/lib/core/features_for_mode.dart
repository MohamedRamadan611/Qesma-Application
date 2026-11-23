import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_mode.dart';

/// The one place that decides which screens, buttons and routes exist in a mode (STANDALONE_SPEC 2).
/// Local mode has one person and ghost members: everything about other people's accounts is absent from the widget
/// tree (not disabled). Widgets ask this class (or `Permissions`, which is built from it); they never test the mode.
class ModeFeatures {
  const ModeFeatures({
    required this.signIn,
    required this.signOut,
    required this.accountDeletion,
    required this.invites,
    required this.joinByCode,
    required this.joinRequests,
    required this.roleChips,
    required this.roleManagement,
    required this.leaveGroup,
    required this.transferOwnership,
    required this.settlementReview,
    required this.serverRemind,
    required this.notifications,
    required this.sessionExpiredDialog,
    required this.changePassword,
    required this.accountSettings,
    required this.backup,
    required this.myShare,
    required this.recap,
    required this.reminderTones,
    required this.pool,
    required this.budget,
    required this.calculator,
    required this.receiptScan,
    required this.archive,
  });

  /// Today's app: everything on (backup is a local-mode feature, SA5).
  static const ModeFeatures server = ModeFeatures(
    signIn: true,
    signOut: true,
    accountDeletion: true,
    invites: true,
    joinByCode: true,
    joinRequests: true,
    roleChips: true,
    roleManagement: true,
    leaveGroup: true,
    transferOwnership: true,
    settlementReview: true,
    serverRemind: true,
    notifications: true,
    sessionExpiredDialog: true,
    changePassword: true,
    accountSettings: true,
    backup: false,
    myShare: false,
    recap: false,
    reminderTones: false,
    pool: false,
    budget: false,
    calculator: false,
    receiptScan: false,
    archive: false,
  );

  /// The standalone release: every server-only feature off. `backup` (export, restore, reminder banner) is on: SA5.
  static const ModeFeatures local = ModeFeatures(
    signIn: false,
    signOut: false,
    accountDeletion: false,
    invites: false,
    joinByCode: false,
    joinRequests: false,
    roleChips: false,
    roleManagement: false,
    leaveGroup: false,
    transferOwnership: false,
    settlementReview: false,
    serverRemind: false,
    notifications: false,
    sessionExpiredDialog: false,
    changePassword: false,
    accountSettings: false,
    backup: true,
    myShare: true,
    recap: true,
    reminderTones: true,
    pool: true,
    budget: true,
    calculator: true,
    receiptScan: true,
    archive: true,
  );

  static ModeFeatures of(AppMode mode) => mode == AppMode.local ? local : server;

  final bool signIn;
  final bool signOut;
  final bool accountDeletion;
  final bool invites;
  final bool joinByCode;
  final bool joinRequests;
  final bool roleChips;
  final bool roleManagement;
  final bool leaveGroup;
  final bool transferOwnership;

  /// Confirm / dispute, the pending and disputed chips and the receiver card.
  final bool settlementReview;
  final bool serverRemind;
  final bool notifications;
  final bool sessionExpiredDialog;
  final bool changePassword;
  final bool accountSettings;
  final bool backup;
  final bool myShare;
  final bool recap;
  final bool reminderTones;

  /// SA10: pool & treasurer (edit-group section, pool card and screen, expense toggle). The breakdown comes from the
  /// local read-model, so it is a local-mode feature.
  final bool pool;

  /// SA20: trip budget (edit-group section, budget card and screen). Computed by the local read-model, so local mode only.
  final bool budget;

  /// SA11: the Khorouga calculator (fuel + tolls, multi-stop ride). It runs the local engine (A149), so it is a
  /// local-mode feature; its result only prefills the add-expense form.
  final bool calculator;

  /// SA12: scan a receipt photo into an unsaved itemized bill (Firebase AI Logic, consent first). Local mode only;
  /// whether it is usable right now (Firebase ready, not hidden) is decided at run time by `receiptScanVisibleProvider`.
  final bool receiptScan;

  /// A184: archive of settled groups (local mode only).
  final bool archive;
}

final modeFeaturesProvider = Provider<ModeFeatures>((ref) => ModeFeatures.of(ref.watch(appModeProvider)));
