#!/usr/bin/env python3
"""Unified OSP generation — one entrypoint for any backend/model/task.

Replaces the three locked scripts:
  osp_agent_generate.py  (idiomize: issue -> jac lift, cursor/pi)
  osp_luna_generate.py   (codegen: problem -> jac, pi/luna)
  osp_minimax_generate.py (codegen: problem -> jac, openrouter)

Usage:
  # idiomize (issue_gen records, same as osp_agent_generate --batch 35 --flow jac-only)
  python scripts/gen/osp_generate.py --task idiomize --batch 35 --flow jac-only --backend auto --model gpt-5.6-luna
  python scripts/gen/osp_generate.py --task idiomize --batch 35 --model composer-2.5 --backend cursor

  # codegen (100 hand-written problems, same as osp_luna/osp_minimax)
  python scripts/gen/osp_generate.py --task codegen --backend pi --model gpt-5.6-luna --limit 10
  python scripts/gen/osp_generate.py --task codegen --backend openrouter --model minimax/minimax-m3:free --limit 10
  python scripts/gen/osp_generate.py --task codegen --backend zen --model deepseek-v4-flash-free --limit 10

Backend auto keeps backward compat:
  luna in model -> pi, *-free -> zen/openrouter, else cursor.
Explicit --backend overrides auto so any model can ride any transport.

Validation gates are identical to the legacy scripts so outputs stay comparable.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
sys.path.insert(0, str(REPO / "scripts" / "gen"))

from llm_backend import get_backend, strip_prefix  # noqa: E402


def _dispatch_idiomize(args) -> int:
    import osp_agent_generate as gen
    import os
    if args.dry_run:
        recs = gen.load_batch(args.batch) if args.batch else []
        print(f"[idiomize dry-run] batch={args.batch} flow={args.flow} backend={args.backend} model={args.model} records={len(recs)}")
        for r in recs[:5]:
            print(f"  {r['repo']}#{r['issue']}: {r.get('title','')[:60]}")
        return 0
    # patch both env and module globals — generate_record closes over MODEL etc.
    os.environ["CURSOR_OSP_BACKEND"] = args.backend
    os.environ["OSP_BACKEND"] = args.backend
    if args.model:
        os.environ["CURSOR_OSP_MODEL"] = args.model
        os.environ["CURSOR_OSP_MODEL_PY"] = args.model
        os.environ["CURSOR_OSP_MODEL_GUARD"] = args.model
        os.environ["CURSOR_OSP_MODEL_PYGEN"] = args.model
        gen.MODEL = args.model
        gen.MODEL_PY = args.model
        gen.MODEL_GUARD = args.model
        gen.MODEL_PYGEN = args.model
    if not args.batch and not (args.repo and args.issue):
        print("need --batch or --repo + --issue for idiomize", file=sys.stderr)
        return 2
    _argv = []
    if args.batch:
        _argv += ["--batch", str(args.batch)]
    if args.repo:
        _argv += ["--repo", args.repo]
    if args.issue:
        _argv += ["--issue", str(args.issue)]
    _argv += ["--flow", args.flow]
    if args.force:
        _argv.append("--force")
    if args.offset:
        _argv += ["--offset", str(args.offset)]
    if args.limit:
        _argv += ["--limit", str(args.limit)]
    if args.chunk:
        _argv += ["--chunk", str(args.chunk)]
    sys.argv = [sys.argv[0]] + _argv
    return gen.main()


def _dispatch_codegen(args) -> int:
    """Codegen via the shared backend — problem -> jac with jac_check + osp_contract gates."""
    import json, subprocess, tempfile, time, re
    from datetime import datetime

    # import the shared gates from osp_luna (single source of truth)
    from osp_luna_generate import (  # type: ignore
        SYSTEM, _user, _fix_user, extract_jac, jac_check, osp_contract,
        load_problems, JAC_FENCE,
    )

    backend = get_backend(args.backend, args.model)
    model_core = strip_prefix(args.model)
    out_path = Path(args.out) if args.out else REPO / "data" / "osp_dataset.jsonl"
    fails_path = out_path.with_name(out_path.stem + "_failures.jsonl")

    problems = load_problems(args.problems)
    problems = problems[args.offset:]
    if args.limit:
        problems = problems[: args.limit]
    if args.shards > 1:
        problems = problems[args.shard :: args.shards]

    print(f"[plan] {len(problems)} problems, backend={backend.name}, model={args.model}, out={out_path.relative_to(REPO)}", flush=True)
    if args.dry_run:
        for p in problems:
            print(f"  {p['id']}: {p['problem'][:80]}...")
        return 0

    out_path.parent.mkdir(parents=True, exist_ok=True)
    existing = set()
    if out_path.exists():
        for line in out_path.read_text().splitlines():
            if line.strip():
                try:
                    existing.add(json.loads(line)["id"])
                except Exception:
                    pass

    tries = args.tries
    fix_tries = args.fix_tries
    timeout = args.timeout

    def log_fail(rid, attempt, stage, err, code=None):
        row = {"id": rid, "attempt": attempt, "stage": stage, "error": err[:500], "ts": datetime.now().isoformat()}
        if code is not None:
            row["code"] = code
        with fails_path.open("a") as fh:
            fh.write(json.dumps(row) + "\n")

    n_ok = n_fail = n_skip = 0
    t0 = time.perf_counter()
    tag = f"osp_{backend.name}_{model_core.replace('/', '_').replace(':', '_')[:24]}"
    variants = args.variants
    items = []
    if variants:
        passed = [p for p in problems if f"{p['id']}__{backend.name}" in existing or p["id"] in existing]
        # variant ids mirror legacy: <rid>__luna_vK etc — use backend name for uniqueness
        for p in passed:
            for v in range(1, variants + 1):
                vid = f"{p['id']}__{backend.name}_v{v}"
                if vid not in existing:
                    items.append((p, v))
    else:
        items = [(p, 0) for p in problems]

    with tempfile.TemporaryDirectory(prefix="osp_codegen_") as tmp:
        for idx, (prob, vn) in enumerate(items, 1):
            rid = prob["id"]
            full_id = rid if vn == 0 else f"{rid}__{backend.name}_v{vn}"
            tag_id = rid if vn == 0 else f"{rid}#v{vn}"
            if full_id in existing:
                n_skip += 1
                continue
            work = Path(tmp) / full_id.replace("/", "_")
            work.mkdir(exist_ok=True)
            code = None
            prev = None
            last_err = "not attempted"
            passed = False
            for attempt in range(1 + fix_tries):
                if code is None:
                    prompt = _user(prob["problem"]) if attempt == 0 else _fix_user(prob["problem"], prev or "", last_err)
                    text, err, _usage = backend.call(SYSTEM, prompt, model_core, timeout, tries=tries)
                    if err or not text:
                        last_err = f"call: {err or 'empty'}"
                        continue
                    prev = extract_jac(text)
                    if prev is None:
                        last_err = "no ```jac fence"
                        continue
                    code = prev
                ok, msg = jac_check(code, work)
                if ok:
                    ok, msg = osp_contract(code)
                if ok:
                    passed = True
                    break
                last_err = msg.strip().splitlines()[0] if msg.strip() else "unknown"
                log_fail(full_id, attempt, "gate", last_err, code)
                print(f"[{idx:3d}/{len(items)}] {tag_id} gate-fail {attempt+1}/{1+fix_tries} ({last_err})", flush=True)
                code = None
            if not passed:
                print(f"[{idx:3d}/{len(items)}] {tag_id} FAIL ({last_err})", flush=True)
                log_fail(full_id, 1 + fix_tries, "final", last_err, None)
                n_fail += 1
                continue
            row = {
                "id": full_id, "category": "code_gen", "task_type": "osp",
                "complexity": "medium", "compiler_pass": True, "test_pass": None,
                "manually_reviewed": False, "generator": backend.name,
                "generator_model_id": args.model, "gate_class": "compile_only",
                "variant_idx": vn, "generation_date": datetime.now().isoformat(),
                "source_prompt_version": "osp-ref-v1",
                "context_bundle_version": "jac-osp-reference-2025",
                "validator_version": "jac-0.36.1-check",
                "dataset_version": "jac-synth-v2.0.0", "run_tag": tag,
                "messages": [{"role": "user", "content": prob["problem"].strip()},
                             {"role": "assistant", "content": f"```jac\n{code.rstrip()}\n```"}],
            }
            with out_path.open("a") as fh:
                fh.write(json.dumps(row) + "\n")
            n_ok += 1
            print(f"[{idx:3d}/{len(items)}] {tag_id} OK ({n_ok} pass / {n_fail} fail / {n_skip} skip / {time.perf_counter()-t0:.1f}s)", flush=True)

    print(f"[stats] pass={n_ok} fail={n_fail} skip={n_skip} wall={time.perf_counter()-t0:.1f}s")
    return 0 if n_fail == 0 else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--task", choices=["idiomize", "codegen"], default="idiomize",
                    help="idiomize: issue_gen lift (py->jac); codegen: problem->jac")
    ap.add_argument("--backend", default="auto",
                    help="pi|cursor|zen|openrouter|auto (auto keeps luna->pi compat)")
    ap.add_argument("--model", default="composer-2.5",
                    help="model id; prefix pi:/cursor:/zen:/openrouter: forces backend")
    # idiomize passthrough
    ap.add_argument("--batch", type=int)
    ap.add_argument("--repo")
    ap.add_argument("--issue", type=int)
    ap.add_argument("--flow", choices=["py-first", "jac-first", "jac-only"], default="jac-only")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--chunk", type=int, default=10)
    # codegen passthrough
    ap.add_argument("--out")
    ap.add_argument("--problems")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--variants", type=int, default=0)
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("--tries", type=int, default=3)
    ap.add_argument("--fix-tries", type=int, default=2)
    args = ap.parse_args()

    if args.task == "idiomize":
        return _dispatch_idiomize(args)
    return _dispatch_codegen(args)


if __name__ == "__main__":
    sys.exit(main())
