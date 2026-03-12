#!/usr/bin/env bash
# cleanup-test-rules.sh — Delete all gap test rules
#
# Usage:
#   bash cleanup-test-rules.sh

set -euo pipefail

source "$(dirname "$0")/../common.sh"

echo "Cleaning up gap test Security rules..."
echo "==> Kibana: ${KIBANA_URL}"
echo

# ---------- Find test rules ----------
echo "Finding gap test rules..."
RULES=$(curl -s -u "${AUTH}" \
  -H "kbn-xsrf: true" \
  "${KIBANA_URL}/api/detection_engine/rules/_find?filter=alert.attributes.tags:%20%22gap-test%22&per_page=500")

RULE_COUNT=$(echo "${RULES}" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['data']))")

if [ "${RULE_COUNT}" -eq 0 ]; then
  echo "No gap test rules found"
  exit 0
fi

echo "Found ${RULE_COUNT} gap test rules"
echo

# ---------- Confirm deletion ----------
read -p "Delete all ${RULE_COUNT} rules? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# ---------- Delete rules ----------
RULE_IDS=$(echo "${RULES}" | python3 -c "
import sys, json
rules = json.load(sys.stdin)['data']
for rule in rules:
    print(rule['id'])
")

SUCCESS=0
FAILED=0

while read -r RULE_ID; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${AUTH}" \
    -H "kbn-xsrf: true" \
    -X DELETE "${KIBANA_URL}/api/detection_engine/rules?id=${RULE_ID}")
  
  if [[ "${STATUS}" == "200" ]]; then
    echo "✓ Deleted rule: ${RULE_ID}"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "✗ Failed to delete: ${RULE_ID} (HTTP ${STATUS})"
    FAILED=$((FAILED + 1))
  fi
done <<< "${RULE_IDS}"

echo
echo "Deleted ${SUCCESS}/${RULE_COUNT} rules"
if [ ${FAILED} -gt 0 ]; then
  echo "Failed: ${FAILED} rules"
fi
