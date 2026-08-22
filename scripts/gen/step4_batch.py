#!/usr/bin/env python3
"""Step 4: batch harness — mechanical floor yield at scale (parallel).

Per record (PLAN.md step 4), deterministic pipeline run in an ISOLATED temp cwd
(so parallel workers don't clash on jac's .jac/ cache):
    record (coverage>=N)
      -> strip u-prefix, concat content+tests   -> .py
      -> jac tool py2jac                         -> floor jac (with entry)
      -> with_entry -> test blocks
      -> jac test                                -> floor guard
      -> outcome: pass_floor | py2jac_fail | test_fail

This measures the **mechanical floor yield** — the count of records that survive
the deterministic pipeline before any model spend. That is the candidate pool for
the idiomize step (step 3 showed 5/5 idiomatic-keep on a hand sample).

``test_fail`` = py2jac succeeded but the floor fails its own tests. Confirmed
example (mergesort 415993): the record's tests fail in PURE PYTHON too, i.e. bad
source data, correctly filtered. A small residual may be genuine py2jac bugs.

Parallel: ThreadPoolExecutor (subprocess-bound, so threads give real speedup),
configurable --workers. Failures are persisted to failures/ for inspection.

Env: HF_HUB_OFFLINE=1 set automatically (full dataset cached).

Usage:
    python scripts/step4_batch.py --limit 1000 --workers 6
    python scripts/step4_batch.py --limit 500 --offset 5000 --min-coverage 90
"""

from __future__ import annotations

import argparse
import json
import os
import statistics
import sys
import tempfile
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import shutil
import subprocess

os.environ.setdefault("HF_HUB_OFFLINE", "1")

REPO = Path(__file__).resolve().parents[2]
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))
from step2_translate_tests import normalize_python, with_entry_to_tests  # noqa: E402

OUT_DIR = REPO / "data" / "step4"
FAIL_DIR = OUT_DIR / "failures"
DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"
MAX_FAILURES_KEPT = 200  # cap persisted failures per run


# --------------------------------------------------------------------------- #
# subprocess wrappers with isolated cwd
# --------------------------------------------------------------------------- #
def _run(cmd: list[str], cwd: str) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=120)
    return p.returncode, p.stdout, p.stderr


def process_record(record: dict) -> dict:
    rid = record["id"]
    res = {
        "id": rid, "entrypoint": record["entrypoint"], "coverage": record.get("coverage"),
        "n_tests": len(record["tests"]), "outcome": None,
        "py2jac_err": None, "test_err": None, "py2jac_ms": None, "test_ms": None,
    }
    py_src = normalize_python(record["content"].rstrip() + "\n\n"
                              + "\n".join(record["tests"]) + "\n")

    with tempfile.TemporaryDirectory(prefix=f"j4_{rid}_") as tmp:
        tmpd = Path(tmp)
        work_py = tmpd / f"{rid}.py"
        work_py.write_text(py_src)

        t0 = time.perf_counter()
        rc, out, err = _run(["jac", "tool", "py2jac", str(work_py)], tmp)
        res["py2jac_ms"] = round((time.perf_counter() - t0) * 1000, 1)
        if rc != 0:
            res["outcome"] = "py2jac_fail"
            res["py2jac_err"] = _sig(err or out)
            _maybe_keep_failure("py2jac_fail", rid, work_py, None, py_src, out if rc == 0 else (err or out))
            return res

        floor_jac = out
        guard_jac = with_entry_to_tests(floor_jac)
        guard_path = tmpd / f"{rid}.jac"
        guard_path.write_text(guard_jac)

        t0 = time.perf_counter()
        rc2, out2, err2 = _run(["jac", "test", str(guard_path)], tmp)
        res["test_ms"] = round((time.perf_counter() - t0) * 1000, 1)
        if rc2 != 0:
            res["outcome"] = "test_fail"
            res["test_err"] = _sig(err2 or out2)
            _maybe_keep_failure("test_fail", rid, work_py, guard_jac, py_src, err2 or out2)
            return res

        res["outcome"] = "pass_floor"
        return res


_fail_kept = 0


