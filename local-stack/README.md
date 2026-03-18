# Local Elastic Stack

Quick-start Docker Compose setup for local Elasticsearch + Kibana development and testing.

## Features

- 🚀 Fast local development without Cloud API keys
- 🔄 Two modes: insecure (default) and security-enabled
- ⚙️ Configurable via environment variables
- 🔑 Pre-configured encryption keys for detection rules and alerts
- 💾 Persistent data storage with Docker volumes
- 🏥 Health checks for reliable startup

## Quick Start

### 1. Start the Stack (Insecure Mode)

```bash
bash scripts/start.sh
```

This starts:
- **Elasticsearch** on `http://localhost:9200`
- **Kibana** on `http://localhost:5601`

No authentication required - perfect for quick testing.

### 2. Start with Security Enabled

```bash
bash scripts/start.sh security
```

Default credentials:
- Username: `elastic`
- Password: `changeme` (configure in `.env`)

### 3. Stop the Stack

```bash
bash scripts/stop.sh
```

Data is preserved in Docker volumes.

### 4. Reset Everything

```bash
bash scripts/reset.sh
```

⚠️ This removes all data - fresh start.

## Configuration

On first run, `.env.example` is copied to `.env`. Edit `.env` to customize:

```bash
# Stack version
STACK_VERSION=8.18.3

# Ports
ES_PORT=9200
KB_PORT=5601

# Elasticsearch heap size
ES_HEAP=1g

# Credentials (security mode)
ELASTIC_PASSWORD=changeme

# Container names (useful for running multiple stacks)
ES_CONTAINER_NAME=es-local
KB_CONTAINER_NAME=kb-local
```

## Using with Other Projects

### Example: Kibana Rule Gaps Testing

From `kibana/rule-gaps/` directory:

**1. Start local stack:**
```bash
cd ../../local-stack
bash scripts/start.sh
```

**2. Configure rule-gaps scripts:**
```bash
cd ../kibana/rule-gaps
cp .env.local.example .env
```

The `.env` should contain:
```bash
KIBANA_URL=http://localhost:5601
ES_URL=http://localhost:9200
KIBANA_USER=elastic
KIBANA_PASSWORD=changeme
```

**3. Run scripts:**
```bash
bash create-test-rules.sh
bash create-gaps.sh
bash check-gaps.sh
```

The scripts automatically detect localhost configuration and skip Cloud API.

## Architecture

### Insecure Mode (`docker-compose.yml`)

- `xpack.security.enabled=false`
- No authentication required
- Fastest for development

### Security Mode (`docker-compose.security.yml`)

- `xpack.security.enabled=true`
- Basic authentication with `elastic` user
- More production-like setup

Both modes include:
- Encryption keys for Kibana (required for detection rules, alerts, saved objects)
- Health checks for reliable service startup
- Persistent volumes for data

## Health Checks

Services include health checks:
- **Elasticsearch**: `/_cluster/health`
- **Kibana**: `/api/status`

Docker waits for Elasticsearch to be healthy before starting Kibana.

Check status:
```bash
docker-compose ps
```

View logs:
```bash
docker-compose logs -f elasticsearch
docker-compose logs -f kibana
```

## Encryption Keys

Kibana requires encryption keys for:
- Encrypted saved objects (detection rules, connectors)
- Alerting framework
- Reporting

Default keys are provided in `.env.example` - sufficient for testing.

For production, generate secure keys:
```bash
docker run --rm docker.elastic.co/kibana/kibana:8.18.3 \
  bin/kibana-encryption-keys generate
```

## Troubleshooting

### Port already in use

Change ports in `.env`:
```bash
ES_PORT=9201
KB_PORT=5602
```

### Elasticsearch won't start (out of memory)

Reduce heap size in `.env`:
```bash
ES_HEAP=512m
```

### Data corruption

Reset everything:
```bash
bash scripts/reset.sh
bash scripts/start.sh
```

### Check service health

```bash
# Elasticsearch
curl http://localhost:9200/_cluster/health?pretty

# Kibana
curl http://localhost:5601/api/status
```

## Multiple Stacks

Run multiple stacks simultaneously by customizing container names and ports:

**Stack 1 (.env):**
```bash
ES_CONTAINER_NAME=es-stack1
KB_CONTAINER_NAME=kb-stack1
ES_PORT=9200
KB_PORT=5601
```

**Stack 2 (.env.stack2):**
```bash
ES_CONTAINER_NAME=es-stack2
KB_CONTAINER_NAME=kb-stack2
ES_PORT=9201
KB_PORT=5602
```

Start stack 2:
```bash
docker-compose --env-file .env.stack2 up -d
```

## Upgrading Stack Version

Edit `.env`:
```bash
STACK_VERSION=8.19.0
```

Restart:
```bash
bash scripts/stop.sh
bash scripts/start.sh
```

## Scripts Reference

| Script | Description |
|--------|-------------|
| `scripts/start.sh` | Start stack (insecure mode) |
| `scripts/start.sh security` | Start stack (security enabled) |
| `scripts/stop.sh` | Stop stack (preserve data) |
| `scripts/reset.sh` | Stop and remove all data |

## Related Projects

This local stack is used by:
- `kibana/rule-gaps` - Detection rule execution gap testing
- Add your project here!

## Requirements

- Docker
- Docker Compose

Tested on:
- macOS (Apple Silicon & Intel)
- Linux
- Windows (WSL2)
