# syntax=docker/dockerfile:1
# Build context is the repository root; the app source lives in ./app (see scripts/fetch-app.sh).

# ---- Stage 1: build the Spring Boot jar ------------------------------------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY app/backend/pom.xml .
COPY app/backend/src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q clean package -DskipTests

# ---- Stage 2: small runtime image, non-root --------------------------------
FROM eclipse-temurin:17-jre
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"
RUN useradd --system --uid 10001 --no-create-home appuser
WORKDIR /app
COPY --from=build /src/target/student-registration-backend-0.0.1-SNAPSHOT.jar app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
