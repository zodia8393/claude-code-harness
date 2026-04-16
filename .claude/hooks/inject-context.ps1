# SessionStart hook: inject project state on session start/resume/compaction
# Windows PowerShell version of inject-context.sh

$ErrorActionPreference = "SilentlyContinue"
$projectRoot = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { (Get-Location).Path }
$context = ""

# [Static] Arena season
$arenaFile = Join-Path $projectRoot ".claude\context\skill_arena.yaml"
if (Test-Path $arenaFile) {
    $content = Get-Content $arenaFile -Raw
    if ($content -match 'season:\s*(\d+)') { $season = $Matches[1] }
    $context += "[Arena] Season $season`n"
}

# [Dynamic] Today's date
$context += "[Date] $(Get-Date -Format 'yyyy-MM-dd dddd')`n"

if ($context) {
    $escaped = $context -replace '"', '\"' -replace "`n", '\n'
    Write-Output "{`"additionalContext`": `"$escaped`"}"
}

exit 0
