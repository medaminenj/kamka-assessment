# ===========================
# Stage 1 — Build
# ===========================
FROM maven:3.9-eclipse-temurin-17-alpine AS build
WORKDIR /app

# Copy pom first — better layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src ./src
RUN mvn clean package -DskipTests -q

# ===========================
# Stage 2 — Runtime (small image)
# ===========================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
