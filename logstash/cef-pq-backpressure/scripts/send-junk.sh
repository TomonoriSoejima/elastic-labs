#!/usr/bin/env bash
# send-junk.sh — sends TLS ClientHello bytes to Logstash's CEF TCP port.
# Each connection triggers multiple CEF decode failures in cef.rb, which are
# yielded as failure events and pushed straight into the PQ via @output_queue.
# This reproduces the TLS-junk-on-plain-TCP situation from STACK-3087.

set -euo pipefail

HOST="${1:-127.0.0.1}"
PORT="${2:-5555}"
COUNT="${3:-100}"

echo "Sending $COUNT TLS junk connections to $HOST:$PORT"
echo "Each openssl connection triggers several CEF decode failure events."
echo ""

for i in $(seq 1 "$COUNT"); do
  # openssl s_client sends a real TLS ClientHello — the server sees raw binary,
  # which the CEF codec cannot decode, producing failure events.
  echo "" | openssl s_client -connect "${HOST}:${PORT}" -quiet 2>/dev/null &
  # small gap to avoid hammering accept queue
  sleep 0.05
done

wait
echo ""
echo "Done. Check queue growth:"
echo "  ./scripts/watch-queue.sh"
echo "  curl -s localhost:9600/_node/stats/pipelines/cef-pq | python3 -m json.tool"
