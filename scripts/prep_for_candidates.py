#!/usr/bin/env python3
"""Targeted prep: regenerate work/<id>.json ONLY for ids present in a candidates file.

Recovery tool for composer chunks whose work/ was purged by the grinder but
whose candidates.jsonl survives. Re-running agent_idiomize_prep.py on the whole
slice is slow (~65% of records fail the floor guard, each burning a 120s jac-test
timeout); this scans the dataset once and preps only the ids we actually have
candidates for, so guarding the existing (already-paid-for) candidates is fast.

Usage:
    .venv/bin/python scripts/prep_for_candidates.py \
        --candidates data/chunks/chunk_9000/candidates.jsonl \
        --work-dir   data/chunks/chunk_9000/work --workers 8
"""
from __future__ import annotations
import argparse, json, sys, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
import step4_full_loop as S  # noqa: E402
from agent_idiomize_prep import prep_one  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()

    work = Path(args.work_dir)
    work.mkdir(parents=True, exist_ok=True)

    # ids we need work for (drop any already prepped on disk -> resume-safe)
    need = set()
    for line in Path(args.candidates).read_text().splitlines():
        if line.strip():
            need.add(json.loads(line)["id"])
    already = {int(p.stem) for p in work.glob("*.json")}
    need -= already
    print(f"need work for {len(need)} ids ({len(already)} already on disk)", flush=True)
    if not need:
        return 0

    from datasets import load_dataset
    ds = load_dataset(S.DATASET, split="train")
    todo = [r for r in ds if r["id"] in need]
    print(f"matched {len(todo)}/{len(need)} ids in dataset; prepping -> {work}", flush=True)

    tallies = {"floor_pass": 0, "py2jac_fail": 0, "test_fail": 0, "prep_error": 0}
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        for i, fut in enumerate(as_completed([ex.submit(prep_one, r) for r in todo]), 1):
            r = fut.result()
            tallies[r["stage"]] = tallies.get(r["stage"], 0) + 1
            if r["stage"] == "floor_pass":
                (work / f"{r['id']}.json").write_text(json.dumps(r))
            if i % 50 == 0:
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s {tallies}", flush=True)
    print(f"done in {time.perf_counter()-t0:.0f}s: {tallies}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
