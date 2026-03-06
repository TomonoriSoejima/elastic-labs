# Node.js APM Demo

Node.js application with Elastic APM using Restify framework.

## Purpose

Demonstrates APM instrumentation with Restify and metrics interval configuration.

## Files

- `apm_restify_demo.js` - Restify demo application
- `KB_reproduce_metrics_interval_issue.md` - Metrics interval knowledge base
- `package.json` - Dependencies

## Setup

```bash
npm install
```

## Run

```bash
node apm_restify_demo.js
```

## Environment Variables

Set APM configuration via environment:
```bash
export ELASTIC_APM_SERVER_URL="https://your-apm-server:8200"
export ELASTIC_APM_SECRET_TOKEN="your-token"
export ELASTIC_APM_SERVICE_NAME="restify-demo"
```

## Notes

- Tests metrics interval configuration
- Check KB document for known issues
- profile.txt contains performance profiling data
