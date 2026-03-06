#!/bin/bash

# Run with trace_continuation_strategy=restart_external

java -javaagent:./elastic-apm-agent-1.52.0.jar \
  -Delastic.apm.service_name=java-service \
  -Delastic.apm.server_url=https://545435e87b134851bf498557e8e9c88a.apm.asia-northeast1.gcp.cloud.es.io:443 \
  -Delastic.apm.secret_token=YOUR_SECRET_TOKEN_HERE \
  -Delastic.apm.environment=test \
  -Delastic.apm.application_packages=co.elastic.test \
  -Delastic.apm.log_level=INFO \
  -Delastic.apm.trace_continuation_strategy=restart_external \
  -jar target/trace-test-1.0.0.jar
