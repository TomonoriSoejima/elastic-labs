# [Java APM] Customer wants separate trace.id for each parallel HTTP client call

**Ticket**: 02032795 | **Customer**: Cetera Financial Group (New Relic migration)

## Problem
Customer migrating from New Relic wants **each parallel outgoing HTTP call to have a separate trace.id**.

**Current behavior**: 3 parallel HTTP calls → 3 spans under 1 trace.id  
**Desired behavior**: 3 parallel HTTP calls → 3 separate trace.ids (like New Relic)

## Context: This IS the Default Design
Per [Elastic APM Distributed Tracing docs](https://www.elastic.co/guide/en/apm/guide/current/apm-distributed-tracing.html):
> "A trace is a group of transactions and spans with a common root. Each trace tracks the entirety of a single request."
> "The `trace.id` is recorded on all transactions and spans that belong to a particular trace."

**This is working as designed.** All spans from one request share the same trace.id for correlation.
Customer wants to disable distributed tracing correlation. Should we support this?**

Current design (per docs): HTTP client calls = child spans (inherit parent trace.id for correlation)  
Customer wants: HTTP client calls = independent transactions (separate trace.ids, no correlation)

**This breaks the fundamental purpose of distributed tracing.** Is there a valid use case, or should we educate customer on why this design is beneficial?ll 3 HTTP spans still share it ✅ (correct per docs)
- Neither strategy separates parallel outgoing calls (because that would break distributed tracing)

## Question
**Is it possible/desirable to have each outgoing HTTP client call create a separate trace instead of a span?**

Current design: HTTP client calls = child spans (inherit parent trace.id)  
Customer wants: HTTP client calls = independent transactions (separate trace.ids)

## Test Case
Repo: `/Users/surfer/elastic/iroiro/trace-test`  
Java 21, Spring Boot 3.2.0, APM Agent 1.52.0  
Endpoint makes 3 parallel HTTP calls to httpbin.org

## Impact
High - Migration deadline-driven, comparing to New Relic
