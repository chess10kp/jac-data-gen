#!/usr/bin/env python3
"""Re-guard the PAID composer-2.5 floorfix candidates — PG-race-free layout.

Root cause of the historical 0%-flip runs: N concurrent `jac test` processes
sharing ONE TMPDIR race the embedded-postgres lifecycle (boot/stop fights ->
"unreachable despite a live pidfile" -> collection/lowering rejects that are
pure infrastructure artifacts). Fix: one worker PROCESS per dedicated TMPDIR,
records processed sequentially inside each worker -> each worker owns exactly
one PG; no cross-process sharing, ever.

Flow: spawn W workers (multiprocessing), each takes ids round-robin (id % W),
guards them with guard_one(shared_tmp=<own dir>), appends results (flock'd
jsonl_io.append). Resume-safe on results ids. Merge flips afterwards.

Usage:
  .venv/bin/python scripts/reguard_paid.py --phase guard --workers 12
  .venv/bin/python scripts/reguard_paid.py --phase merge
"""
from __future__ import annotations
import argparse, json, multiprocessing as mp
import os, sys, time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "scripts"))
os.environ.setdefault("JAC_PROC_TIMEOUT", "300")
os.environ.setdefault("HF_HUB_OFFLINE", "1")

import jsonl_io  # noqa: E402

CAND = REPO / "data/floorfix/composer_candidates.jsonl"
WORK = REPO / "data/floorfix/work"
RESULTS = REPO / "data/floorfix/reguard_paid_results.jsonl"
MASTER = REPO / "data/composer_dataset.jsonl"
EXPORT = REPO / "data/py2jac_dataset_idiomatic.jsonl"
TMP_BASE = "/tmp/floorfix_reguard_pg"


def master_floor_ids() -> set[int]:
    out = set()
    for ln in open(MASTER):
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        if r.get("source") == "floor":
            out.add(r["id"])
    return out


def done_ids() -> set[int]:
    out: set[int] = set()
    if RESULTS.exists():
        for ln in RESULTS.read_text().splitlines():
            try:
                out.add(json.loads(ln)["id"])
            except Exception:  # noqa: BLE001
                continue
    return out


def worker(w: int, nworkers: int) -> int:
    """One process, sequential records. TMPDIR MUST be /tmp for all workers:
    the shared embedded PG at ~/.cache/jac/pg/main exposes its socket at
    $TMPDIR/jacpg-<digest>; any other TMPDIR makes jac think PG is wedged
    ('unreachable despite a live pidfile') -> pg_ctl restart fails -> every
    test rejects. That bug zeroed BOTH the paid run and re-guard attempt 1."""
    from agent_idiomize_guard import guard_one  # import AFTER fork, per proc
    own_tmp = "/tmp"
    os.makedirs(own_tmp, exist_ok=True)
    os.environ["TMPDIR"] = own_tmp  # socket dir of the live shared PG

    floors = master_floor_ids()
    cands: dict[int, str] = {}
    for ln in open(CAND):
        ln = ln.strip()
        if not ln:
            continue
        try:
            d = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        if d.get("candidate"):
            rid = int(d["id"])
            if rid in floors and (WORK / f"{rid}.json").exists():
                cands[rid] = d["candidate"]
    done = done_ids()
    todo = sorted(i for i in cands if i % nworkers == w and i not in done)
    flips = 0
    t0 = time.time()
    for n, rid in enumerate(todo, 1):
        wk = json.loads((WORK / f"{rid}.json").read_text())
        r = guard_one(wk, cands[rid], shared_tmp=own_tmp)
        jsonl_io.append(RESULTS, r)
        if r.get("source") == "idiomatic":
            flips += 1
        if n % 10 == 0:
            print(f"  [w{w}] {n}/{len(todo)} flips={flips} "
                  f"{(time.time()-t0)/n:.0f}s/rec", flush=True)
    print(f"[w{w}] done {len(todo)} flips={flips} in {(time.time()-t0)/60:.0f}m",
          flush=True)
    return flips


def phase_guard(args) -> int:
    floors = master_floor_ids()
    n_cand = 0
    for ln in open(CAND):
        ln = ln.strip()
        if ln:
            try:
                d = json.loads(ln)
            except Exception:  # noqa: BLE001
                continue
            if d.get("candidate") and int(d["id"]) in floors:
                n_cand += 1
    print(f"[reguard-paid] floors={len(floors)} paid-cands={n_cand} "
          f"todo~{n_cand - len(done_ids())} workers={args.workers}", flush=True)
    ctx = mp.get_context("spawn")
    with ctx.Pool(args.workers) as pool:
        results = pool.starmap(worker, [(w, args.workers) for w in range(args.workers)])
    print(f"[reguard-paid] ALL DONE total_flips={sum(results)}", flush=True)
    return 0


def phase_merge(_args) -> int:
    flips = {}
    for ln in RESULTS.read_text().splitlines():
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        if r.get("source") == "idiomatic" and r.get("jac"):
            flips[r["id"]] = r["jac"]
    floors = master_floor_ids()
    applicable = {i: j for i, j in flips.items() if i in floors}
    print(f"[merge] flips={len(flips)} applicable-to-current-floors={len(applicable)}")

    rows, changed = [], 0
    for ln in open(MASTER):
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE001
            rows.append(ln.rstrip("\n"))
            continue
        if r.get("id") in applicable:
            r["jac"] = applicable[r["id"]]
            r["source"] = "idiomatic"
            changed += 1
        rows.append(json.dumps(r))
    jsonl_io.atomic_write(MASTER, rows)

    out = []
    for ln in open(MASTER):
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        if r.get("source") == "idiomatic":
            out.append(json.dumps({"id": r["id"], "jac": r["jac"],
                                   "entrypoint": r["entrypoint"], "source": "idiomatic"}))
    jsonl_io.atomic_write(EXPORT, out)
    print(f"[merge] master rewritten: +{changed} idiomatic -> {len(out)}/{sum(1 for _ in open(MASTER))}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", choices=["guard", "merge"], default="guard")
    ap.add_argument("--workers", type=int, default=12)
    args = ap.parse_args()
    return phase_guard(args) if args.phase == "guard" else phase_merge(args)


if __name__ == "__main__":
    sys.exit(main())
