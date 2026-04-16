"""
Claude Code 스케줄 실행기
- config.yaml에서 스킬 설정을 읽어 Claude CLI로 실행
- 실행 결과를 logs/ 폴더에 저장
- 오래된 로그 자동 정리

사용법:
    python runner.py <스킬명>           # 특정 스킬 실행
    python runner.py --list             # 등록된 스킬 목록
    python runner.py --cleanup-logs     # 오래된 로그 삭제
"""

import io
import os
import shutil
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

import holidays
import yaml

# 콘솔 한글 출력
if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")


SCRIPT_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPT_DIR / "config.yaml"
CLAUDE_CLI = shutil.which("claude") or "/usr/local/bin/claude"


def load_config() -> dict:
    """config.yaml 로드"""
    if not CONFIG_PATH.exists():
        print(f"[ERROR] 설정 파일 없음: {CONFIG_PATH}")
        sys.exit(1)
    with open(CONFIG_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


def get_schedule(config: dict, name: str) -> dict | None:
    """스킬명으로 스케줄 설정 조회"""
    for s in config.get("schedules", []):
        if s["name"] == name:
            return s
    return None


def run_skill(name: str) -> None:
    """스킬을 Claude CLI로 실행하고 결과를 로그에 저장"""
    config = load_config()
    schedule = get_schedule(config, name)

    if schedule is None:
        print(f"[ERROR] 스킬 '{name}'을 config.yaml에서 찾을 수 없습니다.")
        print(f"등록된 스킬: {[s['name'] for s in config.get('schedules', [])]}")
        sys.exit(1)

    settings = config.get("settings", {})

    if not schedule.get("enabled", True):
        print(f"[SKIP] '{name}' 비활성화 상태입니다.")
        return

    skip_holidays = settings.get("skip_holidays", True)
    if skip_holidays:
        today = datetime.now().date()
        kr_holidays = holidays.KR(years=today.year)
        if today in kr_holidays:
            print(f"[SKIP] 공휴일({kr_holidays[today]}) — '{name}' 실행하지 않음")
            return
    working_dir = settings.get("working_directory", "$HOME")
    log_dir = Path(settings.get("log_directory", SCRIPT_DIR / "logs"))
    # 스킬별 timeout 우선, 없으면 글로벌 기본값. 0이면 무제한.
    timeout_min = schedule.get("timeout_minutes", settings.get("max_execution_minutes", 10))

    log_dir.mkdir(parents=True, exist_ok=True)

    now = datetime.now()
    timestamp = now.strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{name}_{timestamp}.log"

    prompt = schedule["prompt"]
    cmd = [CLAUDE_CLI, "-p", prompt, "--output-format", "text", "--dangerously-skip-permissions"]

    print(f"[{now.strftime('%Y-%m-%d %H:%M:%S')}] 스킬 실행: {name}")
    print(f"  프롬프트: {prompt}")
    print(f"  로그: {log_file}")

    with open(log_file, "w", encoding="utf-8") as log:
        log.write(f"스킬: {name}\n")
        log.write(f"시작: {now.strftime('%Y-%m-%d %H:%M:%S')}\n")
        log.write(f"프롬프트: {prompt}\n")
        log.write(f"{'=' * 60}\n\n")

        try:
            env = os.environ.copy()
            env.pop("CLAUDECODE", None)  # 중첩 세션 방지 해제
            run_timeout = timeout_min * 60 if timeout_min > 0 else None
            result = subprocess.run(
                cmd,
                capture_output=True,
                cwd=working_dir,
                timeout=run_timeout,
                env=env,
            )

            stdout = result.stdout.decode("utf-8", errors="replace") if result.stdout else ""
            stderr = result.stderr.decode("utf-8", errors="replace") if result.stderr else ""
            log.write(stdout)
            if stderr:
                log.write(f"\n{'=' * 60}\n[STDERR]\n{stderr}")

            end_time = datetime.now()
            elapsed = (end_time - now).total_seconds()
            status = "성공" if result.returncode == 0 else f"실패 (코드: {result.returncode})"

            log.write(f"\n{'=' * 60}\n")
            log.write(f"종료: {end_time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            log.write(f"소요: {elapsed:.1f}초\n")
            log.write(f"상태: {status}\n")

            print(f"  상태: {status} ({elapsed:.1f}초)")

        except subprocess.TimeoutExpired:
            log.write(f"\n{'=' * 60}\n[TIMEOUT] {timeout_min}분 초과\n")
            print(f"  [TIMEOUT] {timeout_min}분 초과로 중단됨")

        except FileNotFoundError:
            msg = "claude CLI를 찾을 수 없습니다. PATH를 확인하세요."
            log.write(f"\n[ERROR] {msg}\n")
            print(f"  [ERROR] {msg}")

        except Exception as e:
            log.write(f"\n[ERROR] {e}\n")
            print(f"  [ERROR] {e}")


def list_skills() -> None:
    """등록된 스킬 목록 출력"""
    config = load_config()
    print("등록된 스케줄:")
    print(f"{'이름':<16} {'상태':<8} {'주기':<24} {'프롬프트'}")
    print("-" * 80)
    for s in config.get("schedules", []):
        status = "활성" if s.get("enabled", True) else "비활성"
        sched = s.get("schedule", {})
        stype = sched.get("type", "?")
        time = sched.get("time", "?")
        if stype == "weekly":
            days = ",".join(sched.get("days", []))
            period = f"{stype} {days} {time}"
        elif stype == "monthly":
            dom = ",".join(str(d) for d in sched.get("days_of_month", []))
            period = f"{stype} {dom}일 {time}"
        else:
            period = f"{stype} {time}"
        print(f"{s['name']:<16} {status:<8} {period:<24} {s['prompt'][:30]}...")


def cleanup_logs() -> None:
    """오래된 로그 파일 삭제"""
    config = load_config()
    settings = config.get("settings", {})
    log_dir = Path(settings.get("log_directory", SCRIPT_DIR / "logs"))
    retention = settings.get("log_retention_days", 30)
    cutoff = datetime.now() - timedelta(days=retention)

    if not log_dir.exists():
        print("로그 디렉토리가 없습니다.")
        return

    deleted = 0
    for f in log_dir.glob("*.log"):
        mtime = datetime.fromtimestamp(f.stat().st_mtime)
        if mtime < cutoff:
            f.unlink()
            deleted += 1

    print(f"로그 정리: {deleted}개 삭제 ({retention}일 이전)")


def main() -> None:
    if len(sys.argv) < 2:
        print("사용법:")
        print("  python runner.py <스킬명>         스킬 실행")
        print("  python runner.py --list            스킬 목록")
        print("  python runner.py --cleanup-logs    오래된 로그 삭제")
        sys.exit(1)

    arg = sys.argv[1]

    if arg == "--list":
        list_skills()
    elif arg == "--cleanup-logs":
        cleanup_logs()
    else:
        run_skill(arg)


if __name__ == "__main__":
    main()
