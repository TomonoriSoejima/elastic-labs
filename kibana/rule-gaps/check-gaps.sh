#!/usr/bin/env bash
# check-gaps.sh — Check gap status for gap-test rules
#
# Usage:
#   bash check-gaps.sh           # check once
#   WATCH=1 bash check-gaps.sh   # keep checking every 30s

set -euo pipefail

source "$(dirname "$0")/../common.sh"

WATCH="${WATCH:-0}"
INTERVAL="${INTERVAL:-30}"

check() {
  echo "==> Gap check @ $(date '+%H:%M:%S')"
  echo

  curl -s -u "${AUTH}" \
    -H "Content-Type: application/json" \
    "${ES_URL}/.kibana-event-log-*/_search" \
    -d '{
      "size": 20,
      "query": { "term": { "event.action": "gap" } },
      "sort": [{"@timestamp": "desc"}]
    }' | python3 -c "
import sys, json
d = json.load(sys.stdin)
hits = d['hits']['hits']
total = d['hits']['total']['value']
print(f'  Total gaps: {total}')
print()
for h in hits:
    s = h['_source']
    rule_name = s.get('rule', {}).get('name', '?')
    ts = s.get('@timestamp', '?')[:19]
    gap = s.get('kibana', {}).get('alert', {}).get('gap', {})
    duration    = gap.get('duration', '?')
    filled      = gap.get('filled_duration', '0')
    unfilled    = gap.get('unfilled_duration', '?')
    print(f'  [{ts}] {rule_name}')
    print(f'    total={duration}  filled={filled}  unfilled={unfilled}')
    print()
"
}

if [ "${WATCH}" = "1" ]; then
  echo "Watching for gaps every ${INTERVAL}s (Ctrl+C to stop)..."
  echo
  while true; do
    check
    echo "--- sleeping ${INTERVAL}s ---"
    echo
    sleep "${INTERVAL}"
  done
else
  check
fi
