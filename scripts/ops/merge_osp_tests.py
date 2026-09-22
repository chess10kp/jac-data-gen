#!/usr/bin/env python3
"""Fold test results from data/osp_test_results.jsonl into the dataset's
`test_pass` field.

Safety: refuses to run while osp_minimax_generate / osp_minimax_testgen
shards are alive — they append to the dataset concurrently and a rewrite
mid-append could drop rows. Idempotent: safe to re-run as more results land.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATASET = REPO / "data" / "osp_dataset.jsonl"
RESULTS = REPO / "data" / "osp_test_results.jsonl"


def fleet_alive() -> bool:
    out = subprocess.run(
        ["pgrep", "-af", "osp_minimax_(testgen|generate).py"],
        capture_output=True, text=True)
    return bool(out.stdout.strip())


def main() -> int:
    if fleet_alive():
        print("refusing: generation shards still running (pgrep hit); "
              "retry after fleets exit", file=sys.stderr)
        return 2
    if not RESULTS.exists():
        print("no results sidecar yet", file=sys.stderr)
        return 2

    latest: dict[str, dict] = {}
    for line in RESULTS.read_text().splitlines():
        if line.strip():
            r = json.loads(line)
            latest[r["id"]] = r  # last row per id wins

    rows = [json.loads(l) for l in DATASET.read_text().splitlines() if l.strip()]
    matched = tested = 0
    for r in rows:
        res = latest.get(r["id"])
        if res is None:
            continue
        matched += 1
        if r.get("test_pass") == res.get("test_pass") and \
                r.get("test_verdict") == res.get("verdict"):
            continue  # already folded
        r["test_pass"] = res.get("test_pass")
        r["test_verdict"] = res.get("verdict")
        r["test_detail"] = (res.get("detail") or "")[:300]
        r["test_run_tag"] = res.get("run_tag")
        tested += 1

    tmp = DATASET.with_suffix(".jsonl.merge_tmp")
    with tmp.open("w") as fh:
        for r in rows:
            fh.write(json.dumps(r) + "\n")
    tmp.replace(DATASET)
    print(f"dataset={len(rows)} rows, results={len(latest)}, matched={matched}, "
          f"newly_folded={tested}, "
          f"test_pass_true={sum(1 for r in rows if r.get('test_pass') is True)}, "
          f"test_pass_false={sum(1 for r in rows if r.get('test_pass') is False)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
