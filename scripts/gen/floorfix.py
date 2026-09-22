#!/usr/bin/env python3
"""Convert the remaining source=floor rows of the master to idiomatic.

The finish_to_15k grind banked mechanical py2jac floors (never idiomatized) and
guard fallbacks with dead candidates (reguard flipped 0/466). This driver gives
every floor row a FRESH idiomize attempt on the free zen gateway, then guards
with the stock oracle (guard_one from agent_idiomize_guard: jac check -> hidden
tests -> keep-or-floor) and merges flips back into the master.

Phases (all resume-safe, run in order):
  prep      rebuild work records (python/floor_fn/test_blocks) for master floor
            ids from the cached MultiPL-T dataset. py2jac only — NO floor jac
            test (floors are already banked; broken rec_repair test translations
            are harmless: only the CANDIDATE is tested, never the floor).
  generate  one zen_idiomize call per work record -> archive/2026-09/scratch/floorfix/candidates.jsonl
            (candidate may be null on gateway failure; --retry-empty redoes nulls)
  guard     guard_one per candidate -> archive/2026-09/scratch/floorfix/results.jsonl
            shard with --shard/--shards + --shared-tmp (one PG per shard)
  merge     rewrite master rows floor->idiomatic for guard passers (atomic,
            .bak kept) and regenerate data/py2jac_dataset_idiomatic.jsonl
  status    counts everywhere

Usage:
  .venv/bin/python scripts/floorfix.py --phase prep --workers 8
  .venv/bin/python scripts/floorfix.py --phase generate --workers 10
  .venv/bin/python scripts/floorfix.py --phase generate --retry-empty --model mimo-v2.5-free
  .venv/bin/python scripts/floorfix.py --phase guard --shard 0 --shards 4 --workers 4 --shared-tmp /tmp/floorfix_pg_0
  .venv/bin/python scripts/floorfix.py --phase merge
"""
from __future__ import annotations
import argparse, json, os, sys, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = Path(__file__).resolve().parents[2]
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))

import jsonl_io  # noqa: E402
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("JAC_PROC_TIMEOUT", "300")

from step4_full_loop import _run, split_floor_fn, DATASET, OUT_DIR  # noqa: E402
from step2_translate_tests import normalize_python, with_entry_to_tests  # noqa: E402
from idiomize_seam import zen_idiomize  # noqa: E402

MASTER = REPO / "data/composer_dataset.jsonl"
EXPORT = REPO / "data/py2jac_dataset_idiomatic.jsonl"
DIR = REPO / "archive/2026-09/scratch/floorfix"
WORK = DIR / "work"
CAND = DIR / "candidates.jsonl"
RESULTS = DIR / "results.jsonl"


def load_master_floors() -> dict[int, dict]:
    floors = {}
    for ln in open(MASTER):
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        if r.get("source") == "floor":
            floors[r["id"]] = r
    return floors


def floor_ids_sorted() -> list[int]:
    return sorted(load_master_floors())


def append_jsonl(path: Path, obj: dict) -> None:
    # fsync'd locked append (jsonl_io) — power-loss durable
    jsonl_io.append(path, obj)


def ids_in(path: Path) -> set[int]:
    out: set[int] = set()
    if not path.exists():
        return out
    for ln in path.read_text().splitlines():
        try:
            out.add(json.loads(ln)["id"])
        except Exception:  # noqa: BLE001
            continue
    return out


def latest_candidates() -> dict[int, dict]:
    """id -> latest candidate line (later lines win)."""
    out: dict[int, dict] = {}
    if not CAND.exists():
        return out
    for ln in CAND.read_text().splitlines():
        try:
            d = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        out[d["id"]] = d
    return out


