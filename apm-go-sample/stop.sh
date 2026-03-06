#!/bin/bash

echo "Stopping APM test server..."
pkill -f "go run main.go"
echo "Server stopped."
