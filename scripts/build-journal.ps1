param(
  [string]$SourceDir = (Join-Path $PSScriptRoot '..\journal_entries'),
  [string]$OutputFile = (Join-Path $PSScriptRoot '..\data\journal_entries.json')
)

$ErrorActionPreference = 'Stop'

function Convert-ToTitleCase {
  param([string]$Value)

  $text = ($Value -replace '[-_]+', ' ').Trim()
  if ([string]::IsNullOrWhiteSpace($text)) {
    return 'Untitled'
  }

  return [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($text.ToLower())
}

function Get-EntryDate {
  param(
    [System.IO.FileInfo]$File,
    [string]$BaseName
  )

  if ($BaseName -match '^(?<date>\d{4}-\d{2}-\d{2})--(?<slug>.+)$') {
    return $Matches.date
  }

  return $File.LastWriteTime.ToString('yyyy-MM-dd')
}

function Get-EntryTitle {
  param([string]$BaseName)

  if ($BaseName -match '^\d{4}-\d{2}-\d{2}--(?<slug>.+)$') {
    return Convert-ToTitleCase $Matches.slug
  }

  return Convert-ToTitleCase $BaseName
}

if (-not (Test-Path $SourceDir)) {
  New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
}

$entries = Get-ChildItem -Path $SourceDir -Filter '*.txt' -File |
  Sort-Object Name -Descending |
  ForEach-Object {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $body = Get-Content -Path $_.FullName -Raw -Encoding UTF8

    [pscustomobject]@{
      title = Get-EntryTitle $baseName
      date = Get-EntryDate -File $_ -BaseName $baseName
      body = $body.TrimEnd()
    }
  }

$targetDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $targetDir)) {
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$json = $entries | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($OutputFile, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "Generated $($entries.Count) journal entries -> $OutputFile"
