#!/usr/bin/env python3
"""py2jac dogfood — run `jac tool py2jac` over every Python sample in the
MultiPL-T corpus and accumulate failures.

Corpus: nuprl/stack-dedup-python-testgen-starcoder-filter-v2 (train split,
157,767 python functions+tests, already cached in ~/.cache/huggingface — runs
offline).

Each sample's `content` field is written to a temp .py and transpiled with
`jac tool py2jac` (default: the editable venv of the upstream checkout at
~/repos/jaseci, so you are dogfooding whatever that tree currently has).

Pass = rc 0 with non-empty jac output. Everything else (compile errors, crashes,
timeouts, empty output) is a failure and is appended to failures.jsonl with the
error text and the original python.

Outputs (in --out-dir, default <repo>/data/py2jac_dogfood):
  failures.jsonl       {id, entrypoint, coverage, rc, stage, error, content}
  done.jsonl           {id, stage} ledger — resume-safe across reruns
  run.log              progress
  failures_summary.md  end-of-run report: totals, rate, top error signatures

Examples:
  scripts/py2jac_dogfood.sh                     # full corpus, 12 workers
  scripts/py2jac_dogfood.sh --limit 100         # smoke test
  scripts/py2jac_dogfood.sh --workers 16        # more parallelism
  scripts/py2jac_dogfood.sh --jac /home/jac/.local/bin/jac   # stock binary
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATASET = "nuprl/stack-dedup-python-testgen-starcoder-filter-v2"
DEFAULT_JAC = Path.home() / "repos/jaseci/.venv/bin/jac"
DEFAULT_OUT = REPO_ROOT / "data/py2jac_dogfood"

_print_lock = threading.Lock()
_counters = {"pass": 0, "fail": 0}
_counters_lock = threading.Lock()


def log(msg: str) -> None:
    with _print_lock:
        print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def run_one(jac: str, record: dict, workdir: Path, timeout: int, with_tests: bool) -> dict:
    rid = record["id"]
    py_src = record["content"].rstrip() + "\n"
    if with_tests and record.get("tests"):
        tests = record["tests"]
        if isinstance(tests, str):
            tests = [tests]
        py_src += "\n" + "\n".join(tests) + "\n"

    pyf = workdir / f"{rid}.py"
    pyf.write_text(py_src)
    try:
        proc = subprocess.run(
            [jac, "tool", "py2jac", str(pyf)],
            capture_output=True, text=True, timeout=timeout,
            cwd=str(workdir),
        )
    except subprocess.TimeoutExpired:
        return {"id": rid, "entrypoint": record.get("entrypoint"),
                "coverage": record.get("coverage"), "rc": None,
                "stage": "timeout", "error": f"timed out after {timeout}s",
                "content": record["content"]}
    finally:
        pyf.unlink(missing_ok=True)

    out, err, rc = proc.stdout, proc.stderr, proc.returncode
    jac_code = out.strip()
    if rc == 0 and jac_code:
        return {"id": rid, "stage": "pass"}
    if rc == 0:
        stage, error = "empty_output", "rc 0 but no jac output on stdout"
    else:
        stage = "error" if "Traceback" not in err else "crash"
        error = (err.strip() or out.strip())[-2000:]
    return {"id": rid, "entrypoint": record.get("entrypoint"),
            "coverage": record.get("coverage"), "rc": rc, "stage": stage,
            "error": error, "content": record["content"]}


def error_signature(error: str) -> str:
    """Collapse an error tail into a comparable signature (first error line)."""
    head = error.strip().splitlines()
    for line in head:
        if re.search(r"(error|Error|ERROR|Exception|assert|Traceback|timed out)", line):
            line = re.sub(r"\S*/(\w+\.py)", r"\1", line)   # strip dir -> file
            line = re.sub(r"line \d+", "line N", line)
            line = re.sub(r"col \d+", "col N", line)
            line = re.sub(r"'[^']*'", "'X'", line)
            return line[:200]
    return (head[0][:200] if head else "<no error text>")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--jac", default=str(DEFAULT_JAC))
    ap.add_argument("--out-dir", default=str(DEFAULT_OUT))
    ap.add_argument("--workers", type=int, default=12)
    ap.add_argument("--timeout", type=int, default=30,
                    help="per-sample py2jac timeout in seconds")
    ap.add_argument("--limit", type=int, default=0, help="0 = all samples")
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--with-tests", action="store_true",
                    help="append the record's test asserts to the .py before transpiling")
    ap.add_argument("--fresh", action="store_true",
                    help="ignore + clear previous ledger/results in out-dir")
    args = ap.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    failures_f = out_dir / "failures.jsonl"
    done_f = out_dir / "done.jsonl"
    log_f = open(out_dir / "run.log", "a")

    def flog(msg: str) -> None:
        with _print_lock:
            log_f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}\n")
            log_f.flush()

    if args.fresh:
        for f in (failures_f, done_f):
            f.unlink(missing_ok=True)

    # jac provenance for the report
    try:
        v = subprocess.run([args.jac, "--version"], capture_output=True,
                           text=True, timeout=60).stdout.strip()
    except Exception as e:  # noqa: BLE001
        v = f"<version probe failed: {e}>"
    try:
        commit = subprocess.run(["git", "-C", str(Path(args.jac).resolve().parents[1]),
                                 "rev-parse", "--short", "HEAD"],
                                capture_output=True, text=True, timeout=30).stdout.strip()
    except Exception:  # noqa: BLE001
        commit = "?"

    done_ids: set[str] = set()
    if done_f.exists():
        with done_f.open() as fh:
            for line in fh:
                try:
                    done_ids.add(json.loads(line)["id"])
                except (json.JSONDecodeError, KeyError):
                    pass

    os.environ.setdefault("HF_HUB_OFFLINE", "1")
    from datasets import load_dataset
    ds = load_dataset(DATASET, split="train")

    todo = []
    for i, rec in enumerate(ds):
        if i < args.offset:
            continue
        if args.limit and len(todo) >= args.limit:
            break
        if rec["id"] in done_ids:
            continue
        todo.append(rec)

    log(f"corpus={len(ds)} todo={len(todo)} (skipped {len(done_ids)} already done) "
        f"workers={args.workers} timeout={args.timeout}s with_tests={args.with_tests}")
    log(f"jac={args.jac} version='{v}' commit={commit}")
    flog(f"=== run start: todo={len(todo)} jac={args.jac} v='{v}' commit={commit}")

    t0 = time.time()
    with ThreadPoolExecutor(max_workers=args.workers) as pool, \
            open(failures_f, "a") as ffh, open(done_f, "a") as dfh:
        def submit(rec):
            return run_one(args.jac, rec, out_dir, args.timeout, args.with_tests)

        futures = [pool.submit(submit, rec) for rec in todo]
        for fut in as_completed(futures):
            res = fut.result()
            with _counters_lock:
                _counters[res["stage"] if res["stage"] == "pass" else "fail"] += 1
                n_done = _counters["pass"] + _counters["fail"]
            dfh.write(json.dumps({"id": res["id"], "stage": res["stage"]}) + "\n")
            dfh.flush()
            if res["stage"] != "pass":
                ffh.write(json.dumps(res) + "\n")
                ffh.flush()
            if n_done % 50 == 0:
                rate = n_done / max(time.time() - t0, 1e-9)
                eta = (len(todo) - n_done) / max(rate, 1e-9) / 60
                log(f"{n_done}/{len(todo)} pass={_counters['pass']} "
                    f"fail={_counters['fail']} ({rate:.1f}/s, eta {eta:.0f}m)")
                flog(f"progress {n_done}/{len(todo)} pass={_counters['pass']} fail={_counters['fail']}")

    total = _counters["pass"] + _counters["fail"]
    pct = 100.0 * _counters["fail"] / max(total, 1)
    log(f"DONE: {total} processed, pass={_counters['pass']} fail={_counters['fail']} "
        f"({pct:.2f}% fail) in {(time.time()-t0)/60:.1f}m")
    flog(f"=== run end: {total} pass={_counters['pass']} fail={_counters['fail']}")

    # ---- summary report ----
    fails = []
    if failures_f.exists():
        with failures_f.open() as fh:
            fails = [json.loads(l) for l in fh if l.strip()]
    sig_counts = Counter(error_signature(f.get("error", "")) for f in fails)
    md = [
        "# py2jac dogfood failures",
        "",
        f"- run finished: {time.strftime('%Y-%m-%d %H:%M:%S')}",
        f"- corpus: `{DATASET}`",
        f"- jac: `{args.jac}` version `{v}` commit `{commit}`",
        f"- processed: {total} | pass: {_counters['pass']} | fail: {_counters['fail']} "
        f"({pct:.2f}% fail)",
        f"- with_tests: {args.with_tests}",
        "",
        "## Failure entries",
        "",
        f"See `failures.jsonl` — one line per failed sample with `error` and "
        f"the original `content`.",
        "",
        "## Top error signatures (collapsed)",
        "",
        "| count | signature |",
        "|---|---|",
    ]
    for sig, cnt in sig_counts.most_common(40):
        md.append(f"| {cnt} | `{sig.replace(chr(124), '/')}` |")
    (out_dir / "failures_summary.md").write_text("\n".join(md) + "\n")
    log(f"wrote {out_dir / 'failures_summary.md'} and {failures_f}")


if __name__ == "__main__":
    main()
