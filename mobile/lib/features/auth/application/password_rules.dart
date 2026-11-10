import 'dart:convert';

/// Client-side checks that only save a round trip; the server's rules are the real ones (username 3 to 30
/// characters; password 8 characters, at most 72 UTF-8 bytes, not a common password). Nothing here is a money rule.
abstract final class PasswordRules {
  static const int minCharacters = 8;
  static const int maxBytes = 72;

  /// 3 to 30 characters: letters (any script), digits, dots, hyphens, underscores; starts with a letter or digit, no "@".
  /// The server also refuses reserved names; this only saves a round trip.
  static bool usernameLooksValid(String raw) {
    final name = raw.trim();
    final length = name.runes.length;
    return length >= 3 && length <= 30 && RegExp(r'^[\p{L}\p{N}][\p{L}\p{N}._-]*$', unicode: true).hasMatch(name) && !name.endsWith('.');
  }

  static bool tooShort(String password) => password.runes.length < minCharacters;

  static bool tooLong(String password) => utf8.encode(password).length > maxBytes;
}
