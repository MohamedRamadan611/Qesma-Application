# syntax=docker/dockerfile:1
FROM eclipse-temurin:25-jdk-alpine AS build
WORKDIR /workspace
COPY .mvn .mvn
COPY mvnw pom.xml ./
# mvnw may arrive with Windows (CRLF) line endings, which break the shebang inside Linux: normalize first.
RUN tr -d '\r' < mvnw > mvnw.lf && mv mvnw.lf mvnw && chmod +x mvnw && ./mvnw -B -q dependency:go-offline
COPY src src
RUN ./mvnw -B -q -DskipTests package \
 && java -Djarmode=layertools -jar target/*.jar extract --destination target/layers

FROM eclipse-temurin:25-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /workspace/target/layers/dependencies/ ./
COPY --from=build /workspace/target/layers/spring-boot-loader/ ./
COPY --from=build /workspace/target/layers/snapshot-dependencies/ ./
COPY --from=build /workspace/target/layers/application/ ./
USER app
EXPOSE 8080
ENV SPRING_PROFILES_ACTIVE=prod
# Sized for a small VPS shared with PostgreSQL and the proxy: heap is a share of the container limit, the process
# exits on OutOfMemoryError so the restart policy replaces it instead of leaving a half-dead JVM.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=65 -XX:+ExitOnOutOfMemoryError -Xss512k -Djava.security.egd=file:/dev/./urandom"
# Readiness (includes a real database check) on the internal management port; see application-prod.yml.
HEALTHCHECK --interval=15s --timeout=4s --start-period=60s --retries=5 \
  CMD wget -q -T 3 -O /dev/null http://127.0.0.1:8081/actuator/health/readiness || exit 1
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
