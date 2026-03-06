#!/bin/bash

# Test script - sends requests and shows results

echo "=== Testing Trace Test Application ==="
echo ""

# Test with traceparent header (simulating RUM)
echo "📤 Test 1: WITH traceparent header (simulating Angular RUM)"
echo "   This simulates the customer's scenario"
echo ""
curl -s -H "traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01" \
  http://localhost:8080/api/test | jq .

echo ""
echo "---"
echo ""

# Test without traceparent
echo "📤 Test 2: WITHOUT traceparent header"
echo "   This lets the Java agent create a new trace"
echo ""
curl -s http://localhost:8080/api/test | jq .

echo ""
echo "---"
echo ""

echo "✅ Tests complete!"
echo ""
echo "📊 View traces in Kibana: http://localhost:5601/app/apm/services"
echo ""
echo "🔍 Check trace IDs in Elasticsearch:"
echo '   curl -s "http://localhost:9200/apm-*/_search?size=20&pretty" | grep -A 2 "trace.id"'
echo ""
