// ignore_for_file: prefer_initializing_formals (private fields cannot be named parameters)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'reminder_formatter.dart';

/// Abstract seam for launching WhatsApp reminders or falling back to system share sheet (SA9).
abstract class ReminderLauncher {
  Future<bool> launchWhatsApp(String message);
  Future<bool> shareFallback(String message);
  Future<bool> launchOrShare(String message);
}

typedef UrlOpener = Future<bool> Function(Uri uri);
typedef TextSharer = Future<bool> Function(String text);

Future<bool> _openExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

Future<bool> _shareText(String text) async {
  final result = await SharePlus.instance.share(ShareParams(text: text));
  return result.status != ShareResultStatus.dismissed;
}

final class SystemReminderLauncher implements ReminderLauncher {
  const SystemReminderLauncher({UrlOpener opener = _openExternal, TextSharer sharer = _shareText})
      : _opener = opener,
        _sharer = sharer;

  final UrlOpener _opener;
  final TextSharer _sharer;

  @override
  Future<bool> launchWhatsApp(String message) async {
    final uri = ReminderFormatter.buildWhatsAppUri(message);
    try {
      return await _opener(uri);
    } catch (error) {
      // The message holds names and amounts: nothing is logged; the caller reads false and offers the share fallback.
      return false;
    }
  }

  @override
  Future<bool> shareFallback(String message) async {
    try {
      return await _sharer(message);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> launchOrShare(String message) async {
    final launched = await launchWhatsApp(message);
    if (!launched) {
      return shareFallback(message);
    }
    return true;
  }
}

final reminderLauncherProvider = Provider<ReminderLauncher>((ref) {
  return const SystemReminderLauncher();
});
