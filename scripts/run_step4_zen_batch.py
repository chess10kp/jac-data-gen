#!/usr/bin/env python3
"""Non-invasive driver: run step4_full_loop in zen mode into a SEPARATE out dir.

Why: step4_full_loop.py hardcodes OUT_DIR = data/step4 and OVERWRITES
dataset.jsonl/full_results.jsonl/manifest.json there. To continue the @data/
method on a fresh slice WITHOUT clobbering prior batches, we rebind the module
global OUT_DIR before calling main(). main() resolves OUT_DIR at call time from
the module namespace, so the override takes effect.

Usage:
    .venv/bin/python scripts/run_step4_zen_batch.py \
        --out data/step4_zen_b --offset 2000 --limit 40 --k 5 --workers 8

All args after the driver flags are forwarded to step4_full_loop.main().
"""
from __future__ import annotations
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import step4_full_loop as S  # noqa: E402

# --out and --offset-in-dir are consumed here; the rest forwards to main().
if "--out" in sys.argv:
    i = sys.argv.index("--out")
    out = Path(sys.argv[i + 1])
    del sys.argv[i:i + 2]
else:
    out = Path("data/step4_zen_b")

S.OUT_DIR = out
S.OUT_DIR.mkdir(parents=True, exist_ok=True)
print(f"[run_step4_zen_batch] OUT_DIR -> {S.OUT_DIR}", flush=True)
sys.exit(S.main())
