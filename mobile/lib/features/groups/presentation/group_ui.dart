import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/widgets.dart';

/// Short message for a failed change, from the shared error copy (never server text).
void showFailureSnack(BuildContext context, ApiFailure failure, {String? memberName}) {
  final l10n = AppLocalizations.of(context);
  showAppSnackBar(context, errorCopyFor(l10n, failure, memberName: memberName).message);
}

/// Back arrow behaviour that also works when the screen was opened with `go` (no stack).
void goBackOr(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// "N members" with the singular form, Western digits.
String memberCountText(AppLocalizations l10n, int count) => count == 1 ? l10n.groupMemberOne : l10n.groupMemberCount('$count');
