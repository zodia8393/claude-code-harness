# Claude Code Harness — Operating Rules

## Core Rules

| # | Rule |
|---|------|
| **0** | **Autonomous execution**: Read, search, analyze, code, run, test, Bash, edit files autonomously. User confirmation only for: ① `rm` (file deletion) ② `sudo`/system config ③ `git push --force` |
| 1 | **Dev loop**: Write → Run → Debug, up to 10 iterations |
| 2 | **Verify everything**: Run/test code, reverse-check numbers. Never assume "it should work" |
| 3 | **Auto-commit**: Auto commit & push on code changes in git repos. Skip if not a git repo |
| 4 | **Path confirmation**: Explicit → use as-is / Inferrable → suggest + confirm / Unclear → ask. **Never save directly to $HOME** |
| 5 | **Background first**: 10s+ tasks use `run_in_background`, parallelize independent work |
| 6 | **File hygiene**: Auto-delete caches/temp files, no cross-project mixing, 50MB+ → `.gitignore` |
| 7 | **Justify actions**: Self-verify "why" for every action. If you can't explain it, don't do it |
| 8 | **Error loop escape**: Same logical fix fails 2x in a row → change approach |
| 9 | **Skill delegation**: Route to matching skill when applicable. Exceptions: meetings, simple queries, chaining decisions |
| 10 | **Large file check**: Before manipulating 1GB+ files, run `df -h` + `du -sh`. Same-FS `mv` is exempt |
| 11 | **DB connection failure** → Guide user to check VPN/network |

---

## Harness Architecture

```
L3  CLAUDE.md + Memory
L2  agents/ (17 subagents) + commands/ (stubs) + workflows/ (6)
L1  hooks/ (5) + context/ (handoff, registry, state)
L0  settings.json + .mcp.json (Arena MCP)
```

`/skill-name` → commands/ stub (`context:fork`) → agents/ subagent isolated execution.
Meetings, chaining, and interactive work stay in main context.

### Hooks (5)
| Hook | Trigger | Function |
|------|---------|----------|
| `guard-destructive` | PreToolUse(Bash) | Block rm/delete → require user confirmation |
| `cleanup-temp` | Stop | Clean __pycache__, .pytest_cache, ~$*, tmp_*.py |
| `inject-context` | SessionStart | Auto-inject project state + date |
| `log-skill-usage` | PostToolUse | Log skill usage for Arena tracking |
| `session-end-cleanup` | SessionEnd | Remove session sentinels |

### Collaboration (context/)
- **Handoff envelopes**: `context/handoff/` — Inter-skill handoff YAML (see TEMPLATE.yaml)
- **Registries**: `context/registry/` — experiment/defect/risk append-only JSONL
- **State**: `context/state/` — Workflow progress ledgers
- **Meetings**: `context/meetings/` — Skill meeting records
- **Domain constraints**: `context/domain_constraints.yaml` — Expert-authored validation rules

---

## Skill Routing (17 skills)

**Priority**: ① `/skill-name` explicit → ② Matching table → ③ Workflow chaining → ④ Meeting (`/admin`) → ⑤ Direct response

| Request Type | Skill |
|-------------|-------|
| Code implementation, debugging, review, testing, refactoring | `/developer` |
| Data profiling, quality, EDA, SQL, DB exploration | `/data-analyst` |
| Model evaluation, training, experiments, feature engineering | `/ml-engineer` |
| Video processing, object detection, tracking, classification, CV pipeline | `/vision-engineer` |
| Documents, email, meeting notes, Notion, Office files | `/office-worker` |
| Work plans, dashboards, reports, risk, schedules, retrospectives | `/project-manager` |
| Environment, CI/CD, monitoring, backup, Docker, DB ops | `/devops` |
| Papers, tech research, benchmarks, experiment design | `/researcher` |
| Architecture, design patterns, ADR, dependencies, DFD | `/architect` |
| Test strategy, coverage, quality gates, regression, validation | `/qa` |
| UI/UX, wireframes, design systems, visualization | `/designer` |
| Skill management, directory, security, settings, meetings | `/admin` |
| Stocks, economics, investment, portfolio analysis | `/finance-expert` |
| Deliverable inspection, client simulation | `/client` |
| Training curriculum, educational materials | `/trainer` |
| Traffic volume, road capacity, transit, transportation planning | `/urban-engineer` |
| Exercise, nutrition, body composition, supplements | `/health-expert` |
| Post-implementation auto-cleanup | `/simplify` |

### Workflows (6 — `.claude/workflows/*.yaml`)

| Workflow | Skill Chain |
|----------|------------|
| Code Implementation | architect(design)? → developer(impl→review) → qa(verify) → commit |
| Data Analysis | data-analyst(profile→SQL→viz) → project-manager(report) |
| Model Training | data-analyst(quality) → developer(loader) → ml-engineer(train→eval) → qa(verify) |
| Vision Pipeline | urban-engineer(criteria) → vision-engineer(pipeline→eval) → qa(verify) → data-analyst(aggregate) |
| Tech Adoption | researcher(research) → architect(ADR) → developer(PoC) |
| Release | qa(gate) → devops(deploy) → project-manager(report) |

---

## Work Guidelines (Common)

> Detailed standards are delegated to each skill's `agents/*/index.md` + `COMMON_RULES.md`.

**Files**: Filename `{content}_{date}_{version}.{ext}` / No overwrite / Reports: key findings first, units + sources
**Data**: Original = read-only / Large data: DuckDB first / No hardcoding, parameterize paths + dates
**Development**: PEP 8 / utf-8 default / Credentials → `.env` / SQL bind variables
**Git**: 1 commit = 1 logical change, message `{verb} {target}: {detail}` / No auto-resolving conflicts
**Path changes**: Grep full search → batch update → verify

---

# Infrastructure (Customize for your environment)

| Item | Value |
|------|-------|
| OS | (your OS) |
| Python | 3.10+ required |
| GPU | Optional (CPU inference supported) |

## DB (if applicable)

`.env` location: `$PROJECT_ROOT/.env`

```python
import os, oracledb  # or your DB driver
conn = oracledb.connect(user="USER", password=os.environ["DB_PASSWORD"], dsn="HOST:PORT/SID")
```

## Folder Structure

```
$PROJECT_ROOT/
├─ .claude/                 ← Harness (agents, commands, hooks, workflows, context)
├─ .env                     ← Environment variables (git-ignored)
└─ {projects}/              ← Your project directories
```
