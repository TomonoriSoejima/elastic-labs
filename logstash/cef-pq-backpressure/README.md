# Lab: CEF Codec Failures → PQ Growth Under Backpressure

**Logstash:** 8.15.5  
**Question answered:** Do CEF codec decode failures enter the PQ, or are they dropped?  
**Docs:** [Logstash Persistent Queues](https://www.elastic.co/docs/reference/logstash/persistent-queues)

## What This Proves

`cef.rb` rescue block yields a failure event (`_cefparsefailure`) for **every** malformed payload.  
The TCP input's `enqueue_decorated` then does `@output_queue << event` — failure events **do** enter the PQ and traverse the full filter+output chain.

## Setup

```bash
docker compose up -d
# wait ~30s for Logstash to start
curl -s localhost:9600/ | python3 -m json.tool
```

## Running the Lab

**Terminal 1 — watch the queue:**
```bash
chmod +x scripts/watch-queue.sh
./scripts/watch-queue.sh
```

**Terminal 2 — send TLS junk to the CEF port:**
```bash
chmod +x scripts/send-junk.sh
./scripts/send-junk.sh          # 100 connections (default)
./scripts/send-junk.sh 127.0.0.1 5555 500   # more load
```

You will see `QUEUE_BYTES` grow while `EVENTS_OUT` lags behind `EVENTS_IN`.  
The `sleep { time => 3 }` filter simulates the blocked GCSOC output from the real incident.

## What to Observe

| Metric | Expected |
|---|---|
| `QUEUE_BYTES` | Grows with each TLS connection burst |
| `EVENTS_IN` > `EVENTS_OUT` | Events accumulating (not drained) |
| `WORKER_UTIL` > 1.0 | Workers blocked on slow filter |
| Logstash logs | `ERROR logstash.codecs.cef - Failed to decode CEF payload` |

## Adjusting Backpressure Severity

Edit `pipeline/cef-pq.conf`:
- `sleep { time => 10 }` — heavier backpressure, PQ fills faster
- `sleep { time => 0 }` — no backpressure, PQ drains freely (verifies failure events *do* flow through)

Restart with:
```bash
docker compose restart logstash
```

## Inspecting the PQ with pqcheck

While the queue is growing (or after stopping Logstash), you can inspect the raw PQ files with the `pqcheck` utility bundled in the Logstash installation:

```bash
# Inside the container
docker exec -it cef-pq-backpressure-logstash-1 bash

# Run pqcheck against the pipeline's queue directory
/usr/share/logstash/bin/pqcheck /usr/share/logstash/data/queue/<pipeline-id>
```

Example output:

```
Using bundled JDK: /usr/share/logstash/jdk
Checking queue dir: data/queue/cef-pq
checkpoint.head, fully-acked: YES, page.1 size: 67108864
pageNum=1, firstUnackedPageNum=1, firstUnackedSeqNum=1355, minSeqNum=460, elementCount=895, isFullyAcked=yes
```

`elementCount` is the key field — it shows how many events are sitting unacknowledged in the queue. Under active backpressure this number climbs; once output catches up it drops back to zero.

## Cleanup

```bash
docker compose down -v   # -v removes the PQ volume
```

## Relevance to STACK-3087

In the real incident, `07_gdc_gcsoc` had `queue_backpressure.last_1_hour = 0.25` and `worker_utilization = 8.66` on 8 workers — all workers blocked on slow TCP outputs. With `04_gdc_checkpoint` receiving a continuous stream of TLS junk on port 1471 (100% CEF failure rate, 1.9M events in 3h), every failure event needed to drain through that bottleneck. This lab isolates that dynamic.
