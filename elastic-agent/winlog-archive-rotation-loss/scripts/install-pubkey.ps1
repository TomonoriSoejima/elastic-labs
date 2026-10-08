$key = Get-Content -Path "C:\repro\pubkey.txt" -Raw
$key = $key.Trim()
New-Item -ItemType Directory -Force -Path C:\ProgramData\ssh | Out-Null
Set-Content -Path C:\ProgramData\ssh\administrators_authorized_keys -Value $key -Encoding ASCII
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r
icacls C:\ProgramData\ssh\administrators_authorized_keys /grant "Administrators:F"
icacls C:\ProgramData\ssh\administrators_authorized_keys /grant "SYSTEM:F"
Restart-Service sshd
Get-Content C:\ProgramData\ssh\administrators_authorized_keys
