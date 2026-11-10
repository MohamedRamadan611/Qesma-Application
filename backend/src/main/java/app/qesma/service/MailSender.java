package app.qesma.service;

/**
 * Sends the two emails of password accounts. An interface on purpose (ADR-007): no mail provider is chosen yet, so
 * production uses {@link NoopMailSender}; a real SMTP implementation arrives with its own ADR. Implementations must never
 * log the link (it is a credential) except the development-only console sender.
 */
public interface MailSender {

    /** "Confirm your email address": [link] proves control of the address. */
    void sendVerification(String to, String link);

    /** "Reset your password": [link] lets the holder choose a new password once. */
    void sendPasswordReset(String to, String link);
}
