# Quick Start Guide

## 🚀 Run the test in 3 steps:

### 1. Setup (first time only)
```bash
./setup.sh
```
This will:
- Start Elasticsearch, Kibana, APM Server
- Download Java APM Agent v1.52.0
- Build the application

### 2. Run the application
```bash
# Default behavior (customer's issue)
./run-default.sh

# OR with restart strategy
./run-restart.sh

# OR with restart_external strategy
./run-restart-external.sh
```

### 3. Test it (in another terminal)
```bash
./test.sh
```

## 📊 View Results

- **Kibana APM:** http://localhost:5601/app/apm/services
- **Elasticsearch:** http://localhost:9200

## 🎯 What You'll See

### Default Behavior (customer's issue):
- Request comes WITH `traceparent` header
- All 3 Elasticsearch calls share the **same trace.id**
- This is normal distributed tracing behavior
- BUT customer wants separate trace.ids per call

### With restart strategy:
- Each call *might* get a new trace.id
- Test to see if this solves customer's requirement

### With restart_external:
- Similar to restart but only for external traces
- Test to see behavior difference

## 🧹 Cleanup
```bash
docker-compose down -v
```

## 📝 Customer's Stack Match
- ✅ Java backend with Elastic Java APM Agent v1.52.0
- ✅ Multiple parallel API calls
- ✅ Receives `traceparent` from frontend (simulated with curl)
- ✅ Calls to downstream service (Elasticsearch)
