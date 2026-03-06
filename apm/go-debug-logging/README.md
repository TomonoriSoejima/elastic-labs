# Go APM Sample

Go application with Elastic APM instrumentation and debug logging.

## Files

- `main.go` - Sample Go application
- `setup.sh` - Environment setup
- `start.sh` - Start application
- `stop.sh` - Stop application
- `run.sh` - Run test
- `test.sh` - Test runner
- `KB_Go_APM_Debug_Logging.md` - Debug logging knowledge base
- `elastic_apm.json` - APM configuration

## Setup

```bash
./setup.sh
```

## Run

```bash
./start.sh
# or
./run.sh
```

## Stop

```bash
./stop.sh
```

## Notes

- Check KB document for debug logging configuration
- APM configuration can be customized in `elastic_apm.json`
