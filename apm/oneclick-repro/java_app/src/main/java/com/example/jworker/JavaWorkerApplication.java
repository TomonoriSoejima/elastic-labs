package com.example.jworker;

import co.elastic.apm.attach.ElasticApmAttacher;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class JavaWorkerApplication {

  public static void main(String[] args) {
    configureApmFromOverride();
    ElasticApmAttacher.attach();
    SpringApplication.run(JavaWorkerApplication.class, args);
  }

  private static void configureApmFromOverride() {
    String overridePath =
        System.getenv().getOrDefault("ELASTIC_APM_TARGET_OVERRIDE_PATH", "/shared/apm-target.override.json");

    Map<String, String> resolved = new HashMap<>();
    resolved.put("server_url", System.getenv("ELASTIC_APM_SERVER_URL"));
    resolved.put("secret_token", System.getenv("ELASTIC_APM_SECRET_TOKEN"));
    resolved.put("service_name", System.getenv("ELASTIC_APM_SERVICE_NAME"));
    resolved.put("environment", System.getenv().getOrDefault("ELASTIC_APM_ENVIRONMENT", "repro"));

    try {
      if (Files.exists(Path.of(overridePath))) {
        ObjectMapper mapper = new ObjectMapper();
        JsonNode root = mapper.readTree(Files.readString(Path.of(overridePath)));
        if (root.hasNonNull("serverUrl")) {
          resolved.put("server_url", root.get("serverUrl").asText());
        }
        if (root.hasNonNull("secretToken")) {
          resolved.put("secret_token", root.get("secretToken").asText());
        }
        if (root.hasNonNull("serviceName")) {
          resolved.put("service_name", root.get("serviceName").asText());
        }
      }
    } catch (Exception ignored) {
    }

    resolved.forEach((key, value) -> {
      if (value != null && !value.isBlank()) {
        System.setProperty("elastic.apm." + key, value);
      }
    });
  }
}
