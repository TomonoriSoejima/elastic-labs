FROM python:3.12-slim

WORKDIR /app
COPY . /app
RUN pip install -r requirements.txt && opentelemetry-bootstrap -a install
EXPOSE 8080

# Replace <your-api-key> below with your actual API key
ENV OTEL_EXPORTER_OTLP_ENDPOINT="https://<your-motlp-endpoint>"
ENV OTEL_EXPORTER_OTLP_HEADERS="Authorization=ApiKey YOUR_API_KEY_HERE"
ENV OTEL_EXPORTER_OTLP_PROTOCOL="http/protobuf"
ENV OTEL_RESOURCE_ATTRIBUTES="service.name=motlp-connectivity-test,service.version=0.0.1,deployment.environment=test"
ENV OTEL_PYTHON_LOG_LEVEL="debug"
ENV OTEL_LOGS_EXPORTER="none"

CMD ["opentelemetry-instrument", "python", "app.py"]
