# Trace Test - Java APM Agent Trace ID Behavior

Test project to reproduce customer issue: same `trace.id` for multiple parallel API calls.

## Setup

1. **Start Elasticsearch stack:**
```bash
docker-compose up -d
```

Wait 2-3 minutes for services to start. Check status:
```bash
docker-compose ps
```

2. **Download Elastic Java APM Agent v1.52.0:**
```bash
curl -o elastic-apm-agent-1.52.0.jar \
  https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.52.0/elastic-apm-agent-1.52.0.jar
```

3. **Build the application:**
```bash
./mvnw clean package
```

## Run Tests

### Test 1: Default Behavior (all calls share same trace.id)

```bash
java -javaagent:./elastic-apm-agent-1.52.0.jar \
  -Delastic.apm.service_name=trace-test \
  -Delastic.apm.server_url=http://localhost:8200 \
  -Delastic.apm.environment=test \
  -Delastic.apm.application_packages=co.elastic.test \
  -jar target/trace-test-1.0.0.jar
```

**Test with traceparent (simulating RUM):**
```bash
curl -H "traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01" \
  http://localhost:8080/api/test
```

**Test without traceparent:**
```bash
curl http://localhost:8080/api/test
```

### Test 2: With trace_continuation_strategy=restart

```bash
java -javaagent:./elastic-apm-agent-1.52.0.jar \
  -Delastic.apm.service_name=trace-test \
  -Delastic.apm.server_url=http://localhost:8200 \
  -Delastic.apm.environment=test \
  -Delastic.apm.application_packages=co.elastic.test \
  -Delastic.apm.trace_continuation_strategy=restart \
  -jar target/trace-test-1.0.0.jar
```

**Test with traceparent:**
```bash
curl -H "traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01" \
  http://localhost:8080/api/test
```

### Test 3: With trace_continuation_strategy=restart_external

```bash
java -javaagent:./elastic-apm-agent-1.52.0.jar \
  -Delastic.apm.service_name=trace-test \
  -Delastic.apm.server_url=http://localhost:8200 \
  -Delastic.apm.environment=test \
  -Delastic.apm.application_packages=co.elastic.test \
  -Delastic.apm.trace_continuation_strategy=restart_external \
  -jar target/trace-test-1.0.0.jar
```

**Test with traceparent:**
```bash
curl -H "traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01" \
  http://localhost:8080/api/test
```

## View Results

1. **Kibana APM:** http://localhost:5601/app/apm/services
2. **Elasticsearch:** http://localhost:9200

### Check trace IDs in Elasticsearch:

```bash
curl -s "http://localhost:9200/apm-*/_search?size=20&pretty" | grep -A 2 "trace.id"
```

## What to Observe

- **Default behavior:** All 3 ES calls should have the same `trace.id` (from incoming `traceparent`)
- **With restart:** Each call might get a new `trace.id` 
- **With restart_external:** Similar to restart but only for external traces

## Customer's Issue

Customer sees **all API calls sharing same trace.id** when:
- Angular RUM sends `traceparent` header
- Java backend receives it
- Makes multiple parallel API calls
- All inherit the same trace.id (expected distributed tracing behavior)

Customer wants **separate trace.id per API call** (breaks distributed tracing chain).

## Cleanup

```bash
docker-compose down -v
```
