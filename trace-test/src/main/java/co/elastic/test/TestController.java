package co.elastic.test;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@RestController
public class TestController {

    private final RestTemplate restTemplate = new RestTemplate();
    private final ExecutorService executor = Executors.newFixedThreadPool(3);

    @GetMapping("/api/test")
    public Map<String, Object> testRestartExternal(
            @RequestHeader(value = "traceparent", required = false) String traceparent) {
        
        Map<String, Object> response = new HashMap<>();
        response.put("traceparent_received", traceparent);
        response.put("timestamp", System.currentTimeMillis());

        // Make 3 parallel HTTP REST calls
        List<CompletableFuture<Map<String, Object>>> futures = new ArrayList<>();
        
        String[] apiUrls = {
            "https://httpbin.org/delay/2",
            "https://httpbin.org/uuid", 
            "https://httpbin.org/get"
        };
        
        for (int i = 1; i <= 3; i++) {
            final int callNumber = i;
            final String url = apiUrls[i - 1];
            CompletableFuture<Map<String, Object>> future = CompletableFuture.supplyAsync(() -> {
                return makeHttpCall(callNumber, url);
            }, executor);
            futures.add(future);
        }

        // Wait for all calls to complete
        List<Map<String, Object>> results = new ArrayList<>();
        for (CompletableFuture<Map<String, Object>> future : futures) {
            try {
                results.add(future.get());
            } catch (Exception e) {
                Map<String, Object> errorResult = new HashMap<>();
                errorResult.put("error", e.getMessage());
                results.add(errorResult);
            }
        }

        response.put("http_calls", results);
        response.put("total_calls", 3);
        
        return response;
    }

    private Map<String, Object> makeHttpCall(int callNumber, String url) {
        Map<String, Object> result = new HashMap<>();
        result.put("call_number", callNumber);
        result.put("url", url);
        
        try {
            long startTime = System.currentTimeMillis();
            String httpResponse = restTemplate.getForObject(url, String.class);
            long duration = System.currentTimeMillis() - startTime;
            
            result.put("status", "success");
            result.put("response_length", httpResponse != null ? httpResponse.length() : 0);
            result.put("duration_ms", duration);
            
        } catch (Exception e) {
            result.put("status", "error");
            result.put("error", e.getMessage());
        }
        
        return result;
    }
}
