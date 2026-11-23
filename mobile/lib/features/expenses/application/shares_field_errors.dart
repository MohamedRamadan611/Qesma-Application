import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';

/// What is wrong with one person's row or with the billing period (SA19). The editor shows its own localized text per
/// kind; the server's English message is never shown.
enum SharesErrorKind { units, presence, period }

/// The field errors of a shares split, from the server's validation problems.
class SharesFieldErrors {
  const SharesFieldErrors({this.byMember = const {}, this.period = false});

  static const SharesFieldErrors none = SharesFieldErrors();

  /// Member id -> what is wrong with that person's row.
  final Map<String, SharesErrorKind> byMember;

  /// The billing period itself is wrong.
  final bool period;

  bool get isEmpty => byMember.isEmpty && !period;
}

/// Reads the first shares field named by any of [failures] (the last save, the split preview). Index `i` of a
/// `shareParticipants[i]` path is the i-th person in [participantIds], which is the order the request builder sent.
SharesFieldErrors sharesFieldErrorsOf(Iterable<ApiFailure?> failures, List<String> participantIds) {
  var byMember = <String, SharesErrorKind>{};
  var period = false;
  for (final failure in failures) {
    final path = failure is ApiHttpFailure ? failure.problem?.fieldPath : null;
    if (path == null) continue;
    if (path.isPeriod) {
      period = true;
      continue;
    }
    final index = path.index;
    if (index == null || index < 0 || index >= participantIds.length) continue;
    final kind = path.field == SharesField.shareUnits ? SharesErrorKind.units : SharesErrorKind.presence;
    byMember = {...byMember, participantIds[index]: kind};
  }
  return SharesFieldErrors(byMember: byMember, period: period);
}
