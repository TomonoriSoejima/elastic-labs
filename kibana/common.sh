#!/usr/bin/env bash
# common.sh — Shared utility for discovering deployment credentials and URLs via Cloud API
#
# Sources .env from calling script's directory, discovers deployment, resets elastic password,
# and exports credentials and endpoints.
#
# Usage: source "$(dirname "$0")/../common.sh"
#
# Exports:
#   - KIBANA_USER (always "elastic")
#   - KIBANA_PASSWORD (fresh from password reset API)
#   - KIBANA_URL (Kibana endpoint)
#   - ES_URL (Elasticsearch endpoint)
#   - AUTH (KIBANA_USER:KIBANA_PASSWORD for curl)
#   - DEPLOYMENT_ID (deployment identifier)

set -euo pipefail

# Determine calling script's directory (for .env lookup)
if [ -z "${BASH_SOURCE[1]:-}" ]; then
  CALLER_DIR="$(pwd)"
else
  CALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
fi

# ---------- Load .env from caller's directory ----------
if [ -f "${CALLER_DIR}/.env" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "${CALLER_DIR}/.env" | xargs) 2>/dev/null || true
fi

CLOUD_API_KEY="${ELASTIC_CLOUD_API_KEY:?ELASTIC_CLOUD_API_KEY not found. Add it to .env file.}"
CLOUD_API_BASE="https://api.elastic-cloud.com/api/v1"

# Export for Python scripts
export CLOUD_API_KEY
export CLOUD_API_BASE

echo "==> Discovering deployment via Cloud API..." >&2

# ---------- Discover deployment ----------
DEPLOYMENT_JSON=$(python3 - <<'PYEOF'
import requests, sys, os

CLOUD_API_BASE = os.environ["CLOUD_API_BASE"]
CLOUD_API_KEY = os.environ["CLOUD_API_KEY"]
DEPLOYMENT_ID_ENV = os.environ.get("DEPLOYMENT_ID", "")

hdrs = {"Authorization": f"ApiKey {CLOUD_API_KEY}", "Content-Type": "application/json"}

resp = requests.get(f"{CLOUD_API_BASE}/deployments", headers=hdrs, timeout=10)
resp.raise_for_status()
deployments = resp.json().get("deployments", [])

if not deployments:
    sys.exit("No deployments found for this Cloud API key")

# If DEPLOYMENT_ID specified, find that one
if DEPLOYMENT_ID_ENV:
    for dep in deployments:
        if dep["id"].startswith(DEPLOYMENT_ID_ENV):
            print(dep["id"])
            sys.exit(0)
    sys.exit(f"Deployment {DEPLOYMENT_ID_ENV} not found")

# Otherwise use first deployment
dep_id = deployments[0]["id"]
dep_name = deployments[0].get("name", dep_id)
print(f"[auto-selected: {dep_name}]", file=sys.stderr)
print(dep_id)
PYEOF
)

export DEPLOYMENT_ID="${DEPLOYMENT_JSON}"
echo "[deployment: ${DEPLOYMENT_ID}]" >&2

# ---------- Get elastic user password ----------
echo "==> Getting elastic user password..." >&2

PASSWORD_JSON=$(python3 - <<'PYEOF'
import requests, sys, os

CLOUD_API_BASE = os.environ["CLOUD_API_BASE"]
CLOUD_API_KEY = os.environ["CLOUD_API_KEY"]
DEPLOYMENT_ID = os.environ["DEPLOYMENT_ID"]
KIBANA_PASSWORD_ENV = os.environ.get("KIBANA_PASSWORD", "")

# If password already cached in .env, use it directly
if KIBANA_PASSWORD_ENV:
    print(f"[✓] Using cached KIBANA_PASSWORD from .env", file=sys.stderr)
    print(KIBANA_PASSWORD_ENV)
    sys.exit(0)

hdrs = {"Authorization": f"ApiKey {CLOUD_API_KEY}", "Content-Type": "application/json"}

# Get deployment details to find ES ref_id
resp = requests.get(f"{CLOUD_API_BASE}/deployments/{DEPLOYMENT_ID}", headers=hdrs, timeout=10)
resp.raise_for_status()
resources = resp.json().get("resources", {})
es_resources = resources.get("elasticsearch", [])

if not es_resources:
    sys.exit("No Elasticsearch resource found in deployment")

ref_id = es_resources[0]["ref_id"]

# Reset elastic user password via Cloud API
reset_url = f"{CLOUD_API_BASE}/deployments/{DEPLOYMENT_ID}/elasticsearch/{ref_id}/_reset-password"
reset_resp = requests.post(reset_url, headers=hdrs, timeout=10)

if reset_resp.status_code == 200:
    password = reset_resp.json().get("password")
    if password:
        print(f"[✓] Password reset via Cloud API", file=sys.stderr)
        print(password)
        sys.exit(0)

sys.exit(
    f"Password reset failed: HTTP {reset_resp.status_code}\n"
    f"{reset_resp.text[:300]}\n\n"
    f"To fix: either add KIBANA_PASSWORD=<password> to your .env file, "
    f"or use a Cloud API key with Admin role."
)
PYEOF
)

