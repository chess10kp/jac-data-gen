#!/usr/bin/env python3
"""Generate model samples for evals/function/v1 — decoupled from grading.

Reads the PUBLIC split files (never private/), calls any llm_backend model,
and appends samples.jsonl rows in the exact schema eval_jac.py consumes:

    completion tasks   -> {"problem_id", "sample_id", "completion": <raw>}
    translation tasks  -> {"problem_id", "sample_id", "output": <raw>}

The grader re-extracts fenced/raw Jac and assembles prefixes, so raw model
text is stored verbatim; no fence surgery happens here.

Resume-safe: (problem_id, sample_id) pairs already in the output file are
skipped, so re-running the same command continues where it stopped.

Usage:
  python scripts/gen/function_eval_generate.py \
      --backend auto --model gpt-5.6-luna \
      --samples 4 --workers 8

  python scripts/gen/function_eval_generate.py --backend openrouter \
      --model minimax/minimax-m3:free --samples 1 --limit 20 --dry-run

Outputs (under --out-dir, default runs/function_eval/<model-slug>):
  samples.jsonl   one row per (problem, sample)
  gen_meta.json   run config + final counts
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))

from generation_ledger import new_run, record_call  # noqa: E402
from llm_backend import get_backend, strip_prefix  # noqa: E402

EVAL_DIR = REPO / "evals" / "function" / "v1" / "public"

SYSTEM_PROMPT = (
    "You are an expert Jac programmer. Follow the task instructions exactly. "
    "Output only the requested Jac code with no commentary."
)


def slugify(model: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "-", model).strip("-") or "model"


def load_done(out_path: Path) -> set[tuple[str, int]]:
    done: set[tuple[str, int]] = set()
    if out_path.exists():
        with out_path.open() as fh:
            for line in fh:
                try:
                    row = json.loads(line)
                    done.add((str(row["problem_id"]), int(row["sample_id"])))
                except (json.JSONDecodeError, KeyError, ValueError):
                    continue
    return done


def load_problems(splits: list[str], tasks: list[str], limit: int | None) -> list[dict]:
    problems: list[dict] = []
    for split in splits:
        path = EVAL_DIR / f"{split}.jsonl"
        if not path.exists():
            print(f"[warn] missing {path}", file=sys.stderr)
            continue
        with path.open() as fh:
            for line in fh:
                row = json.loads(line)
                if row.get("task") in tasks:
                    problems.append(row)
    if limit:
        problems = problems[:limit]
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--backend", default="auto", help="pi|cursor|zen|openrouter|auto")
    ap.add_argument("--model", required=True)
    ap.add_argument("--samples", type=int, default=4, help="samples per problem (pass@k n)")
    ap.add_argument("--splits", default="dev,test", help="comma list: dev,test")
    ap.add_argument("--tasks", default="completion,translation", help="comma list")
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--limit", type=int, default=None, help="cap number of problems")
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--tries", type=int, default=3)
    ap.add_argument("--out-dir", default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    splits = [s.strip() for s in args.splits.split(",") if s.strip()]
    tasks = [t.strip() for t in args.tasks.split(",") if t.strip()]
    problems = load_problems(splits, tasks, args.limit)
    if not problems:
        print("no problems matched --splits/--tasks", file=sys.stderr)
        return 2

    out_dir = Path(args.out_dir) if args.out_dir else REPO / "runs" / "function_eval" / slugify(args.model)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "samples.jsonl"
    meta_path = out_dir / "gen_meta.json"

    done = load_done(out_path)
    work = [
        (p, k)
        for p in problems
        for k in range(args.samples)
        if (str(p["id"]), k) not in done
    ]
    total_units = len(problems) * args.samples
    print(
        f"[plan] model={args.model} backend={args.backend} splits={splits} tasks={tasks}\n"
        f"[plan] problems={len(problems)} samples/problem={args.samples} "
        f"units={total_units} already_done={len(done)} todo={len(work)} out={out_path}"
    )
    if args.dry_run:
        for p, k in work[:5]:
            print(f"  would generate: {p['id']}#{k} ({p['task']}, entry={p.get('entrypoint')})")
        return 0
    if not work:
        print("[done] nothing to generate")
        return 0

    backend = get_backend(args.backend, args.model)
    model_core = strip_prefix(args.model)
    run_id = new_run(pipeline="function_eval_gen", model=args.model,
                     note=f"splits={','.join(splits)} tasks={','.join(tasks)}")

    write_lock = threading.Lock()
    counters = {"ok": 0, "err": 0}
    started = time.time()

    def generate(item: tuple[dict, int]) -> None:
        problem, k = item
        pid = str(problem["id"])
        t0 = time.time()
        text, err, usage = backend.call(SYSTEM_PROMPT, problem["prompt"], model_core,
                                        timeout=args.timeout, tries=args.tries)
        ms = int((time.time() - t0) * 1000)
        if err or not text:
            record_call(run_id, pipeline="function_eval_gen", status="error",
                        batch=pid, model=args.model, error=str(err),
                        usage=usage, dur_s=ms / 1000)
            with write_lock:
                counters["err"] += 1
            return
        # completion -> 'completion' key (grader prepends prefix);
        # translation -> 'output' key (grader extracts fence/raw source).
        field = "completion" if problem["task"] == "completion" else "output"
        row = {
            "problem_id": pid,
            "sample_id": k,
            "model": args.model,
            "backend": args.backend,
            field: text,
        }
        record_call(run_id, pipeline="function_eval_gen", status="ok",
                    batch=pid, model=args.model, usage=usage, dur_s=ms / 1000)
        with write_lock:
            with out_path.open("a") as fh:
                fh.write(json.dumps(row) + "\n")
            counters["ok"] += 1
            n = counters["ok"] + counters["err"]
            if n % 25 == 0 or n == len(work):
                rate = n / max(time.time() - started, 1e-9)
                eta = (len(work) - n) / max(rate, 1e-9)
                print(f"[prog] {n}/{len(work)} ok={counters['ok']} err={counters['err']} "
                      f"{rate:.1f}/s eta={eta/60:.1f}m")

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(generate, item) for item in work]
        for fut in as_completed(futures):
            fut.result()

    meta = {
        "model": args.model,
        "backend": args.backend,
        "splits": splits,
        "tasks": tasks,
        "samples_per_problem": args.samples,
        "problems": len(problems),
        "requested_units": total_units,
        "previously_done": len(done),
        "generated_ok": counters["ok"],
        "generated_err": counters["err"],
        "wall_s": round(time.time() - started, 1),
        "out_path": str(out_path),
        "run_id": run_id,
    }
    meta_path.write_text(json.dumps(meta, indent=2) + "\n")
    print(f"[done] ok={counters['ok']} err={counters['err']} -> {out_path}")
    print(f"[done] meta -> {meta_path}  ledger run={run_id}")
    return 0 if counters["err"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
