#!/usr/bin/env python3
"""Compare the 4 free opencode-gateway models head-to-head on idiomize+guard.

For a fixed set of N records, each model runs: zen_idiomize -> extract -> jac test guard.
Reports per model: response_rate (non-empty fence), guard_pass_rate, mean latency.
Picks the best free model for the batch. Reuses idiomize_seam.zen_idiomize.

Usage: python scripts/step4_free_model_compare.py --limit 12 --workers 4
"""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
os.environ.setdefault("HF_HUB_OFFLINE", "1")

REPO = Path(__file__).resolve().parents[2]
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))
from step2_translate_tests import normalize_python, with_entry_to_tests  # noqa: E402
from idiomize_seam import zen_idiomize  # noqa: E402

DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"
MODELS = ["deepseek-v4-flash-free", "mimo-v2.5-free", "nemotron-3-ultra-free", "north-mini-code-free"]


def floor_and_tests(record):
    """py2jac -> (floor_fn, test_blocks) or None on py2jac fail."""
    rid = record["id"]
    py = normalize_python(record["content"].rstrip() + "\n\n" + "\n".join(record["tests"]) + "\n")
    with tempfile.TemporaryDirectory(prefix=f"cmp_{rid}_") as tmp:
        wp = Path(tmp) / f"{rid}.py"; wp.write_text(py)
        p = subprocess.run(["jac", "tool", "py2jac", str(wp)], capture_output=True, text=True, cwd=tmp, timeout=120)
        if p.returncode != 0:
            return None
        floor = p.stdout
        gp = Path(tmp) / f"{rid}.jac"; gp.write_text(with_entry_to_tests(floor))
        p2 = subprocess.run(["jac", "test", str(gp)], capture_output=True, text=True, cwd=tmp, timeout=120)
        if p2.returncode != 0:
            return None  # floor itself fails; skip
        m = re.search(r"\nwith entry \{", floor)
        floor_fn = floor[:m.start()].rstrip() if m else floor.rstrip()
        tb = with_entry_to_tests(floor)
        test_blocks = tb[len(floor_fn):].strip()
        return floor_fn, test_blocks


def guard(fn_jac, test_blocks, rid):
    with tempfile.TemporaryDirectory(prefix=f"g_{rid}_") as tmp:
        gp = Path(tmp) / f"{rid}.jac"
        gp.write_text(fn_jac.rstrip() + "\n\n" + test_blocks + "\n")
        p = subprocess.run(["jac", "test", str(gp)], capture_output=True, text=True, cwd=tmp, timeout=120)
        return p.returncode == 0


def run_model(model, cases, workers):
    """cases: list of (rid, entry, floor_fn, test_blocks, py). Returns list of dicts."""
    out = []
    def one(c):
        rid, entry, floor_fn, test_blocks, py = c
        jac, dt = zen_idiomize(floor_fn, py, entry, model=model)
        fenced = jac is not None
        passed = guard(jac, test_blocks, rid) if fenced else False
        return {"rid": rid, "latency": dt, "fenced": fenced, "guard_pass": passed}
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = [ex.submit(one, c) for c in cases]
        for f in as_completed(futs):
            out.append(f.result())
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=12)
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()

    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")
    cases, seen = [], 0
    for r in ds:
        if (r.get("coverage") or 0) < 90:
            continue
        seen += 1
        ft = floor_and_tests(r)
        if not ft:
            continue
        floor_fn, test_blocks = ft
        cases.append((r["id"], r["entrypoint"], floor_fn, test_blocks, normalize_python(r["content"])))
        if len(cases) >= args.limit:
            break
    print(f"Built {len(cases)} floor-pass cases. Running {len(MODELS)} models x {len(cases)} records...\n", flush=True)

    rows = []
    for m in MODELS:
        t0 = time.perf_counter()
        res = run_model(m, cases, args.workers)
        n = len(res)
        fenced = sum(1 for x in res if x["fenced"])
        passed = sum(1 for x in res if x["guard_pass"])
        lat = [x["latency"] for x in res]
        rows.append({
            "model": m, "n": n,
            "response_rate": round(fenced / n, 2),
            "guard_pass_of_total": round(passed / n, 2),
            "guard_pass_of_responses": round(passed / fenced, 2) if fenced else 0,
            "mean_latency_s": round(sum(lat) / len(lat), 1) if lat else None,
            "wall_s": round(time.perf_counter() - t0, 1),
        })
        print(f"  {m:26} response={fenced}/{n}  guard_pass={passed}/{n} "
              f"({100*passed/max(fenced,1):.0f}% of resp)  mean_lat={rows[-1]['mean_latency_s']}s", flush=True)

    Path(REPO / "data/step4/free_model_compare.json").write_text(json.dumps(rows, indent=2) + "\n")
    print("\nDone. Wrote data/step4/free_model_compare.json")


if __name__ == "__main__":
    main()
