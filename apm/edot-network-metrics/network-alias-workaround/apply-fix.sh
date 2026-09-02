#!/bin/bash
# Validated fix (case 02136457 / KB f9813ea9): declare the concrete system.network.*
# field mapping IN THE SAME component template as the alias, so ES can resolve the
# alias target at validation time. Rollover-safe: composed into every new backing index.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

[ -f "$ROOT/.env" ] && set -a && source "$ROOT/.env" && set +a
: "${ES_URL:?Set ES_URL in .env (see .env.example)}"
: "${ES_USER:?Set ES_USER in .env}"
: "${ES_PASSWORD:?Set ES_PASSWORD in .env}"
COMPONENT_TEMPLATE="${COMPONENT_TEMPLATE:-metrics-apm.app@custom}"

curl -s -u "$ES_USER:$ES_PASSWORD" -X PUT "$ES_URL/_component_template/$COMPONENT_TEMPLATE" \
  -H "Content-Type: application/json" -d '{
  "template": {
    "mappings": {
      "properties": {
        "system": {
          "properties": {
            "network": {
              "properties": {
                "in":  { "properties": { "bytes": { "type": "double", "index": false } } },
                "out": { "properties": { "bytes": { "type": "double", "index": false } } }
              }
            }
          }
        },
        "host": {
          "properties": {
            "network": {
              "properties": {
                "ingress": { "properties": { "bytes": { "type": "alias", "path": "system.network.in.bytes" } } },
                "egress":  { "properties": { "bytes": { "type": "alias", "path": "system.network.out.bytes" } } }
              }
            }
          }
        }
      }
    }
  }
}' | python3 -m json.tool

echo ""
echo "Expected: {\"acknowledged\": true}"
