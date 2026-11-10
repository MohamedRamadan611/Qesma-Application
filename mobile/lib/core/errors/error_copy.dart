import '../l10n/generated/app_localizations.dart';
import 'api_failure.dart';
import 'api_problem.dart';

/// User-facing copy for a failure. [title] is set for dialogs that need one (blocked
/// deletes, conflicts); [message] is always set. Never contains the server's English text.
class ErrorCopy {
  const ErrorCopy({required this.message, this.title});

  final String? title;
  final String message;
}

/// Maps a failure to localized copy (SCREEN_MAP section 7).
///
/// [memberName] is used by DUPLICATE_MEMBER_NAME to quote the rejected name.
/// The `switch` statements are exhaustive: a new [ApiErrorCode] or [ApiFailure] subtype
/// does not compile until it has copy.
ErrorCopy errorCopyFor(AppLocalizations l10n, ApiFailure failure, {String? memberName}) {
  return switch (failure) {
    ApiTimeout() => ErrorCopy(message: l10n.errorTimeout),
    ApiNoConnection() => ErrorCopy(title: l10n.stateNoInternetTitle, message: l10n.errorNoConnection),
    ApiCancelled() || ApiUnexpected() => ErrorCopy(message: l10n.errorUnexpected),
    ApiHttpFailure(:final problem, :final status) => problem == null
        ? ErrorCopy(message: status >= 500 ? l10n.errorInternal : l10n.errorUnexpected)
        : _forCode(l10n, problem.code, memberName),
  };
}

ErrorCopy _forCode(AppLocalizations l10n, ApiErrorCode code, String? memberName) {
  return switch (code) {
    ApiErrorCode.validationError => ErrorCopy(message: l10n.errorValidation),
    ApiErrorCode.payersTotalMismatch => ErrorCopy(message: l10n.errorPayersTotalMismatch),
    ApiErrorCode.splitTotalMismatch => ErrorCopy(message: l10n.errorSplitTotalMismatch),
    ApiErrorCode.memberNotInGroup => ErrorCopy(message: l10n.errorMemberNotInGroup),
    // A client bug (SCREEN_MAP): the caller retries once with a new key, otherwise generic.
    ApiErrorCode.idempotencyKeyReused => ErrorCopy(message: l10n.errorUnexpected),
    ApiErrorCode.duplicateMemberName => ErrorCopy(message: l10n.errorDuplicateMemberName(memberName ?? '')),
    ApiErrorCode.memberHasTransactions => ErrorCopy(
        title: l10n.errorMemberHasTransactionsTitle,
        message: l10n.errorMemberHasTransactionsMessage,
      ),
    ApiErrorCode.ownerMemberProtected => ErrorCopy(
        title: l10n.errorOwnerMemberProtectedTitle,
        message: l10n.errorOwnerMemberProtectedMessage,
      ),
    ApiErrorCode.versionConflict => ErrorCopy(
        title: l10n.errorVersionConflictTitle,
        message: l10n.errorVersionConflictMessage,
      ),
    ApiErrorCode.groupNotEmpty => ErrorCopy(
        title: l10n.errorGroupNotEmptyTitle,
        message: l10n.errorGroupNotEmptyMessage,
      ),
    ApiErrorCode.notFound => ErrorCopy(message: l10n.errorNotFound),
    ApiErrorCode.unauthorized => ErrorCopy(message: l10n.errorUnauthorized),
    ApiErrorCode.internalError => ErrorCopy(message: l10n.errorInternal),
    ApiErrorCode.rateLimited => ErrorCopy(message: l10n.errorRateLimited),
    ApiErrorCode.authProviderUnavailable => ErrorCopy(message: l10n.errorAuthProviderUnavailable),
    ApiErrorCode.usernameTaken => ErrorCopy(message: l10n.authErrorUsernameTaken),
    ApiErrorCode.unknown => ErrorCopy(message: l10n.errorUnexpected),
  };
}
