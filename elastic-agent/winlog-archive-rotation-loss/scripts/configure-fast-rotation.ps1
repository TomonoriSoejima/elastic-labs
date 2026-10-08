<#
Case 02123222 repro, step 2: force ~10-minute Security log rotation cycle.

wevtutil can't shrink maxSize on a live, non-disableable channel (see
configure-security-log-rotation.ps1 notes), so this sets MaxSize directly via
registry - takes effect after the next reboot of the Eventlog service (i.e. a VM reboot).

Also registers a Scheduled Task that generates a steady trickle of trivial
process-create/exit events (not a load/pressure test - just enough volume to
reach the 1MB cap on a predictable ~10-minute cadence instead of waiting hours
for background auditing alone to do it).

Run this in an elevated PowerShell prompt on the repro VM. Reboot after running.
#>

$ErrorActionPreference = "Stop"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security"

Write-Host "=== Current registry MaxSize ==="
Get-ItemProperty -Path $regPath -Name MaxSize | Select-Object MaxSize

# 1MB floor - takes effect once the Eventlog service restarts (i.e. next reboot).
Set-ItemProperty -Path $regPath -Name MaxSize -Value 1048576 -Type DWord

Write-Host "=== Updated registry MaxSize (applies after reboot) ==="
Get-ItemProperty -Path $regPath -Name MaxSize | Select-Object MaxSize

# Steady trickle generator: ~120 process-create/exit event pairs per minute,
# tuned for roughly a 1MB/10min fill rate. Persists across reboots (Task Scheduler).
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument '-NoProfile -WindowStyle Hidden -Command "1..60 | ForEach-Object { Start-Process cmd.exe -ArgumentList ''/c exit'' -WindowStyle Hidden -Wait }"'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 3650)
Register-ScheduledTask -TaskName "repro-02123222-security-event-generator" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest -Force | Out-Null

Write-Host "`nDone. Reboot the VM now for the new MaxSize to take effect (gcloud compute instances reset)."
Write-Host "After reboot, the scheduled task resumes automatically and Security.evtx should rotate (Event ID 1105) roughly every 10 minutes."
