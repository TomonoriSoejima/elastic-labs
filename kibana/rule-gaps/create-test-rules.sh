#!/usr/bin/env bash
# create-test-rules.sh — Create Security detection rules with short intervals to reproduce gaps
#
# Usage (fully automatic — reads .env for ELASTIC_CLOUD_API_KEY + credentials CSV):
#   bash create-test-rules.sh
#
# Configuration via environment variables:
#   NUM_RULES=100 RULE_INTERVAL=30s bash create-test-rules.sh

set -euo pipefail

# ---------- Configuration ----------
NUM_RULES="${NUM_RULES:-5}"
RULE_INTERVAL="${RULE_INTERVAL:-5s}"
RULE_INDEX="${RULE_INDEX:-metrics-*}"

echo "Creating ${NUM_RULES} test rules with ${RULE_INTERVAL} interval..."
echo

source "$(dirname "$0")/../common.sh"

HEADERS=(-H "kbn-xsrf: true" -H "Content-Type: application/json")

echo "==> Creating ${NUM_RULES} rules querying: ${RULE_INDEX}"
echo

# ---------- Create rules ----------
SUCCESS=0
FAILED=0

for i in $(seq 1 ${NUM_RULES}); do
  RULE_NAME="Gap Test Rule ${i}"
  RULE_ID="gap-test-rule-${i}"
  
  BODY=$(cat <<EOJSON
{
  "rule_id": "${RULE_ID}",
  "name": "${RULE_NAME}",
  "description": "Test rule for reproducing execution gaps - rule ${i}/${NUM_RULES}",
  "risk_score": 21,
  "severity": "low",
  "interval": "${RULE_INTERVAL}",
  "from": "now-5m",
  "type": "query",
  "language": "kuery",
  "index": ["${RULE_INDEX}"],
  "query": "*:*",
  "enabled": true,
  "tags": ["gap-test", "load-testing", "rule-monitoring"],
  "max_signals": 100
}
EOJSON
)
  
  STATUS=$(curl -s -o /tmp/rule_resp.json -w "%{http_code}" \
    -u "${AUTH}" "${HEADERS[@]}" \
    -X POST "${KIBANA_URL}/api/detection_engine/rules" \
    -d "${BODY}")
  
  if [[ "${STATUS}" =~ ^2 ]]; then
    RULE_API_ID=$(cat /tmp/rule_resp.json | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "unknown")
    echo "✓ Created: ${RULE_NAME} - ${RULE_API_ID}"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "✗ Failed: ${RULE_NAME} (HTTP ${STATUS})"
    cat /tmp/rule_resp.json
    echo
    FAILED=$((FAILED + 1))
  fi
done

echo
echo "Created ${SUCCESS}/${NUM_RULES} rules successfully"
if [ ${FAILED} -gt 0 ]; then
  echo "Failed: ${FAILED} rules"
  exit 1
fi
