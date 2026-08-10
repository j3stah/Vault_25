param(
  [string]$SourceDir = (Join-Path $PSScriptRoot '..\journal_entries')
)

$ErrorActionPreference = 'Stop'
$buildScript = Join-Path $PSScriptRoot 'build-journal.ps1'

function Invoke-Build {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $buildScript
}

Invoke-Build

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Resolve-Path $SourceDir).Path
$watcher.Filter = '*.txt'
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, CreationTime'
$watcher.EnableRaisingEvents = $true

$action = {
  Start-Sleep -Milliseconds 200
  & powershell -NoProfile -ExecutionPolicy Bypass -File $event.MessageData
}

Register-ObjectEvent -InputObject $watcher -EventName Created -MessageData $buildScript -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Changed -MessageData $buildScript -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Renamed -MessageData $buildScript -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName Deleted -MessageData $buildScript -Action $action | Out-Null

Write-Host "Watching $SourceDir for journal changes. Press Ctrl+C to stop."
while ($true) {
  Wait-Event -Timeout 1 | Out-Null
}
