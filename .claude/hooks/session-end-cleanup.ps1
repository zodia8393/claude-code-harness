# SessionEnd hook: clean up session sentinel
# Windows PowerShell version of session-end-cleanup.sh

$ErrorActionPreference = "SilentlyContinue"

$input_json = $input | ConvertFrom-Json
$sessionId = if ($input_json.session_id) { $input_json.session_id } else { "unknown" }

$sentinel = "$env:TEMP\claude-rm-allowed-$sessionId"
if (Test-Path $sentinel) {
    Remove-Item $sentinel -Force
}

# Clean stale sentinels (4+ hours old)
Get-ChildItem "$env:TEMP\claude-rm-allowed-*" | Where-Object {
    (Get-Date) - $_.LastWriteTime -gt (New-TimeSpan -Hours 4)
} | Remove-Item -Force

exit 0
