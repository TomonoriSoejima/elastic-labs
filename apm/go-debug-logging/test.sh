#!/bin/bash

echo "Testing APM endpoints..."
echo ""

echo "1. Testing home endpoint:"
curl http://localhost:8080/
echo -e "\n"

echo "2. Testing hello endpoint:"
curl "http://localhost:8080/hello?name=TestUser"
echo -e "\n"

echo "3. Testing API data endpoint:"
curl http://localhost:8080/api/data
echo -e "\n"

echo "Done! Check Kibana APM for traces."
