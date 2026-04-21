# ── Stage 1 : build ──────────────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Télécharger les dépendances en cache layer séparé
COPY pom.xml .
RUN mvn -B -ntp dependency:go-offline -q

COPY src ./src
RUN mvn -B -ntp package -DskipTests -q

# ── Stage 2 : runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r oklifor && useradd -r -g oklifor oklifor
USER oklifor

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8100

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-jar", "app.jar"]
