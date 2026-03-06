FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml ./
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/java-worker-0.0.1-SNAPSHOT.jar ./app.jar
EXPOSE 3002
CMD ["java", "-jar", "/app/app.jar"]
