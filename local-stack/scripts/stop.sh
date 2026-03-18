#!/usr/bin/env bash
# stop.sh - Stop local Elastic Stack
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Stopping Elastic Stack..."
echo ""

# Try to stop both modes (one will fail silently if not running)
docker-compose -f docker-compose.yml down 2>/dev/null || true
docker-compose -f docker-compose.security.yml down 2>/dev/null || true

echo "✓ Stack stopped"
echo ""
echo "Note: Data is preserved in Docker volumes"
echo "To completely remove data: bash scripts/reset.sh"
