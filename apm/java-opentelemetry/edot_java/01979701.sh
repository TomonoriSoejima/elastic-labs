export OTEL_RESOURCE_ATTRIBUTES=service.name=spring-petclinic,service.version=1.0,deployment.environment=production
export OTEL_EXPORTER_OTLP_ENDPOINT=https://2f52f00ee43d46759faaec42e0c38b53.apm.asia-northeast1.gcp.cloud.es.io:443
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer cFLm5NsCmXaFSH8j9f"
export OTEL_METRICS_EXPORTER="otlp"
export OTEL_LOGS_EXPORTER="otlp"
export OTEL_RESOURCE_PROVIDERS_AWS_ENABLED=false
export OTEL_RESOURCE_PROVIDERS_GCP_ENABLED=false
export OTEL_INSTRUMENTATION_COMMON_DEFAULT_ENABLED=true
java -javaagent:./elastic-otel-javaagent-1.5.0.jar \
    -Dotel.javaagent.debug=true \
    -jar spring-petclinic-3.5.0-SNAPSHOT.jar