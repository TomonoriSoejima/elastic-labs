#!/bin/bash

# Quick Start Script for Trace Test

set -e

echo "=== Trace Test Setup ==="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Start Elasticsearch
echo ""
echo "📦 Starting Elasticsearch (for API test calls)..."
docker-compose up -d

echo ""
echo "⏳ Waiting for Elasticsearch to be ready..."
until curl -s http://localhost:9200 > /dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo ""
echo "✅ Elasticsearch is ready at http://localhost:9200"

# Download APM agent if not present
if [ ! -f "elastic-apm-agent-1.52.0.jar" ]; then
    echo ""
    echo "📥 Downloading Elastic Java APM Agent v1.52.0..."
    curl -o elastic-apm-agent-1.52.0.jar \
      https://repo1.maven.org/maven2/co/elastic/apm/elastic-apm-agent/1.52.0/elastic-apm-agent-1.52.0.jar
    echo "✅ APM Agent downloaded"
fi

# Build the application
echo ""
echo "🔨 Building application..."
mvn clean package -DskipTests

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Run the app:    ./run-default.sh"
echo "   2. Test it:        ./test.sh (in another terminal)"
echo "   3. View APM data:  https://cloud.elastic.co (Observability → APM → Services)"
echo ""
echo "ℹ️  Using Elastic Cloud APM - traces will be sent to your cloud deployment"
echo ""
