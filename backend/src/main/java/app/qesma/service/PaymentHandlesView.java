package app.qesma.service;

/**
 * A user's payment handles (B14). Either field is null when not set. Personal data (PDPL): the record never prints its
 * values, so a log line or an exception message cannot leak them (A51 style, A92).
 */
public record PaymentHandlesView(String instapay, String wallet) {

    @Override
    public String toString() {
        return "PaymentHandlesView[***]";
    }
}
