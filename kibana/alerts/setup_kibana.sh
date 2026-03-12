#!/usr/bin/env bash
# setup_kibana.sh — Create data views and the Indicator Match detection rule via Kibana API
#
# Usage (fully automatic — reads .env for ELASTIC_CLOUD_API_KEY + credentials CSV):
#   bash setup_kibana.sh
#
# All values are auto-discovered. Override any explicitly if needed:
#   KIBANA_URL=https://<host> KIBANA_USER=elastic KIBANA_PASSWORD=<pw> bash setup_kibana.sh

set -euo pipefail

source "$(dirname "$0")/../common.sh"

HEADERS=(-H "kbn-xsrf: true" -H "Content-Type: application/json")

echo "==> Kibana: ${KIBANA_URL}"

# ---------- helper ----------
kibana_post() {
  local path="$1"
  local body="$2"
  local desc="$3"
  echo -n "  ${desc} ... "
  status=$(curl -s -o /tmp/kb_resp.json -w "%{http_code}" \
    -u "${AUTH}" "${HEADERS[@]}" \
    -X POST "${KIBANA_URL}${path}" \
    -d "${body}")
  if [[ "${status}" =~ ^2 ]]; then
    echo "OK (${status})"
  else
    echo "WARN (${status})"
    cat /tmp/kb_resp.json
    echo
  fi
}

# ---------- 1. Data views ----------
echo
echo "==> Creating data views..."

kibana_post "/api/content_management/rpc/create" '{
  "contentTypeId": "index-pattern",
  "data": {
    "fieldAttrs": "{}",
    "title": "software",
    "timeFieldName": "@timestamp",
    "sourceFilters": "[]",
    "fields": "[]",
    "fieldFormatMap": "{}",
    "runtimeFieldMap": "{}",
    "name": "software",
    "allowHidden": false
  },
  "options": { "id": "software", "overwrite": true },
  "version": 1
}' "data view: software"

kibana_post "/api/content_management/rpc/create" '{
  "contentTypeId": "index-pattern",
  "data": {
    "fieldAttrs": "{}",
    "title": "eol-versions",
    "timeFieldName": "@timestamp",
    "sourceFilters": "[]",
    "fields": "[]",
    "fieldFormatMap": "{}",
    "runtimeFieldMap": "{}",
    "name": "eol-versions",
    "allowHidden": false
  },
  "options": { "id": "eol-versions", "overwrite": true },
  "version": 1
}' "data view: eol-versions"

# ---------- 2. Detection rule ----------
echo
echo "==> Creating Indicator Match detection rule..."

kibana_post "/api/detection_engine/rules" '{
  "rule_id": "indicator-match-repro",
  "name": "Indicator Match Repro — EOL Software",
  "description": "Reproduces false positives in indicator match with AND conditions (kibana#179825)",
  "risk_score": 21,
  "severity": "low",
  "interval": "1m",
  "from": "now-120s",
  "type": "threat_match",
  "language": "kuery",
  "index": ["software"],
  "query": "*:*",
  "enabled": true,
  "filters": [],
  "threat_query": "@timestamp >= \"now-30d/d\"",
  "threat_index": ["eol-versions"],
  "threat_mapping": [
    {
      "entries": [
        {
          "field": "version.keyword",
          "type": "mapping",
          "value": "threat.indicator.version.keyword"
        },
        {
          "field": "software.keyword",
          "type": "mapping",
          "value": "threat.indicator.software.keyword"
        }
      ]
    }
  ],
  "threat_language": "kuery",
  "threat_indicator_path": "threat.indicator"
}' "detection rule: indicator-match-repro"

echo
echo "Done. Open Security → Rules in Kibana to verify."
