param(
  [string]$SourceDir = (Join-Path $PSScriptRoot '..\writings')
)

$ErrorActionPreference = 'Stop'
$buildScript = Join-Path $PSScriptRoot 'build-writings.ps1'

function Invoke-Build {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $buildScript
}

function Get-Snapshot {
  param([string]$Path)

  Get-ChildItem -Path $Path -Filter '*.txt' -File |
    Sort-Object Name |
    ForEach-Object {
      [pscustomobject]@{
        Name = $_.Name
        Length = $_.Length
        LastWriteTimeUtc = $_.LastWriteTimeUtc
      }
    }
}

Invoke-Build

$resolvedSource = (Resolve-Path $SourceDir).Path
$previous = Get-Snapshot -Path $resolvedSource

Write-Host "Watching $SourceDir for writing changes. Press Ctrl+C to stop."
while ($true) {
  Start-Sleep -Seconds 1
  $current = Get-Snapshot -Path $resolvedSource

  if (($current | ConvertTo-Json -Depth 5) -ne ($previous | ConvertTo-Json -Depth 5)) {
    $previous = $current
    Invoke-Build
  }
}
