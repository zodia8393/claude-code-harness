# PreToolUse hook: destructive command guard (session sentinel based)
# Windows PowerShell version of guard-destructive.sh

$ErrorActionPreference = "Stop"

$input_json = $input | ConvertFrom-Json
$toolName = $input_json.tool_name
$toolInput = $input_json.tool_input.command
$sessionId = if ($input_json.session_id) { $input_json.session_id } else { "unknown" }

if ($toolName -ne "Bash") { exit 0 }

$sentinel = "$env:TEMP\claude-rm-allowed-$sessionId"
$sentinelTTL = 4 * 3600

# Check sentinel expiry
if (Test-Path $sentinel) {
    $age = (Get-Date) - (Get-Item $sentinel).LastWriteTime
    if ($age.TotalSeconds -gt $sentinelTTL) {
        Remove-Item $sentinel -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path $sentinel) { exit 0 }

$blockMsg = @"
-> Rule 0: File deletion requires user confirmation.

[Session temporary permit procedure]
1. Ask user for explicit 'allow rm for this session?' confirmation
2. If permitted, create sentinel: New-Item -Path '$sentinel' -ItemType File
3. Then retry the delete command. No more prompts for this session.

* Sentinel is auto-deleted on session end.
"@

# Detect destructive patterns
$patterns = @(
    '(^|\||\;|\&\&)\s*(rm|rmdir|shred|unlink|del|Remove-Item)\s',
    'find\s.*-delete',
    'find\s.*-exec\s*(rm|rmdir)',
    'xargs\s.*(rm|rmdir)',
    'python3?\s.*\b(os\.remove|os\.unlink|shutil\.rmtree|pathlib.*\.unlink|\.rmdir)\b'
)

foreach ($pattern in $patterns) {
    if ($toolInput -match $pattern) {
        Write-Error "[HOOK BLOCKED] Destructive command detected: '$toolInput'"
        Write-Error $blockMsg
        exit 2
    }
}

exit 0
