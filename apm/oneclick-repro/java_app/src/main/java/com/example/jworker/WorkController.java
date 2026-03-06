package com.example.jworker;

import co.elastic.apm.api.ElasticApm;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class WorkController {

  @GetMapping("/health")
  public Map<String, Object> health() {
    return Map.of("ok", true);
  }

  @GetMapping("/work")
  public Map<String, Object> work(
      @RequestParam(defaultValue = "java") String language,
      @RequestParam(defaultValue = "") String deploymentId)
      throws InterruptedException {

    ElasticApm.currentTransaction().setLabel("test_language", language);
    if (!deploymentId.isBlank()) {
      ElasticApm.currentTransaction().setLabel("test_deployment_id", deploymentId);
    }

    long started = System.currentTimeMillis();
    long value = runWork();

    Map<String, Object> out = new HashMap<>();
    out.put("ok", true);
    out.put("x", value);
    out.put("durationMs", System.currentTimeMillis() - started);
    out.put("language", language);
    out.put("deploymentId", deploymentId);
    out.put("runtime", "java");
    return out;
  }

  @PostMapping("/work/batch")
  public Map<String, Object> batch(@RequestBody(required = false) Map<String, Object> body)
      throws InterruptedException {
    int requestedCount = body != null && body.get("count") != null ? Integer.parseInt(String.valueOf(body.get("count"))) : 1;
    int count = Math.max(1, Math.min(requestedCount, 1000));
    String language = body != null && body.get("language") != null ? String.valueOf(body.get("language")) : "java";
    String deploymentId = body != null && body.get("deploymentId") != null ? String.valueOf(body.get("deploymentId")) : "";

    ElasticApm.currentTransaction().setLabel("test_language", language);
    if (!deploymentId.isBlank()) {
      ElasticApm.currentTransaction().setLabel("test_deployment_id", deploymentId);
    }

    long started = System.currentTimeMillis();
    for (int i = 0; i < count; i++) {
      runWork();
    }

    return Map.of(
        "ok", true,
        "count", count,
        "durationMs", System.currentTimeMillis() - started,
        "language", language,
        "deploymentId", deploymentId,
        "runtime", "java");
  }

  @PostMapping("/internal/restart")
  public Map<String, Object> restart() {
    Thread restartThread = new Thread(() -> {
      try {
        TimeUnit.MILLISECONDS.sleep(250);
      } catch (InterruptedException ignored) {
      }
      System.exit(0);
    });
    restartThread.setDaemon(true);
    restartThread.start();

    return Map.of("ok", true, "message", "java worker restarting");
  }

  private long runWork() throws InterruptedException {
    long value = 0;
    for (int i = 0; i < 2_000_000; i++) {
      value += i % 7;
    }
    TimeUnit.MILLISECONDS.sleep(80);
    return value;
  }
}
