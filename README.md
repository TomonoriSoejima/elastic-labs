# Elastic Labs

Testing and experimentation environments for Elastic products, organized by product area.

## Structure

```
apm/          - APM instrumentation across multiple languages (11 labs)
kibana/       - Kibana features and testing (1 lab)
logstash/     - Logstash configurations and edge cases (1 lab)
```

## APM Labs (apm/)

**Multi-Language Tools**
- `oneclick-repro/` - One-click APM reproduction environment with UI (all languages)

**Python**
- `python-frameworks/` - APM with various Python frameworks

**Go**
- `go-debug-logging/` - APM debug logging configuration

**Java**
- `java-kubernetes/` - Kubernetes APM with cgroup parsing
- `java-cgroup-bug/` - Bug reproduction for cgroup detection
- `java-opentelemetry/` - Elastic Distribution of OpenTelemetry
- `java-tracing/` - Trace testing and validation

**Node.js**
- `nextjs-apm/` - Next.js with APM instrumentation
- `nodejs-restify/` - Restify framework with APM
- `nodejs-mysql/` - Full-stack Node.js + MySQL + APM
- `nodejs-sqlite/` - Containerized Node.js + SQLite + APM

## Kibana Labs (kibana/)

- `alerts/` - Alerting features and testing

## Logstash Labs (logstash/)

- `nanoseconds/` - Nanosecond timestamp precision testing

## Getting Started

Each lab has its own README with:
- Purpose and description
- Setup instructions
- Run commands
- Configuration notes

Navigate to any lab directory for specific instructions.

## Prerequisites

- **Docker & Docker Compose** - Required for most labs
- **Node.js 18+** - For Node.js labs
- **Python 3.8+** - For Python labs
- **Java 17+** - For Java labs
- **Go 1.19+** - For Go labs
- **kubectl** - For Kubernetes labs

## Notes

- JAR files, node_modules, and build artifacts are gitignored
- Download required agents from elastic.co or Maven Central
- Each lab is self-contained and can run independently
