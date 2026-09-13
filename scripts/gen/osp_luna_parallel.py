#!/usr/bin/env python3
"""N-way parallel driver for the gpt-5.6-luna idiomize wave.

Same task/flow/validation gates as `osp_generate.py --task idiomize
--flow jac-only --backend pi --model gpt-5.6-luna`, but runs records
concurrently (default 3-way — the luna/codex subscription fits 3-way,
starves past 6-way). Records are pulled from a shared queue; per-record
state is isolated (distinct stems -> distinct files under issue_gen/),
so the only shared mutation is appends to the jsonl ledgers, which are
single write() syscalls (atomic under O_APPEND).

Records already complete() are skipped at queue-build time, so the
driver is resumable: kill it, relaunch, it picks up where it left off.
conv-chaining is a no-op on the pi backend (--no-session never yields a
conversation id), so parallel workers lose nothing vs the sequential
chunk chain.

Queue policy (failure-history aware — wave 42-45 postmortem):
  - P1: stems with >= ATTEMPT_CAP rejections in the last WINDOW_S are
    BANKED, not enqueued; the rest sort fewest-fails-first (stable —
    fresh records run before burned ones).
  - P2: "stuck" stems (last two in-window rejections share the same
    error class — the fix loop is not converging) get a single
    repair-mode attempt per round instead of the full PHASE_TRIES
    budget, sort last, and bank early (>= ATTEMPT_CAP - 2).
  - P3: fix rounds for records with >= REPAIR_AFTER prior rejections
    use prompt_repair() (previous candidate + error inline) instead of
    error-informed rerolls — see osp_agent_generate.py.

Usage:
  python scripts/gen/osp_luna_parallel.py [--batches 42,43,44,45] [--workers 3]
      [--dry-run]   # build + print the queue, no LLM calls
"""
from __future__ import annotations

import argparse
import json
import multiprocessing as mp
import os
import queue
import re
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
sys.path.insert(0, str(REPO / "scripts" / "gen"))

MODEL = "gpt-5.6-luna"
FAILURES = REPO / "data" / "osp_lifts" / "_gen_failures.jsonl"
WINDOW_S = 24 * 3600  # rejection history window (lifetime counts span waves
                      # and would bank stems that later recovered)
ATTEMPT_CAP = 8       # in-window rejections before a stem is banked
                      # (every stem that ever landed: <= 7; doomed: >= 9)


def _patch_worker() -> None:
    import osp_agent_generate as gen
    os.environ["CURSOR_OSP_BACKEND"] = "pi"
    os.environ["OSP_BACKEND"] = "pi"
    for var in ("CURSOR_OSP_MODEL", "CURSOR_OSP_MODEL_PY",
                "CURSOR_OSP_MODEL_GUARD", "CURSOR_OSP_MODEL_PYGEN"):
        os.environ[var] = MODEL
    gen.MODEL = gen.MODEL_PY = gen.MODEL_GUARD = gen.MODEL_PYGEN = MODEL


def error_class(err: str) -> str:
    """Coarse error fingerprint for stuck detection: the first jac error
    code if present, else a normalized message prefix."""
    m = re.search(r"error\[([A-Z]+\d+)\]", err)
    if m:
        return m.group(1)
    m = re.search(r"\b([EW]\d{4})\b", err)
    if m:
        return m.group(1)
    return re.sub(r"\s+", " ", (err or "?"))[:80]


def ledger_state() -> tuple[dict[str, int], set[str]]:
    """(in-window rejection counts per stem, set of stuck stems — last two
    rejections share an error class, i.e. the fix loop is not converging).
    Windowed to the last WINDOW_S: lifetime counts span waves and would
    bank stems that recovered after many old failures."""
    cutoff = time.time() - WINDOW_S
    counts: dict[str, int] = {}
    classes: dict[str, list[str]] = {}
    if FAILURES.exists():
        for line in FAILURES.read_text().splitlines():
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            s = row.get("stem")
            if not s or row.get("ts", 0) < cutoff:
                continue
            counts[s] = counts.get(s, 0) + 1
            classes.setdefault(s, []).append(error_class(str(row.get("error", ""))))
    stuck = {s for s, cl in classes.items() if len(cl) >= 2 and cl[-1] == cl[-2]}
    return counts, stuck


