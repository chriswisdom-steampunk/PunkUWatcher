# PunkUWatcher

This is a quick script to launch a punkU video in the browser in an automated fashion. Just leave your laptop on and it will watch punkU for you.

## Installation

Install by running this script to copy the watcher to the right folder and it will self schedule for 9 AM local time evey Monday, Wednesday, and Friday

```powershell
$destDir = Join-Path $env:LOCALAPPDATA 'Programs\PunkUWatcher'; `
New-Item -ItemType Directory -Path $destDir -Force | Out-Null; `
$dest = Join-Path $destDir 'watchPunkU.ps1'; `
$raw = 'https://raw.githubusercontent.com/chriswisdom-steampunk/PunkUWatcher/refs/heads/main/watchPunkU.ps1'; `
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
Invoke-WebRequest -Uri $raw -OutFile $dest -UseBasicParsing; `
Unblock-File -Path $dest; `
powershell.exe -ExecutionPolicy Bypass -File $dest
```