"""
Arena MCP Server — 스킬 사용 로깅 및 Elo 레이팅 관리
fastmcp 기반 stdio 서버
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

from fastmcp import FastMCP

mcp = FastMCP("arena")

CONTEXT_DIR = Path("$PROJECT_ROOT/.claude/context")
ARENA_FILE = CONTEXT_DIR / "skill_arena.yaml"
USAGE_LOG = CONTEXT_DIR / "skill_usage.log"


@mcp.tool()
def log_skill_usage(skill_name: str, mode: str = "", quality_score: float = 0.0) -> str:
    """스킬 사용을 기록한다. 스킬 실행 완료 후 호출.

    Args:
        skill_name: 스킬 이름 (예: developer, data-analyst)
        mode: 실행 모드 (예: 구현, 프로파일링, 리뷰)
        quality_score: 결과 품질 점수 (0.0~5.0, 선택)
    """
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "skill": skill_name,
        "mode": mode,
        "quality_score": quality_score,
    }
    USAGE_LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(USAGE_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    return f"[Arena] {skill_name}/{mode} 기록 완료 (품질: {quality_score})"


@mcp.tool()
def get_skill_stats(skill_name: str = "") -> str:
    """스킬별 사용 통계를 조회한다.

    Args:
        skill_name: 특정 스킬 (빈 문자열이면 전체)
    """
    if not USAGE_LOG.exists():
        return "사용 로그 없음"

    stats: dict[str, dict] = {}
    with open(USAGE_LOG, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            name = entry.get("skill", "unknown")
            if skill_name and name != skill_name:
                continue
            if name not in stats:
                stats[name] = {"count": 0, "scores": [], "modes": {}}
            stats[name]["count"] += 1
            score = entry.get("quality_score", 0)
            if score > 0:
                stats[name]["scores"].append(score)
            mode = entry.get("mode", "")
            if mode:
                stats[name]["modes"][mode] = stats[name]["modes"].get(mode, 0) + 1

    if not stats:
        return f"'{skill_name}' 사용 기록 없음" if skill_name else "사용 기록 없음"

    lines = ["# 스킬 사용 통계\n"]
    for name, data in sorted(stats.items(), key=lambda x: x[1]["count"], reverse=True):
        avg_score = sum(data["scores"]) / len(data["scores"]) if data["scores"] else 0
        modes_str = ", ".join(f"{m}({c})" for m, c in sorted(data["modes"].items(), key=lambda x: x[1], reverse=True))
        lines.append(f"**{name}**: {data['count']}회 | 평균품질: {avg_score:.1f} | 모드: {modes_str}")

    return "\n".join(lines)


@mcp.tool()
def get_arena_status() -> str:
    """Arena 현재 상태 (시즌, 리그, 최근 이벤트)를 반환한다."""
    if not ARENA_FILE.exists():
        return "Arena 파일 없음"

    try:
        import yaml
        with open(ARENA_FILE, encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except ImportError:
        # yaml 없으면 텍스트로 읽기
        with open(ARENA_FILE, encoding="utf-8") as f:
            return f.read()[:2000]

    season = data.get("season", "?")
    last_event = data.get("skill_arena", {}).get("last_event", "없음") if isinstance(data.get("skill_arena"), dict) else "없음"

    ratings = data.get("ratings", {})
    top5 = sorted(ratings.items(), key=lambda x: x[1].get("total", 0) if isinstance(x[1], dict) else 0, reverse=True)[:5]

    lines = [
        f"# Arena Status — Season {season}\n",
        "## Top 5 스킬",
    ]
    for name, info in top5:
        if isinstance(info, dict):
            total = info.get("total", 0)
            streak = info.get("streak", 0)
            lines.append(f"  {name}: Elo {total} (연승: {streak})")

    return "\n".join(lines)


if __name__ == "__main__":
    mcp.run()
