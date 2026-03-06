# Logstash Date Filter Truncates Nanosecond Precision

## Issue Description

Logstash 9.2.0's date filter truncates timestamp precision to milliseconds during parsing, even when the target Elasticsearch field is mapped as `date_nanos`. 

**Example:**
- Input: `2025-12-15T10:00:00.123456789Z` (9 decimal places)
- Output: `2025-12-15T10:00:00.123Z` (3 decimal places)

The truncation occurs **during Logstash parsing**, before data reaches Elasticsearch. This means even fields mapped as `date_nanos` cannot preserve the original precision.

## Environment

- Logstash: 9.2.0
- Elasticsearch: 9.2.0

## Why This Shouldn't Happen

PR [#12797](https://github.com/elastic/logstash/pull/12797) was merged to add nanosecond precision support to Logstash. However, the issue persists in version 9.2.0, suggesting either:
- The PR wasn't included in this release
- The implementation is incomplete
- Additional configuration is required (not documented)

## Reproduction

Complete test environment with Docker setup, configurations, and sample data available at:

**https://github.com/TomonoriSoejima/logstash-nanos-test**

The repository includes ready-to-run reproduction steps with all necessary files.

## References

- Related PR: https://github.com/elastic/logstash/pull/12797
- Elasticsearch date_nanos docs: https://www.elastic.co/guide/en/elasticsearch/reference/current/date_nanos.html
- Logstash date filter docs: https://www.elastic.co/guide/en/logstash/current/plugins-filters-date.html
