/// The three reminder tones for WhatsApp messages (SA9, STANDALONE_SPEC 12).
enum ReminderTone {
  soft('SOFT'),
  firm('FIRM'),
  funny('FUNNY');

  const ReminderTone(this.dbValue);

  final String dbValue;

  static ReminderTone fromDb(String? value) => switch (value) {
        'FIRM' => ReminderTone.firm,
        'FUNNY' => ReminderTone.funny,
        _ => ReminderTone.soft,
      };
}
