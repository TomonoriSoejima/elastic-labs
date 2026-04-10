# Kibana Alert Testing

Scripts for testing and debugging Kibana alerting execution history.

## Overview

These scripts help reproduce and verify alert execution history issues in Kibana. They create test data, alert rules, and fetch execution logs to validate that alerting is working correctly.

## Scripts

### test-alert-execution.sh

Creates a test alert rule in the default Kibana space and verifies execution history.

**What it does:**
1. Creates test data in `test-alert-data` index
2. Creates an ES Query alert rule that monitors the test data
3. Provides instructions to verify execution history in Kibana UI

**Usage:**
```bash
# 1. Update configuration at the top of the script
ES_ENDPOINT="https://your-cluster.es.cloud"
KIBANA_ENDPOINT="https://your-cluster.kb.cloud"
USERNAME="elastic"
PASSWORD="your-password"

# 2. Run the script
chmod +x test-alert-execution.sh
./test-alert-execution.sh
```

**After running:**
- Go to Kibana → Stack Management → Rules
- Find the rule "Test Alert - Execution History Check"
- Click on it and verify the "Execution history" tab shows data

---

### test-alert-with-space.sh

Same as `test-alert-execution.sh`, but creates a **custom Kibana space** first, then creates the alert in that space.

**What it does:**
1. Creates a custom Kibana space (configurable space ID)
2. Creates test data in `test-alert-data` index
3. Creates an ES Query alert rule in the custom space
4. Provides instructions to verify execution history

**Usage:**
```bash
# 1. Update configuration at the top of the script
ES_ENDPOINT="https://your-cluster.es.cloud"
KIBANA_ENDPOINT="https://your-cluster.kb.cloud"
USERNAME="elastic"
PASSWORD="your-password"
SPACE_ID="test-space"
SPACE_NAME="Test Space for Alert History"

# 2. Run the script
chmod +x test-alert-with-space.sh
./test-alert-with-space.sh
```

**Use case:** Testing alert execution history in non-default spaces to reproduce space-specific issues.

---

### get-execution-log.sh

Fetches alert execution logs directly via Kibana internal API.

**What it does:**
- Makes a direct API call to Kibana's internal alerting execution log endpoint
- Returns execution log data in JSON format
- Useful for debugging when UI doesn't show execution history

**Usage:**
```bash
# 1. Update configuration at the top of the script
KIBANA_ENDPOINT="http://localhost:5601"
USERNAME="elastic"
PASSWORD="changeme"
SPACE_ID="test-space"
RULE_ID="9f46cf1c-a018-4d58-a67f-b9fba7ad47ca"
DATE_START="2026-01-05T11:18:47+09:00"
DATE_END="2026-01-05T11:33:47+09:00"

# 2. Run the script
chmod +x get-execution-log.sh
./get-execution-log.sh
```

**Finding the Rule ID:**
- In Kibana UI, go to the rule details page
- The URL contains the rule ID: `/app/management/insightsAndAlerting/rules/<RULE_ID>`

---

## Common Issues

### No execution history appears

**Possible causes:**
1. Alert hasn't run yet (check schedule)
2. Event log indices are full or corrupted
3. Kibana version-specific bugs
4. Space isolation issues (for custom spaces)

**Debugging steps:**
1. Check if alert is enabled
2. Verify alert has executed (check last run time)
3. Check Kibana event log indices: `.kibana-event-log-*`
4. Use `get-execution-log.sh` to fetch logs directly from API

### Script fails to create resources

**Common errors:**
- Authentication failure: Verify username/password
- Index creation blocked: Check cluster settings for `action.auto_create_index`
- API endpoint incorrect: Ensure URLs don't have trailing slashes

---

## Alert Rule Details

The test alert rules created by these scripts use:

**Rule Type:** ES Query (`.es-query`)
**Index:** `test-alert-data`
**Query:** `status_code:>499`
**Schedule:** Every 1 minute
**Threshold:** Count > 0

This setup ensures the alert triggers quickly for testing.

---

## Cleanup

To remove test resources after testing:

```bash
# Delete the index
curl -u elastic:password -X DELETE "https://your-cluster.es.cloud/test-alert-data"

# Delete the alert rule
# Go to Kibana UI → Stack Management → Rules → Delete the test rule

# Delete the test space (if created)
curl -u elastic:password -X DELETE "https://your-kibana.kb.cloud/api/spaces/space/test-space" \
  -H 'kbn-xsrf: true'
```

---

## Requirements

- `curl` - for making HTTP requests
- `jq` - for JSON parsing (optional, for pretty output)
- Elasticsearch cluster with alerting enabled
- Sufficient permissions to create indices and alert rules

---

## Notes

- These scripts are for **testing and debugging purposes only**
- Do not use in production environments
- Update credentials before running
- Scripts contain example credentials - **never commit real credentials**
