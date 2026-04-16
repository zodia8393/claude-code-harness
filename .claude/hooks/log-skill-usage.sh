#!/usr/bin/env bash
# PostToolUse hook: Skill 도구 호출 시 사용 로그 기록
# Arena 자동 Elo 산출의 데이터 기반

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skill 도구만 로깅
if [[ "$TOOL_NAME" != "Skill" ]]; then
  exit 0
fi

SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.skill // empty')
TASK_SUMMARY=$(echo "$INPUT" | jq -r '(.tool_input.args // "")[:100]')
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# args가 비어있으면 기본값
if [[ -z "$TASK_SUMMARY" ]]; then
  TASK_SUMMARY="(no args)"
fi

LOG_FILE="$PROJECT_ROOT/.claude/context/skill_usage.log"
ARENA_LOG="$EXTERNAL_DRIVE/.claude/arena_log.jsonl"

# jq로 안전하게 JSON 생성 (특수문자 이스케이프)
echo "$INPUT" | jq -c --arg ts "$TIMESTAMP" --arg sk "$SKILL_NAME" --arg sid "$SESSION_ID" \
  '{timestamp: $ts, skill: $sk, session: $sid}' >> "$LOG_FILE"

echo "$INPUT" | jq -c --arg ts "$TIMESTAMP" --arg sk "$SKILL_NAME" --arg task "$TASK_SUMMARY" \
  '{timestamp: $ts, skill: $sk, task: $task, success: true}' >> "$ARENA_LOG"

exit 0
