#!/bin/bash
# Fix: adds resourcedetection processor so hostmetrics carries host.hostname / host.name.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

[ -f "$ROOT/.env" ] && set -a && source "$ROOT/.env" && set +a
: "${APM_ENDPOINT:?Set APM_ENDPOINT in .env (see .env.example)}"
: "${APM_API_KEY:?Set APM_API_KEY in .env (see .env.example)}"

sed -e "s|\${APM_ENDPOINT}|$APM_ENDPOINT|g" -e "s|\${APM_API_KEY}|$APM_API_KEY|g" \
  "$DIR/otel.yml.template" > "$DIR/otel.yml"

docker rm -f edot-hostmetrics-fix 2>/dev/null || true

docker run -d \
  --name edot-hostmetrics-fix \
  -v "$DIR/otel.yml:/otel.yml:ro" \
  docker.elastic.co/elastic-agent/elastic-agent:9.5.2 \
  otelcol --config /otel.yml

echo "Running. Query ${DATA_STREAM:-metrics-apm.app.mfrs_judge_system-default} in ~20s — host.hostname should be PRESENT."
