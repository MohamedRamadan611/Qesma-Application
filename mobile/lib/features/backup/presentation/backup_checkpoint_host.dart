import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../local/backup/backup_service.dart';

/// Folds the SQLite write-ahead log into the main database file whenever the app goes to the background, so the one
/// file Android auto-backup copies is complete (A157, SA5). Local mode only (the caller decides).
class BackupCheckpointHost extends ConsumerStatefulWidget {
  const BackupCheckpointHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BackupCheckpointHost> createState() => _BackupCheckpointHostState();
}

class _BackupCheckpointHostState extends ConsumerState<BackupCheckpointHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused && state != AppLifecycleState.detached) return;
    // Best effort: a failed checkpoint only means the next one folds more pages; the data itself is safe in the WAL.
    ref.read(backupServiceProvider).checkpoint().ignore();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
