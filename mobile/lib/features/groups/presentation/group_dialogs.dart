import 'package:flutter/material.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/widgets.dart';

/// Which error code a failure carries, if any.
ApiErrorCode? codeOf(ApiFailure failure) => failure is ApiHttpFailure ? failure.problem?.code : null;

/// "Someone changed this" dialog. Returns true when the user wants the latest version loaded
/// (their typed input stays in the form either way).
Future<bool> showConflictDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final copy = errorCopyFor(
    l10n,
    const ApiHttpFailure(status: 409, problem: ApiProblem(code: ApiErrorCode.versionConflict, status: 409)),
  );
  return showConfirmDialog(
    context,
    title: copy.title ?? l10n.errorVersionConflictTitle,
    message: copy.message,
    confirmLabel: l10n.groupConflictReload,
    cancelLabel: l10n.groupConflictKeep,
  );
}

/// Blocked-action dialog from a failure (blocked deletes, owner member protected).
Future<void> showBlockedFor(BuildContext context, ApiFailure failure, {String? extra}) {
  final l10n = AppLocalizations.of(context);
  final copy = errorCopyFor(l10n, failure);
  return showBlockedDialog(
    context,
    title: copy.title ?? l10n.stateErrorTitle,
    message: extra == null ? copy.message : '${copy.message}\n$extra',
  );
}
