# APM Kubernetes Test

Testing Java APM agent in Kubernetes environment with cgroup parsing.

## Purpose

Bug reproduction lab for testing MountInfoParser and cgroup detection in containerized environments.

## Files

- `Dockerfile` - Container image
- `deployment.yaml` - Kubernetes deployment
- `MountInfoParser.java` - Cgroup mount info parser
- `FailingMountInfoParser.java` - Test case for parser failures
- `mountinfo` - Sample /proc/self/mountinfo
- `cgroup` - Sample /proc/self/cgroup

## Build

```bash
docker build -t apm-kube-test .
```

## Deploy to Kubernetes

```bash
kubectl apply -f deployment.yaml
```

## Notes

- Requires elastic-apm-agent JAR (download from Maven Central)
- Tests cgroup v1/v2 detection in Kubernetes
