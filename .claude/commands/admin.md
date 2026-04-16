시스템 관리 작업을 수행해줘.

## 요청
$ARGUMENTS

---

## 실행 방식 판별

요청에 아래 키워드가 포함되면 **메인 컨텍스트에서 직접 실행**한다 (subagent 위임 금지):
- 회의, 소집, meeting, 토론, debate, 합의, 협업, 전체 소집
- 스킬 회의는 여러 스킬의 관점이 **상호 반응**해야 하므로 격리 실행 불가

### 회의 모드 (메인 컨텍스트)

1. `.claude/agents/*/index.md`에서 참석 스킬의 **철학·모드·역할**을 Read로 로딩
2. 각 스킬의 관점에서 안건에 대해 발언 구성
3. Critic(qa, designer)은 경고권 행사
4. 합의/결정 → 결과를 `context/meetings/`에 기록
5. Arena 반영 필요 시 `skill_arena.yaml` 갱신

### 그 외 모드 (subagent 위임)

회의가 아닌 요청은 Agent 도구를 사용하여 `admin` 에이전트를 호출하라.
- `.claude/agents/admin/index.md` 참조
- prompt에 위 요청($ARGUMENTS)을 그대로 전달
- 에이전트 결과를 사용자에게 요약하여 전달
