Phase 1: One-click APM repro (Node.js)

Steps:
1. Create a `.env` file.
    - Required:
       - `ELASTIC_CLOUD_API_KEY`
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
