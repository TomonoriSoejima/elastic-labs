# mOTLP Connectivity Test

A minimal Flask app for testing connectivity to the Elastic Cloud [Managed OTLP (mOTLP) endpoint](https://www.elastic.co/docs/reference/opentelemetry/motlp).

Useful for verifying that traces, metrics, and logs can reach Elastic from a given network environment (e.g. Lambda, Docker, Kubernetes).

## Usage

Build and run, passing your endpoint and API key at runtime:

```bash
docker build -t motlp-test .
docker run --rm -p 8080:8080 \
  -e OTEL_EXPORTER_OTLP_ENDPOINT="https://<your-motlp-endpoint>" \
  -e OTEL_EXPORTER_OTLP_HEADERS="Authorization=ApiKey YOUR_API_KEY_HERE" \
  motlp-test
```

Then trigger a trace:

```bash
curl http://localhost:8080/test
```

## What to look for

With `OTEL_PYTHON_LOG_LEVEL=debug` and `logging.basicConfig(level=logging.DEBUG)` enabled, successful exports appear as:

```
DEBUG:urllib3.connectionpool:https://<endpoint>:443 "POST /v1/traces HTTP/1.1" 200 2
```

| Log output | Meaning |
|---|---|
| `POST /v1/traces HTTP/1.1" 200` | Data reaching Elastic successfully |
| Connection timeout / `ConnectionError` | Network blockage (firewall, NAT, VPC) |
| No `POST` lines at all | OTel instrumentation not set up correctly |

## Environment variables

| Variable | Description |
|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Your mOTLP endpoint URL |
| `OTEL_EXPORTER_OTLP_HEADERS` | `Authorization=ApiKey YOUR_API_KEY_HERE` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` (default) |
| `OTEL_LOGS_EXPORTER` | Set to `none` to suppress noisy `/v1/logs` exports |