export KIBANA_USER="elastic"
export KIBANA_PASSWORD="${PASSWORD_JSON}"
export AUTH="${KIBANA_USER}:${KIBANA_PASSWORD}"

echo "[✓] Using elastic user credentials" >&2

# Cache the password in .env so future runs skip the reset
ENV_FILE="${CALLER_DIR}/.env"
if ! grep -q "^KIBANA_PASSWORD=" "${ENV_FILE}" 2>/dev/null; then
  echo "KIBANA_PASSWORD=${KIBANA_PASSWORD}" >> "${ENV_FILE}"
  echo "[✓] Password cached in .env" >&2
fi
echo "==> Discovering endpoints..." >&2

ENDPOINTS_JSON=$(python3 - <<'PYEOF'
import requests, sys, os, json

CLOUD_API_BASE = os.environ["CLOUD_API_BASE"]
CLOUD_API_KEY = os.environ["CLOUD_API_KEY"]
DEPLOYMENT_ID = os.environ["DEPLOYMENT_ID"]

hdrs = {"Authorization": f"ApiKey {CLOUD_API_KEY}", "Content-Type": "application/json"}

resp = requests.get(f"{CLOUD_API_BASE}/deployments/{DEPLOYMENT_ID}", headers=hdrs, timeout=10)
resp.raise_for_status()
resources = resp.json().get("resources", {})

kb_resources = resources.get("kibana", [])
es_resources = resources.get("elasticsearch", [])

if not kb_resources or not es_resources:
    sys.exit("Missing Kibana or Elasticsearch resources")

kb_meta = kb_resources[0].get("info", {}).get("metadata", {})
es_meta = es_resources[0].get("info", {}).get("metadata", {})

kb_url = kb_meta.get("aliased_url") or kb_meta.get("service_url")
es_url = es_meta.get("aliased_url") or es_meta.get("service_url")

if not kb_url or not es_url:
    sys.exit("Could not extract URLs from deployment metadata")

result = {"kibana_url": kb_url.rstrip("/"), "es_url": es_url.rstrip("/")}
print(json.dumps(result))
PYEOF
)

export KIBANA_URL=$(echo "${ENDPOINTS_JSON}" | python3 -c "import sys, json; print(json.load(sys.stdin)['kibana_url'])")
export ES_URL=$(echo "${ENDPOINTS_JSON}" | python3 -c "import sys, json; print(json.load(sys.stdin)['es_url'])")

echo "[✓] Kibana: ${KIBANA_URL}" >&2
echo "[✓] ES: ${ES_URL}" >&2

# Wait for password to propagate to ES (reset API returns before ES picks it up)
echo "==> Waiting for new password to be accepted by ES..." >&2
for i in $(seq 1 12); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -u "${AUTH}" "${ES_URL}/_cluster/health")
  if [ "${HTTP_STATUS}" = "200" ]; then
    echo "[✓] ES authenticated (attempt ${i})" >&2
    break
  fi
  if [ "${i}" = "12" ]; then
    echo "[✗] ES still returning ${HTTP_STATUS} after 60s — giving up" >&2
    exit 1
  fi
  echo "[...] attempt ${i}: HTTP ${HTTP_STATUS}, retrying in 5s..." >&2
  sleep 5
done
echo "" >&2
