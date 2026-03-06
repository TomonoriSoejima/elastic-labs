#!/bin/bash

# Load APM Configuration from .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
    echo "Loaded configuration from .env"
else
    echo "Error: .env file not found. Run ./setup.sh first."
    exit 1
fi

# Enable Debug Logging
export ELASTIC_APM_LOG_LEVEL=debug
export ELASTIC_APM_LOG_FILE=apm_debug.log

# Go Configuration
export GOPATH=$HOME/go
export GOCACHE=$HOME/.cache/go-build
export GOSUMDB=off

echo "APM Configuration:"
echo "  Service: $ELASTIC_APM_SERVICE_NAME"
echo "  Server:  $ELASTIC_APM_SERVER_URL"
echo "  Env:     $ELASTIC_APM_ENVIRONMENT"
echo

echo "Starting APM test server in background..."
nohup go run main.go > server.log 2>&1 &
SERVER_PID=$!
echo "Server started with PID: $SERVER_PID"
echo "Waiting for server to be ready..."
sleep 3
echo "Server is ready at http://localhost:8080"
echo "Logs: tail -f server.log"
