#!/usr/bin/env python3
"""Emit the test-verified gold slice of data/osp_dataset.jsonl.

Read-only join: dataset rows for which ANY verdict row in
data/osp_test_results.jsonl is PASS (fields from the latest PASS row,
including the generated `tests` annex merged in as `jac_tests`).
Any-run-PASS is deliberate: a record that passed one testgen run stays gold
even if a later run's tests fail (tests disagree, code does not change).
This intentionally diverges from ops/merge_osp_tests.py last-wins.

Re-run as more verdicts land; output is a fresh point-in-time snapshot.

Usage: python3 scripts/gen/pack_tested_pass.py [--out data/osp_dataset_pass.jsonl]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATASET = REPO / "data" / "osp_dataset.jsonl"
RESULTS = REPO / "data" / "osp_test_results.jsonl"
OUT = REPO / "data" / "osp_dataset_pass.jsonl"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()

    latest: dict[str, dict] = {}
    passed: dict[str, dict] = {}  # latest PASS row per id
    with RESULTS.open() as fh:
        for line in fh:
            if line.strip():
                r = json.loads(line)
                latest[r["id"]] = r  # last row per id wins
                if r.get("verdict") == "PASS":
                    passed[r["id"]] = r

    kept = skipped = 0
    out = Path(args.out)
    tmp = out.with_suffix(".jsonl.pack_tmp")
    with DATASET.open() as fh, tmp.open("w") as dst:
        for line in fh:
            if not line.strip():
                continue
            r = json.loads(line)
            res = passed.get(r["id"])
            if res is None:
                skipped += 1
                continue
            r["test_pass"] = True
            r["test_verdict"] = res.get("verdict")
            r["test_detail"] = (res.get("detail") or "")[:300]
            r["test_run_tag"] = res.get("run_tag")
            if res.get("tests"):
                r["jac_tests"] = res["tests"]
            dst.write(json.dumps(r) + "\n")
            kept += 1
    tmp.replace(out)
    print(f"kept {kept} PASS records -> {out} "
          f"(skipped {skipped}: {len(latest)} verdicts seen, "
          f"{len(passed)} ids with a PASS row)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
