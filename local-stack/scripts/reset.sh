#!/usr/bin/env bash
# reset.sh - Stop and remove all data (fresh start)
set -euo pipefail

cd "$(dirname "$0")/.."

echo "⚠️  WARNING: This will remove all Elasticsearch data!"
echo ""
read -p "Are you sure? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "Cancelled"
  exit 0
fi

echo "Stopping containers..."
docker-compose -f docker-compose.yml down 2>/dev/null || true
docker-compose -f docker-compose.security.yml down 2>/dev/null || true

echo "Removing volumes..."
docker-compose -f docker-compose.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.security.yml down -v 2>/dev/null || true

echo ""
echo "✓ Stack reset complete"
echo ""
echo "To start fresh: bash scripts/start.sh"
