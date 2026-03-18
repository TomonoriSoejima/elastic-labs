#!/usr/bin/env bash
# start.sh - Start local Elastic Stack
set -euo pipefail

cd "$(dirname "$0")/.."

# Check if .env exists, if not copy from example
if [ ! -f .env ]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
  echo "✓ .env created - edit it if you need custom configuration"
  echo ""
fi

# Determine which compose file to use
COMPOSE_FILE="docker-compose.yml"
MODE="insecure"

if [ "${1:-}" = "security" ] || [ "${1:-}" = "secure" ]; then
  COMPOSE_FILE="docker-compose.security.yml"
  MODE="secure"
fi

echo "Starting Elastic Stack ($MODE mode)..."
echo ""

docker-compose -f "${COMPOSE_FILE}" up -d

echo ""
echo "Waiting for services to be healthy..."
docker-compose -f "${COMPOSE_FILE}" ps

echo ""
echo "✓ Stack started successfully!"
echo ""
echo "Services:"
echo "  Elasticsearch: http://localhost:${ES_PORT:-9200}"
echo "  Kibana:        http://localhost:${KB_PORT:-5601}"

if [ "$MODE" = "secure" ]; then
  echo ""
  echo "Credentials:"
  echo "  Username: elastic"
  echo "  Password: ${ELASTIC_PASSWORD:-changeme}"
fi

echo ""
echo "To stop: bash scripts/stop.sh"
echo "To reset: bash scripts/reset.sh"
