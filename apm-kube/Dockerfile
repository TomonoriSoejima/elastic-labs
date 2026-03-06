FROM eclipse-temurin:21-jdk-jammy

WORKDIR /app

COPY myspark-1.1-SNAPSHOT.jar app.jar
COPY elastic-apm-agent-1.53.0.jar apm-agent.jar

CMD java \
  -javaagent:apm-agent.jar \
  -Delastic.apm.service_name=my-service-name-from-minikube \
  -Delastic.apm.secret_token=YOUR_SECRET_TOKEN_HERE \
  -Delastic.apm.server_url=https://YOUR_CLUSTER_ID.apm.REGION.cloud.es.io:443 \
  -Delastic.apm.environment=my-environment \
  -Delastic.apm.log_level=DEBUG \
  -Delastic.apm.application_packages=MySpark \
  -jar app.jar
