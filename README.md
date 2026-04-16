# Claude Code Harness

Claude Code를 **17개 전문 스킬 시스템**으로 확장하는 하네스.
스킬 간 자동 라우팅, 핸드오프, 품질 게이트, Arena 경쟁 진화를 제공합니다.

## 특징

- **17개 전문 에이전트**: developer, data-analyst, ml-engineer, vision-engineer, architect, qa, devops 등
- **자동 라우팅**: 요청 유형에 따라 최적 스킬로 자동 위임 (`context:fork` 격리)
- **6개 워크플로우**: 코드 구현, 데이터 분석, 모델 학습, 영상 분석, 기술 도입, 릴리즈
- **협업 체계**: 핸드오프 봉투, append-only 레지스트리, 도메인 제약조건
- **5개 Hooks**: 파괴적 명령 가드, 캐시 자동정리, 세션 상태 주입, 스킬 로깅
- **Arena**: MCP 기반 스킬 사용 추적 + Elo 레이팅
- **크로스 플랫폼**: Linux/macOS (bash) + Windows (PowerShell) 지원

## 빠른 시작

### 1. 클론

```bash
git clone https://github.com/zodia8393/claude-code-harness.git
cd your-project
cp -r claude-code-harness/.claude .
cp claude-code-harness/CLAUDE.md .
cp claude-code-harness/.mcp.json .
```

### 2. 설정

**Linux / macOS / WSL:**
```bash
chmod +x .claude/hooks/*.sh
cp .claude/settings.json .claude/settings.json
```

**Windows (PowerShell):**
```powershell
Copy-Item .claude\settings.windows.json .claude\settings.json
```

### 3. CLAUDE.md 커스터마이즈

`CLAUDE.md`의 Infrastructure 섹션을 자신의 환경에 맞게 수정:
- OS, Python 버전, GPU 유무
- DB 접속 정보 (있다면)
- 프로젝트 디렉토리 구조

### 4. (선택) Arena MCP 서버

```bash
pip install fastmcp pyyaml
# .mcp.json이 자동으로 arena 서버를 등록합니다
```

### 5. (선택) 스케줄러

```bash
pip install pyyaml holidays
cp .claude/schedules/config.example.yaml .claude/schedules/config.yaml
# config.yaml 편집 후:
python .claude/schedules/runner.py --list
python .claude/schedules/runner.py daily-cleanup
```

## 구조

```
.claude/
├── agents/                  ← 17개 스킬 에이전트 정의
│   ├── COMMON_RULES.md      ← 전 에이전트 공통 규칙
│   ├── developer/index.md   ← 개발자 (Karpathy 철학)
│   ├── data-analyst/        ← 데이터 분석 (Tukey EDA 철학)
│   │   ├── index.md
│   │   ├── profiling.md
│   │   └── sql.md
│   ├── ml-engineer/         ← ML 엔지니어 (Andrew Ng)
│   ├── vision-engineer/     ← 영상처리 (Karpathy CV)
│   ├── architect/           ← 아키텍트 (Fred Brooks)
│   ├── qa/                  ← 품질보증 (James Bach) [읽기전용]
│   ├── admin/               ← 시스템 관리 (Deming PDCA)
│   └── ...                  ← 나머지 10개 스킬
├── commands/                ← `/스킬명` 슬래시 커맨드 스텁
├── hooks/                   ← 이벤트 기반 자동화
│   ├── *.sh                 ← Linux/macOS
│   └── *.ps1                ← Windows
├── workflows/               ← 6개 워크플로우 정의 (YAML)
├── context/                 ← 스킬 간 협업 데이터
│   ├── handoff/TEMPLATE.yaml
│   ├── registry/SCHEMA.md
│   ├── state/LEDGER_TEMPLATE.yaml
│   └── domain_constraints.example.yaml
├── mcp-servers/             ← Arena MCP 서버
├── institutional/           ← 모범사례 + 패턴
├── schedules/               ← 정기 실행 스케줄러
├── settings.json            ← Linux/macOS 설정
└── settings.windows.json    ← Windows 설정
```

## 스킬 목록

| 리그 | 스킬 | 모델 | 철학 |
|------|------|------|------|
| 구현 | developer | opus | Andrej Karpathy |
| 구현 | architect | opus | Fred Brooks |
| 구현 | devops | sonnet | Gene Kim |
| 분석 | data-analyst | sonnet | John Tukey |
| 분석 | ml-engineer | opus | Andrew Ng |
| 분석 | researcher | sonnet | Richard Feynman |
| 분석 | vision-engineer | opus | Andrej Karpathy (CV) |
| 커뮤니케이션 | office-worker | sonnet | David Allen (GTD) |
| 커뮤니케이션 | project-manager | sonnet | Ed Catmull |
| 커뮤니케이션 | trainer | sonnet | Benjamin Bloom |
| 검증 | qa | sonnet | James Bach [읽기전용] |
| 검증 | client | sonnet | Peter Drucker [읽기전용] |
| 검증 | urban-engineer | opus | Jan Gehl |
| 전략 | admin | opus | W. Edwards Deming |
| 전략 | designer | sonnet | Dieter Rams |
| 전략 | finance-expert | sonnet | Warren Buffett |
| 전략 | health-expert | sonnet | Progressive Overload |

## 사용법

```
/developer 로그인 기능 구현해줘
/data-analyst 이 CSV 프로파일링해줘
/vision-engineer YOLO로 객체 탐지 파이프라인 만들어줘
/admin 전 스킬 소집, 안건: 아키텍처 리뷰
```

## 커스터마이징

### 스킬 추가
1. `agents/{skill-name}/index.md` 작성 (기존 스킬 참고)
2. `commands/{skill-name}.md` 스텁 작성
3. `CLAUDE.md` 라우팅 테이블에 추가

### 스킬 제거
해당 `agents/` + `commands/` 파일 삭제, `CLAUDE.md` 테이블에서 제거.

### 워크플로우 추가
`workflows/` 디렉토리에 YAML 작성. 기존 파일 참고.

## 요구사항

- [Claude Code](https://claude.com/claude-code) CLI
- Python 3.10+
- `jq` (Linux/macOS hooks용)
- (선택) `fastmcp`, `pyyaml` (Arena MCP 서버)
- (선택) `holidays` (스케줄러 공휴일 스킵)

## 라이선스

MIT
