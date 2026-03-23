# Logstash — UID mismatch after tar.gz upgrade

**Reproduces:** Logstash fails to start after upgrading via `tar.gz` + symlink swap when the `logstash` user UID on the target system does not match the UID embedded in the archive.

**Related case:** 02035374

---

## Background

Elastic `tar.gz` archives preserve file ownership as **numeric UIDs** from the build environment. The standard RPM-assigned UID for the `logstash` user is **992**.

When installing via RPM on a clean system, RPM creates the `logstash` user (uid=992) and sets file ownership in the same transaction — everything lines up.

When extracting a `tar.gz` onto a system where UID 992 is already taken by another account, the OS assigns the next available UID (e.g. **1002**) to the `logstash` user. The extracted files are still owned by numeric UID 992, which is **not** the `logstash` user on that system.

Because `bin/logstash` has mode `750` (`rwxr-x---`), only the owner (uid=992) and group members can execute it. The `logstash` service user (uid=1002) falls into the "other" bucket and is denied.

```
systemd: Failed at step EXEC spawning /usr/share/logstash/bin/logstash: Permission denied
```

---

## Why the repro environment worked fine

The customer's reproduction environment used a fresh EC2 instance where UID 992 was not taken, so RPM assigned the `logstash` user uid=992 — matching the archive. The production server had uid=992 occupied, leading to the mismatch.

| | Production (failed) | Repro env (succeeded) |
|---|---|---|
| `logstash` user UID | **1002** | **992** |
| tar.gz file owner (numeric) | **992** | **992** |
| Match? | No → Permission denied | Yes → OK |

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

After extracting the tar.gz, reset ownership to the local `logstash` user:

```bash
sudo chown -R logstash:logstash /usr/share/logstash-7.17.x
sudo ln -sfn /usr/share/logstash-7.17.x /usr/share/logstash
sudo systemctl restart logstash-opensearch.service
```

> **Note:** For production upgrades, RPM (`rpm -Uvh`) is the recommended method as it handles user creation and file ownership atomically.
