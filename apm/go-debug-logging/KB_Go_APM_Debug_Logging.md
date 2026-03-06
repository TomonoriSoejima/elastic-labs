# How to Enable Debug Logging for Go APM Client

## Overview

This article explains how to enable debug logging for the Elastic APM Go agent to troubleshoot issues with APM instrumentation, connectivity, and data transmission.

## Prerequisites

- Elastic APM Go agent installed (`go.elastic.co/apm`)
- Go application instrumented with APM

## Enabling Debug Logging

### Step 1: Set Environment Variables

Set the following environment variables before starting your application:

```bash
export ELASTIC_APM_LOG_LEVEL=debug
export ELASTIC_APM_LOG_FILE=apm_debug.log
```

### Step 2: Run Your Application

```bash
go run main.go
```

The debug logs will be written to `apm_debug.log` in JSON format.

## Configuration Options

### Log Levels

- `error` - Error messages only
- `warning` - Warnings and errors
- `info` - Informational messages (default)
- `debug` - Most detailed level available (recommended for troubleshooting)

**Note**: The Go APM agent does not implement trace-level logging. `debug` is the most verbose level available.

### Log Output Location

**Option 1: Write to a specific file (recommended)**
```bash
export ELASTIC_APM_LOG_FILE=apm_debug.log
```

**Option 2: Use stderr (no ELASTIC_APM_LOG_FILE set)**
```bash
# APM logs will go to stderr
go run main.go 2> apm_debug.log
```

## Complete Example

Create a shell script to run your application with debug logging:

```bash
#!/bin/bash

# APM Configuration
export ELASTIC_APM_SERVICE_NAME=my_service
export ELASTIC_APM_SECRET_TOKEN=your_secret_token
export ELASTIC_APM_SERVER_URL=https://your-apm-server:443
export ELASTIC_APM_ENVIRONMENT=production

# Enable Debug Logging
export ELASTIC_APM_LOG_LEVEL=debug
export ELASTIC_APM_LOG_FILE=apm_debug.log

# Run application
go run main.go
```

## What to Expect in Debug Logs

Debug logs are in JSON format and include:

**1. Data transmission status:**
```json
{"level":"debug","time":"2026-02-05T11:26:03+09:00","message":"sent request with 3 transactions, 1 span, 0 errors, 0 metricsets"}
```

**2. Metrics gathering:**
```json
{"level":"debug","time":"2026-02-05T11:26:18+09:00","message":"gathering metrics"}
```

**3. Connection errors:**
```json
{"level":"debug","time":"...","message":"request failed: connection timeout (next request in ~30s)"}
```

## Viewing the Logs

```bash
# View logs in real-time
tail -f apm_debug.log

# Search for specific messages
grep "sent request with" apm_debug.log
```

## Important Notes

- Debug logging generates verbose output and should be used for troubleshooting only
- For production use, set `ELASTIC_APM_LOG_LEVEL=info` or `error`
- Debug logs will grow over time - monitor disk space for long-running applications
- Using `ELASTIC_APM_LOG_FILE` keeps APM logs separate from application logs

## Source Code Reference

The debug logging implementation can be found in the Go APM agent source code:
- **File**: `tracer.go`
- **Location**: `loop()` method around line 1120
- **Format**: JSON structured logs with level, timestamp, and message

## Additional Resources

- [Elastic APM Go Agent Documentation](https://www.elastic.co/guide/en/apm/agent/go/current/index.html)
- [Configuration Reference](https://www.elastic.co/guide/en/apm/agent/go/current/configuration.html)

---

**Document Version:** 1.0  
**Last Updated:** February 5, 2026  
**Applicable Versions:** Elastic APM Go Agent v1.x, v2.x
