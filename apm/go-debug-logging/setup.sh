#!/bin/bash

# Dynamic APM Configuration Setup
# Auto-discovers deployment and fetches APM config from Fleet API

unset EC_API_KEY  # Use ~/.ecctl/config.json instead

SERVICE_NAME="apm_go_sample"
ENVIRONMENT="production"

# Find credentials file
CRED_FILE=$(ls credentials-*.csv 2>/dev/null | head -1)
[ -z "$CRED_FILE" ] && echo "Error: No credentials-*.csv file found" && exit 1

# Extract deployment prefix (e.g., credentials-6d6bb1-... -> 6d6bb1)
DEPLOYMENT_PREFIX=$(echo "$CRED_FILE" | sed -n 's/credentials-\([^-]*\)-.*/\1/p')

# Find full deployment ID via ecctl
DEPLOYMENT_ID=$(ecctl deployment list --output json 2>/dev/null | \
    jq -r ".deployments[] | select(.id | startswith(\"$DEPLOYMENT_PREFIX\")) | .id" | head -1)

[ -z "$DEPLOYMENT_ID" ] && echo "Error: Deployment not found. Check ecctl config." && exit 1

echo "Found deployment: $DEPLOYMENT_ID"

# Get deployment info
DEPLOYMENT_JSON=$(ecctl deployment show "$DEPLOYMENT_ID" --output json 2>/dev/null)

# Extract integrations_server ID and region
APM_ID=$(echo "$DEPLOYMENT_JSON" | jq -r '.resources.integrations_server[0].id')
REGION=$(echo "$DEPLOYMENT_JSON" | jq -r '.resources.elasticsearch[0].region')

# Convert region format: "gcp-asia-northeast1" -> "asia-northeast1.gcp"
[[ "$REGION" =~ ^([^-]+)-(.+)$ ]] && REGION="${BASH_REMATCH[2]}.${BASH_REMATCH[1]}"

# Construct APM server URL
SERVER_URL="https://${APM_ID}.apm.${REGION}.cloud.es.io:443"

# Get APM secret token from Fleet API
KIBANA_URL=$(echo "$DEPLOYMENT_JSON" | jq -r '.resources.kibana[0].info.metadata.service_url')
ES_USER=$(head -n 2 "$CRED_FILE" | tail -n 1 | cut -d',' -f1)
ES_PASSWORD=$(tail -n 1 "$CRED_FILE" | cut -d',' -f2)

SECRET_TOKEN=$(curl -s -u "$ES_USER:$ES_PASSWORD" "$KIBANA_URL/api/fleet/agent_policies/policy-elastic-agent-on-cloud" | \
    jq -r '.item.package_policies[] | select(.name == "Elastic APM") | .inputs[0].vars.secret_token.value')

# Create config files
cat > elastic_apm.json << EOF
{
  "ElasticApm": {
    "ServiceName": "$SERVICE_NAME",
    "SecretToken": "$SECRET_TOKEN",
    "ServerUrl": "$SERVER_URL",
    "Environment": "$ENVIRONMENT"
  }
}
EOF

cat > .env << EOF
ELASTIC_APM_SERVICE_NAME=$SERVICE_NAME
ELASTIC_APM_SECRET_TOKEN=$SECRET_TOKEN
ELASTIC_APM_SERVER_URL=$SERVER_URL
ELASTIC_APM_ENVIRONMENT=$ENVIRONMENT
EOF

echo "✓ APM configured: $SERVER_URL"
cat elastic_apm.json
