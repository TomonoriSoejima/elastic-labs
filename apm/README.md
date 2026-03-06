# APM Labs

Testing and experimentation environments for Elastic APM across multiple languages and frameworks.

## Labs by Type

### Multi-Language Tools (1)
- `oneclick-repro/` - **One-click APM reproduction environment** (Python, Java, Go, Node.js) with UI for deployment selection and traffic generation

## Labs by Language

### Python (1)
- `python-frameworks/` - APM with various Python frameworks

### Go (1)
- `go-debug-logging/` - APM debug logging configuration

### Java (4)
- `java-kubernetes/` - Kubernetes APM with cgroup parsing
- `java-cgroup-bug/` - Bug reproduction for cgroup detection
- `java-opentelemetry/` - Elastic Distribution of OpenTelemetry (EDOT)
- `java-tracing/` - Trace testing and validation

### Node.js (4)
- `nextjs-apm/` - Next.js with APM instrumentation
- `nodejs-restify/` - Restify framework with APM
- `nodejs-mysql/` - Full-stack Node.js + MySQL + APM
- `nodejs-sqlite/` - Containerized Node.js + SQLite + APM

## Getting Started

Each lab directory contains:
- README.md with setup and run instructions
- Source code and configuration files
- Scripts for quick testing

## Common Setup

Most labs require:
1. APM Server URL and credentials (set via environment variables)
2. Language-specific runtime (Node.js, Python, Java, Go)
3. Docker for running Elasticsearch/Kibana locally (optional)

## Notes

- JAR files are gitignored (download from Maven Central or elastic.co)
- node_modules are gitignored (run `npm install` in each Node.js lab)
- Each lab is independent and self-contained
