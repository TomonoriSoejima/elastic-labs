# Escalation: Nanosecond Precision Not Working in Logstash 9.2.0

## Summary

Logstash 9.2.0 truncates timestamps to millisecond precision despite PR [#12797](https://github.com/elastic/logstash/pull/12797) being merged to add nanosecond support. The date filter drops nanosecond precision during parsing, before data reaches Elasticsearch.

## Impact

Users cannot preserve nanosecond precision in logs, even with `date_nanos` field mappings.

## Request

Please investigate why the nanosecond precision feature from PR #12797 is not functional in version 9.2.0:
- Was the PR included in this release?
- Is there missing configuration or documentation?
- Are there additional steps required to enable the feature?

## Reproduction

Complete test environment: https://github.com/TomonoriSoejima/logstash-nanos-test

Ready-to-run Docker setup with all configs and sample data included.

## Environment

- Logstash: 9.2.0
- Elasticsearch: 9.2.0
