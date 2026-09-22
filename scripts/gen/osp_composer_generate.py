#!/usr/bin/env python3
"""Generate OSP variants with composer-2.5 via cursor-agent.

Sibling of osp_minimax_generate.py: same 100 problems, same enriched SYSTEM
prompt, same `jac check`+`jac run`+OSP-contract gates, same dataset row
schema, appended to the same data/osp_dataset.jsonl. Only the backend differs
(cursor-agent composer-2.5, the reference batch's generator, instead of the
OpenRouter free model), plus provenance fields:

  ids        `<rid>__composer_vK`  (minimax uses `__mm3_vK` -> no collisions)
  run_tag    osp_composer_2_5
  failures   data/osp_composer_failures.jsonl (per-model repair-pair provenance)

Every cursor call is ledgered to data/run_ledger.sqlite3 via
scripts/lib/generation_ledger.py (one row per attempt, all outcomes).
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))

import generation_ledger  # noqa: E402
import osp_minimax_generate as mm  # noqa: E402

REPO = mm.REPO
OUT = Path(os.environ.get("OSP_COMPOSER_OUT", REPO / "data" / "osp_dataset.jsonl"))
FAILS = REPO / "data" / "osp_composer_failures.jsonl"
# MODEL IS LOCKED. Do not parameterize this script for other models; if
# another model is needed, write a separate sibling script.
MODEL = "composer-2.5"
TAG = "osp_composer_2_5"
SUF = "composer"
assert MODEL == "composer-2.5", "model locked"
TIMEOUT = int(os.environ.get("OSP_COMPOSER_TIMEOUT", "300"))
TRIES = int(os.environ.get("OSP_COMPOSER_TRIES", "2"))
FIX_TRIES = int(os.environ.get("OSP_COMPOSER_FIX", "2"))
CURSOR_WS = os.environ.get("CURSOR_OSP_WS", "/tmp/cursor_osp_ws_empty")
CURSOR_TMP = os.environ.get("CURSOR_OSP_TMP", "/tmp/cursor_osp_tmp")
ISO = os.environ.get("CURSOR_OSP_ISO", "1") != "0"
ISO_HOME = Path(os.environ.get("CURSOR_OSP_ISO_HOME", "/tmp/cursor_iso_home"))

from osp_agent_generate import _ensure_iso_home  # noqa: E402

_RUN_ID: str | None = None  # created lazily on first call so import has no side effect


def call_composer(system: str, user: str, tag: str,
                  pipeline: str = "osp-composer") -> tuple[str | None, str | None]:
    """One ledgered cursor-agent call. Returns (content, error)."""
    global _RUN_ID
    if _RUN_ID is None:
        _RUN_ID = generation_ledger.new_run("osp-composer", model=MODEL)
    prompt = f"{system}\n\n---\n\n{user}"
    Path(CURSOR_WS).mkdir(parents=True, exist_ok=True)
    Path(CURSOR_TMP).mkdir(parents=True, exist_ok=True)
    env = {**os.environ, "TMPDIR": CURSOR_TMP}
    if ISO:
        _ensure_iso_home()
        env["HOME"] = str(ISO_HOME)
        env["XDG_CONFIG_HOME"] = str(ISO_HOME / ".config")
    last_err: str | None = None
    for attempt in range(TRIES):
        t0 = time.perf_counter()
        usage: dict | None = None
        try:
            p = subprocess.run(
                ["cursor-agent", "--print", "--output-format", "json",
                 "--mode", "ask", "--trust", "--model", MODEL,
                 "--workspace", CURSOR_WS, prompt],
                capture_output=True, text=True, timeout=TIMEOUT, env=env)
        except subprocess.TimeoutExpired:
            last_err = f"timeout after {TIMEOUT}s"
            generation_ledger.record_call(
                _RUN_ID, pipeline=pipeline, status="timeout", model=MODEL,
                batch=tag, dur_s=time.perf_counter() - t0)
            continue
        dur = time.perf_counter() - t0
        if not p.stdout.strip():
            last_err = (p.stderr or "empty stdout").strip()[:300]
            generation_ledger.record_call(
                _RUN_ID, pipeline=pipeline, status="is_error", model=MODEL,
                batch=tag, error=last_err, dur_s=dur)
            time.sleep(5)
            continue
        try:
            d = json.loads(p.stdout)
        except json.JSONDecodeError as e:
            last_err = f"parse_error: {e}: {p.stdout[:200]}"
            generation_ledger.record_call(
                _RUN_ID, pipeline=pipeline, status="parse_error",
                model=MODEL, batch=tag, error=last_err, dur_s=dur)
            continue
        usage = d.get("usage")
        out = d.get("result") or ""
        status = "is_error" if d.get("is_error") else "ok"
        generation_ledger.record_call(
            _RUN_ID, pipeline=pipeline, status=status, model=MODEL,
            batch=tag, error=str(d.get("error") or "")[:400] or None,
            usage=usage, dur_s=dur)
        if status == "is_error":
            last_err = str(d.get("error") or "agent reported error")
            time.sleep(5)
            continue
        if not out.strip():
            last_err = "empty result"
            time.sleep(5)
            continue
        return out, None
    return None, last_err or "exhausted retries"


def log_failure(rid: str, attempt: int, stage: str, error: str,
                code: str | None) -> None:
    row = {"id": rid, "attempt": attempt, "stage": stage,
           "error": error[:500], "ts": datetime.now().isoformat()}
    if code is not None:
        row["code"] = code
    with FAILS.open("a") as fh:
        fh.write(json.dumps(row) + "\n")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=0,
                    help="stop after N problems (0 = all 100)")
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--problems", default=None,
                    help="jsonl file with {id, problem} records; replaces "
                         "the osp_examples group replay")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--variants", type=int, default=0,
                    help="generate N variant slots per already-passed problem "
                         "(ids `<rid>__composer_vK`, variant_idx=K)")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1,
                    help="split the work list across --shards workers; "
                         "this worker takes shard --shard")
    args = ap.parse_args()

    problems = mm.load_problems(args.problems)
    problems = problems[args.offset:]
    if args.limit:
        problems = problems[: args.limit]

    print(f"[plan] {len(problems)} problems, model={MODEL} (cursor-agent), "
          f"out={OUT.relative_to(REPO)}", flush=True)
    if args.dry_run:
        for p in problems:
            print(f"  {p['id']}: {p['problem'][:80]}...")
        return 0

    OUT.parent.mkdir(parents=True, exist_ok=True)
    FAILS.parent.mkdir(parents=True, exist_ok=True)

    existing_ids = set()
    if OUT.exists():
        for line in OUT.read_text().splitlines():
            if not line.strip():
                continue
            try:
                existing_ids.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                continue
    if args.variants:
        # Variant mode: only re-solve problems that already passed once as
        # either the composer reference batch (plain ids) or a composer base
        # record. Slots are owned by exactly one shard (index slicing), and
        # ids never collide with the minimax farm's `__mm3_vK` slots.
        passed = [p for p in problems if p["id"] in existing_ids
                  or f"{p['id']}__{SUF}" in existing_ids]
        items = [(p, n) for p in passed for n in range(1, args.variants + 1)
                 if f"{p['id']}__{SUF}_v{n}" not in existing_ids]
        items = items[args.shard::args.shards]
    else:
        items = [(p, 0) for p in problems][args.shard::args.shards]

    n_ok = n_fail = n_skip = 0
    t0 = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="osp_composer_") as tmp:
        for idx, (prob, vn) in enumerate(items, 1):
            rid = prob["id"]
            full_id = rid if vn == 0 else f"{rid}__{SUF}_v{vn}"
            tag = rid if vn == 0 else f"{rid}#v{vn}"
            if full_id in existing_ids:
                n_skip += 1
                continue
            work = Path(tmp) / full_id
            work.mkdir(exist_ok=True)
            code: str | None = None
            prev_code: str | None = None
            last_err = "not attempted"
            passed_flag = False
            for attempt in range(1 + FIX_TRIES):
                if code is None:
                    prompt = (mm._user(prob["problem"]) if attempt == 0 else
                              mm._fix_user(prob["problem"], prev_code or "",
                                           last_err))
                    content, err = call_composer(mm.SYSTEM, prompt, full_id)
                    if err or not content:
                        last_err = f"call: {err or 'empty response'}"
                        continue
                    prev_code = mm.extract_jac(content)
                    if prev_code is None:
                        last_err = "no ```jac fence in response"
                        continue
                    code = prev_code
                ok, log = mm.jac_check(code, work)
                if ok:
                    ok, log = mm.osp_contract(code)
                if ok:
                    passed_flag = True
                    break
                last_err = log.strip().splitlines()[0] if log.strip() else "unknown"
                log_failure(full_id, attempt, "gate", last_err, code)
                print(f"[{idx:3d}/{len(items)}] {tag} gate-fail "
                      f"{attempt + 1}/{1 + FIX_TRIES} ({last_err})", flush=True)
                code = None
            if not passed_flag:
                print(f"[{idx:3d}/{len(items)}] {tag} FAIL ({last_err})",
                      flush=True)
                log_failure(full_id, 1 + FIX_TRIES, "final", last_err, None)
                n_fail += 1
                continue
            row = {
                "id": full_id,
                "category": "code_gen",
                "task_type": "osp",
                "complexity": "medium",
                "compiler_pass": True,
                "test_pass": None,
                "manually_reviewed": False,
                "generator": "cursor-cli",
                "generator_model_id": MODEL,
                "gate_class": "compile_only",
                "variant_idx": vn,
                "generation_date": datetime.now().isoformat(),
                "source_prompt_version": "osp-ref-v1",
                "context_bundle_version": "jac-osp-reference-2025",
                "validator_version": "jac-0.36.1-check",
                "dataset_version": "jac-synth-v2.0.0",
                "run_tag": TAG,
                "messages": [
                    {"role": "user", "content": prob["problem"].strip()},
                    {"role": "assistant", "content": f"```jac\n{code.rstrip()}\n```"},
                ],
            }
            # O_APPEND per-record write: a crash or early stop (e.g. hitting
            # the target count) keeps every completed record.
            with OUT.open("a") as fh:
                fh.write(json.dumps(row) + "\n")
            n_ok += 1
            elapsed = time.perf_counter() - t0
            print(f"[{idx:3d}/{len(items)}] {tag} OK  "
                  f"({n_ok} pass / {n_fail} fail / {n_skip} skip / "
                  f"{elapsed:.1f}s)", flush=True)

    print(f"\n[done] records in {OUT.relative_to(REPO)}")
    total = time.perf_counter() - t0
    print(f"[stats] pass={n_ok} fail={n_fail} skip={n_skip} wall={total:.1f}s")
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
