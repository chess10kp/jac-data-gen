#!/usr/bin/env python3
"""Probe muse-spark free-tier quota; on first 200, resume generation via zen.

Polls the opencode zen gateway every --interval seconds with a 16-token call.
On success, execs function_eval_generate.py with --backend zen (8-key
round-robin) so the main run resumes automatically. Gives up after --max-hours.

Usage (background):
  nohup python scripts/gen/function_eval_resume_watchdog.py \
      --workers 6 > runs/function_eval/muse-spark-n8/watchdog.log 2>&1 &
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import time
import uuid
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))

import httpx  # noqa: E402
from llm_backend import ZEN_BASE, _opencode_keys  # noqa: E402

MODEL = "muse-spark-1.2-contributor-free"


def probe() -> tuple[bool, str]:
    keys = _opencode_keys()
    H = {"Authorization": f"Bearer {keys[0]}", "Content-Type": "application/json",
         "User-Agent": "opencode/1.0.83", "x-opencode-session-id": str(uuid.uuid4())}
    try:
        r = httpx.post(f"{ZEN_BASE}/chat/completions", headers=H, timeout=60,
                       json={"model": MODEL, "max_tokens": 16,
                             "messages": [{"role": "user", "content": "say pong"}]})
    except Exception as e:
        return False, f"{type(e).__name__}: {e}"
    if r.status_code == 200:
        return True, "quota available"
    return False, f"{r.status_code}: {r.text[:80]}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--interval", type=int, default=1200, help="probe every N sec [1200]")
    ap.add_argument("--max-hours", type=float, default=24.0)
    ap.add_argument("--workers", type=int, default=6)
    args = ap.parse_args()

    deadline = time.time() + args.max_hours * 3600
    attempt = 0
    while time.time() < deadline:
        attempt += 1
        ok, msg = probe()
        print(f"[{datetime.now():%H:%M:%S}] probe#{attempt}: {msg}", flush=True)
        if ok:
            print("[watchdog] quota reset — resuming generation via zen backend", flush=True)
            cmd = [sys.executable, str(REPO / "scripts" / "gen" / "function_eval_generate.py"),
                   "--backend", "zen", "--model", MODEL,
                   "--samples", "8", "--workers", str(args.workers),
                   "--out-dir", str(REPO / "runs" / "function_eval" / "muse-spark-n8")]
            return subprocess.call(cmd)
        time.sleep(args.interval)
    print("[watchdog] gave up after max-hours", flush=True)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
