# Local Stack — ES + Kibana + Fleet Server

Runs a secured (TLS) local Elastic stack with Elasticsearch, Kibana, and Fleet Server.

## Setup

```bash
cp .env.example .env
# Edit .env and set your passwords
docker compose up -d
```

## Default credentials

| Field    | Value               |
|----------|---------------------|
| URL      | https://localhost:5601 (Kibana) |
| URL      | https://localhost:9200 (ES)     |
| Username | `elastic`           |
| Password | value of `ELASTIC_PASSWORD` in `.env` (default: `changeme`) |

> **Note**: Kibana uses HTTPS with a self-signed CA. Your browser will show a certificate warning — this is expected.

## Ports

| Service      | Port |
|--------------|------|
| Elasticsearch | 9200 |
| Kibana        | 5601 |
| Fleet Server  | 8220 |
| APM Server    | 8200 |

## Stop / teardown

```bash
# Stop (keeps data volumes)
docker compose down

# Stop and remove all data
docker compose down -v
```

## Notes

- TLS certs are auto-generated on first start and stored in the `certs` Docker volume.
- To enroll an Elastic Agent, use Fleet URL `https://localhost:8220` and the CA at `/certs/ca/ca.crt` inside the `certs` volume.
