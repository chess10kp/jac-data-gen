#!/usr/bin/env python3
"""Kill the 8-shard nemotron sweep when the free-model daily budget dries up.

Probes every 5 min; 2 consecutive 429s -> pkill fleet -> exit(0) so the
operator gets pinged. Exits silently if the fleet is gone and quota is OK
(work finished) — check sweep logs before re-arming.
"""
import httpx
import subprocess
import sys
import time

sys.path.insert(0, "scripts/gen")
from osp_minimax_generate import _or_keys  # noqa: E402

DEADLINE = time.time() + 48 * 3600
fails = 0

while time.time() < DEADLINE:
    try:
        r = httpx.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={"Authorization": f"Bearer {_or_keys()[0]}"},
            json={"model": "nvidia/nemotron-3.5-lightning:free",
                  "messages": [{"role": "user", "content": "hi"}],
                  "max_tokens": 1},
            timeout=30,
        )
        now = time.strftime("%H:%M:%S")
        if r.status_code == 429:
            fails += 1
            print(f"[killer] {now} 429 streak {fails}", flush=True)
            if fails >= 2:
                print(f"[killer] {now} budget dry, killing fleet", flush=True)
                subprocess.run(["pkill", "-f", "osp_minimax_testgen.*--shards 8"])
                sys.exit(0)
        else:
            fails = 0
            live = subprocess.run(
                ["pgrep", "-fc", "osp_minimax_testgen.*--shards 8"],
                capture_output=True, text=True).stdout.strip()
            if live == "0":
                print(f"[killer] {now} fleet finished with quota to spare", flush=True)
                sys.exit(0)
    except Exception as e:  # noqa: BLE001
        print(f"[killer] probe error: {e}", flush=True)
    time.sleep(300)
