import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "The server said 403 for this group": the role the app shows may be out of date.
class ForbiddenEvent {
  const ForbiddenEvent(this.gid, this.sequence);

  final String gid;

  /// Grows with every event, so two events for the same group are two different values.
  final int sequence;
}

/// The latest [ForbiddenEvent]. A listener in the groups feature reloads that group (and so the role and the
/// buttons that depend on it); nothing here knows about screens or controllers.
class ForbiddenEvents extends Notifier<ForbiddenEvent?> {
  int _sequence = 0;

  @override
  ForbiddenEvent? build() => null;

  void report(String gid) => state = ForbiddenEvent(gid, ++_sequence);
}

final forbiddenEventsProvider = NotifierProvider<ForbiddenEvents, ForbiddenEvent?>(ForbiddenEvents.new);

final RegExp _groupPath = RegExp(r'/groups/([^/?#]+)(?=[/?#]|$)');

/// The group id in a request path like `/api/v1/groups/{gid}/expenses`, or null.
String? groupIdOfPath(String path) => _groupPath.firstMatch(path)?.group(1);

/// Reports a group-scoped `403` so the screens can correct themselves. It never changes the failure: the
/// caller still gets the same error and shows the same message.
class ForbiddenRefreshInterceptor extends Interceptor {
  ForbiddenRefreshInterceptor(this._onForbidden);

  final void Function(String gid) _onForbidden;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 403) {
      final gid = groupIdOfPath(err.requestOptions.uri.path);
      if (gid != null) _onForbidden(gid);
    }
    handler.next(err);
  }
}
