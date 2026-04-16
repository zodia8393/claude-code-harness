# 공통 규칙 (모든 subagent 필수)

## 파일 저장 경로 규칙
1. 사용자가 경로를 명시 → 그대로 저장
2. 프로젝트 컨텍스트에서 추론 가능 → 추론 경로 제시 + 사용자 확인
3. 불명확 → 사용자에게 경로 질문 후 생성
- **금지**: 홈(`$HOME`)에 직접 저장

## 자기 결과물 불신 원칙
- 코드는 반드시 실행/테스트로 검증
- 수치/통계는 역산/교차검증
- "맞을 것이다"라는 가정 금지

## 요청 범위 준수
- 요청된 것만 수행 — 요청 외 리팩토링/확장 금지
- "이왕이면"으로 범위를 넓히지 말 것

## 핸드오프 의무 (스킬 간 협업)

작업 종료 시 다음 스킬에 넘길 내용이 있으면 **핸드오프 봉투**를 작성한다.
- 경로: `context/handoff/{YYYYMMDD}_{HHMMSS}_{from}_{to}.yaml`
- 템플릿: `context/handoff/TEMPLATE.yaml` 참조
- **필수 필드**: id, from, to, action, timestamp, summary, artifacts, expects
- **선택 필드**: decisions, context_ref, risk_notes, quality_gate, cv_meta
- 핸드오프 단위: **배치(영상/디렉토리)** 기준, 프레임 단위 금지
- artifacts 경로의 파일 존재 검증은 **수신 측 책임**
- 읽기전용 스킬(qa/client)은 메인 컨텍스트가 대리 작성
- 다음 스킬이 없는 단독 작업은 핸드오프 생략 가능

## 레지스트리 기록 (해당 시)

스킬 유형별로 해당 레지스트리에 **append-only** 1줄 기록한다. 스키마: `context/registry/SCHEMA.md`
- **ml-engineer / vision-engineer**: 실험 완료 → `context/registry/experiment_registry.jsonl`
- **qa / client**: 결함 발견 → `context/registry/defect_registry.jsonl` (읽기전용 스킬은 메인 대리 기록)
- **전 스킬**: 리스크 발견 → `context/registry/risk_registry.jsonl`
- 기존 줄 수정/삭제 금지. 상태 변경은 같은 ID로 새 줄 append.
- **품질 게이트 연동**: defect에 `severity: critical` + `status: open` ≥ 1이면 gate 불통과

## 환경 정보
- DB: Oracle (YTBS/TBGD) — oracledb, DSN YOUR_DB_HOST:PORT/SID, .env 참조
- Python 3.13, DuckDB, pandas, matplotlib 사용 가능
- OS: Ubuntu 25.10
