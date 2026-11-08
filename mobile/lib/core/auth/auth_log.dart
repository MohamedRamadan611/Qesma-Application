import 'package:flutter/foundation.dart';

/// Things worth knowing about the session, as a closed set of events.
enum AuthEvent {
  restoreStart,
  restoreOk,
  restoreSignedOut,
  restoreOffline,
  refreshStart,
  refreshOk,
  refreshFailed,
  signInStart,
  signInOk,
  signInCancelled,
  signInFailed,
  signOut,
  sessionEnded,
}

/// Structured, secret-free logging for the session.
///
/// The signature is the safeguard: an event, an optional enum value and an optional HTTP
/// status. There is deliberately no free-text parameter, so a token, e-mail address, name
/// or response body cannot be passed in by mistake (SCREEN_MAP rule 9).
abstract interface class AuthLog {
  void event(AuthEvent event, {Enum? kind, int? status});
}

/// The only line format used anywhere: `auth.<event> kind=<name> status=<code>`.
String formatAuthEvent(AuthEvent event, {Enum? kind, int? status}) {
  final buffer = StringBuffer('auth.${event.name}');
  if (kind != null) buffer.write(' kind=${kind.name}');
  if (status != null) buffer.write(' status=$status');
  return buffer.toString();
}

/// Prints in debug builds only; release builds log nothing.
class DebugAuthLog implements AuthLog {
  const DebugAuthLog();

  @override
  void event(AuthEvent event, {Enum? kind, int? status}) {
    if (kDebugMode) debugPrint(formatAuthEvent(event, kind: kind, status: status));
  }
}

/// Collects formatted lines, for tests.
class RecordingAuthLog implements AuthLog {
  final List<String> lines = [];

  @override
  void event(AuthEvent event, {Enum? kind, int? status}) =>
      lines.add(formatAuthEvent(event, kind: kind, status: status));
}
