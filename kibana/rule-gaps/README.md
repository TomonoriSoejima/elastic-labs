# Rule Gaps Testing

Scripts for reproducing Security detection rule execution gaps through rule disable/enable cycles.

## Strategy

Create gaps by disabling rules, waiting, then re-enabling them manually via the Kibana UI or API.

- Create test rules with a short interval (default: `1s`)
- Disable all test rules
- Wait a few minutes
- Re-enable all rules
- Gaps appear in the monitoring window

This method creates predictable, demonstrable gaps.

> **Note:** In practice, ~30 rules are needed to reliably reproduce gaps. The default of 5 is enough to verify the workflow. Increase with `NUM_RULES=30`.

## Quick Start

**1. Copy `.env` from alerts directory:**
```bash
cp ../alerts/.env .
```

**2. Edit `.env` and add your Cloud API key (if not already set):**
```bash
ELASTIC_CLOUD_API_KEY=your-cloud-api-key-here
```

**3. Create test rules:**
```bash
bash create-test-rules.sh
```

**4. In Kibana, disable the gap-test rules, wait a few minutes, then re-enable them:**

Security → Detection rules → filter by tag `gap-test` → select all → Disable → wait → Enable

**5. Monitor for gaps:**

**Script (easiest):**
```bash
bash check-gaps.sh          # check once
WATCH=1 bash check-gaps.sh  # poll every 30s until Ctrl+C
```

**UI:**  
Security → Detection rules → Rule Monitoring → Gaps tab

**Event log query:**
```json
GET .kibana-event-log-*/_search
{
  "size": 10,
  "query": { "term": { "event.action": "gap" } },
  "sort": [{"@timestamp": "desc"}]
}
```

**6. Clean up when done:**
```bash
bash cleanup-test-rules.sh
```

## Configuration

### Environment Variables (create-test-rules.sh)

- `NUM_RULES` - Number of rules to create (default: `5`, recommend `30` for reliable reproduction)
- `RULE_INTERVAL` - Rule execution interval (default: `1s`)
- `RULE_INDEX` - Indices to query (default: `metrics-*`)
- `DEPLOYMENT_ID` - Target deployment ID (auto-detected from first deployment if not set)

## Monitoring Commands

**Check current rule count:**
```bash
curl -s -u "elastic:PASSWORD" \
  -H "kbn-xsrf: true" \
  "https://deployment.kb.region.gcp.elastic-cloud.com/api/detection_engine/rules/_find?filter=alert.attributes.tags:%20%22gap-test%22&per_page=1" \
  | jq '.total'
```

**Check gap count:**
```bash
curl -s -u "elastic:PASSWORD" \
  "https://deployment.es.region.gcp.elastic-cloud.com/.kibana-event-log-*/_search" \
  -H "Content-Type: application/json" \
  -d '{"size":10,"query":{"term":{"event.action":"gap"}},"sort":[{"@timestamp":"desc"}]}' \
  | jq '.hits.hits[]._source | {timestamp: .["@timestamp"], rule: .rule.name, duration: .kibana.alert.rule.gap.duration}'
```

## References

- [Rule Monitoring - Gaps Table](https://www.elastic.co/guide/en/security/8.18/alerts-ui-monitor.html#gaps-table)
- [Task Manager Production Considerations](https://www.elastic.co/guide/en/kibana/current/task-manager-production-considerations.html)
