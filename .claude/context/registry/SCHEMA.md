# Registry 스키마 정의

> 2026-04-16 전 스킬 회의 합의. 모든 레지스트리는 **append-only JSONL**.
> 한 줄 = 하나의 이벤트. 수정/삭제 금지, status 필드로 상태 전이.

---

## 1. experiment_registry.jsonl

ml-engineer / vision-engineer가 실험 완료 시 1줄 추가.

```json
{
  "run_id": "r001",
  "timestamp": "2026-04-16T15:00:00",
  "skill": "ml-engineer",
  "project": "CCTV차종분류",
  "model": "yolo11x-cls",
  "dataset": "부평IC_7cls_train",
  "metrics": {
    "accuracy": 0.992,
    "f1_macro": 0.985,
    "per_class": {"승용": 0.99, "버스": 0.98}
  },
  "params": {
    "epochs": 100,
    "imgsz": 224,
    "batch": 32,
    "lr": 0.001
  },
  "weights_path": "/path/to/best.pt",
  "notes": "self-training 2라운드 적용",
  "status": "completed"
}
```

**필수 필드**: run_id, timestamp, skill, model, dataset, metrics, status
**선택 필드**: project, params, weights_path, notes, per_class

---

## 2. defect_registry.jsonl

qa / client가 결함 발견 시 1줄 추가. (읽기전용 스킬은 메인 컨텍스트가 대리 기록)

```json
{
  "defect_id": "D-001",
  "timestamp": "2026-04-16T16:00:00",
  "reporter": "qa",
  "assignee": "developer",
  "severity": "critical",
  "category": "logic",
  "summary": "NMS threshold 미적용으로 중복 bbox 발생",
  "artifact": "/workspace/CCTV차종분류/pipeline/detect.py",
  "line": 142,
  "reproduce": "conf=0.25, iou=0.45에서 재현",
  "status": "open",
  "resolved_by": null,
  "resolved_at": null
}
```

**필수 필드**: defect_id, timestamp, reporter, severity, summary, status
**선택 필드**: assignee, category, artifact, line, reproduce, resolved_by, resolved_at
**severity**: critical | high | mid | low
**status**: open | in_progress | resolved | wontfix
**상태 전이**: 새 줄로 append (같은 defect_id, 새 status)

---

## 3. risk_registry.jsonl

모든 스킬이 리스크 발견 시 1줄 추가.

```json
{
  "risk_id": "R-001",
  "timestamp": "2026-04-16T17:00:00",
  "reporter": "devops",
  "severity": "high",
  "category": "infra",
  "summary": "외장 디스크 I/O 병목 — crop 30만장 처리 시 4시간 소요",
  "impact": "파이프라인 전체 소요시간 2배 증가",
  "mitigation": "중간 결과를 NVMe로 저장 후 최종만 외장 이동",
  "status": "open",
  "resolved_at": null
}
```

**필수 필드**: risk_id, timestamp, reporter, severity, summary, status
**선택 필드**: category, impact, mitigation, resolved_at
**severity**: critical | high | mid | low
**status**: open | mitigated | accepted | closed
**category**: infra | data | model | process | security | domain

---

## 공통 규칙

1. **append-only** — 기존 줄 수정/삭제 금지. 상태 변경은 새 줄로 기록
2. **ID 형식** — 실험: `r{NNN}`, 결함: `D-{NNN}`, 리스크: `R-{NNN}`
3. **정리 주기** — resolved/closed 상태 3개월 초과분은 archive/로 이동
4. **품질 게이트 연동** — defect에 `severity: critical` + `status: open`이 1건 이상이면 워크플로우 gate 불통과
