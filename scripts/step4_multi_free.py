#!/usr/bin/env python3
"""Step 4 multi-free-model racer: fire ALL free models per record, keep the first
guard-passing rewrite.

Why: each free model alone is ~50% empty-response (rate-limit/reasoning) and
~70% guard-pass when it responds. Racing all 4 concurrently per record:
  - response rate  ~50%  -> 1-(0.5^4) = ~94%  (any model fencing)
  - keep          picks the first guard-pass among the responses -> higher keep
  - if the gateway rate-limits per-model, aggregate throughput multiplies too.

Per record: py2jac -> floor+tests; fire 4 models concurrently; guard each fenced
response as it arrives; keep first pass (source = winning model); else fall back
to floor. Then jac fmt + ROUGE-L dedup, same as step4_full_loop.

Usage: python scripts/step4_multi_free.py --limit 40 --workers 3
"""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
os.environ.setdefault("HF_HUB_OFFLINE", "1")

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "scripts"))
from step2_translate_tests import normalize_python, with_entry_to_tests  # noqa: E402
from idiomize_seam import zen_idiomize  # noqa: E402
from step4_full_loop import jac_fmt, split_floor_fn, dedup  # noqa: E402

DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"
MODELS = ["deepseek-v4-flash-free", "mimo-v2.5-free", "nemotron-3-ultra-free", "north-mini-code-free"]
OUT = REPO / "data" / "step4"


def floor_and_tests(record):
    rid = record["id"]
    py_full = normalize_python(record["content"].rstrip() + "\n\n" + "\n".join(record["tests"]) + "\n")
    with tempfile.TemporaryDirectory(prefix=f"mf_{rid}_") as tmp:
        wp = Path(tmp) / f"{rid}.py"; wp.write_text(py_full)
        pr = subprocess.run(["jac", "tool", "py2jac", str(wp)], capture_output=True, text=True, cwd=tmp, timeout=120)
        if pr.returncode != 0:
            return None, None, None, None
        floor = pr.stdout
        gp = Path(tmp) / f"{rid}.jac"; gp.write_text(with_entry_to_tests(floor))
        if subprocess.run(["jac", "test", str(gp)], capture_output=True, text=True, cwd=tmp, timeout=120).returncode != 0:
            return None, None, None, None
    floor_fn = split_floor_fn(floor)
    test_blocks = with_entry_to_tests(floor)[len(floor_fn):].strip()
    return floor_fn, test_blocks, normalize_python(record["content"]), record["tests"]


def guard(fn_jac, test_blocks, rid):
    with tempfile.TemporaryDirectory(prefix=f"mg_{rid}_") as tmp:
        gp = Path(tmp) / f"{rid}.jac"
        gp.write_text(fn_jac.rstrip() + "\n\n" + test_blocks + "\n")
        return subprocess.run(["jac", "test", str(gp)], capture_output=True, text=True, cwd=tmp, timeout=120).returncode == 0


def race(record):
    """Return result dict: floor -> race 4 models -> keep first guard-pass | floor."""
    rid = record["id"]
    r = {"id": rid, "entrypoint": record["entrypoint"], "stage": None, "source": None,
         "winner": None, "jac": None, "fenced_count": 0, "race_ms": None}
    ft = floor_and_tests(record)
    if ft[0] is None:
        r["stage"] = "floor_fail"; return r
    floor_fn, test_blocks, py_src, _ = ft
    r["stage"] = "floor_pass"

    t0 = time.perf_counter()
    winner_jac, winner_model = None, None
    with ThreadPoolExecutor(max_workers=len(MODELS)) as ex:
        futs = {ex.submit(zen_idiomize, floor_fn, py_src, record["entrypoint"], m, 16384, 180): m for m in MODELS}
        for fut in as_completed(futs):
            m = futs[fut]
            try:
                jac, _ = fut.result()
            except Exception:  # noqa: BLE001
                jac = None
            if jac is None:
                continue
            r["fenced_count"] += 1
            if winner_jac is None and guard(jac, test_blocks, rid):
                winner_jac, winner_model = jac, m
                # cancel the rest (no-op if already running) and stop early
                for f in futs:
                    f.cancel()
                break
    r["race_ms"] = round((time.perf_counter() - t0) * 1000, 1)

    if winner_jac:
        with tempfile.TemporaryDirectory(prefix=f"mfmt_{rid}_") as tmp:
            r["jac"] = jac_fmt(winner_jac, Path(tmp), str(rid))
        r["source"], r["winner"] = "idiomatic", winner_model
    else:
        with tempfile.TemporaryDirectory(prefix=f"mfmt_{rid}_") as tmp:
            r["jac"] = jac_fmt(floor_fn, Path(tmp), str(rid))
        r["source"] = "floor"
    return r


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=40)
    ap.add_argument("--workers", type=int, default=3, help="parallel records (each fires 4 models)")
    ap.add_argument("--progress-every", type=int, default=10)
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)

    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")
    todo, seen = [], 0
    for r in ds:
        if (r.get("coverage") or 0) < 90:
            continue
        seen += 1
        if len(todo) >= args.limit:
            break
        todo.append(r)

    print(f"Racing {len(MODELS)} free models x {len(todo)} records ({args.workers} records parallel)...", flush=True)
    results, t0 = [], time.perf_counter()
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(race, r): r for r in todo}
        for i, fut in enumerate(as_completed(futs), 1):
            try:
                results.append(fut.result())
            except Exception as e:  # noqa: BLE001
                rr = futs[fut]; results.append({"id": rr.get("id"), "stage": "crash", "error": str(e)[:120]})
            if i % args.progress_every == 0:
                idi = sum(1 for x in results if x.get("source") == "idiomatic")
                print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s, idiomatic {idi}/{i}", flush=True)

    kept = [r for r in results if r.get("jac")]
    final, dropped = dedup(kept, 0.9)
    from collections import Counter
    winners = Counter(r["winner"] for r in final if r.get("source") == "idiomatic")
    idi = sum(1 for r in final if r.get("source") == "idiomatic")
    elapsed = time.perf_counter() - t0
    summ = {
        "processed": len(results), "final": len(final), "dedup_dropped": dropped,
        "idiomatic": idi, "floor_fallback": len(final) - idi,
        "keep_rate": round(idi / max(len(final), 1), 3),
        "winner_counts": dict(winners),
        "elapsed_s": round(elapsed, 1), "throughput_rec_per_s": round(len(results) / elapsed, 3),
    }
    (OUT / "multi_free_results.jsonl").write_text("\n".join(json.dumps(r, default=str) for r in results) + "\n")
    (OUT / "multi_free_summary.json").write_text(json.dumps(summ, indent=2) + "\n")
    print(f"\n=== Multi-free race: {len(results)} -> kept {len(kept)} -> final {len(final)} ===")
    print(f"  idiomatic={idi}  floor_fallback={len(final)-idi}  keep_rate={summ['keep_rate']}")
    print(f"  winners: {dict(winners)}")
    print(f"  throughput={summ['throughput_rec_per_s']} rec/s  ({elapsed:.0f}s)")


if __name__ == "__main__":
    main()
