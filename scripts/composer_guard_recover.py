#!/usr/bin/env python3
"""Memory-safe guard recovery: guard prepped work + composer candidates in small
sub-batches and APPEND new records to the master dataset.

Why this exists: scripts/agent_idiomize_guard.py loads ALL work records for a
chunk and runs jac check/test on them concurrently (12 workers). On ~1900-record
chunks that gets SIGKILL'd (rc=137 / OOM). This driver instead processes records
in sub-batches (default 100), guards each sub-batch, dedups within it, and
appends only records not already in master (by id) — so it is resume-safe and
bounds peak memory regardless of chunk size.

Reuses guard_one/enforce_bans from agent_idiomize_guard and dedup from
step4_full_loop, so the guard semantics are identical to the stock pipeline.

Usage:
    .venv/bin/python scripts/composer_guard_recover.py \
        --work-dir data/chunks/chunk_11000/work \
        --candidates data/chunks/chunk_11000/candidates.jsonl \
        --tag rec_11000 --sub-batch 100 --workers 8
"""
from __future__ import annotations
import argparse, gc, json, os, shutil, tempfile, time
from pathlib import Path
from collections import Counter

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import step4_full_loop as S  # noqa: E402
from agent_idiomize_guard import guard_one  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--master", default="data/composer_dataset.jsonl")
    ap.add_argument("--tag", required=True, help="chunk tag written into each record")
    ap.add_argument("--sub-batch", type=int, default=100)
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--dedup-threshold", type=float, default=0.9)
    ap.add_argument("--shared-tmp",
                    help="TMPDIR for embedded Postgres (default: $TMPDIR or fresh dir)")
    args = ap.parse_args()

    work_dir = Path(args.work_dir)
    cand = {}
    cpath = Path(args.candidates)
    if cpath.exists():
        for line in cpath.read_text().splitlines():
            if line.strip():
                d = json.loads(line); cand[d["id"]] = d.get("candidate")

    # master ids already present (skip-done across ALL chunks, not just this tag)
    master = Path(args.master)
    done: set[int] = set()
    if master.exists():
        for line in master.read_text().splitlines():
            if line.strip():
                done.add(json.loads(line)["id"])
    master_n0 = len(done)

    # work records for this chunk that are not yet in master
    works = []
    skipped_bad = 0
    for p in sorted(work_dir.glob("*.json")):
        try:
            txt = p.read_text()
            if not txt.strip():
                skipped_bad += 1; continue
            w = json.loads(txt)
        except (json.JSONDecodeError, ValueError):
            skipped_bad += 1; continue
        if not isinstance(w, dict) or w.get("id") in done:
            continue
        works.append(w)
    if skipped_bad:
        print(f"[{args.tag}] skipped {skipped_bad} corrupt/empty work file(s)", flush=True)
    works.sort(key=lambda w: w["id"])
    print(f"[{args.tag}] recovery start: master has {master_n0} records; "
          f"{len(works)} work / {len(works)} not-yet-done "
          f"(sub-batch={args.sub_batch} workers={args.workers})", flush=True)
    if not works:
        print(f"[{args.tag}] nothing to do — DONE", flush=True)
        return 0

    shared_tmp = args.shared_tmp or os.environ.get("TMPDIR")
    cleanup_tmp = False
    if not shared_tmp:
        shared_tmp = tempfile.mkdtemp(prefix="guard_shared_")
        cleanup_tmp = True
    os.makedirs(shared_tmp, exist_ok=True)
    print(f"[{args.tag}] shared_tmp={shared_tmp}", flush=True)

    # Atomic appends: open master O_APPEND and write each record with a single
    # os.write(). On Linux, O_APPEND makes each write() atomic w.r.t. other
    # O_APPEND writers, so CONCURRENT guard-recover runs (one per chunk, disjoint
    # id spaces) can safely append to the same master without interleaving lines.
    # This replaces the buffered fh.write that forced cross-run serialization.
    from concurrent.futures import ThreadPoolExecutor, as_completed
    fd = os.open(master, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o644)
    added_total, t0 = 0, time.perf_counter()
    try:
        for bi in range(0, len(works), args.sub_batch):
            sub = works[bi:bi + args.sub_batch]
            results = []
            with ThreadPoolExecutor(max_workers=args.workers) as ex:
                futs = {ex.submit(guard_one, w, cand.get(w["id"]), shared_tmp): w for w in sub}
                for fut in as_completed(futs):
                    results.append(fut.result())
            kept = [r for r in results if r.get("jac")]
            final, _ = S.dedup(kept, args.dedup_threshold)
            # append only records not already in master (dedup may overlap)
            nadd = 0
            for r in final:
                if r["id"] in done:
                    continue
                rec = {"id": r["id"], "entrypoint": r["entrypoint"],
                       "source": r["source"], "jac": r["jac"], "chunk": args.tag}
                os.write(fd, (json.dumps(rec) + "\n").encode())
                done.add(r["id"]); nadd += 1
            added_total += nadd
            split = Counter(r["source"] for r in final)
            print(f"  [{bi // args.sub_batch} {args.tag.replace('rec_', '')}] "
                  f"+{nadd} (split {dict(split)}) | added {added_total} | "
                  f"{int(time.perf_counter() - t0)}s | free", flush=True)
            gc.collect()
    finally:
        os.close(fd)
    print(f"[{args.tag}] done, +{added_total} this run "
          f"({int(time.perf_counter() - t0)}s)", flush=True)
    if cleanup_tmp:
        shutil.rmtree(shared_tmp, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
