#!/usr/bin/env python3
"""Phase 1 of the agent-idiomize path: prepare work records for Sonnet subagents.

For each MultiPL-T record (coverage >= --min-coverage): py2jac -> floor guard.
Emits one JSON per surviving record to data/step4/agent_work/<id>.json holding
everything a subagent needs to idiomize it (python, floor_fn, entrypoint) plus
what the guard phase needs (test_blocks). py2jac/test failures are dropped and
tallied. This is deterministic and cheap (~2 rec/s); no model calls here.
"""
from __future__ import annotations
import argparse, json, os, shutil, sys, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "lib"))
import step4_full_loop as S
from idiomize_seam import build_prompt

WORK = S.OUT_DIR / "agent_work"


def prep_one(record: dict, shared_tmp: str) -> dict:
    try:
        return _prep_one(record, shared_tmp)
    except Exception as e:  # noqa: BLE001  (py2jac/test hang or crash -> drop record)
        return {"id": record.get("id"), "entrypoint": record.get("entrypoint"),
                "coverage": record.get("coverage"), "stage": "prep_error",
                "error": f"{type(e).__name__}: {str(e)[:120]}"}


def _prep_one(record: dict, shared_tmp: str) -> dict:
    rid = record["id"]
    out = {"id": rid, "entrypoint": record["entrypoint"],
           "coverage": record.get("coverage"), "stage": None}
    py_src = S.normalize_python(record["content"].rstrip() + "\n\n"
                                + "\n".join(record["tests"]) + "\n")
    # Per-record subdir under ONE shared TMPDIR -> one embedded Postgres for all
    # workers (initdb ~80s once; jac test drops to ~7-12s vs ~40s+ per worker PG).
    tmpd = Path(tempfile.mkdtemp(prefix=f"prep_{rid}_", dir=shared_tmp))
    env = {**os.environ, "TMPDIR": shared_tmp}
    try:
        (tmpd / f"{rid}.py").write_text(py_src)
        rc, o, e = S._run(["jac", "tool", "py2jac", str(tmpd / f"{rid}.py")],
                          str(tmpd), env=env)
        if rc != 0:
            out["stage"] = "py2jac_fail"; out["error"] = (e or o)[-200:]; return out
        floor_jac = o
        guard = tmpd / f"{rid}.jac"; guard.write_text(S.with_entry_to_tests(floor_jac))
        rc2, o2, e2 = S._run(["jac", "test", str(guard)], str(tmpd), env=env)
        if rc2 != 0:
            out["stage"] = "test_fail"; out["error"] = (e2 or o2)[-200:]; return out
        floor_fn = S.split_floor_fn(floor_jac)
        test_blocks = S.with_entry_to_tests(floor_jac)[len(floor_fn):].strip()
        out.update(stage="floor_pass", python=record["content"], floor_fn=floor_fn,
                   test_blocks=test_blocks,
                   prompt=build_prompt(floor_fn, record["content"], record["entrypoint"]))
    finally:
        shutil.rmtree(tmpd, ignore_errors=True)
    return out


def main() -> int:
    global WORK
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=1000)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--min-coverage", type=int, default=90)
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--work-dir", default=str(WORK))
    ap.add_argument("--shared-tmp",
                    help="TMPDIR for embedded Postgres (default: $TMPDIR or fresh dir)")
    args = ap.parse_args()

    WORK = Path(args.work_dir)
    WORK.mkdir(parents=True, exist_ok=True)
    from datasets import load_dataset
    ds = load_dataset(S.DATASET, split="train")
    todo, seen = [], 0
    for rec in ds:
        cov = rec.get("coverage")
        if cov is None or cov < args.min_coverage:
            continue
        seen += 1
        if seen <= args.offset:
            continue
        if len(todo) >= args.limit:
            break
        todo.append(rec)

    shared_tmp = args.shared_tmp or os.environ.get("TMPDIR")
    cleanup_tmp = False
    if not shared_tmp:
        shared_tmp = tempfile.mkdtemp(prefix="prep_shared_")
        cleanup_tmp = True
    os.makedirs(shared_tmp, exist_ok=True)
    print(f"prep {len(todo)} records -> {WORK} | shared_tmp={shared_tmp}", flush=True)
    tallies = {"floor_pass": 0, "py2jac_fail": 0, "test_fail": 0}
    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        for i, fut in enumerate(
                as_completed([ex.submit(prep_one, r, shared_tmp) for r in todo]), 1):
            r = fut.result()
            tallies[r["stage"]] = tallies.get(r["stage"], 0) + 1
            if r["stage"] == "floor_pass":
                (WORK / f"{r['id']}.json").write_text(json.dumps(r))
            if i % 100 == 0:
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s {tallies}", flush=True)
    print(f"done in {time.perf_counter()-t0:.0f}s: {tallies}", flush=True)
    if cleanup_tmp:
        shutil.rmtree(shared_tmp, ignore_errors=True)
    (S.OUT_DIR / "agent_prep_manifest.json").write_text(json.dumps(
        {"requested": len(todo), "tallies": tallies}, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
