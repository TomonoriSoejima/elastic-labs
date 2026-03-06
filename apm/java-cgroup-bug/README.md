# Java APM Agent Bug Lab

Bug reproduction environment for Java APM agent cgroup parsing issues.

## Purpose

Isolated test case for debugging MountInfoParser behavior with various cgroup configurations.

## Files

- `Dockerfile` - Test container
- `MountInfoParser.java` - Parser implementation
- `FailingMountInfoParser.java` - Failing test case
- `mountinfo` - Sample /proc/self/mountinfo data
- `cgroup` - Sample /proc/self/cgroup data

## Build & Run

```bash
# Compile
javac MountInfoParser.java FailingMountInfoParser.java

# Run test
java FailingMountInfoParser

# Or use Docker
docker build -t bug-lab .
docker run --rm bug-lab
```

## Notes

- Tests edge cases in cgroup detection
- Used for bug reports to elastic/apm-agent-java
