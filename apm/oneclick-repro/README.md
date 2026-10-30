Phase 1: One-click APM repro (Node.js)

Steps:
1. Create a `.env` file.
    - Required:
       - `ELASTIC_CLOUD_API_KEY`
    - To create the key:
       1. Sign in at https://cloud.elastic.co and go to **Organization** > **API keys** (https://cloud.elastic.co/account/keys).
       2. Click **Create API key**, enter a name and expiration, and assign a role with access to your deployments (for example, Organization owner, or Admin on the target deployments). This is an Elastic Cloud API key, not an Elasticsearch one.
       3. Copy the key immediately; it is shown only once. Cloud API keys start with `essu_`.
       4. Add it to `.env`: `ELASTIC_CLOUD_API_KEY=essu_...`
       5. Optional check: `curl -H "Authorization: ApiKey $ELASTIC_CLOUD_API_KEY" https://api.elastic-cloud.com/api/v1/deployments`
2. Run:
   `docker compose up --build`
3. Open http://localhost:3000 to use the UI for:
   1. choose deployment
   2. choose language (`java`, `go`, `python`, `js`)
   3. deployment auto-activates in the background, then start traffic
   4. open Kibana link to check APM data


<img width="1125" height="730" alt="image" src="https://github.com/user-attachments/assets/a8db2f2f-ba1b-4f72-81e5-d286b6e1b1d8" />

Runtime behavior on this branch:
- `python` traffic is routed to `python-worker`.
- `java` traffic is routed to `java-worker`.
- `go` traffic is routed to `go-worker`.
- `js` traffic runs on the Node service.

Success:
- Service appears in Kibana APM within ~1 minute.
