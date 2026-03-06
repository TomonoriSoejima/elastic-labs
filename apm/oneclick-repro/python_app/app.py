import json
import os
import threading
import time

import elasticapm
from elasticapm.contrib.flask import ElasticAPM
from flask import Flask, jsonify, request


def read_override(path: str):
    try:
        if not os.path.exists(path):
            return None
        with open(path, "r", encoding="utf-8") as file:
            payload = json.load(file)
        if not payload.get("serverUrl") or not payload.get("secretToken"):
            return None
        return payload
    except Exception:
        return None


override_path = os.getenv("ELASTIC_APM_TARGET_OVERRIDE_PATH", "/shared/apm-target.override.json")
override = read_override(override_path)

active_server_url = (override or {}).get("serverUrl") or os.getenv("ELASTIC_APM_SERVER_URL", "")
active_secret_token = (override or {}).get("secretToken") or os.getenv("ELASTIC_APM_SECRET_TOKEN", "")
active_service_name = (override or {}).get("serviceName") or os.getenv("ELASTIC_APM_SERVICE_NAME", "python-demo")
active_environment = os.getenv("ELASTIC_APM_ENVIRONMENT", "repro")

app = Flask(__name__)
app.config["ELASTIC_APM"] = {
    "SERVICE_NAME": active_service_name,
    "SECRET_TOKEN": active_secret_token,
    "SERVER_URL": active_server_url,
    "ENVIRONMENT": active_environment,
    "DEBUG": False,
}
ElasticAPM(app)


def run_work():
    value = 0
    for index in range(2_000_000):
        value += index % 7
    time.sleep(0.08)
    return value


@app.get("/health")
def health():
    return jsonify({"ok": True})


@app.get("/work")
def work():
    language = request.args.get("language", "python")
    deployment_id = request.args.get("deploymentId", "")

    elasticapm.label(test_language=language)
    if deployment_id:
        elasticapm.label(test_deployment_id=deployment_id)

    started = time.time()
    value = run_work()
    duration_ms = int((time.time() - started) * 1000)
    return jsonify(
        {
            "ok": True,
            "x": value,
            "durationMs": duration_ms,
            "language": language,
            "deploymentId": deployment_id,
            "runtime": "python",
        }
    )


@app.post("/work/batch")
def work_batch():
    body = request.get_json(silent=True) or {}
    requested_count = int(body.get("count", 1))
    count = max(1, min(requested_count, 1000))
    language = str(body.get("language", "python"))
    deployment_id = str(body.get("deploymentId", ""))

    elasticapm.label(test_language=language)
    if deployment_id:
        elasticapm.label(test_deployment_id=deployment_id)

    started = time.time()
    for _ in range(count):
        run_work()
    duration_ms = int((time.time() - started) * 1000)

    return jsonify(
        {
            "ok": True,
            "count": count,
            "durationMs": duration_ms,
            "language": language,
            "deploymentId": deployment_id,
            "runtime": "python",
        }
    )


@app.post("/internal/restart")
def internal_restart():
    def delayed_exit():
        time.sleep(0.2)
        os._exit(0)

    thread = threading.Thread(target=delayed_exit, daemon=True)
    thread.start()
    return jsonify({"ok": True, "message": "python worker restarting"})


if __name__ == "__main__":
    port = int(os.getenv("PORT", "3001"))
    app.run(host="0.0.0.0", port=port)
