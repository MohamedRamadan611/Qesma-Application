package app.qesma;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class QesmaApplication {

    public static void main(String[] args) {
        SpringApplication.run(QesmaApplication.class, args);
    }
}
