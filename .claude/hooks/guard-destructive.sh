#!/usr/bin/env bash
# PreToolUse hook: 파괴적 명령 가드 (세션 sentinel 기반)
#
# 동작:
#   1. 첫 rm/삭제 명령: sentinel 없음 → exit 2로 차단 + Claude에게 사용자 허가 절차 안내
#   2. 사용자가 명시 허락 → Claude가 sentinel 파일 생성 → 이후 세션 동안 모든 삭제 명령 통과
#   3. 세션 종료 시 SessionEnd hook이 sentinel 삭제
#   4. 만료(4시간) 초과 시 sentinel 무효화
#
# settings.allow에 영구 등록되지 않음. 세션 한정 in-memory 허가.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Bash 도구가 아니면 통과
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# === 세션 sentinel ===
SENTINEL="/tmp/claude-rm-allowed-${SESSION_ID}"
SENTINEL_TTL=$((4 * 3600))  # 4시간

# sentinel 만료 체크 (mtime 기반)
if [[ -f "$SENTINEL" ]]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$SENTINEL" 2>/dev/null || echo 0) ))
  if (( AGE > SENTINEL_TTL )); then
    rm -f "$SENTINEL" 2>/dev/null
  fi
fi

# sentinel이 유효하면 모든 삭제 명령 통과 (세션 한정 일시 허가)
if [[ -f "$SENTINEL" ]]; then
  exit 0
fi

BLOCK_MSG=$(cat <<EOF
→ CLAUDE.md 규칙 0: 파일 삭제는 사용자 확인 필요.

[세션 일시 허가 절차]
1. AskUserQuestion으로 사용자에게 명시적으로 'rm 일시 허용?' 확인
2. 허락 받으면, 다음 명령으로 세션 sentinel 생성:
     touch ${SENTINEL}
3. 그 후 원래 삭제 명령 재시도. 이번 세션 동안은 더 이상 묻지 않음.

* sentinel은 세션 종료 시 자동 삭제 (settings.allow에 영구 등록되지 않음)
* sentinel 경로: ${SENTINEL}
EOF
)

# 1. 직접 삭제 명령: rm, rmdir, shred, unlink (단독 또는 파이프/체인 내)
if echo "$TOOL_INPUT" | grep -qEi '(^|\||\;|\&\&)\s*(rm|rmdir|shred|unlink)\s'; then
  echo "[HOOK 차단] 삭제 명령 감지: '$TOOL_INPUT'" >&2
  echo "$BLOCK_MSG" >&2
  exit 2
fi

# 2. find -delete
if echo "$TOOL_INPUT" | grep -qEi 'find\s.*-delete'; then
  echo "[HOOK 차단] find -delete 감지: '$TOOL_INPUT'" >&2
  echo "$BLOCK_MSG" >&2
  exit 2
fi

# 3. find -exec rm (우회 패턴)
if echo "$TOOL_INPUT" | grep -qEi 'find\s.*-exec\s*(rm|rmdir)'; then
  echo "[HOOK 차단] find -exec rm 감지: '$TOOL_INPUT'" >&2
  echo "$BLOCK_MSG" >&2
  exit 2
fi

# 4. xargs rm (우회 패턴)
if echo "$TOOL_INPUT" | grep -qEi 'xargs\s.*(rm|rmdir)'; then
  echo "[HOOK 차단] xargs rm 감지: '$TOOL_INPUT'" >&2
  echo "$BLOCK_MSG" >&2
  exit 2
fi

# 5. python/python3 os.remove/shutil.rmtree (우회 패턴)
if echo "$TOOL_INPUT" | grep -qEi 'python3?\s.*\b(os\.remove|os\.unlink|shutil\.rmtree|pathlib.*\.unlink|\.rmdir)\b'; then
  echo "[HOOK 차단] Python 삭제 API 감지: '$TOOL_INPUT'" >&2
  echo "$BLOCK_MSG" >&2
  exit 2
fi

# 통과
exit 0
