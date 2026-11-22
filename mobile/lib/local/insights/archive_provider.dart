import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/groups/application/groups_list_controller.dart';
import '../db/local_database_provider.dart';
import '../service/archive_service.dart';
import '../service/local_context.dart';

final archiveServiceProvider = Provider<ArchiveService>((ref) => ArchiveService(LocalContext(ref.watch(localDatabaseProvider))));

/// The archived groups with the date each one is deleted. Invalidate after archive, restore or delete.
final archivedGroupsProvider = FutureProvider.autoDispose<List<ArchivedGroup>>((ref) => ref.watch(archiveServiceProvider).list());

/// The retention period in days (7, 15 or 30).
final archiveRetentionProvider = FutureProvider.autoDispose<int>((ref) => ref.watch(archiveServiceProvider).retentionDays());

/// Deletes the archived groups whose period is over (A184), once per app run, when the shell first builds. The groups
/// list is read again when something was deleted or restored.
final archivePurgeProvider = FutureProvider<int>((ref) async {
  final deleted = await ref.watch(archiveServiceProvider).purgeExpired();
  if (deleted > 0 && ref.mounted) ref.invalidate(groupsListControllerProvider);
  return deleted;
});
