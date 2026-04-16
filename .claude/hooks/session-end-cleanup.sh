#!/usr/bin/env bash
# SessionEnd hook: 세션 종료 시 일시 허가 sentinel 정리
#
# guard-destructive.sh가 만든 /tmp/claude-rm-allowed-${SESSION_ID} 를 삭제.
# 이로써 "rm 일시 허가"가 세션을 넘어서 지속되지 않음을 보장.

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo '{}')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")

SENTINEL="/tmp/claude-rm-allowed-${SESSION_ID}"
if [[ -f "$SENTINEL" ]]; then
  rm -f "$SENTINEL" 2>/dev/null
fi

# 추가 안전: 4시간 이상 묵은 rm-allowed sentinel 일괄 청소 (세션이 비정상 종료된 잔재)
find /tmp -maxdepth 1 -name 'claude-rm-allowed-*' -type f -mmin +240 -delete 2>/dev/null || true

exit 0
