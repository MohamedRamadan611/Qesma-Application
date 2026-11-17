/// Internal helpers shared by the engine files. Not exported.
library;

/// Indices of [items] ordered by [key], ties kept in input order: the same result as Java's stable
/// `List.sort(Comparator.comparingInt(...))`. Dart's `List.sort` is not stable, so the index is the
/// final tie-break.
List<T> stableSortedBy<T>(List<T> items, int Function(T) key) {
  final order = List<int>.generate(items.length, (i) => i)
    ..sort((a, b) {
      final c = key(items[a]).compareTo(key(items[b]));
      return c != 0 ? c : a.compareTo(b);
    });
  return [for (final i in order) items[i]];
}

bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
