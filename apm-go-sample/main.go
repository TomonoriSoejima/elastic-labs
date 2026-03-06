package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"go.elastic.co/apm"
	"go.elastic.co/apm/module/apmhttp"
)

func main() {
	// Initialize APM tracer
	tracer, err := apm.NewTracer(os.Getenv("ELASTIC_APM_SERVICE_NAME"), "")
	if err != nil {
		log.Fatal(err)
	}
	defer tracer.Close()

	// Create HTTP handlers with APM instrumentation
	mux := http.NewServeMux()
	
	mux.HandleFunc("/", homeHandler)
	mux.HandleFunc("/hello", helloHandler)
	mux.HandleFunc("/api/data", dataHandler)

	// Wrap the mux with APM middleware
	handler := apmhttp.Wrap(mux)

	port := ":8080"
	fmt.Printf("Server starting on http://localhost%s\n", port)
	fmt.Println("Try these endpoints:")
	fmt.Println("  - http://localhost:8080/")
	fmt.Println("  - http://localhost:8080/hello")
	fmt.Println("  - http://localhost:8080/api/data")
	
	if err := http.ListenAndServe(port, handler); err != nil {
		log.Fatal(err)
	}
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to the APM Test Application!\n")
	fmt.Fprintf(w, "This request is being monitored by Elastic APM.\n")
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name == "" {
		name = "World"
	}
	fmt.Fprintf(w, "Hello, %s!\n", name)
}

func dataHandler(w http.ResponseWriter, r *http.Request) {
	// Simulate some work
	ctx := r.Context()
	span, _ := apm.StartSpan(ctx, "process_data", "custom")
	defer span.End()
	
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status": "success", "message": "Data processed successfully"}`)
}
