# Execute this script as Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Start all SQL* Services
Get-Service | where {$_.Name -like "SQL*"} |  Start-Service

# Start SSMS and wait till is closed
Start-Process "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe" -NoNewWindow -Wait

# Stop all SQL* Services
Get-Service | where {$_.Name -like "SQL*"} |  Stop-Service