def _jac_only_pending(gen, rec: dict) -> bool:
    """complete() requires a .py sibling — always False for jac-only records.
    The real oracle is: jac + guard exist AND jac_validate passes."""
    stem = gen.stem_for(rec["repo"], rec["issue"])
    jac, guard = gen.IG / f"{stem}.jac", gen.IG / f"{stem}_guard.jac"
    if not (jac.exists() and guard.exists()):
        return True
    return not gen.jac_validate(stem)[0]


def worker(wid: int, q: "mp.Queue[tuple]") -> None:
    import osp_agent_generate as gen
    _patch_worker()
    spec = gen.load_spec_excerpt()
    while True:
        try:
            rec, tries = q.get_nowait()
        except queue.Empty:
            return
        stem = gen.stem_for(rec["repo"], rec["issue"])
        t0 = time.time()
        try:
            ok, _ = gen.generate_record(rec, None, spec, force=False,
                                        flow="jac-only", phase_tries=tries)
        except Exception as e:  # never let one record kill a worker
            print(f"[w{wid}] {stem}: EXCEPTION {type(e).__name__}: {e}",
                  flush=True)
            ok = False
        dt = time.time() - t0
        print(f"[w{wid}] {stem}: {'OK' if ok else 'FAIL'} ({dt:.0f}s)",
              flush=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batches", default="42,43,44,45")
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--dry-run", action="store_true",
                    help="build and print the queue, then exit (no LLM calls)")
    args = ap.parse_args()

    import osp_agent_generate as gen
    _patch_worker()

    from concurrent.futures import ThreadPoolExecutor
    cands: list[dict] = []
    for b in (int(x) for x in args.batches.split(",")):
        cands.extend(gen.load_batch(b))
    with ThreadPoolExecutor(8) as ex:
        pendings = list(ex.map(lambda r: _jac_only_pending(gen, r), cands))
    todo = [r for r, p in zip(cands, pendings) if p]

    # P1/P2: failure-history-aware queue
    counts, stuck = ledger_state()
    def pfail(r: dict) -> int:
        return counts.get(gen.stem_for(r["repo"], r["issue"]), 0)
    def pstuck(r: dict) -> bool:
        return gen.stem_for(r["repo"], r["issue"]) in stuck

    banked = [r for r in todo
              if pfail(r) >= ATTEMPT_CAP or (pstuck(r) and pfail(r) >= ATTEMPT_CAP - 2)]
    if banked:
        bnames = sorted(gen.stem_for(r["repo"], r["issue"]) for r in banked)
        print(f"banking {len(banked)} (>= {ATTEMPT_CAP} rejections, or stuck "
              f"and close): {', '.join(bnames)}", flush=True)
    bset = {gen.stem_for(r["repo"], r["issue"]) for r in banked}
    todo = [r for r in todo
            if gen.stem_for(r["repo"], r["issue"]) not in bset]
    todo.sort(key=lambda r: (pstuck(r), pfail(r)))  # stable: fresh, then
    # retried, then stuck; within a tier, original batch order

    fresh = sum(1 for r in todo if pfail(r) == 0)
    stuck_n = sum(1 for r in todo if pstuck(r))
    print(f"{len(cands)} candidates, {len(todo)} pending "
          f"({fresh} fresh, {len(todo) - fresh} retry, {stuck_n} stuck), "
          f"{len(banked)} banked, {args.workers} workers", flush=True)
    if args.dry_run or not todo:
        return 0

    q: "mp.Queue[tuple]" = mp.Queue()
    for r in todo:
        q.put((r, 1 if pstuck(r) else None))  # stuck: single repair attempt
    t0 = time.time()
    procs = [mp.Process(target=worker, args=(i, q)) for i in range(args.workers)]
    for p in procs:
        p.start()
    for p in procs:
        p.join()
    print(f"ALL DONE: {len(todo)} records, {args.workers} workers, "
          f"{time.time() - t0:.0f}s wall", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
