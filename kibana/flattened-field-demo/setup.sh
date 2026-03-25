#!/bin/bash
# Flattened Field Demo Setup
# Demonstrates why detection rule Required Fields show as "Unknown"
# when the field is inside a `flattened` mapped object.

ES="http://elastic:changeme@localhost:9250"
KB="http://localhost:5650"
KB_AUTH="-u elastic:changeme"

wait_for() {
  local url=$1
  local label=$2
  echo -n "Waiting for $label..."
  until curl -sf "$url" > /dev/null 2>&1; do
    sleep 2
    echo -n "."
  done
  echo " ready"
}

echo "==> Waiting for stack to be ready..."
wait_for "$ES/_cluster/health" "Elasticsearch"
wait_for "$KB/api/status" "Kibana (unauthenticated check)"
# Wait for Kibana to accept authenticated requests
echo -n "Waiting for Kibana auth..."
until curl -sf $KB_AUTH "$KB/api/status" > /dev/null 2>&1; do
  sleep 2
  echo -n "."
done
echo " ready"

echo ""
echo "==> Step 1: Create index with flattened field mapping"
curl -sf -X PUT "$ES/demo-flattened-auth" \
  -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "@timestamp":        { "type": "date" },
      "event": {
        "properties": {
          "action":        { "type": "keyword" },
          "category":      { "type": "keyword" },
          "outcome":       { "type": "keyword" }
        }
      },
      "user": {
        "properties": {
          "name":          { "type": "keyword" },
          "type":          { "type": "keyword" }
        }
      },
      "auth": {
        "properties": {
          "requirement":   { "type": "keyword" },
          "details":       { "type": "flattened" }
        }
      }
    }
  }
}' | jq '.acknowledged'

echo ""
echo "==> Step 2: Index sample documents"
curl -sf -X POST "$ES/demo-flattened-auth/_bulk" \
  -H "Content-Type: application/json" -d '
{"index":{}}
{"@timestamp":"2026-03-25T10:00:00Z","event":{"action":"sign-in","category":"authentication","outcome":"success"},"user":{"name":"john.doe@example.com","type":"Member"},"auth":{"requirement":"singleFactorAuthentication","details":{"authentication_method":"Password","succeeded":true,"step_requirement":"Primary authentication"}}}
{"index":{}}
{"@timestamp":"2026-03-25T10:05:00Z","event":{"action":"sign-in","category":"authentication","outcome":"success"},"user":{"name":"jane.doe@example.com","type":"Guest"},"auth":{"requirement":"multiFactorAuthentication","details":{"authentication_method":"Fido2","succeeded":true,"step_requirement":"Primary authentication"}}}
{"index":{}}
{"@timestamp":"2026-03-25T10:10:00Z","event":{"action":"sign-in","category":"authentication","outcome":"failure"},"user":{"name":"attacker@evil.com","type":"Guest"},"auth":{"requirement":"singleFactorAuthentication","details":{"authentication_method":"X509Certificate","succeeded":false,"step_requirement":"Primary authentication"}}}
' | jq '.errors'

echo ""
echo "==> Step 3: Show mapping (notice auth.details.authentication_method is NOT listed)"
curl -sf "$ES/demo-flattened-auth/_mapping" | jq '.["demo-flattened-auth"].mappings.properties.auth'

echo ""
echo "==> Step 4: Create DataView"
DV_ID=$(curl -sf $KB_AUTH -X POST "$KB/api/data_views/data_view" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" -d '{
  "data_view": {
    "title": "demo-flattened-auth*",
    "name": "Demo Flattened Auth",
    "timeFieldName": "@timestamp"
  }
}' | jq -r '.data_view.id')
echo "DataView ID: $DV_ID"

echo ""
echo "==> Step 5: Create detection rule with flattened sub-field as Required Field"
RULE_ID=$(curl -sf $KB_AUTH -X POST "$KB/api/detection_engine/rules" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" -d '{
  "type": "query",
  "name": "Demo: Unusual Auth Method (Flattened Field Test)",
  "description": "Reproduces the Unknown field warning caused by flattened mapping. Mirrors the customer issue with azure.signinlogs.properties.authentication_details.authentication_method.",
  "severity": "medium",
  "risk_score": 47,
  "enabled": false,
  "query": "event.action: sign-in and event.category: authentication",
  "language": "kuery",
  "index": ["demo-flattened-auth*"],
  "required_fields": [
    { "name": "auth.details.authentication_method", "type": "keyword" },
    { "name": "auth.requirement",                   "type": "keyword" },
    { "name": "user.name",                          "type": "keyword" },
    { "name": "user.type",                          "type": "keyword" }
  ],
  "from": "now-1h",
  "interval": "5m"
}' | jq -r '.id')
echo "Rule ID: $RULE_ID"

echo ""
echo "======================================"
echo "Setup complete!"
echo ""
echo "  Kibana:        http://localhost:5650"
echo "  Elasticsearch: http://localhost:9250"
echo ""
echo "  Navigate to:"
echo "  http://localhost:5650/app/security/rules/id/$RULE_ID"
echo ""
echo "  Expected: 'auth.details.authentication_method' shows as Unknown"
echo "            'auth.requirement', 'user.name', 'user.type' resolve fine"
echo ""
echo "  Why: auth.details is mapped as 'flattened' — sub-keys are not"
echo "       registered in the mapping, so Kibana's field picker can't"
echo "       resolve auth.details.authentication_method."
echo "======================================"
