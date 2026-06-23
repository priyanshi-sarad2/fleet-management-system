# ---------- Stage 1: build ----------
# Use the ECR Public mirror of the Docker Official Image (same maven:3.9-eclipse-temurin-21)
# to avoid Docker Hub anonymous pull rate limits in CodeBuild.
FROM public.ecr.aws/docker/library/maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy only the pom first and pre-download dependencies (cached layer).
COPY pom.xml ./
RUN mvn -q -B dependency:go-offline

# Build the jar (tests skipped for the image build)
COPY src ./src
RUN mvn -q -B -DskipTests package

# ---------- Stage 2: runtime ----------
# ECR Public mirror of the Docker Official Image (same eclipse-temurin:21-jre-alpine).
FROM public.ecr.aws/docker/library/eclipse-temurin:21-jre-alpine
LABEL org.opencontainers.image.authors="Priyanshi Sarad <itspriyanshisarad@gmail.com>"

# Create a non-root user/group and an app dir it owns (security best practice)
RUN addgroup -S app && adduser -S app -G app \
    && mkdir -p /app && chown app:app /app

WORKDIR /app
# Copy the jar out of the build stage and give ownership to the app user
COPY --chown=app:app --from=build /app/target/*.jar app.jar

USER app

# No ports are exposed — the simulator only sends messages to the queue.
ENTRYPOINT ["java", "-jar", "app.jar"]
