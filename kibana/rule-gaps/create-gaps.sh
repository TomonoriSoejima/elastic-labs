#!/usr/bin/env bash
# create-gaps.sh — Disable gap-test rules, wait, then re-enable to create execution gaps
#
# Usage:
#   bash create-gaps.sh
#
# Configuration via environment variables:
#   DISABLE_DURATION=300 bash create-gaps.sh  # default is 300 seconds (5 minutes)

set -euo pipefail

DISABLE_DURATION="${DISABLE_DURATION:-300}"

echo "Creating gaps by disabling rules for ${DISABLE_DURATION} seconds..."
echo

source "$(dirname "$0")/../common.sh"

HEADERS=(-H "kbn-xsrf: true" -H "Content-Type: application/json")

# ---------- Get all gap-test rules ----------
echo "==> Finding gap-test rules..."
RULES_JSON=$(curl -s -u "${AUTH}" "${HEADERS[@]}" \
  "${KIBANA_URL}/api/detection_engine/rules/_find?filter=alert.attributes.tags:%20%22gap-test%22&per_page=100")

RULE_IDS=$(echo "${RULES_JSON}" | python3 -c "import sys,json; data=json.load(sys.stdin); print('\n'.join([r['id'] for r in data['data']]))" 2>/dev/null || echo "")

if [ -z "${RULE_IDS}" ]; then
  echo "[!] No gap-test rules found"
  exit 1
fi

RULE_COUNT=$(echo "${RULE_IDS}" | wc -l | tr -d ' ')
echo "[✓] Found ${RULE_COUNT} gap-test rules"
echo

# ---------- Disable all rules ----------
echo "==> Disabling ${RULE_COUNT} rules..."

RULE_IDS_ARRAY=$(echo "${RULE_IDS}" | python3 -c "import sys,json; print(json.dumps([line.strip() for line in sys.stdin if line.strip()]))")

DISABLE_BODY=$(cat <<EOJSON
{
  "ids": ${RULE_IDS_ARRAY}
}
EOJSON
)

STATUS=$(curl -s -o /tmp/disable_resp.json -w "%{http_code}" \
  -u "${AUTH}" "${HEADERS[@]}" \
  -X POST "${KIBANA_URL}/api/detection_engine/rules/_bulk_action" \
  -d "{\"action\":\"disable\",\"ids\":${RULE_IDS_ARRAY}}")

if [[ "${STATUS}" =~ ^2 ]]; then
  echo "[✓] Rules disabled"
else
  echo "[✗] Failed to disable rules (HTTP ${STATUS})"
  cat /tmp/disable_resp.json
  echo
  exit 1
fi

# ---------- Wait ----------
echo
echo "==> Waiting ${DISABLE_DURATION} seconds to create gaps..."
echo "    (Rules are disabled - execution halted)"

WAIT_INTERVAL=30
ELAPSED=0
while [ ${ELAPSED} -lt ${DISABLE_DURATION} ]; do
  REMAINING=$((DISABLE_DURATION - ELAPSED))
  echo "    [${ELAPSED}s / ${DISABLE_DURATION}s] — ${REMAINING}s remaining..."
  sleep ${WAIT_INTERVAL}
  ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

echo "[✓] Wait complete"
echo

# ---------- Re-enable all rules ----------
echo "==> Re-enabling ${RULE_COUNT} rules..."

STATUS=$(curl -s -o /tmp/enable_resp.json -w "%{http_code}" \
  -u "${AUTH}" "${HEADERS[@]}" \
  -X POST "${KIBANA_URL}/api/detection_engine/rules/_bulk_action" \
  -d "{\"action\":\"enable\",\"ids\":${RULE_IDS_ARRAY}}")

if [[ "${STATUS}" =~ ^2 ]]; then
  echo "[✓] Rules re-enabled"
else
  echo "[✗] Failed to re-enable rules (HTTP ${STATUS})"
  cat /tmp/enable_resp.json
  echo
  exit 1
fi

echo
echo "==> Gap creation complete!"
echo
echo "Next steps:"
echo "  1. Wait a few minutes for gap detection to run"
echo "  2. Check for gaps:"
echo "     bash check-gaps.sh"
echo "  3. View in Kibana UI:"
echo "     Security → Detection rules → Rule Monitoring → Gaps tab"