def _maybe_keep_failure(kind, rid, work_py, guard_jac, py_src, err):
    global _fail_kept
    if _fail_kept >= MAX_FAILURES_KEPT:
        return
    _fail_kept += 1
    d = FAIL_DIR / kind
    d.mkdir(parents=True, exist_ok=True)
    if work_py and work_py.exists():
        shutil.copy(work_py, d / f"{rid}.py")
    if guard_jac:
        (d / f"{rid}.jac").write_text(guard_jac)
    (d / f"{rid}.err").write_text((err or "")[:2000])


def _sig(s: str) -> str:
    for line in (s or "").splitlines():
        line = line.strip()
        if any(k in line.lower() for k in ("error", "syntax", "unexpected", "expected", "assert")):
            return line[:70]
    return (s or "").strip()[:70]


# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=1000)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--min-coverage", type=int, default=90)
    ap.add_argument("--workers", type=int, default=min(8, os.cpu_count() or 4))
    ap.add_argument("--progress-every", type=int, default=50)
    args = ap.parse_args()

    for d in (OUT_DIR, FAIL_DIR):
        d.mkdir(parents=True, exist_ok=True)

    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")

    # collect the slice (coverage filter + offset + limit)
    todo: list[dict] = []
    seen = 0
    for record in ds:
        cov = record.get("coverage")
        if cov is None or cov < args.min_coverage:
            continue
        seen += 1
        if seen <= args.offset:
            continue
        if len(todo) >= args.limit:
            break
        todo.append(record)

    print(f"Processing {len(todo)} records (offset {args.offset}, "
          f"cov>={args.min_coverage}) with {args.workers} workers...", flush=True)
    results: list[dict] = []
    t_start = time.perf_counter()
    results_path = OUT_DIR / "floor_results.jsonl"
    with results_path.open("w") as fout, ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(process_record, r): r for r in todo}
        done = 0
        for fut in as_completed(futs):
            try:
                res = fut.result()
            except Exception as e:  # noqa: BLE001
                r = futs[fut]
                res = {"id": r.get("id"), "entrypoint": r.get("entrypoint"),
                       "outcome": "crash", "error": str(e)[:200]}
            results.append(res)
            fout.write(json.dumps(res) + "\n"); fout.flush()
            done += 1
            if done % args.progress_every == 0:
                el = time.perf_counter() - t_start
                ok = sum(1 for x in results if x["outcome"] == "pass_floor")
                print(f"  [{done}/{len(todo)}] {el:.0f}s, floor_pass {ok}/{done} "
                      f"({100*ok/done:.1f}%), {done/el:.1f} rec/s", flush=True)

    elapsed = time.perf_counter() - t_start
    stats = aggregate(results, elapsed, args)
    (OUT_DIR / "floor_stats.json").write_text(json.dumps(stats, indent=2) + "\n")
    write_report(stats)
    print_summary(stats)
    return 0


def aggregate(results, elapsed, args) -> dict:
    n = len(results)
    oc = Counter(r["outcome"] for r in results)
    p2 = sorted(r["py2jac_ms"] for r in results if r["py2jac_ms"] is not None)
    te = [r["test_ms"] for r in results if r["test_ms"] is not None]
    fail_sigs = Counter(r["py2jac_err"] for r in results if r["outcome"] == "py2jac_fail")
    test_sigs = Counter(r["test_err"] for r in results if r["outcome"] == "test_fail")

    def q(lst, p):
        return round(statistics.quantiles(lst, n=100)[p - 1], 1) if len(lst) >= 100 else None

    fp = oc.get("pass_floor", 0)
    # Wilson 95% CI for the floor-pass proportion (quick confidence read)
    z = 1.96
    ph = fp / n if n else 0
    ci = z * (ph * (1 - ph) / max(n, 1)) ** 0.5
    return {
        "min_coverage": args.min_coverage,
        "processed": n, "elapsed_s": round(elapsed, 1),
        "throughput_rec_per_s": round(n / elapsed, 2) if elapsed else None,
        "outcome_counts": dict(oc),
        "floor_pass": fp,
        "floor_pass_rate": round(ph, 4),
        "floor_pass_rate_ci95": round(ci, 4),
        "py2jac_fail": oc.get("py2jac_fail", 0),
        "test_fail": oc.get("test_fail", 0),
        "py2jac_ms_p50": q(p2, 50), "py2jac_ms_p95": q(p2, 95),
        "test_ms_p50": q(te, 50) if te else None,
        "top_py2jac_fail_signatures": fail_sigs.most_common(15),
        "top_test_fail_signatures": test_sigs.most_common(15),
        "extrapolated_floor_pass_of_133668": round(fp / max(n, 1) * 133668),
    }


