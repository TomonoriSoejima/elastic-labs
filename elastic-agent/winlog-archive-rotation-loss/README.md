# winlog archive-on-full event loss repro

GCP Windows VM lab reproducing permanent Windows Security event loss across an
`archive-on-full` log rotation switchover, as seen with Elastic Agent's `winlog`
input (System integration).

Originates from support case 02123222. Confirms the mechanism behind the
customer's `EvtNext failed, recreating subscription` / `The query result is
stale or invalid and must be recreated` errors: when `Security.evtx` archives
and switches to a new active file, any records not yet read before the
switchover are stranded in the archive file — `winlog` never reads archived
files, so those records are **permanently skipped**, not just delayed.

No fix exists in current versions (confirmed through 9.3.8). Tracked publicly at
[elastic/beats#53655](https://github.com/elastic/beats/issues/53655).

## Environment

- GCP Compute Engine Windows Server VM
- Elastic Agent enrolled to a Fleet policy running the `System` integration
  (`winlog` input against the `Security` channel)
- Customer's retention mode: 4 GB max size, archive-and-keep-old-logs
  (`archive-on-full`), scaled down here for a fast repro cycle

## Repro steps (run in order on the VM)

1. **`scripts/enable-ssh.ps1`** — one-time: enables OpenSSH Server so the VM can
   be driven remotely (`gcloud compute ssh`) instead of RDP + screenshots.
2. **`scripts/install-pubkey.ps1`** — installs your SSH public key
   (expects `C:\repro\pubkey.txt` to already be on the VM).
3. **`scripts/install-agent.ps1`** — downloads Elastic Agent and enrolls it
   into a Fleet policy. **Edit the `$url` / `--enrollment-token` placeholders**
   for your own repro policy before running.
4. **`scripts/configure-security-log-rotation.ps1`** — sets the Security
   channel to `archive-on-full` (`wevtutil sl Security /rt:true /ab:true`,
   matches the customer's retention mode) and broadens default auditing so
   ordinary background activity fills the log without needing a load test.
5. **`scripts/configure-fast-rotation.ps1`** — shrinks `MaxSize` to 1 MB via
   registry (wevtutil can't shrink a live, non-disableable channel) and
   registers a scheduled task that generates a steady trickle of trivial
   process-create/exit events, tuned for a ~10-minute fill/rotate cadence.
   **Reboot the VM after this step** (e.g. `gcloud compute instances reset`)
   for the new `MaxSize` to take effect.
6. **`scripts/generate-events.ps1`** — same trickle generator as step 5, usable
   standalone for an on-demand burst instead of waiting on the scheduled task.
7. Enable debug logging on the agent policy (Fleet → Agent policies → policy →
   Settings → Logging level = debug) to capture `winlog` internals around the
   switchover (bookmark updates, subscription recreation, Windows API error
   codes).

## What to watch

- **System log, Event ID 1105** — fires on each archive switchover.
- **elastic-agent debug logs** — `EvtNext failed, recreating subscription`,
  `The query result is stale or invalid and must be recreated`.
- **Kibana** — gaps in `winlog.record_id` that line up with the ID 1105
  timestamps; compare against the archived `.evtx` file's own record range to
  confirm the missing records exist only in the archive, not the new active
  file.

## Result

Reproduced the same permanent-skip mechanism reported by the customer: records
unread at switchover time are left behind in the archived file and never
ingested. This is a known limitation of `archive-on-full` mode, not a transient
delay — see [elastic/beats#53655](https://github.com/elastic/beats/issues/53655)
for the fix tracking (reading out the archive before switching).

**Workaround**: ingest the archive files directly via a Custom Windows Event
Logs integration input pointed at the archive path, with "Ignore events older
than" cleared — note this can resend/duplicate already-ingested events.

## Cleanup

```powershell
Unregister-ScheduledTask -TaskName "repro-02123222-security-event-generator" -Confirm:$false
```
Then uninstall the agent / tear down the VM as usual.
