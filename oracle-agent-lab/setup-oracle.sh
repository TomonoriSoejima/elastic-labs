#!/bin/bash
# Oracle Database Setup Script for Integration Testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICKET_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Oracle Database Setup for Integration Testing ==="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Create scripts directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/oracle-init"

# Start Oracle container
echo "📦 Starting Oracle Database container..."
echo "   This may take a few minutes on first run (downloading ~2GB image)"
cd "$TICKET_DIR"
docker-compose up -d

echo ""
echo "⏳ Waiting for Oracle to be ready (this can take 1-2 minutes)..."

# Wait for healthcheck
for i in {1..60}; do
    if docker exec oracle-test healthcheck.sh > /dev/null 2>&1; then
        echo "✓ Oracle Database is ready!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Timeout waiting for Oracle to start"
        echo "   Check logs: docker logs oracle-test"
        exit 1
    fi
    sleep 5
    echo -n "."
done

echo ""
echo ""
echo "=== Connection Information ==="
echo ""
echo "Container Name:    oracle-test"
echo "Database Port:     1521"
echo "Enterprise Manager: 5500 (https://localhost:5500/em)"
echo ""
echo "System User:"
echo "  Username: system"
echo "  Password: OracleTest123"
echo "  Service:  FREEPDB1"
echo ""
echo "Monitoring User (for Elastic integration):"
echo "  Username: elastic_monitor"
echo "  Password: ElasticMon123"
echo "  Service:  FREEPDB1"
echo ""
echo "Connection Strings:"
echo "  SQL*Plus: sqlplus elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1"
echo "  JDBC:     jdbc:oracle:thin:@localhost:1521/FREEPDB1"
echo "  DSN:      user=\"elastic_monitor\" password=\"ElasticMon123\" connectString=\"localhost:1521/FREEPDB1\""
echo ""

# Test connection
echo "🔍 Testing connection..."
if docker exec oracle-test sqlplus -s elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1 <<EOF > /dev/null 2>&1
SELECT 'Connection OK' FROM dual;
EXIT;
EOF
then
    echo "✓ Connection test successful"
else
    echo "⚠️  Connection test failed - checking user setup..."
    echo "   Running user creation script..."
    docker exec oracle-test sqlplus -s system/OracleTest123@localhost:1521/FREEPDB1 @/opt/oracle/scripts/startup/01-create-user.sql
fi

echo ""
echo "=== Quick Test Commands ==="
echo ""
echo "# Connect to Oracle:"
echo "docker exec -it oracle-test sqlplus elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1"
echo ""
echo "# Test the tablespace query:"
echo "docker exec oracle-test sqlplus -s elastic_monitor/ElasticMon123@localhost:1521/FREEPDB1 < analysis/tablespace-query.sql"
echo ""
echo "# View container logs:"
echo "docker logs oracle-test"
echo ""
echo "# Stop Oracle:"
echo "docker-compose down"
echo ""
echo "# Stop and remove all data:"
echo "docker-compose down -v"
echo ""

echo "=== Next Steps ==="
echo ""
echo "1. Configure Oracle integration in Fleet with these settings:"
echo "   Hosts: localhost:1521/FREEPDB1"
echo "   Username: elastic_monitor"
echo "   Password: ElasticMon123"
echo ""
echo "2. Enable the tablespace dataset"
echo ""
echo "3. Monitor for the ORA-00923 error"
echo ""
echo "✅ Setup complete!"
