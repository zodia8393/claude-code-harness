# context/ 디렉토리 규칙

> 2026-04-16 전 스킬(17개) 회의 합의 — Tier 1/2/3 전체 구현 완료

## 구조

```
context/
├── handoff/                    ← 스킬 간 핸드오프 봉투
│   └── TEMPLATE.yaml           ← 봉투 템플릿
├── state/                      ← 워크플로우 현재 상태 (Ledger)
│   └── LEDGER_TEMPLATE.yaml    ← Ledger 템플릿
├── registry/                   ← append-only 레지스트리
│   ├── SCHEMA.md               ← 전체 스키마 정의
│   ├── experiment_registry.jsonl
│   ├── defect_registry.jsonl
│   └── risk_registry.jsonl
├── archive/                    ← 완료된 핸드오프/상태/레지스트리 보관
├── meetings/                   ← 회의록
├── domain_constraints.yaml     ← 도메인 제약조건 (역방향 지식 채널)
├── project_state.yaml
├── decisions.log
├── failures.log
├── skill_arena.yaml
└── skill_usage.log
```

## 네이밍 규칙

| 디렉토리 | 파일명 패턴 | 예시 |
|----------|------------|------|
| handoff/ | `{YYYYMMDD}_{HHMMSS}_{from}_{to}.yaml` | `20260416_153000_developer_qa.yaml` |
| state/ | `{workflow}_{task_id}.yaml` | `code_impl_fix-parser.yaml` |
| registry/ | `{종류}_registry.jsonl` | `experiment_registry.jsonl` |
| archive/ | 원본 파일명 유지, 이동만 | — |
| meetings/ | `meeting_{YYYYMMDD}_{안건}.md` | `meeting_20260416_협업메커니즘.md` |

## 생명주기

1. **생성**: 스킬이 작업 종료 시 해당 디렉토리에 파일 생성
2. **소비**: 수신 스킬이 읽고 작업 수행
3. **완료**: 워크플로우 종료 시 handoff/, state/ 파일을 archive/로 이동
4. **정리**: cleanup 훅이 archive/ 내 7일 초과 파일 삭제, registry resolved 3개월 초과 → archive/

## 핸드오프 봉투 (Tier 1)

- 템플릿: `handoff/TEMPLATE.yaml`
- 필수 필드: id, from, to, action, timestamp, summary, artifacts, expects
- 선택 필드: decisions, context_ref, risk_notes, quality_gate, cv_meta
- 핸드오프 단위: **배치(영상/디렉토리)** — 프레임 단위 금지
- artifacts 경로의 파일 존재 검증: **수신 측 책임**
- 읽기전용 스킬(qa/client): 메인 컨텍스트가 대리 작성
- 다음 스킬 없는 단독 작업: 핸드오프 생략 가능

## Registry (Tier 2)

append-only JSONL. 스키마 상세: `registry/SCHEMA.md`

| 파일 | 작성자 | 용도 |
|------|--------|------|
| `experiment_registry.jsonl` | ml-engineer, vision-engineer | 실험 결과 누적 |
| `defect_registry.jsonl` | qa, client (메인 대리) | 결함 보고·추적 |
| `risk_registry.jsonl` | 전 스킬 | 리스크 보고·완화 |

**공통 규칙**:
- append-only — 수정/삭제 금지, 상태 변경은 새 줄로 기록
- ID: 실험 `r{NNN}`, 결함 `D-{NNN}`, 리스크 `R-{NNN}`
- 품질 게이트 연동: defect `severity:critical` + `status:open` ≥ 1이면 gate 불통과

## Workflow Ledger (Tier 2)

- 템플릿: `state/LEDGER_TEMPLATE.yaml`
- 워크플로우 실행 시 메인 컨텍스트가 생성
- 각 스킬 실행 전후로 해당 step 업데이트
- 완료 시 summary 작성 후 archive/로 이동

## 조기 검증 훅 (Tier 3)

- `code_implementation.yaml` v1.2: architect(설계검토) → qa(설계검증) → developer(구현)
- `model_training.yaml` v1.2: data-analyst(프로파일링) → qa(데이터설계검증) → developer(구현)
- `optional: true` — 설계 단계가 있는 경우에만 실행
- 구현 전 구조적 결함 사전 차단 목적

## Domain Constraints (Tier 3)

- 파일: `context/domain_constraints.yaml`
- 작성: researcher, urban-engineer (도메인 권위)
- 참조: data-analyst(프로파일링 시 위반 플래그), vision-engineer(후처리 시 검증)
- 섹션: traffic, vehicle_classification, temporal
- 새 프로젝트/데이터셋 추가 시 해당 섹션 append
