/// The one normalizer behind `members.name_key` (UNIQUE per group, decision A152).
///
/// SQLite `lower()` is ASCII-only, so the key is computed here and stored. Rule (owner decision, SA2):
/// trim, collapse every run of whitespace (tabs, NBSP and other Unicode spaces included) to one space, then
/// Unicode lower case. Arabic letters, hamza forms and diacritics are left as typed.
String memberNameKey(String displayName) =>
    displayName.trim().replaceAll(_whitespaceRun, ' ').toLowerCase();

final _whitespaceRun = RegExp(r'\s+', unicode: true);
