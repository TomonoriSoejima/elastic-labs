<#
Generates a steady trickle of trivial process-create/exit Security events (~120/min),
tuned to fill a 1MB Security.evtx roughly every 10 minutes under archive-on-full mode.
#>
1..60 | ForEach-Object { Start-Process cmd.exe -ArgumentList '/c exit' -WindowStyle Hidden -Wait }
