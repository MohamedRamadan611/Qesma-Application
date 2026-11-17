import 'package:flutter/foundation.dart';

/// Where the local backend reports an unexpected failure (a 500). It receives ids and types only, never a body, a
/// name, an amount or a stack trace (invariant 10).
typedef LocalFailureLog = void Function(LocalFailure failure);

/// One unexpected failure: the request id echoed in `x-request-id` and the Problem body, the method, the route
/// template (no ids) and the error's type.
final class LocalFailure {
  const LocalFailure({required this.requestId, required this.method, required this.route, required this.errorType});
  final String requestId;
  final String method;
  final String route;
  final String errorType;

  @override
  String toString() => 'local-backend 500 requestId=$requestId $method $route $errorType';
}

/// The default sink: debug builds only, like the request logger in `dio_factory.dart`.
void debugLocalFailureLog(LocalFailure failure) {
  if (kDebugMode) debugPrint(failure.toString());
}
