#!/usr/bin/env bash
# watch-queue.sh — polls the Logstash stats API every 2 seconds and prints
# PQ size, events in/out, and worker utilization so you can see the queue growing.

HOST="${1:-127.0.0.1}"
API_PORT="${2:-9600}"
PIPELINE="${3:-cef-pq}"

echo "Watching pipeline '$PIPELINE' on http://$HOST:$API_PORT (Ctrl-C to stop)"
printf "%-10s %-18s %-14s %-14s %-22s\n" "TIME" "QUEUE_BYTES" "EVENTS_IN" "EVENTS_OUT" "WORKER_UTIL(last1h)"
echo "----------------------------------------------------------------------"

while true; do
  DATA=$(curl -sf "http://${HOST}:${API_PORT}/_node/stats/pipelines/${PIPELINE}" 2>/dev/null) || {
    echo "$(date '+%H:%M:%S')  Logstash not ready..."
    sleep 2
    continue
  }

  QUEUE_BYTES=$(echo "$DATA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
p = d['pipelines']['${PIPELINE}']
print(p.get('queue', {}).get('queue_size_in_bytes', 'n/a'))
" 2>/dev/null)

  EVENTS_IN=$(echo "$DATA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['pipelines']['${PIPELINE}']['events']['in'])
" 2>/dev/null)

  EVENTS_OUT=$(echo "$DATA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['pipelines']['${PIPELINE}']['events']['out'])
" 2>/dev/null)

  WORKER_UTIL=$(echo "$DATA" | python3 -c "
import sys, json
d = json.load(sys.stdin)
f = d['pipelines']['${PIPELINE}'].get('flow', {})
wu = f.get('worker_utilization', {}).get('last_1_minute', 'n/a')
print(wu)
" 2>/dev/null)

  printf "%-10s %-18s %-14s %-14s %-22s\n" \
    "$(date '+%H:%M:%S')" "$QUEUE_BYTES" "$EVENTS_IN" "$EVENTS_OUT" "$WORKER_UTIL"

  sleep 2
done
