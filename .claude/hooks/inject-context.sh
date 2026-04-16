#!/usr/bin/env bash
# SessionStart hook: 세션 시작/재개/컴팩션 시 프로젝트 상태 자동 주입
#
# Payload 순서: 정적(Arena → 프로젝트) → 동적(날짜)
# 이유: prompt caching prefix 안정성. 자주 변경되는 텍스트는 뒤쪽에.

set -uo pipefail

CONTEXT=""

# [정적] Arena 시즌 (가장 적게 변경)
ARENA_FILE="$PROJECT_ROOT/.claude/context/skill_arena.yaml"
if [[ -f "$ARENA_FILE" ]]; then
  SEASON=$(grep '^season:' "$ARENA_FILE" | head -1 | awk '{print $2}')
  LAST_EVENT=$(grep 'last_event:' "$ARENA_FILE" | head -1 | sed 's/.*last_event: *//')
  CONTEXT+="[Arena] Season ${SEASON:-?} | 최근: ${LAST_EVENT:-없음}"$'\n'
fi

# [반정적] 진행중 프로젝트
STATE_FILE="$PROJECT_ROOT/.claude/context/project_state.yaml"
if [[ -f "$STATE_FILE" ]]; then
  CONTEXT+="[프로젝트 상태]"$'\n'
  CONTEXT+=$(python3 -c "
import yaml
with open('$STATE_FILE') as f:
    data = yaml.safe_load(f)
for name, info in (data.get('projects', {}) or {}).items():
    if info.get('status') == '진행중':
        print(f'  - {name}: {info.get(\"current_task\",\"없음\")}')
decisions = data.get('pending_decisions', []) or []
if decisions:
    print('미결:')
    for d in decisions:
        print(f'  - {d}')
" 2>/dev/null || echo "  (파싱 실패)")
  CONTEXT+=$'\n'
fi

# [동적] 오늘 날짜 (매일 변경 → 가장 마지막)
CONTEXT+="[날짜] $(date '+%Y-%m-%d %A')"$'\n'

# JSON 출력
if [[ -n "$CONTEXT" ]]; then
  ESCAPED=$(printf '%s' "$CONTEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")
  echo "{\"additionalContext\": ${ESCAPED}}"
fi

exit 0
