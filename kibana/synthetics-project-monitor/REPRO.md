# STACK-3058 Repro Lab

Reproduces: monitor ID collision when pushing the same `@elastic/synthetics` project
to two different environments (staging + production).

**Confirmed on:** `@elastic/synthetics` v1.23.1, Kibana 8.19.7

---

## 1. Prerequisites

- Node.js installed
- Access to an Elastic Cloud deployment (v8.x)
- `ELASTIC_CLOUD_API_KEY` env var set (ESS user key, `essu_...`)

---

## 2. Create the API key

The Synthetics push command requires **Kibana feature privileges** (`uptime-read` /
`uptime-write`), not just ES cluster/index privileges. This tripped us up for a while.

Use the **ES REST API directly** authenticated with the **`elastic` user password**, including the `applications` field in the role descriptor.

> If you don't know the `elastic` user password, reset it via the Cloud API:
> ```bash
> curl -s -X POST \
>   "https://api.elastic-cloud.com/api/v1/deployments/<dep_id>/elasticsearch/main-elasticsearch/_reset-password" \
>   -H "Authorization: ApiKey $ELASTIC_CLOUD_API_KEY"
> ```

#### Create the API key with Kibana uptime privileges

```bash
curl -s -X POST "https://<your-deployment>.es.<region>.gcp.cloud.es.io/_security/api_key" \
  -H "Content-Type: application/json" \
  -u "elastic:<password>" \
  -d '{
    "name": "synthetics-lab",
    "role_descriptors": {
      "synthetics_role": {
        "cluster": ["all"],
        "indices": [{"names": ["*"], "privileges": ["all"]}],
        "applications": [
          {
            "application": "kibana-.kibana",
            "privileges": ["feature_uptime.all"],
            "resources": ["space:default"]
          }
        ]
      }
    }
  }'
```

Copy the `encoded` value from the response — that is your API key.

---

## 3. Setup

```bash
npm install
```

Fill in `.env`:
```
STAGING_KIBANA_URL=https://<deployment>.kb.<region>.gcp.cloud.es.io
STAGING_API_KEY=<encoded-key-from-above>
```

---

## 4. Reproduce the collision

### Step 1 — Push as staging
```bash
NODE_ENV=staging npx @elastic/synthetics push --auth $STAGING_API_KEY --yes
```

Output:
```
Monitor Diff: Added(1) Updated(0) Removed(0) Unchanged(0)
```

### Step 2 — Snapshot the monitor state
```bash
curl -s "https://<kibana-url>/api/synthetics/project/lab-synthetics-project/monitors" \
  -H "Authorization: ApiKey $STAGING_API_KEY" \
  -H "kbn-xsrf: true"
```

Output:
```json
{
  "total": 1,
  "monitors": [
    { "journey_id": "pg-cj1", "hash": "txj+1Z61cSTMqyM0PIBxsyAMHBu2h+453FFIxYUtVIo=" }
  ]
}
```

### Step 3 — Push as production
```bash
NODE_ENV=production npx @elastic/synthetics push --auth $STAGING_API_KEY --yes
```

Output:
```
Monitor Diff: Added(0) Updated(0) Removed(0) Unchanged(1)
```

### Step 4 — Check the monitor state again

Same API call as Step 2. Output is **identical**:
```json
{
  "total": 1,
  "monitors": [
    { "journey_id": "pg-cj1", "hash": "txj+1Z61cSTMqyM0PIBxsyAMHBu2h+453FFIxYUtVIo=" }
  ]
}
```

### Result

- Monitor count is still **1**, not 2
- `journey_id` and `hash` are unchanged — the production push found the same monitor ID and did nothing
- `NODE_ENV` has no effect on the monitor ID, which is derived solely from journey name + project ID + space

In the customer's real scenario (two separate Kibana deployments), both deployments create a monitor with the same ID — impossible to tell them apart, and whichever pushes last silently overwrites the other's config.

---

## 5. Workaround (what the customer did)

Embed the environment in the **journey name**:
```
pg-cj1  →  pg-cj1-stg-aa0b5fc4   (staging)
pg-cj1  →  pg-cj1-prod-aa0b5fc4  (production)
```

This is the correct approach. There is no `environment` field in the `project` config
block and no `--environment` CLI flag — both were confirmed against the 8.19 docs.
