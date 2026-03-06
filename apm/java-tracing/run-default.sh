#!/bin/bash

# Run with default settings (all calls share same trace.id)

java -javaagent:./elastic-apm-agent-1.52.0.jar \
  -Delastic.apm.service_name=java-service \
  -Delastic.apm.server_url=https://545435e87b134851bf498557e8e9c88a.apm.asia-northeast1.gcp.cloud.es.io:443 \
  -Delastic.apm.secret_token=YOUR_SECRET_TOKEN_HERE \
  -Delastic.apm.environment=test \
  -Delastic.apm.application_packages=co.elastic.test \
  -Delastic.apm.log_level=INFO \
  -jar target/trace-test-1.0.0.jar