# ------------------------------------------------------------------ prep ---- #
def phase_prep(args) -> int:
    WORK.mkdir(parents=True, exist_ok=True)
    floors = load_master_floors()
    todo_ids = sorted(floors)
    if args.shards > 1:
        todo_ids = [i for i in todo_ids if i % args.shards == args.shard]
    already = {int(p.stem) for p in WORK.glob("*.json")}
    todo_ids = [i for i in todo_ids if i not in already]
    print(f"[prep] floors={len(floors)} todo={len(todo_ids)} (skip {len(already)} done)", flush=True)
    if not todo_ids:
        return 0

    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")
    by_id = {r["id"]: r for r in ds if r["id"] in floors}
    print(f"[prep] dataset records matched: {len(by_id)}", flush=True)

    shared_tmp = args.shared_tmp or os.environ.get("TMPDIR") or "/tmp"
    os.makedirs(shared_tmp, exist_ok=True)
    stats = {"ok": 0, "py2jac_fail": 0, "no_record": 0, "floor_mismatch": 0}

    def one(rid: int) -> None:
        rec = by_id.get(rid)
        if rec is None:
            stats["no_record"] += 1
            return
        tmpd = Path(tempfile.mkdtemp(prefix=f"ff_{rid}_", dir=shared_tmp))
        try:
            py_src = normalize_python(rec["content"].rstrip() + "\n\n"
                                      + "\n".join(rec["tests"]) + "\n")
            (tmpd / f"{rid}.py").write_text(py_src)
            env = {**os.environ, "TMPDIR": shared_tmp}
            rc, o, e = _run(["jac", "tool", "py2jac", str(tmpd / f"{rid}.py")], str(tmpd), env=env)
            if rc != 0:
                stats["py2jac_fail"] += 1
                return
            floor = o
            floor_fn = split_floor_fn(floor)
            if floor_fn.strip() != (floors[rid].get("jac") or "").strip():
                stats["floor_mismatch"] += 1
            test_blocks = with_entry_to_tests(floor)[len(floor_fn):].strip()
            (WORK / f"{rid}.json").write_text(json.dumps({
                "id": rid, "entrypoint": rec["entrypoint"],
                "python": rec["content"], "floor_fn": floor_fn,
                "test_blocks": test_blocks}))
            stats["ok"] += 1
        finally:
            import shutil
            shutil.rmtree(tmpd, ignore_errors=True)

    t0 = time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(one, i) for i in todo_ids]
        for n, _ in enumerate(as_completed(futs), 1):
            if n % 200 == 0:
                print(f"  [{n}/{len(todo_ids)}] {time.perf_counter()-t0:.0f}s {stats}", flush=True)
    print(f"[prep] done {time.perf_counter()-t0:.0f}s {stats}", flush=True)
    return 0


# -------------------------------------------------------------- generate ---- #
def phase_generate(args) -> int:
    DIR.mkdir(parents=True, exist_ok=True)
    models = [m.strip() for m in args.models.split(",") if m.strip()]
    cands = latest_candidates()
    todo = []
    for p in sorted(WORK.glob("*.json")):
        rid = int(p.stem)
        if rid not in cands:
            todo.append(rid)
        elif args.retry_empty and cands[rid].get("candidate") is None:
            todo.append(rid)
    print(f"[generate] todo={len(todo)} models={models} retry_empty={args.retry_empty}", flush=True)
    t0, ok, empty = time.perf_counter(), 0, 0

    def one(rid: int) -> None:
        w = json.loads((WORK / f"{rid}.json").read_text())
        nonlocal ok, empty
        # sequential fallback across models: free gateway 429s per-model, so a
        # record only goes empty when EVERY model is empty for it.
        for m in models:
            cand, dt = zen_idiomize(w["floor_fn"], w["python"], w["entrypoint"],
                                    model=m, timeout=args.call_timeout)
            if cand:
                ok += 1
                append_jsonl(CAND, {"id": rid, "candidate": cand, "model": m,
                                    "dt": round(dt, 1)})
                return
        empty += 1
        append_jsonl(CAND, {"id": rid, "candidate": None, "model": "all-empty",
                            "dt": 0})

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(one, i) for i in todo]
        for n, _ in enumerate(as_completed(futs), 1):
            if n % 25 == 0:
                print(f"  [{n}/{len(todo)}] {time.perf_counter()-t0:.0f}s ok={ok} empty={empty}", flush=True)
    print(f"[generate] done {time.perf_counter()-t0:.0f}s ok={ok} empty={empty}", flush=True)
    return 0


