#!/usr/bin/env bash
# Kibana heap analysis lab helper
set -euo pipefail

HELPER="http://localhost:3001"
KIBANA="http://localhost:5601"
ES="http://localhost:9200"

cmd="${1:-help}"

case "$cmd" in

  start)
    echo "▶  Starting Elasticsearch + Kibana + snapshot-helper..."
    echo "   (first pull may take a few minutes)"
    docker compose up --build -d
    echo ""
    echo "  Waiting for Kibana to be ready..."
    until curl -sf "$KIBANA/api/status" > /dev/null 2>&1; do
      printf '.'
      sleep 5
    done
    echo ""
    echo "────────────────────────────────────────────"
    echo "  Kibana        → $KIBANA"
    echo "  Elasticsearch → $ES"
    echo "  Inspector     → chrome://inspect  (port 9230)"
    echo "  Snapshot API  → $HELPER"
    echo "────────────────────────────────────────────"
    ;;

  stop)
    docker compose down -v
    ;;

  status)
    echo "=== Elasticsearch ==="
    curl -s "$ES/_cluster/health?pretty"
    echo ""
    echo "=== Kibana ==="
    curl -s "$KIBANA/api/status" | python3 -m json.tool 2>/dev/null | head -30
    ;;

  task-health)
    echo "=== Kibana Task Manager Health ==="
    curl -s -H "kbn-xsrf: true" "$KIBANA/api/task_manager/_health" | python3 -m json.tool
    ;;

  memory)
    echo "=== Kibana Node.js Memory (via inspector targets) ==="
    curl -s "$HELPER/targets" | python3 -m json.tool
    ;;

  snapshot)
    echo "▶  Capturing Kibana heap snapshot via CDP..."
    echo "   (this may take 30–120 seconds for large heaps)"
    curl -s -X POST "$HELPER/snapshot" | python3 -m json.tool
    ;;

  list-snapshots)
    curl -s "$HELPER/snapshots" | python3 -m json.tool
    ;;

  download)
    FILE="${2:-}"
    if [[ -z "$FILE" ]]; then
      echo "Usage: ./lab.sh download <filename.heapsnapshot>"
      echo ""
      echo "Available snapshots:"
      curl -s "$HELPER/snapshots" | python3 -m json.tool
      exit 1
    fi
    echo "▶  Downloading $FILE ..."
    curl -s -o "$FILE" "$HELPER/snapshot/$FILE"
    echo ""
    echo "✓ Saved → ./$FILE ($(du -sh "$FILE" | cut -f1))"
    echo ""
    echo "To analyze:"
    echo "  1. Open Chrome → chrome://inspect → Open dedicated DevTools for Node"
    echo "  2. Go to Memory tab → Load profile → select $FILE"
    echo "  OR"
    echo "  1. Open Chrome DevTools (F12) → Memory tab → Load profile"
    ;;

  watch-tasks)
    echo "Polling Task Manager health every 5s  (Ctrl-C to stop)"
    while true; do
      clear
      echo "=== $(date) ==="
      curl -s -H "kbn-xsrf: true" "$KIBANA/api/task_manager/_health" \
        | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'Status:        {d.get(\"status\", \"?\")}')
s = d.get('stats', {})
wl = s.get('workload', {}).get('value', {})
if wl:
    print(f'Tasks in queue: {wl.get(\"tasks\", {}).get(\"non_recurring\", \"?\")}')
    print(f'Overdue tasks:  {wl.get(\"overdue\", \"?\")}')
cfg = s.get('capacity_estimation', {}).get('value', {})
if cfg:
    print(f'Capacity OK:   {cfg.get(\"observed_kibana_instances\", \"?\")} instance(s)')
print()
print('Raw snippet:')
print(json.dumps(d, indent=2)[:800])
" 2>/dev/null || curl -s -H "kbn-xsrf: true" "$KIBANA/api/task_manager/_health"
      sleep 5
    done
    ;;

  logs)
    TARGET="${2:-kibana-lab}"
    docker logs -f "$TARGET"
    ;;

  *)
    cat <<EOF
Usage: ./lab.sh <command>

Commands:
  start               Start ES + Kibana + snapshot-helper (Docker)
  stop                Stop and remove all containers + volumes
  status              Show ES cluster health + Kibana status
  task-health         Show Kibana Task Manager health API (like the ticket)
  memory              Show Node.js inspector targets
  snapshot            Capture Kibana heap snapshot (CDP, no Chrome needed)
  list-snapshots      List captured snapshots
  download <file>     Download snapshot for Chrome DevTools analysis
  watch-tasks         Poll Task Manager health every 5 seconds
  logs [container]    Tail container logs (default: kibana-lab)

Chrome DevTools (live inspection):
  1. Run: ./lab.sh start
  2. Open Chrome → chrome://inspect
  3. Click "Configure" → add localhost:9230
  4. Kibana process appears → click "inspect"
  5. Memory tab → Take snapshot / Allocation timeline
EOF
    ;;
esac
