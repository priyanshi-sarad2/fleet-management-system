# ---------- Stage 1: build ----------
FROM maven:3.6.3-jdk-8-slim AS build
WORKDIR /app

# Copy only the pom first and pre-download dependencies.
# This layer is cached and only re-runs when pom.xml changes — so
# normal code changes don't re-download every dependency again.
COPY pom.xml ./
RUN mvn -q -B dependency:go-offline

# Now copy the source and build the jar (tests skipped for the image build)
COPY src ./src
RUN mvn -q -B -DskipTests package

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:8-jre-alpine
LABEL org.opencontainers.image.authors="Priyanshi Sarad <itspriyanshisarad@gmail.com>"

# Run as a non-root user (security best practice)
RUN addgroup -S app && adduser -S app -G app
USER app

WORKDIR /app
# Copy only the built jar out of the build stage -> small final image
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
