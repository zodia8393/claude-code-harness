# PostToolUse hook: log Skill tool usage for Arena
# Windows PowerShell version of log-skill-usage.sh

$ErrorActionPreference = "SilentlyContinue"

$input_json = $input | ConvertFrom-Json
$toolName = $input_json.tool_name

if ($toolName -ne "Skill") { exit 0 }

$skillName = $input_json.tool_input.skill
$timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
$sessionId = if ($input_json.session_id) { $input_json.session_id } else { "unknown" }

$projectRoot = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { (Get-Location).Path }
$logFile = Join-Path $projectRoot ".claude\context\skill_usage.log"

$entry = @{ timestamp = $timestamp; skill = $skillName; session = $sessionId } | ConvertTo-Json -Compress
Add-Content -Path $logFile -Value $entry

exit 0
