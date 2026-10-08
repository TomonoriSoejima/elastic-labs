<#
Case 02123222 repro: configure Security log for archive-on-full rotation (matches customer's
4GB/archive/no-overwrite setup, scaled down so a switchover happens quickly).
No reboot required — wevtutil applies live.

Run this in an elevated PowerShell prompt on the repro VM.
#>

Write-Host "=== Current Security log config (baseline) ==="
wevtutil gl Security

# Enable archive-on-full (Event ID 1105 fires on each switchover), matching customer's
# retention mode. autoBackup requires retention:true (archive-and-keep-old-logs implies
# don't overwrite). NOTE: wevtutil cannot shrink maxSize below the Security channel's
# current allocated size, and the Security channel cannot be disabled (/e:false errors
# out by design) to force a resize - so we keep the existing maxSize and just rely on
# natural fill time instead of fighting the OS over size.
wevtutil sl Security /rt:true /ab:true

# Broaden default auditing so ordinary background activity (not artificial load) fills
# the log faster, shortening time-to-first-switchover without testing volume itself.
auditpol /set /subcategory:"Process Creation","Process Termination","Logon","Logoff" /success:enable /failure:enable

Write-Host "`n=== Updated Security log config ==="
wevtutil gl Security

Write-Host "`nDone. Security.evtx will now archive-and-rotate (Event ID 1105) each time it hits its configured max size (still 20MB - see note above)."
Write-Host "Watch System log for ID 1105, and check elastic-agent logs / winlog.record_id gaps in Kibana around that timestamp."
Write-Host "NOTE: enable debug logging separately via Kibana -> Fleet -> Agent policies -> 'repro-02123222-winlog-policy' (or 'Agent policy 1') -> Settings -> Logging level = debug."
