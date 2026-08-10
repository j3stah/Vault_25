param(
  [string]$SourceDir = (Join-Path $PSScriptRoot '..\writings'),
  [string]$OutputFile = (Join-Path $PSScriptRoot '..\all-writings.html')
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

function Convert-TextToHtml {
  param(
    [string]$TextFile,
    [string]$OutputPath,
    [string]$Title
  )

  $content = Get-Content -Path $TextFile -Raw -Encoding UTF8
  $content = $content.Trim()
  
  # Convert line breaks to <br/> tags, preserving paragraph breaks
  $formattedContent = $content -replace "`r`n`r`n", "</p>`r`n<p>" -replace "`n`n", "</p>`r`n<p>"
  # Replace remaining single line breaks with <br/>
  $formattedContent = $formattedContent -replace "`r`n", "<br/>" -replace "`n", "<br/>"
  $formattedContent = "<p>$formattedContent</p>"

  $htmlContent = @"
<!DOCTYPE html>

<html lang="en">
<head>
<meta charset="utf-8"/>
<title>$Title</title>
<link rel="icon" type="image/png" href="../assets/site_icon.png">
<link href="../style.css" rel="stylesheet"/>
</head>
<body>
<div id="header"></div>
<article class="centered-content">
<h2>$Title</h2>
$formattedContent
</article>
<script src="../site-shell.js"></script>
</body>
</html>
"@

  [System.IO.File]::WriteAllText($OutputPath, $htmlContent, [System.Text.UTF8Encoding]::new($false))
}

if (-not (Test-Path $SourceDir)) {
  New-Item -ItemType Directory -Path $SourceDir -Force | Out-Null
}

$textFiles = Get-ChildItem -Path $SourceDir -Filter '*.txt' -File | Sort-Object Name

foreach ($file in $textFiles) {
  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  $title = Convert-ToTitleCase $baseName
  $htmlOutput = Join-Path $SourceDir "$baseName.html"

  Convert-TextToHtml -TextFile $file.FullName -OutputPath $htmlOutput -Title $title
  Write-Host "Converted: $($file.Name) -> $baseName.html"
}

Write-Host "Processed $($textFiles.Count) writing files"
