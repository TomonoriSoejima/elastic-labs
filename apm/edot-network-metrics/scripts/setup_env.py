#!/usr/bin/env python3
"""Populate .env for this lab from a downloaded deployment credentials CSV.

Usage:
  python3 scripts/setup_env.py credentials-<prefix>-<timestamp>.csv

Reads the deployment id prefix from the CSV filename, looks up the deployment's
ES/APM endpoints via the Elastic Cloud API, mints a scoped ES API key for the
EDOT collector's APM auth, and writes .env (gitignored - never commit it).

Requires ELASTIC_CLOUD_API_KEY in the environment.
"""
import csv
import json
import os
import re
import sys
import urllib.request

CLOUD_API = "https://api.elastic-cloud.com/api/v1/deployments"


def cloud_api_get(path, key):
    req = urllib.request.Request(f"{CLOUD_API}{path}", headers={"Authorization": f"ApiKey {key}"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp)


def es_api_post(url, path, user, password, body):
    req = urllib.request.Request(
        f"{url}{path}",
        data=json.dumps(body).encode(),
        method="POST",
        headers={"Content-Type": "application/json"},
    )
    import base64

    token = base64.b64encode(f"{user}:{password}".encode()).decode()
    req.add_header("Authorization", f"Basic {token}")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp)


def main():
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <credentials-csv>", file=sys.stderr)
        sys.exit(1)

    csv_path = sys.argv[1]
    m = re.search(r"credentials-([0-9a-f]{6,})-", os.path.basename(csv_path))
    if not m:
        print("could not find a deployment id prefix in the filename", file=sys.stderr)
        sys.exit(1)
    prefix = m.group(1)

    key = os.environ.get("ELASTIC_CLOUD_API_KEY", "")
    if not key:
        print("Error: ELASTIC_CLOUD_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    with open(csv_path) as f:
        row = next(csv.DictReader(f))
    es_user, es_password = row["username"], row["password"]

    deployments = cloud_api_get("", key).get("deployments", [])
    matches = [d for d in deployments if d.get("id", "").startswith(prefix)]
    if not matches:
        print(f"no deployment found matching prefix {prefix}", file=sys.stderr)
        sys.exit(1)
    dep_id = matches[0]["id"]

    data = cloud_api_get(f"/{dep_id}", key)
    es_url = "https://" + data["resources"]["elasticsearch"][0]["info"]["metadata"]["endpoint"] + ":443"
    apm_endpoint = data["resources"]["integrations_server"][0]["info"]["metadata"]["endpoint"] + ":443"

    api_key_resp = es_api_post(es_url, "/_security/api_key", es_user, es_password, {"name": f"edot-repro-{prefix}"})
    apm_api_key = api_key_resp["encoded"]

    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
    with open(env_path, "w") as f:
        f.write(f"ES_URL={es_url}\n")
        f.write(f"ES_USER={es_user}\n")
        f.write(f"ES_PASSWORD={es_password}\n")
        f.write(f"APM_ENDPOINT={apm_endpoint}\n")
        f.write(f"APM_API_KEY={apm_api_key}\n")
        f.write("DATA_STREAM=metrics-apm.app.mfrs_judge_system-default\n")
        f.write("COMPONENT_TEMPLATE=metrics-apm.app@custom\n")

    print(f"Wrote {env_path} for deployment {dep_id}")


if __name__ == "__main__":
    main()
