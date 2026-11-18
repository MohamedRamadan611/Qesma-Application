import '../values.dart';

/// [members] ordered by sortOrder, then id, so the result never depends on the input order.
List<MemberRef> sortedMembers(List<MemberRef> members) => [...members]..sort((a, b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
