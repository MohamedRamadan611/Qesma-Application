package app.qesma.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import app.qesma.api.ApiException;
import org.junit.jupiter.api.Test;

class EmailRulesTest {

    @Test
    void addressesAreTrimmedAndLowerCased() {
        assertThat(EmailRules.normalize("  Ali.Hassan@Example.COM ")).isEqualTo("ali.hassan@example.com");
        assertThat(EmailRules.normalize("a+tag@sub.example.co.uk")).isEqualTo("a+tag@sub.example.co.uk");
    }

    @Test
    void thingsThatAreNotAddressesAreRefused() {
        for (String bad : new String[] {"", " ", "plain", "a@b", "a@@b.com", "a b@c.com", "@c.com", "a@.com", "a@c..com", null}) {
            assertThatThrownBy(() -> EmailRules.normalize(bad)).as("[" + bad + "]").isInstanceOf(ApiException.class);
            assertThat(EmailRules.normalizeOrNull(bad)).as("[" + bad + "]").isNull();
        }
        assertThatThrownBy(() -> EmailRules.normalize("a".repeat(65) + "@example.com")).as("local part over 64").isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> EmailRules.normalize("a@" + "b".repeat(250) + ".com")).as("over 254").isInstanceOf(ApiException.class);
    }
}
