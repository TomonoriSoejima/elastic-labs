# Elastic Distribution of OpenTelemetry (EDOT) - Java

Testing Elastic's OpenTelemetry Java distribution with Spring Boot applications.

## Purpose

Evaluate EDOT Java agent with Spring Boot Petclinic application.

## Structure

```
edot_java/
  - Spring Boot application
  - EDOT Java agent configuration
```

## Setup

Download EDOT Java agent:
```bash
cd edot_java
# Download from elastic.co/downloads
# elastic-otel-javaagent-{version}.jar
```

Download Spring Petclinic (optional):
```bash
git clone https://github.com/spring-projects/spring-petclinic.git
cd spring-petclinic
./mvnw package
```

## Run

```bash
cd edot_java
java -javaagent:elastic-otel-javaagent-{version}.jar \
     -jar spring-petclinic-*.jar
```

## Notes

- Requires JDK 17+
- Compare EDOT vs vanilla APM agent behavior
- Spring Boot Petclinic JAR can be rebuilt from source
