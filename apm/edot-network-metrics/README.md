# EDOT Network Metrics — Infrastructure View Repro Lab

Repro and validated fix for two related EDOT Collector issues affecting the Kibana
Infrastructure (`Observability → Infrastructure → Hosts`) view:

1. `docker-repro/` — missing `host.hostname` in hostmetrics (case 02135373)
2. `network-alias-workaround/` — network metrics not displaying, and how to make the
   KB 2244088e alias workaround survive data stream rollover (case 02136457)

## Setup

Option A — manual:
```bash
cp .env.example .env
# fill in ES_URL / ES_USER / ES_PASSWORD / APM_ENDPOINT / APM_API_KEY for your sandbox deployment
chmod +x docker-repro/*/run.sh network-alias-workaround/*.sh
```

Option B — from a downloaded deployment credentials CSV (e.g. `credentials-0e40fc-...csv`
from the Cloud console when creating/resetting a sandbox deployment):
```bash
python3 scripts/setup_env.py /path/to/credentials-0e40fc-2026-Sep-02--09_25_10.csv
chmod +x docker-repro/*/run.sh network-alias-workaround/*.sh
```
This looks up the deployment's ES/APM endpoints from the deployment id prefix in the
filename, mints a scoped ES API key, and writes `.env` automatically. Requires
`ELASTIC_CLOUD_API_KEY` in the environment. `.env` is gitignored — never commit it.


## docker-repro/ — host.hostname missing

- `baseline/run.sh` — hostmetrics without `resourcedetection`; confirms `host.*` is missing.
- `with-host-detection/run.sh` — adds the `resourcedetection` processor; confirms `host.hostname` / `host.name` populate.

## network-alias-workaround/ — network metrics + rollover-safe alias

Root cause: the `inframetrics` processor maps network fields to `system.network.*`,
but the Kibana Infrastructure UI reads `host.network.*`. KB 2244088e's Option I
(`PUT <index>/_mapping`) fixes this, but the alias is lost on rollover since new
backing indices don't inherit a manually applied `_mapping` change.

- `trigger-alias-error.sh` — reproduces the customer's exact `mapper_parsing_exception`
  when adding the alias directly to a component template (`metrics-apm.app@custom`).
  Fails because the template is validated in isolation and can't see the
  dynamically-mapped `system.network.*` fields.
- `apply-fix.sh` — the validated fix: declare the concrete `system.network.*` field
  mapping in the **same** component template as the alias, so ES can resolve the
  alias target. Confirmed `{"acknowledged": true}`.
- `verify-rollover.sh` — forces a rollover and confirms the new backing index
  inherits the alias automatically, with no manual re-application.

Full writeup: [Making Field Aliases Rollover-Safe via Component Templates](https://support.elastic.co/knowledge/f9813ea9)
(and the original [KB 2244088e](https://support.elastic.co/knowledge/2244088e)).
