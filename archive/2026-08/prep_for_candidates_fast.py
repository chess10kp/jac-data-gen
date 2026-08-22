#!/usr/bin/env python3
"""FAST recovery prep: py2jac ONLY (no floor-guard jac test) -> work/<id>.json.

For recovering composer chunks whose candidates.jsonl survives but work/ was
purged. The expensive idiomize (cursor-agent) is already done; we only need
`floor_fn` + `test_blocks` (extracted from py2jac output, ~1s) to feed
agent_idiomize_guard, which runs its own `jac test` on the candidate anyway.

Skipping the floor-guard test here is safe for RECOVERY: the floor already
passed its guard in the original run (that's why it has a candidate). The guard
phase will still runtime-verify the candidate and fall back to floor on any
drift. Drops any record where py2jac itself fails.

Usage:
    .venv/bin/python scripts/prep_for_candidates_fast.py \
        --candidates data/chunks/chunk_9000/candidates.jsonl \
        --work-dir   data/chunks/chunk_9000/work --workers 8
"""
from __future__ import annotations
import argparse, json, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
import step4_full_loop as S  # noqa: E402


def fast_prep(record: dict) -> dict:
    rid = record["id"]
    out = {"id": rid, "entrypoint": record["entrypoint"],
           "coverage": record.get("coverage"), "stage": None}
    py_src = S.normalize_python(record["content"].rstrip() + "\n\n"
                                + "\n".join(record["tests"]) + "\n")
    with tempfile.TemporaryDirectory(prefix=f"fp_{rid}_") as tmp:
        tmpd = Path(tmp)
        (tmpd / f"{rid}.py").write_text(py_src)
        rc, o, e = S._run(["jac", "tool", "py2jac", str(tmpd / f"{rid}.py")], tmp)
        if rc != 0:
            out["stage"] = "py2jac_fail"; out["error"] = (e or o)[-160:]; return out
        floor_fn = S.split_floor_fn(o)
        test_blocks = S.with_entry_to_tests(o)[len(floor_fn):].strip()
    out.update(stage="floor_pass", python=record["content"],
               floor_fn=floor_fn, test_blocks=test_blocks)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()

    work = Path(args.work_dir)
    work.mkdir(parents=True, exist_ok=True)
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
    print(f"matched {len(todo)}/{len(need)}; FAST prepping (py2jac only) -> {work}", flush=True)

    tallies = {"floor_pass": 0, "py2jac_fail": 0}
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        for i, fut in enumerate(as_completed([ex.submit(fast_prep, r) for r in todo]), 1):
            r = fut.result(); tallies[r["stage"]] = tallies.get(r["stage"], 0) + 1
            if r["stage"] == "floor_pass":
                (work / f"{r['id']}.json").write_text(json.dumps(r))
            if i % 100 == 0:
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s {tallies}", flush=True)
    print(f"done in {time.perf_counter()-t0:.0f}s: {tallies}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
