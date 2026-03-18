# Rule Gaps Testing

Scripts for reproducing Security detection rule execution gaps through rule disable/enable cycles.

## Strategy

Create gaps by disabling rules, waiting, then re-enabling them manually via the Kibana UI or API.

- Create test rules with a short interval (default: `5s`)
- Disable all test rules
- Wait 5 minutes
- Re-enable all rules
- Gaps appear in the monitoring window

This method creates predictable, demonstrable gaps.

> **Note:** In practice, ~30 rules are needed to reliably reproduce gaps. The default of 5 is enough to verify the workflow. Increase with `NUM_RULES=30`.

## Kibana Log Output When a Gap Occurs

When a gap is detected, the following error appears in the Kibana server logs:

```
Executing Rule siem.queryRule:2e2188b6-7116-40b7-a2e8-b087c99237c9 has resulted in the following error(s):
a minute (74065ms) were not queried between this rule execution and the last execution,
so signals may have been missed. Consider increasing your look behind time or adding more Kibana instances
```

> **Important:** This message is **generic** — it fires whenever a gap is detected, regardless of the actual root cause. It does **not** reliably indicate Task Manager overload. The recommendation to "add more Kibana instances" may be misleading; the real cause could be slow queries (e.g. against Frozen/Cold tier nodes), too many rules, or other resource constraints.
>
> This behaviour is tracked in [elastic/kibana#190100](https://github.com/elastic/kibana/issues/190100), which proposes reclassifying this as a user error rather than a framework error.

## Quick Start

> **💡 Tip:** For faster local testing, use the [local-stack](../../local-stack/) Docker setup instead of Cloud deployments.

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

**4. Create gaps (choose one method):**

**Method A: Automated Script (Recommended)**
```bash
bash create-gaps.sh                    # disable for 5 min (default)
DISABLE_DURATION=600 bash create-gaps.sh  # disable for 10 min
```

**Method B: Manual via Kibana UI**  
Security → Detection rules → filter by tag `gap-test` → select all → Disable → wait 5 min → Enable

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

## Querying Gaps by Rule Name Pattern

The gap information displayed in **Security → Rules → (Rule Name) → Gaps** is stored in `.kibana-event-log-*` and can be queried via DevTools or Discover.

### DevTools Query Example

Search for gaps matching specific rule name patterns:

```json
GET .kibana-event-log-*/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "term": {
            "event.provider": "alerting"
          }
        },
        {
          "term": {
            "event.action": "execute"
          }
        },
        {
          "exists": {
            "field": "kibana.alert.rule.execution.gap_duration_s"
          }
        },
        {
          "wildcard": {
            "rule.name": "Gap Test Rule*"
          }
        }
      ],
      "filter": [
        {
          "range": {
            "@timestamp": {
              "gte": "now-7d"
            }
          }
        }
      ]
    }
  },
  "sort": [
    {
      "@timestamp": {
        "order": "desc"
      }
    }
  ],
  "_source": [
    "@timestamp",
    "rule.name",
    "rule.id",
    "kibana.alert.rule.execution.gap_duration_s",
    "event.outcome",
    "message"
  ],
  "size": 100
}
```

### Key Fields

- `kibana.alert.rule.execution.gap_duration_s` - Gap duration in seconds
- `rule.name` - Rule name (supports wildcard and regexp queries)
- `rule.id` - Rule ID
- `event.outcome` - Execution outcome (success, failure, etc.)
- `@timestamp` - Execution timestamp

### Discover Method

1. Index pattern: `.kibana-event-log-*`
2. Add filters:
   - `event.provider: alerting`
   - `event.action: execute`
   - `kibana.alert.rule.execution.gap_duration_s exists`
   - `rule.name: Gap Test Rule*` (KQL wildcard)
3. Add fields to table: `@timestamp`, `rule.name`, `kibana.alert.rule.execution.gap_duration_s`

**6. Clean up when done:**
```bash
bash cleanup-test-rules.sh
```

## Configuration

### Environment Variables

**create-test-rules.sh:**
- `NUM_RULES` - Number of rules to create (default: `5`, recommend `30` for reliable reproduction)
- `RULE_INTERVAL` - Rule execution interval (default: `5s`)
- `RULE_INDEX` - Indices to query (default: `metrics-*`)
- `DEPLOYMENT_ID` - Target deployment ID (auto-detected from first deployment if not set)

**create-gaps.sh:**
- `DISABLE_DURATION` - How long to disable rules in seconds (default: `300` = 5 minutes)

**check-gaps.sh:**
- `WATCH` - Enable continuous monitoring (default: `0`, set to `1` for watch mode)
- `INTERVAL` - Check interval in seconds when watching (default: `30`)

## Scripts Overview

- `create-test-rules.sh` - Create detection rules with short intervals for gap testing
- `create-gaps.sh` - Automated gap creation by disabling/waiting/re-enabling rules
- `check-gaps.sh` - Query and display gaps from event log
- `cleanup-test-rules.sh` - Delete all gap-test rules

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
- [elastic/kibana#190100](https://github.com/elastic/kibana/issues/190100) - Open issue: gap message miscategorised as framework error
