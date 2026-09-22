#!/usr/bin/env python3
"""Probe nvidia/nemotron-3.5-lightning:free every 5 min; exit(0) when quota
returns so the operator gets pinged and launches the sweep. Gives up after 48h.
"""
import httpx
import sys
import time

sys.path.insert(0, "scripts/gen")
from osp_minimax_generate import _or_keys  # noqa: E402

DEADLINE = time.time() + 48 * 3600

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
        if r.status_code == 200:
            print(f"[watchdog] {now} QUOTA BACK", flush=True)
            sys.exit(0)
        print(f"[watchdog] {now} {r.status_code}", flush=True)
    except Exception as e:  # noqa: BLE001
        print(f"[watchdog] probe error: {e}", flush=True)
    time.sleep(300)
