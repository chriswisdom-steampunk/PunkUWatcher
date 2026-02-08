<#
    watchPunkU.ps1

    - Registers a Scheduled Task named "Punku Steampunk Launcher" that runs this script
      every Monday, Wednesday, and Friday at 9:00 AM (only if not already registered).
    - Opens your default browser to:
        https://punku.steampunk.com/share/asset/view/{nextInt}
      where {nextInt} increments each run based on a local log.
    - Logs each run to:
        C:\Users\{username}\AppData\Local\Programs\PunkUWatcher\logs\punku-launch.log
#>

# Fail fast on errors
$ErrorActionPreference = 'Stop'

# ----------------------------
# Configuration
# ----------------------------
$TaskName   = 'PunkU Watcher'
$BaseUrl    = 'https://punku.steampunk.com/share/asset/view' # base without trailing slash
$Days       = @('Monday','Wednesday','Friday')               # trigger days
$AtTime     = '09:00AM'                                      # trigger time
$StartFrom  = 1                                              # first integer if no log exists yet

# Base user Programs directory: C:\Users\{username}\AppData\Local\Programs
$BasePrograms = Join-Path $env:LOCALAPPDATA 'Programs'

# Our app directory & script path
$AppDir     = Join-Path $BasePrograms 'PunkUWatcher'
$ScriptPath = $PSCommandPath
if (-not $ScriptPath) { $ScriptPath = $MyInvocation.MyCommand.Path }
# Expected placement for clarity (not required but useful for validation)
$ExpectedScriptPath = Join-Path $AppDir 'watchPunkU.ps1'
if ($ScriptPath -ne $ExpectedScriptPath) {
    Write-Warning "Script is running from '$ScriptPath'. Expected location: '$ExpectedScriptPath'."
    Write-Warning "The scheduled task will run this actual path: $ScriptPath"
}

# Log path: C:\Users\{username}\AppData\Local\Programs\PunkUWatcher\logs\punku-launch.log
$LogDir  = Join-Path $AppDir 'logs'
$LogFile = Join-Path $LogDir 'punku-launch.log'

# Ensure directories exist
foreach ($dir in @($AppDir, $LogDir)) {
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# ----------------------------
# One-time: Create scheduled task if not already present
# ----------------------------
try {
    $existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $existing) {
        $trigger   = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $Days -At $AtTime
        $action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        # Run as current user when logged on (no password prompt)
        $principal = New-ScheduledTaskPrincipal -UserId $env:UserName -LogonType Interactive

        Register-ScheduledTask -TaskName $TaskName `
                               -Trigger $trigger `
                               -Action $action `
                               -Principal $principal `
                               -Description 'Launches Punku Steampunk next asset (M/W/F at 9:00 AM). Action: run this script.' | Out-Null
        Write-Host "Scheduled Task '$TaskName' created (M/W/F @ $AtTime)."
    } else {
        # Do NOT modify if it already exists
        # Write-Host "Scheduled Task '$TaskName' already exists; not modifying."
    }
} catch {
    Write-Warning "Unable to create or verify the scheduled task. Error: $($_.Exception.Message)"
    # Continue so a manual run still opens the URL and logs
}

# ----------------------------
# Determine next integer from log
# ----------------------------
function Get-NextIntFromLog {
    param(
        [string]$Path,
        [int]$DefaultStart = 1
    )

    if (-not (Test-Path $Path)) {
        return $DefaultStart
    }

    $lastLine = $null
    try {
        # Read last line only (efficient)
        $lastLine = Get-Content -Path $Path -Tail 1 -ErrorAction Stop
    } catch {
        return $DefaultStart
    }

    # Extract trailing integer from the last logged URL
    if ($lastLine -match '/(\d+)\s*$') {
        return ([int]$Matches[1] + 1)
    }

    # Fallback if log format unexpected
    return $DefaultStart
}

$nextInt = Get-NextIntFromLog -Path $LogFile -DefaultStart $StartFrom
$url     = "$BaseUrl/$nextInt"

# ----------------------------
# Launch URL in default browser
# ----------------------------
try {
    Start-Process $url
} catch {
    Write-Error "Failed to open the browser for URL: $url. Error: $($_.Exception.Message)"
}

# ----------------------------
# Append to log
# ----------------------------
try {
    $timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
    Add-Content -Path $LogFile -Value "$timestamp | $url"
} catch {
    Write-Warning "Failed to append to log file at '$LogFile'. Error: $($_.Exception.Message)"
}

# Optional: console output for manual runs
Write-Host "Launched: $url"
Write-Host "Logged to: $LogFile"