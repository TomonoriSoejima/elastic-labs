# Logstash — UID mismatch after tar.gz upgrade

**Reproduces:** Logstash fails to start after upgrading via `tar.gz` + symlink swap when a file ownership mismatch exists between the extracted files and the `logstash` service user on the system.

**Related case:** 02035374

---

## Background

When upgrading Logstash by extracting a `tar.gz` archive, the file ownership of the extracted files must match the `logstash` user running the service. If ownership is not explicitly set after extraction, a mismatch can occur.

In this case, the customer reported:

- **VUP失敗環境（本番）**: `id logstash` → `uid=1002(logstash)`
- **再現環境**: `id logstash` → `uid=992(logstash)`

The production environment had a different UID assigned to the `logstash` user compared to the reproduction environment. After the tar.gz extraction, the file ownership did not match the `logstash` user on production, causing the following error when systemd tried to start the service:

```
Failed at step EXEC spawning /usr/share/logstash/bin/logstash: Permission denied
```

The reproduction environment worked because the `logstash` user UID happened to match the file owner — so no permission issue occurred.

---

## What this test simulates

The test script simulates the permission denied scenario by:

1. Creating a fake `logstash` binary owned by **uid=992** with mode `750` (`rwxr-x---`)
2. **Case A**: Creates a `logstash` user with uid=**1002** (production) → execution fails
3. **Case B**: Creates a `logstash` user with uid=**992** (repro env) → execution succeeds

This demonstrates how a UID mismatch between the file owner and the service user leads to `Permission denied` when the binary mode is `750`.

---

## Reproduce it

Requires Docker.

```bash
bash test.sh
```

Expected output:

```
File on disk (same in both cases):
-rwxr-x--- 1 992 992  ...  /usr/share/logstash/bin/logstash

======================================================
 CASE A: Production  ->  logstash = uid=1002 (VUP env)
======================================================
uid=1002(logstash) gid=1002(logstash) groups=1002(logstash)
runuser: failed to execute /usr/share/logstash/bin/logstash: Permission denied
Result: FAILED (Permission denied)

======================================================
 CASE B: Repro env   ->  logstash = uid=992 (RPM default)
======================================================
uid=992(logstash) gid=1000(logstash) groups=1000(logstash)
Logstash started successfully
Result: OK
```

---

## Fix

After extracting the tar.gz, explicitly reset ownership to the local `logstash` user:

```bash
sudo chown -R logstash:logstash /usr/share/logstash-7.17.x
sudo ln -sfn /usr/share/logstash-7.17.x /usr/share/logstash
sudo systemctl restart logstash-opensearch.service
```

> **Note:** For production upgrades, RPM (`rpm -Uvh`) is the recommended method as it handles user creation and file ownership atomically, avoiding this class of issue entirely.
