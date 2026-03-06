package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"go.elastic.co/apm"
	"go.elastic.co/apm/module/apmhttp"
)

type overridePayload struct {
	ServerURL   string `json:"serverUrl"`
	SecretToken string `json:"secretToken"`
	ServiceName string `json:"serviceName"`
}

type batchRequest struct {
	Count        int    `json:"count"`
	Language     string `json:"language"`
	DeploymentID string `json:"deploymentId"`
}

func main() {
	configureApmFromOverride()

	tracer, err := apm.NewTracerOptions(apm.TracerOptions{})
	if err != nil {
		panic(err)
	}
	defer tracer.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/work", workHandler)
	mux.HandleFunc("/work/batch", workBatchHandler)
	mux.HandleFunc("/internal/restart", restartHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "3003"
	}

	handler := apmhttp.Wrap(mux)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		panic(err)
	}
}

func configureApmFromOverride() {
	overridePath := os.Getenv("ELASTIC_APM_TARGET_OVERRIDE_PATH")
	if overridePath == "" {
		overridePath = "/shared/apm-target.override.json"
	}

	payload := readOverride(overridePath)
	if payload == nil {
		return
	}

	if payload.ServerURL != "" {
		_ = os.Setenv("ELASTIC_APM_SERVER_URL", payload.ServerURL)
	}
	if payload.SecretToken != "" {
		_ = os.Setenv("ELASTIC_APM_SECRET_TOKEN", payload.SecretToken)
	}
	if payload.ServiceName != "" {
		_ = os.Setenv("ELASTIC_APM_SERVICE_NAME", payload.ServiceName)
	}
}

func readOverride(path string) *overridePayload {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	var payload overridePayload
	if err := json.Unmarshal(data, &payload); err != nil {
		return nil
	}
	if payload.ServerURL == "" || payload.SecretToken == "" {
		return nil
	}
	return &payload
}

func healthHandler(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"ok": true})
}

func workHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "message": "method not allowed"})
		return
	}

	language := r.URL.Query().Get("language")
	if language == "" {
		language = "go"
	}
	deploymentID := r.URL.Query().Get("deploymentId")

	setTxnLabels(r, language, deploymentID)

	started := time.Now()
	value := runWork()
	writeJSON(w, http.StatusOK, map[string]any{
		"ok":           true,
		"x":            value,
		"durationMs":   time.Since(started).Milliseconds(),
		"language":     language,
		"deploymentId": deploymentID,
		"runtime":      "go",
	})
}

func workBatchHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "message": "method not allowed"})
		return
	}

	var body batchRequest
	_ = json.NewDecoder(r.Body).Decode(&body)

	count := body.Count
	if count < 1 {
		count = 1
	}
	if count > 1000 {
		count = 1000
	}

	language := body.Language
	if language == "" {
		language = "go"
	}
	deploymentID := body.DeploymentID

	setTxnLabels(r, language, deploymentID)

	started := time.Now()
	for i := 0; i < count; i++ {
		runWork()
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"ok":           true,
		"count":        count,
		"durationMs":   time.Since(started).Milliseconds(),
		"language":     language,
		"deploymentId": deploymentID,
		"runtime":      "go",
	})
}

func restartHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "message": "method not allowed"})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "message": "go worker restarting"})
	go func() {
		time.Sleep(250 * time.Millisecond)
		os.Exit(0)
	}()
}

func setTxnLabels(r *http.Request, language string, deploymentID string) {
	tx := apm.TransactionFromContext(r.Context())
	if tx == nil {
		return
	}
	tx.Context.SetLabel("test_language", language)
	if deploymentID != "" {
		tx.Context.SetLabel("test_deployment_id", deploymentID)
	}
}

func runWork() int64 {
	var value int64
	for i := 0; i < 2_000_000; i++ {
		value += int64(i % 7)
	}
	time.Sleep(80 * time.Millisecond)
	return value
}

func writeJSON(w http.ResponseWriter, status int, payload map[string]any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		http.Error(w, fmt.Sprintf(`{"ok":false,"message":%q}`, err.Error()), http.StatusInternalServerError)
	}
}
