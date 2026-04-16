#!/usr/bin/env bash
# Stop hook: 작업 완료 시 캐시/임시파일 자동 정리
# CLAUDE.md 규칙 7: __pycache__, .pytest_cache, ~$* Office 임시파일, tmp_*.py

set -uo pipefail

CLEANED=0

# __pycache__ 정리
while IFS= read -r -d '' dir; do
  rm -rf "$dir" 2>/dev/null && ((CLEANED++)) || true
done < <(find "${PROJECT_ROOT:-.}" -name '__pycache__' -type d -print0 2>/dev/null)

# .pytest_cache 정리
while IFS= read -r -d '' dir; do
  rm -rf "$dir" 2>/dev/null && ((CLEANED++)) || true
done < <(find "${PROJECT_ROOT:-.}" -name '.pytest_cache' -type d -print0 2>/dev/null)

# Office 임시파일 (~$*)
while IFS= read -r -d '' f; do
  rm -f "$f" 2>/dev/null && ((CLEANED++)) || true
done < <(find "${PROJECT_ROOT:-.}" -name '~\$*' -type f -print0 2>/dev/null)

# tmp_*.py 임시 스크립트
while IFS= read -r -d '' f; do
  rm -f "$f" 2>/dev/null && ((CLEANED++)) || true
done < <(find "${PROJECT_ROOT:-.}" -name 'tmp_*.py' -type f -print0 2>/dev/null)

# Additional directories (uncomment and customize)
# while IFS= read -r -d '' dir; do
#   rm -rf "$dir" 2>/dev/null && ((CLEANED++)) || true
# done < <(find "$HOME/projects" -maxdepth 4 -name '__pycache__' -type d -print0 2>/dev/null)

if [[ $CLEANED -gt 0 ]]; then
  echo "{\"additionalContext\": \"[자동정리] ${CLEANED}개 캐시/임시파일 정리 완료\"}"
fi

exit 0
