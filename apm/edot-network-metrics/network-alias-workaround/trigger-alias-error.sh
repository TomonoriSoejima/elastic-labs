#!/bin/bash
# Reproduces the customer's exact mapper_parsing_exception from case 02136457:
# adding an alias-only mapping to a component template fails because the alias
# target (system.network.*) is never declared in any template - only created
# dynamically once real data lands in a concrete index.
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
echo "Expected: mapper_parsing_exception - an alias must refer to an existing field in the mappings."
