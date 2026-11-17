import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../local/backup/backup_format.dart';

/// The two system dialogs backup needs: the share sheet and the file picker. A seam so the flows can be tested
/// without a platform.
abstract class BackupFileGateway {
  /// Hands the backup [bytes] to the share sheet as `qesma-backup-v1.json` with [text]. The file lives in the temporary
  /// directory only while the sheet is open and is always deleted. False when the user dismissed the sheet.
  Future<bool> share(Uint8List bytes, String text);

  /// The bytes of the file the user picks; null when they cancel. Throws [BackupException] (`tooLarge`) before
  /// reading a file above the size cap.
  Future<List<int>?> pick();
}

final class SystemBackupFileGateway implements BackupFileGateway {
  const SystemBackupFileGateway();

  @override
  Future<bool> share(Uint8List bytes, String text) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$backupFileName');
    try {
      await file.writeAsBytes(bytes, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(text: text, files: [XFile(file.path, mimeType: 'application/json', name: backupFileName)]),
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // The system clears the temp directory; a failed delete must not fail the export.
      }
    }
  }

  @override
  Future<List<int>?> pick() async {
    final picked = await FilePicker.pickFile(dialogTitle: null, type: FileType.any);
    if (picked == null) return null;
    final size = await picked.length();
    if (size != null && size > maxBackupBytes) throw const BackupException(BackupError.tooLarge);
    return picked.readAsBytes();
  }
}

final backupFileGatewayProvider = Provider<BackupFileGateway>((ref) => const SystemBackupFileGateway());
