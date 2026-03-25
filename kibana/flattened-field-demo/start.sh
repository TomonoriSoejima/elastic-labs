#!/bin/bash
# Start the flattened-field-demo stack
set -e

ES="http://elastic:changeme@localhost:9250"

echo "==> Starting Elasticsearch..."
docker compose up -d elasticsearch

echo -n "Waiting for Elasticsearch..."
until curl -sf "$ES/_cluster/health" > /dev/null 2>&1; do
  sleep 2; echo -n "."
done
echo " ready"

echo "==> Generating Kibana service account token..."
TOKEN=$(curl -sf -X POST "$ES/_security/service/elastic/kibana/credential/token/ffd-token" \
  | jq -r '.token.value')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Token already exists, fetching existing..."
  curl -sf -X DELETE "$ES/_security/service/elastic/kibana/credential/token/ffd-token" > /dev/null 2>&1 || true
  TOKEN=$(curl -sf -X POST "$ES/_security/service/elastic/kibana/credential/token/ffd-token" \
    | jq -r '.token.value')
fi

echo "Token: $TOKEN"
export KB_SERVICE_TOKEN="$TOKEN"

echo "==> Starting Kibana..."
KB_SERVICE_TOKEN="$TOKEN" docker compose up -d kibana

echo -n "Waiting for Kibana..."
until curl -sf -u elastic:changeme "http://localhost:5650/api/status" | grep -q available 2>/dev/null; do
  sleep 3; echo -n "."
done
echo " ready"

echo ""
echo "Stack is up!"
echo "  Kibana:        http://localhost:5650  (elastic / changeme)"
echo "  Elasticsearch: http://localhost:9250  (elastic / changeme)"
echo ""
echo "Run ./setup.sh to create the demo index, DataView, and detection rule."
