# Test Method: Verifying Logstash Nanosecond Precision Handling

## Overview

This document describes how to test whether Logstash preserves nanosecond precision when parsing timestamps into Elasticsearch fields mapped as `date_nanos`.

## Test Setup

### Prerequisites

- Docker and docker-compose installed
- Test repository files:
  - `docker-compose.yml` - Elasticsearch and Kibana configuration
  - `logstash-es.conf` - Logstash pipeline configuration
  - `test-logs.json` - Sample data with nanosecond timestamps

### Test Data

Sample input with nanosecond precision:
```json
{"timestamp": "2025-12-15T10:00:00.123456789Z", "message": "Test log 1 with nanoseconds"}
{"timestamp": "2025-12-15T10:00:00.123456999Z", "message": "Test log 2 with nanoseconds"}
{"timestamp": "2025-12-15T10:00:00.123789123Z", "message": "Test log 3 with nanoseconds"}
```

### Logstash Configuration

The test uses a Logstash pipeline that:
- Reads JSON data from stdin
- Parses the `timestamp` field using the date filter
- Outputs to both Elasticsearch and stdout

```ruby
input {
  stdin {
    codec => "json_lines"
  }
}

filter {
  date {
    match => ["timestamp", "ISO8601"]
    target => "@timestamp"
  }
  
  date {
    match => ["timestamp", "ISO8601"]
    target => "log_timestamp"
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "nanos-test"
  }
  stdout { codec => rubydebug }
}
```

### Elasticsearch Mapping

The index uses `date_nanos` mapping for the `log_timestamp` field:

```json
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "log_timestamp": { "type": "date_nanos" },
      "timestamp": { "type": "keyword" },
      "message": { "type": "text" }
    }
  }
}
```

## Test Procedure

### Step 1: Start Elasticsearch

```bash
docker-compose up -d elasticsearch kibana
sleep 30  # Wait for Elasticsearch to be ready
```

Verify Elasticsearch is running:
```bash
curl -s http://localhost:9200/_cluster/health | grep status
```

### Step 2: Create Index with date_nanos Mapping

```bash
curl -X PUT "localhost:9200/nanos-test" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "log_timestamp": { "type": "date_nanos" },
      "timestamp": { "type": "keyword" },
      "message": { "type": "text" }
    }
  }
}'
```

Expected response:
```json
{"acknowledged":true,"shards_acknowledged":true,"index":"nanos-test"}
```

### Step 3: Ingest Data via Logstash

```bash
docker run --rm -i \
  --network logstash-nanos-test_elastic \
  -v "$(pwd)/logstash-es.conf:/usr/share/logstash/pipeline/logstash.conf" \
  docker.elastic.co/logstash/logstash:9.2.0 \
  < test-logs.json
```

### Step 4: Query and Verify Results

```bash
curl -X GET "localhost:9200/nanos-test/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "fields": [
    {"field": "@timestamp", "format": "strict_date_optional_time_nanos"},
    {"field": "log_timestamp", "format": "strict_date_optional_time_nanos"}
  ],
  "_source": ["timestamp", "message"]
}'
```

### Step 5: Cleanup

```bash
docker-compose down -v
```

## Expected vs Actual Results

### Input Data
```json
{"timestamp": "2025-12-15T10:00:00.123456789Z", "message": "Test log 1"}
```

### Expected Result (if nanosecond precision is preserved)

```json
{
  "timestamp": "2025-12-15T10:00:00.123456789Z",
  "@timestamp": "2025-12-15T10:00:00.123456789Z",
  "log_timestamp": "2025-12-15T10:00:00.123456789Z"
}
```

### Actual Result (current behavior in Logstash 9.2.0)

```json
{
  "timestamp": "2025-12-15T10:00:00.123456789Z",      // ✅ Preserved (keyword field)
  "@timestamp": "2025-12-15T10:00:00.123Z",           // ❌ Truncated to milliseconds
  "log_timestamp": "2025-12-15T10:00:00.123Z"         // ❌ Truncated despite date_nanos mapping
}
```

## Key Observations

1. **Keyword field preserves precision**: The original `timestamp` field (mapped as `keyword`) retains the full nanosecond precision
2. **Date field truncates as expected**: The `@timestamp` field (mapped as `date`) shows millisecond precision, which is expected behavior
3. **date_nanos field also truncates**: The `log_timestamp` field (mapped as `date_nanos`) also shows millisecond precision, indicating the truncation happens during Logstash parsing, not during Elasticsearch indexing

## Verification Points

- [ ] Elasticsearch is running and healthy
- [ ] Index created with correct `date_nanos` mapping for `log_timestamp` field
- [ ] Test data contains timestamps with 9 decimal places (nanoseconds)
- [ ] Query results show only 3 decimal places (milliseconds) for parsed timestamp fields
- [ ] Keyword field retains full 9 decimal places

## Troubleshooting

### Elasticsearch not starting
Wait longer (up to 60 seconds) or check logs:
```bash
docker-compose logs elasticsearch
```

### Network not found
Ensure the docker-compose network name matches your setup:
```bash
docker network ls
```

### No data indexed
Check Logstash logs for errors or verify the file path is correct.

## Test Environment Details

- **Logstash Version**: 9.2.0
- **Elasticsearch Version**: 9.2.0
- **Docker Image**: docker.elastic.co/logstash/logstash:9.2.0
- **Date Filter Pattern**: ISO8601
- **Input Method**: stdin with json_lines codec
