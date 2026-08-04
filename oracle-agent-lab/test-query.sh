#!/bin/bash
# Test the tablespace query directly against the Oracle container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICKET_DIR="$(dirname "$SCRIPT_DIR")"

if ! docker ps | grep -q oracle-test; then
    echo "❌ Oracle container is not running"
    echo "   Run: ./scripts/setup-oracle.sh"
    exit 1
fi

echo "=== Testing Tablespace Query ==="
echo ""
echo "Running query from analysis/tablespace-query.sql..."
echo ""

# Copy the SQL file into the container and execute it
docker cp "$TICKET_DIR/analysis/tablespace-query.sql" oracle-test:/tmp/test-query.sql

docker exec oracle-test sqlplus -s elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1 <<EOF
@/tmp/test-query.sql
EXIT;
EOF

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Query executed successfully"
else
    echo "❌ Query failed with exit code: $EXIT_CODE"
    echo ""
    echo "Check for ORA-00923 error above"
fi

exit $EXIT_CODE
