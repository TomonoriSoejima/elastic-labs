<#
One-time: enable OpenSSH Server so commands can be run remotely via `gcloud compute ssh`
instead of RDP + screenshots. No reboot required.
Run this in an elevated PowerShell prompt on the repro VM.
#>

$ErrorActionPreference = "Stop"

Write-Host "=== Installing OpenSSH Server capability ==="
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Write-Host "=== Starting sshd service ==="
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

Write-Host "=== Adding firewall rule for port 22 ==="
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" `
    -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

Write-Host "=== sshd service status ==="
Get-Service sshd

Write-Host "`nDone. SSH should now be reachable on port 22."
