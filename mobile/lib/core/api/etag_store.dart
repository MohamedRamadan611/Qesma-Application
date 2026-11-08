/// Remembers the version a resource had when it was last read, so edits and deletes can
/// send `If-Match` (SCREEN_MAP rule 7). The backend sends `ETag: "<version>"`.
class ETagStore {
  final Map<String, int> _versions = {};

  /// Extracts the integer version from an ETag header value (`"3"` or `W/"3"`).
  static int? parseVersion(String? header) {
    if (header == null) return null;
    final match = RegExp(r'^(?:W/)?"(\d{1,9})"$').firstMatch(header.trim());
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// The `If-Match` header value for [version].
  static String ifMatch(int version) => '"$version"';

  void remember(String id, String? etagHeader) {
    final version = parseVersion(etagHeader);
    if (version != null) _versions[id] = version;
  }

  int? versionOf(String id) => _versions[id];

  /// `If-Match` value for [id], or null if it was never read (the caller must read first).
  String? ifMatchFor(String id) {
    final v = _versions[id];
    return v == null ? null : ifMatch(v);
  }

  void forget(String id) => _versions.remove(id);
}
