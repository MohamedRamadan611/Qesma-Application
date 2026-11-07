package app.qesma.security;

/**
 * What we accept from a verified Google ID token. {@code email} is non-null only when Google marks it
 * verified; {@code displayName} may be null.
 */
public record GoogleIdentity(String subject, String email, String displayName) {
}
