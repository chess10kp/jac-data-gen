#!/usr/bin/env python3
"""Generate OSP records with openai/gpt-5.6-luna via OpenRouter (paid).

Sibling of osp_minimax_generate.py / osp_glm_generate.py — same gates
(imported from the minimax module), same row schema, own id suffix so
models coexist on one dataset without colliding on skip-by-id.

Env knobs:
  GPT_OR_KEY     OpenRouter api key   [~/.secrets OPENROUTER_API_KEY]
  GPT_MAXTOK     max_tokens per call  [4096]
  GPT_TEMP       temperature          [0.7]
  GPT_TIMEOUT    per-call seconds     [180]
  GPT_TRIES      retries on 429/5xx   [4]
  GPT_FIX        repair attempts      [2]
  OSP_GPT_OUT    output jsonl         [data/osp_dataset.jsonl]
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "gen"))
import osp_minimax_generate as mm3  # noqa: E402  (gates + prompts, single source)

MODEL = "openai/gpt-5.6-luna"
TAG = "osp_gpt_5_6_luna"
assert MODEL == "openai/gpt-5.6-luna", "model locked"
OUT = Path(os.environ.get("OSP_GPT_OUT", REPO / "data" / "osp_dataset.jsonl"))
FAILS = REPO / "data" / "osp_gpt_failures.jsonl"
TEMP = float(os.environ.get("GPT_TEMP", "0.7"))
TIMEOUT = int(os.environ.get("GPT_TIMEOUT", "180"))
TRIES = int(os.environ.get("GPT_TRIES", "4"))
MAXTOK = int(os.environ.get("GPT_MAXTOK", "4096"))
FIX_TRIES = int(os.environ.get("GPT_FIX", "2"))
OR_BASE = "https://openrouter.ai/api/v1"


def _or_key() -> str:
    k = os.environ.get("GPT_OR_KEY")
    if k:
        return k
    for rc in (Path.home() / ".secrets", Path.home() / ".secrets.env"):
        if rc.exists():
            for ln in rc.read_text().splitlines():
                if ln.startswith("OPENROUTER_API_KEY="):
                    return ln.split("=", 1)[1].strip().strip('"').strip("'")
    raise RuntimeError("OpenRouter key not found (set GPT_OR_KEY)")


def call_gpt(system: str, user: str) -> tuple[str | None, str | None]:
    """Return (content, error). Retries on 429/5xx; fails fast on 4xx."""
    import httpx
    body = {
        "model": MODEL,
        "messages": [{"role": "system", "content": system},
                     {"role": "user", "content": user}],
        "max_tokens": MAXTOK,
        "temperature": TEMP,
    }
    last_err: str | None = None
    for attempt in range(TRIES):
        try:
            r = httpx.post(f"{OR_BASE}/chat/completions", headers={
                "Authorization": f"Bearer {_or_key()}",
                "Content-Type": "application/json",
            }, json=body, timeout=TIMEOUT)
        except (httpx.TimeoutException, httpx.HTTPError) as e:
            last_err = f"transport: {type(e).__name__}: {e}"
            time.sleep(2 ** attempt)
            continue
        if r.status_code in (429, 500, 502, 503, 504):
            last_err = f"http {r.status_code}: {r.text[:160]}"
            time.sleep(2 ** attempt)
            continue
        if 400 <= r.status_code < 500:
            # 402 = out of credits: no point retrying anything else either
            return None, f"http {r.status_code}: {r.text[:200]}"
        try:
            payload = r.json()
            content = payload["choices"][0]["message"]["content"] or ""
        except Exception as e:
            return None, f"malformed payload: {e}"
        if not content.strip():
            last_err = "empty content"
            time.sleep(2 ** attempt)
            continue
        return content, None
    return None, last_err or "exhausted retries"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--problems", required=True,
                    help="jsonl file with {id, problem} records")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1)
    args = ap.parse_args()

    problems = mm3.load_problems(args.problems)
    problems = problems[args.offset:]
    if args.limit:
        problems = problems[: args.limit]
    items = [(p, 0) for p in problems][args.shard::args.shards]

    print(f"[plan] {len(items)} problems, model={MODEL}, "
          f"out={os.path.relpath(OUT, REPO)}", flush=True)
    if args.dry_run:
        for p in items:
            print(f"  {p[0]['id']}__gpt: {p[0]['problem'][:70]}...")
        return 0

    OUT.parent.mkdir(parents=True, exist_ok=True)
    FAILS.parent.mkdir(parents=True, exist_ok=True)

    # GPT rows are suffixed __gpt; skip anything already banked.
    existing: set[str] = set()
    if OUT.exists():
        for line in OUT.read_text().splitlines():
            if not line.strip():
                continue
            try:
                existing.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                continue

    def log_failure(rid: str, stage: str, error: str, code: str | None) -> None:
        row = {"id": rid, "stage": stage, "error": error[:500],
               "ts": datetime.now().isoformat()}
        if code is not None:
            row["code"] = code
        with FAILS.open("a") as fh:
            fh.write(json.dumps(row) + "\n")

    n_ok = n_fail = n_skip = 0
    t0 = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="osp_gpt_") as tmp:
        for idx, (prob, _vn) in enumerate(items, 1):
            rid = f"{prob['id']}__gpt"
            if rid in existing:
                n_skip += 1
                continue
            work = Path(tmp) / prob["id"]
            work.mkdir(exist_ok=True)
            code: str | None = None
            prev_code: str | None = None
            last_err = "not attempted"
            passed = False
            for attempt in range(1 + FIX_TRIES):
                if code is None:
                    prompt = (mm3._user(prob["problem"]) if attempt == 0 else
                              mm3._fix_user(prob["problem"], prev_code or "",
                                            last_err))
                    content, err = call_gpt(mm3.SYSTEM, prompt)
                    if err or not content:
                        last_err = f"call: {err or 'empty response'}"
                        if "http 402" in last_err:
                            print(f"[{idx}] OUT OF CREDITS — stopping", flush=True)
                            return 2
                        continue
                    prev_code = mm3.extract_jac(content)
                    if prev_code is None:
                        last_err = "no ```jac fence in response"
                        continue
                    code = prev_code
                ok, log = mm3.jac_check(code, work)
                if ok:
                    ok, log = mm3.osp_contract(code)
                if ok:
                    passed = True
                    break
                last_err = log.strip().splitlines()[0] if log.strip() else "unknown"
                log_failure(rid, "gate", last_err, code)
                print(f"[{idx:3d}/{len(items)}] {prob['id']} gate-fail "
                      f"{attempt + 1}/{1 + FIX_TRIES} ({last_err})", flush=True)
                code = None
            if not passed:
                print(f"[{idx:3d}/{len(items)}] {prob['id']} FAIL ({last_err})",
                      flush=True)
                log_failure(rid, "final", last_err, None)
                n_fail += 1
                continue
            row = {
                "id": rid,
                "category": "code_gen",
                "task_type": "osp",
                "complexity": "medium",
                "compiler_pass": True,
                "test_pass": None,
                "manually_reviewed": False,
                "generator": "openrouter",
                "generator_model_id": MODEL,
                "gate_class": "compile_only",
                "variant_idx": 0,
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
            with OUT.open("a") as fh:
                fh.write(json.dumps(row) + "\n")
            n_ok += 1
            elapsed = time.perf_counter() - t0
            print(f"[{idx:3d}/{len(items)}] {prob['id']} OK  "
                  f"({n_ok} pass / {n_fail} fail / {n_skip} skip / "
                  f"{elapsed:.1f}s)", flush=True)

    total = time.perf_counter() - t0
    print(f"[stats] pass={n_ok} fail={n_fail} skip={n_skip} wall={total:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