# ----------------------------------------------------------------- guard ---- #
def phase_guard(args) -> int:
    from agent_idiomize_guard import guard_one
    # NOTE: guard subprocesses MUST see TMPDIR=/tmp so the shared embedded
    # Postgres socket ($TMPDIR/jacpg-*) is reachable. A custom shared-tmp
    # anywhere else hides the socket -> every jac test rejects -> 0% flips
    # (the bug that zeroed the paid composer run; see memory id 751).
    if args.shared_tmp and args.shared_tmp != "/tmp":
        print(f"[guard] WARNING: shared-tmp {args.shared_tmp!r} hides the embedded-PG "
              f"socket; forcing /tmp", flush=True)
        args.shared_tmp = "/tmp"
    if args.shared_tmp:
        os.makedirs(args.shared_tmp, exist_ok=True)
    done = ids_in(RESULTS)
    cands = {i: d for i, d in latest_candidates().items() if d.get("candidate")}
    todo = sorted(i for i in cands if i not in done and (WORK / f"{i}.json").exists())
    if args.shards > 1:
        todo = [i for i in todo if i % args.shards == args.shard]
    print(f"[guard] shard {args.shard}/{args.shards} todo={len(todo)} "
          f"(skip {len(done)} done, {len(cands)} cands total)", flush=True)
    t0, flips = time.perf_counter(), 0

    def one(rid: int) -> None:
        w = json.loads((WORK / f"{rid}.json").read_text())
        r = guard_one(w, cands[rid]["candidate"], shared_tmp=args.shared_tmp or "/tmp")
        append_jsonl(RESULTS, r)
        nonlocal flips
        if r.get("source") == "idiomatic":
            flips += 1

    # Cold-boot race: concurrent jac tests on a fresh shared-tmp all race the
    # embedded-postgres initdb and wedge each other (the historical guard
    # contamination). Run ONE record synchronously first to boot PG, then fan
    # out — sessions then connect to the warm PG instead of booting.
    if todo:
        one(todo.pop(0))
        print(f"  [warmup] done {time.perf_counter()-t0:.0f}s (PG booted)", flush=True)

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(one, i) for i in todo]
        for n, _ in enumerate(as_completed(futs), 1):
            if n % 50 == 0:
                print(f"  [{n}/{len(todo)}] {time.perf_counter()-t0:.0f}s flipped={flips}", flush=True)
    print(f"[guard] shard {args.shard} done {time.perf_counter()-t0:.0f}s flipped={flips}", flush=True)
    return 0


# ----------------------------------------------------------------- merge ---- #
def phase_merge(args) -> int:
    flips = {}
    for ln in RESULTS.read_text().splitlines():
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE001
            continue
        if r.get("source") == "idiomatic" and r.get("jac"):
            flips[r["id"]] = r["jac"]
    floors = load_master_floors()
    applicable = {i: j for i, j in flips.items() if i in floors}
    print(f"[merge] flips={len(flips)} applicable-to-current-floors={len(applicable)}")

    rows, changed = [], 0
    for ln in open(MASTER):
        try:
            r = json.loads(ln)
        except Exception:  # noqa: BLE401
            rows.append(ln.rstrip("\n"))
            continue
        if r.get("id") in applicable:
            r["jac"] = applicable[r["id"]]
            r["source"] = "idiomatic"
            changed += 1
        rows.append(json.dumps(r))
    jsonl_io.atomic_write(MASTER, rows)
    # regenerate export from the new master (4 canonical keys)
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

    total = sum(1 for _ in open(MASTER))
    idi_n = len(out)
    print(f"[merge] master rewritten: +{changed} idiomatic -> {idi_n}/{total} idiomatic")
    return 0


# ---------------------------------------------------------------- status ---- #
def phase_status(_args) -> int:
    floors = load_master_floors()
    work = {int(p.stem) for p in WORK.glob("*.json")}
    cands = latest_candidates()
    res = {}
    for ln in RESULTS.read_text().splitlines() if RESULTS.exists() else []:
        try:
            r = json.loads(ln)
            res[r["id"]] = r
        except Exception:  # noqa: BLE001
            pass
    fl = sum(1 for r in res.values() if r.get("source") == "idiomatic")
    total = sum(1 for _ in open(MASTER))
    idi_now = total - len(floors)
    print(f"master {total} | idiomatic {idi_now} | floor {len(floors)}")
    print(f"prep: work {len(work)}/{len(floors)}")
    print(f"generate: candidates {len(cands)} (null {sum(1 for c in cands.values() if not c.get('candidate'))})")
    print(f"guard: results {len(res)} | flipped {fl}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--phase", required=True,
                    choices=["prep", "generate", "guard", "merge", "status"])
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--models",
                    default="deepseek-v4-flash-free,mimo-v2.5-free,nemotron-3-ultra-free,north-mini-code-free")
    ap.add_argument("--retry-empty", action="store_true")
    ap.add_argument("--call-timeout", type=float, default=240)
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1)
    ap.add_argument("--shared-tmp")
    args = ap.parse_args()
    return {"prep": phase_prep, "generate": phase_generate, "guard": phase_guard,
            "merge": phase_merge, "status": phase_status}[args.phase](args)


if __name__ == "__main__":
    sys.exit(main())
