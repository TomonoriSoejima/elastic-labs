#!/bin/bash

# Script to fetch alert execution log from Kibana
# Adapted from cloud URL to work with dev Kibana

# ============================================
# CONFIGURATION - UPDATE FOR YOUR DEV ENVIRONMENT
# ============================================
KIBANA_ENDPOINT="http://localhost:5601"
USERNAME="elastic"
PASSWORD="changeme"
SPACE_ID="test-space"
RULE_ID="9f46cf1c-a018-4d58-a67f-b9fba7ad47ca"

# Date parameters from the original URL
DATE_START="2026-01-05T11:18:47+09:00"
DATE_END="2026-01-05T11:33:47+09:00"
PER_PAGE=10
PAGE=1

# ============================================
# DO NOT MODIFY BELOW THIS LINE
# ============================================

echo "=========================================="
echo "Fetching Alert Execution Log"
echo "=========================================="
echo ""
echo "Kibana: $KIBANA_ENDPOINT"
echo "Space: $SPACE_ID"
echo "Rule ID: $RULE_ID"
echo "Date Range: $DATE_START to $DATE_END"
echo ""

# URL encode the date parameters
# Need to properly encode + as %2B and : as %3A
DATE_START_ENCODED=$(printf '%s' "$DATE_START" | jq -sRr @uri | sed 's/+/%2B/g')
DATE_END_ENCODED=$(printf '%s' "$DATE_END" | jq -sRr @uri | sed 's/+/%2B/g')

# Construct the full URL
FULL_URL="$KIBANA_ENDPOINT/s/$SPACE_ID/internal/alerting/rule/${RULE_ID}/_execution_log?date_start=${DATE_START_ENCODED}&date_end=${DATE_END_ENCODED}&per_page=${PER_PAGE}&page=${PAGE}"

echo "Making request to:"
echo "$FULL_URL"
echo ""

# Make the request
RESPONSE=$(curl -s -u "$USERNAME:$PASSWORD" -X GET "$FULL_URL" \
  -H 'kbn-xsrf: true' \
  -H 'Content-Type: application/json')

# Pretty print the response
echo "Response:"
echo "$RESPONSE" | jq '.'

echo ""
echo "=========================================="
echo "Done"
echo "=========================================="
