<#
Startup script: downloads Elastic Agent and enrolls it into a repro Fleet policy.
Fill in $fleetUrl / $enrollmentToken for your own policy before running.
#>
$ErrorActionPreference = "Stop"
$version = "9.3.8"
$zip = "elastic-agent-$version-windows-x86_64.zip"
$url = "https://artifacts.elastic.co/downloads/beats/elastic-agent/$zip"
$dest = "C:\elastic-agent-install"

$fleetUrl = "<fleet-server-url>"            # e.g. https://<id>.fleet.<region>.gcp.cloud.es.io:443
$enrollmentToken = "<enrollment-token>"     # from Fleet -> Agent policies -> your repro policy

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri $url -OutFile "$dest\$zip"
Expand-Archive -Path "$dest\$zip" -DestinationPath $dest -Force

$extracted = Get-ChildItem -Path $dest -Directory | Where-Object { $_.Name -like "elastic-agent-$version*" } | Select-Object -First 1
Set-Location $extracted.FullName

.\elastic-agent.exe install `
  --url=$fleetUrl `
  --enrollment-token=$enrollmentToken `
  --force
