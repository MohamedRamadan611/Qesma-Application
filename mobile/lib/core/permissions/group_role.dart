/// A member's role in a group (PHASE2_SPEC section 2). The server sends it as the string `yourRole`.
enum GroupRole {
  owner,
  admin,
  member;

  /// Reads the wire value. Anything unknown, empty or missing becomes [member]: the least privilege, so a newer
  /// server never makes an older app show a control the person may not use.
  static GroupRole parse(String? wire) => switch (wire) {
        'OWNER' => owner,
        'ADMIN' => admin,
        _ => member,
      };
}
