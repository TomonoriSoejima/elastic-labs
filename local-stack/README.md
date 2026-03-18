# Local Elastic Stack

Quick-start Docker Compose setup for local Elasticsearch + Kibana development and testing.

## Quick Start

**Start the stack:**
```bash
bash scripts/start.sh
```

**Access:**
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

**Stop:**
```bash
bash scripts/stop.sh
```

**Reset (remove all data):**
```bash
bash scripts/reset.sh
```

## Configuration

Edit `.env` (created on first run) to customize:
- `STACK_VERSION` - Elastic Stack version (default: 8.18.3)
- `ES_PORT` / `KB_PORT` - Port numbers
- `ES_HEAP` - Elasticsearch heap size
- Container names, credentials, encryption keys

## Modes

- **Default** (`bash scripts/start.sh`): No authentication, fast testing
- **Security** (`bash scripts/start.sh security`): Authentication enabled (elastic/changeme)

## Usage Example

See [kibana/rule-gaps/README.md](../kibana/rule-gaps/README.md) for a complete example of using local-stack for detection rule gap testing.

**Quick version:**
```bash
# 1. Start local stack
cd local-stack && bash scripts/start.sh

# 2. Configure your project to use localhost
cd ../kibana/rule-gaps
cp .env.local.example .env

# 3. Run scripts - they auto-detect localhost mode
bash create-test-rules.sh
```

## Requirements

- Docker
- Docker Compose
