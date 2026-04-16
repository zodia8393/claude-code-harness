# Stop hook: clean up cache/temp files on task completion
# Windows PowerShell version of cleanup-temp.sh

$ErrorActionPreference = "SilentlyContinue"
$projectRoot = if ($env:PROJECT_ROOT) { $env:PROJECT_ROOT } else { (Get-Location).Path }
$cleaned = 0

# __pycache__
Get-ChildItem -Path $projectRoot -Recurse -Directory -Filter "__pycache__" | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force; $cleaned++
}

# .pytest_cache
Get-ChildItem -Path $projectRoot -Recurse -Directory -Filter ".pytest_cache" | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force; $cleaned++
}

# Office temp files (~$*)
Get-ChildItem -Path $projectRoot -Recurse -File -Filter "~`$*" | ForEach-Object {
    Remove-Item $_.FullName -Force; $cleaned++
}

# tmp_*.py
Get-ChildItem -Path $projectRoot -Recurse -File -Filter "tmp_*.py" | ForEach-Object {
    Remove-Item $_.FullName -Force; $cleaned++
}

if ($cleaned -gt 0) {
    Write-Output "{`"additionalContext`": `"[Auto-cleanup] $cleaned cache/temp items cleaned`"}"
}

exit 0