def write_report(stats):
    n = stats["processed"]; fp = stats["floor_pass"]
    lines = [
        "# Step 4 report: mechanical floor yield (batch, parallel)",
        "",
        f"**Date:** {time.strftime('%Y-%m-%d')}  ",
        f"**Dataset:** `{DATASET}` (coverage >= {stats.get('min_coverage', 90)})  ",
        f"**Slice:** processed {n}  ",
        f"**Throughput:** {stats['throughput_rec_per_s']} rec/s  ",
        "",
        "## Headline",
        "",
        f"- **Floor yield: {fp}/{n} = {100*fp/max(n,1):.1f}% "
        f"(95% CI ±{100*stats['floor_pass_rate_ci95']:.1f}pp)**  ",
        f"- py2jac_fail: {stats['py2jac_fail']}  ",
        f"- test_fail (py2jac ok, floor/tests wrong — incl. bad source data): {stats['test_fail']}  ",
        f"- Extrapolated floor-pass over the 133,668 cov>=90 set: ~{stats['extrapolated_floor_pass_of_133668']:,}  ",
        f"- py2jac p50/p95: {stats['py2jac_ms_p50']} / {stats['py2jac_ms_p95']} ms  ",
        "",
        "## Top py2jac failure signatures",
        "", "| count | signature |", "|------:|-----------|",
    ]
    lines += [f"| {c} | {s} |" for c, s in stats["top_py2jac_fail_signatures"]] or ["| _(none)_ | |"]
    lines += ["", "## Top test_fail signatures", "", "| count | signature |", "|------:|-----------|"]
    lines += [f"| {c} | {s} |" for c, s in stats["top_test_fail_signatures"]] or ["| _(none)_ | |"]
    lines += [
        "",
        "## Interpretation",
        "",
        "Floor yield is the candidate pool for the idiomize step. test_fail records are "
        "dropped (one confirmed case, mergesort 415993, fails in pure Python — bad source "
        "data, not a py2jac bug). py2jac_fail records are dropped too. Multiply floor yield "
        "by the idiomatic-keep ratio (step 3: 5/5 on the hand sample) for the expected "
        "idiomatic dataset size, then subtract jac fmt + ROUGE-L dedup losses.",
        "",
        "## Artifacts",
        "", "- `floor_results.jsonl` — per-record outcome",
        "- `floor_stats.json` — this aggregate",
        "- `failures/{py2jac_fail,test_fail}/<id>.{py,jac,err}` — persisted failure samples",
    ]
    (OUT_DIR / "REPORT.md").write_text("\n".join(lines) + "\n")


def print_summary(stats):
    n = stats["processed"]; fp = stats["floor_pass"]
    print(f"\n=== Floor yield: {fp}/{n} ({100*fp/max(n,1):.1f}%)  "
          f"±{100*stats['floor_pass_rate_ci95']:.1f}pp (95% CI) ===")
    print(f"  py2jac_fail={stats['py2jac_fail']}  test_fail={stats['test_fail']}")
    print(f"  throughput={stats['throughput_rec_per_s']} rec/s  "
          f"py2jac p50/p95={stats['py2jac_ms_p50']}/{stats['py2jac_ms_p95']}ms")
    print(f"  extrapolated floor-pass over 133,668 cov>=90: ~{stats['extrapolated_floor_pass_of_133668']:,}")
    if stats["top_py2jac_fail_signatures"]:
        print("  top py2jac fails:")
        for c, s in stats["top_py2jac_fail_signatures"][:5]:
            print(f"    {c:>4}  {s}")


if __name__ == "__main__":
    sys.exit(main())
