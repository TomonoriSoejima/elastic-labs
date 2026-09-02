#!/bin/bash
# Confirms the alias survives a data stream rollover after apply-fix.sh has been run,
# without any manual _mapping call on the new backing index.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

[ -f "$ROOT/.env" ] && set -a && source "$ROOT/.env" && set +a
: "${ES_URL:?Set ES_URL in .env (see .env.example)}"
: "${ES_USER:?Set ES_USER in .env}"
: "${ES_PASSWORD:?Set ES_PASSWORD in .env}"
DATA_STREAM="${DATA_STREAM:-metrics-apm.app.mfrs_judge_system-default}"

echo "--- pre-rollover mapping ---"
curl -s -u "$ES_USER:$ES_PASSWORD" \
  "$ES_URL/$DATA_STREAM/_mapping/field/host.network.ingress.bytes,host.network.egress.bytes" | python3 -m json.tool

echo "--- forcing rollover ---"
curl -s -u "$ES_USER:$ES_PASSWORD" -X POST "$ES_URL/$DATA_STREAM/_rollover" | python3 -m json.tool

echo "--- post-rollover mapping (new backing index should already have the alias) ---"
curl -s -u "$ES_USER:$ES_PASSWORD" \
  "$ES_URL/$DATA_STREAM/_mapping/field/host.network.ingress.bytes,host.network.egress.bytes" | python3 -m json.tool
