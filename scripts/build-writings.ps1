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

function Get-WritingLinkHtml {
  param([System.IO.FileInfo]$File)

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
  $title = Convert-ToTitleCase $baseName

  return ('          <a href="writings/{0}" class="poem-link"><div class="poem-tile">{1}</div></a>' -f $File.Name, $title)
}

function Update-AllWritingsPage {
  param([string]$PagePath, [string]$SourceDir)

  if (-not (Test-Path $PagePath)) {
    return
  }

  $links = Get-ChildItem -Path $SourceDir -Filter '*.html' -File |
    Sort-Object Name |
    ForEach-Object { Get-WritingLinkHtml $_ }

  $content = Get-Content -Path $PagePath -Raw -Encoding UTF8
  $replacement = @"
          <!-- WRITINGS:START -->
$($links -join "`r`n")
          <!-- WRITINGS:END -->
"@

  if ($content -match '(?s)<!-- WRITINGS:START -->.*<!-- WRITINGS:END -->') {
    $content = [System.Text.RegularExpressions.Regex]::Replace(
      $content,
      '(?s)<!-- WRITINGS:START -->.*<!-- WRITINGS:END -->',
      [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $replacement }
    )
  }
  else {
    $content = $content -replace '(?s)(<div class="grid-container">\s*)', "`$1$replacement`r`n"
  }

  [System.IO.File]::WriteAllText($PagePath, $content, [System.Text.UTF8Encoding]::new($false))
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

function Publish-Changes {
  param([string]$RepoRoot)

  Push-Location $RepoRoot
  try {
    $insideRepo = & git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($insideRepo)) {
      return $false
    }

    $status = & git status --porcelain --untracked-files=all
    if ($LASTEXITCODE -ne 0) {
      return $false
    }

    if ([string]::IsNullOrWhiteSpace(($status -join "`n"))) {
      return $false
    }

    & git add -- writings all-writings.html scripts/build-writings.ps1 scripts/watch-writings.ps1 README.md .vscode/tasks.json
    if ($LASTEXITCODE -ne 0) {
      return $false
    }

    & git commit -m "Auto-generated writing pages"
    if ($LASTEXITCODE -ne 0) {
      return $false
    }

    & git push origin HEAD:master HEAD:retro-vibe
    if ($LASTEXITCODE -ne 0) {
      return $false
    }

    return $true
  }
  finally {
    Pop-Location
  }
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

$allWritingsPage = Join-Path (Split-Path -Parent $PSScriptRoot) 'all-writings.html'
Update-AllWritingsPage -PagePath $allWritingsPage -SourceDir $SourceDir

$repoRoot = Split-Path -Parent $PSScriptRoot
$published = Publish-Changes -RepoRoot $repoRoot
if ($published) {
  Write-Host "Published changes to GitHub"
}

Write-Host "Processed $($textFiles.Count) writing files"
