import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions/group_role.dart';
import '../../../core/permissions/permissions.dart';
import 'group_detail_controller.dart';

/// The role of the signed-in person in one group, from the last read of the group. Until the group has
/// been read the role is unknown and [Permissions.unknown] (the least privilege) applies.
final groupPermissionsProvider = Provider.autoDispose.family<Permissions, String>((ref, gid) {
  final group = ref.watch(groupDetailControllerProvider(gid).select((s) => s.group));
  if (group == null) return const Permissions.unknown();
  return Permissions(GroupRole.parse(group.yourRole));
});
