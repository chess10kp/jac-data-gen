#!/usr/bin/env python3
"""Repair wave for SEMANTIC_FAIL records: think-fix -> test -> review, in a loop.

For each dataset record whose LATEST verdict in data/osp_test_results.jsonl
is SEMANTIC_FAIL (default: base records only; --include-variants opts in):

  round (up to --rounds):
    1. FIX  — minimax/minimax-m3:free (imported client) rewrites the whole
       program given (problem, current program, failing test annex, pytest
       output). Max tokens raised so the reasoning model can think.
    2. TEST — `jac test` against the PERSISTED test annex from the sidecar
       (tests are ground truth; the fixer never rewrites them). EVERY
       candidate is tested — nothing is dropped on opinion.
    3. REVIEW — only for failed candidates: glm-5.3-flash (independent
       model family AND provider, via call_glm) critiques the proposal in
       strict JSON {"sound": bool, "issues": [...]}; the issues join the
       test output in the next round's fix prompt. Reviewer outage never
       blocks: its gate is advisory, the test gate is authoritative.
  PASS -> emit record to data/osp_repaired.jsonl (merge schema, run_tag
  osp_repair_m3_free). Exhausted rounds -> ledger rows in
  data/osp_repair_failures.jsonl.

Idempotent per id against the output file. Never touches data/osp_dataset.jsonl.

Usage:
  python3 osp_repair_wave.py --limit 40                 # pilot
  python3 osp_repair_wave.py --shard 0 --shards 6       # full wave
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "gen"))
from osp_minimax_generate import call_or, extract_jac  # noqa: E402
from osp_minimax_testgen import classify, jac_test  # noqa: E402
from osp_glm_generate import call_glm  # noqa: E402

DATASET = REPO / "data" / "osp_dataset.jsonl"
RESULTS = REPO / "data" / "osp_test_results.jsonl"
OUT = REPO / "data" / "osp_repaired.jsonl"
FAILS = REPO / "data" / "osp_repair_failures.jsonl"

FIXER = "minimax/minimax-m3:free"
FIXER_TAG = "osp_repair_m3_free"
DEFERRED = REPO / "data" / "osp_repair_deferred.jsonl"
TEMP = float(os.environ.get("OSP_REPAIR_TEMP", "0.5"))
TIMEOUT = int(os.environ.get("OSP_REPAIR_TIMEOUT", "180"))
TRIES = int(os.environ.get("OSP_REPAIR_TRIES", "3"))
MAXTOK = int(os.environ.get("OSP_REPAIR_MAXTOK", "8192"))  # headroom for reasoning
OFFLINE_MARKERS = ("ConnectError", "CERTIFICATE_VERIFY_FAILED", "Temporary failure in name resolution", "NameResolutionError", "Network is unreachable")

# Structural contract — mirrors osp_minimax_generate.SYSTEM (the skill you give manually).
# Repair was under-constrained (613 chars) vs generation (~4k); model drifted to fragments.
# This restores the 8 OSP invariants so the fixer emits complete, runnable Jac.
FIX_SYSTEM = """You are an expert Jac (Jaseci) engineer. You REPAIR a Jac program that compiles but fails its regression tests.

The tests are ground truth — they encode the behavior the original problem demands. NEVER propose changing the tests; rewrite the program.

OUTPUT CONTRACT — your response must contain exactly one ```jac ... ``` fenced block. No prose before or after the fence.

STRUCTURAL REQUIREMENTS (every repair must satisfy all of these — same as generation):
1. The module begins with a top-level docstring (`\"\"\"\"\"`) on the first line.
2. Entity archetypes are declared with `node Name { ... }` and have typed `has` fields with defaults: `has title: str = \"\";`, `has year: int = 0;`, `has available: bool = True;`. NEVER use `Any` or leave a field untyped.
3. Walker names are PascalCase (`Librarian`, `Hiker`, `OrderAuditor`). Ability signatures use `can <name> with <NodeType> entry { ... }` (or `exit`, or `Root entry`). A walker that visits multiple node types declares one ability per type (union `TypeA | TypeB` is allowed when the body only touches shared fields).
4. Walkers queue next BEFORE early exit. Pattern: `visit [-->] else { self.report(); disengage; }` at the top of the ability, then decide. At least one walker ability must end with `visit [-->];` (forward) or `visit [<--];` (backward). When the frontier may be empty use `visit [-->] else { disengage; }`. A walker ability that only prints and never `visit`s is NOT a real walker.
5. The module ends with a `with entry { ... }` block that wires the demo: creates nodes, connects them (`root ++> ... ++> ...`), and spawns the walker(s) on `root` (e.g. `root spawn Librarian();`). This demo is for humans — before `jac test` the harness deletes `with entry` so the shared `root` stays clean. For a summary after the walk, don't use a second `Root entry`; call `self.report()` when `visit` has no frontier (`else` branch).
6. Syntax is Jac, not Python. Statements end with `;`. Blocks use `{ ... }`. NO `def f():` style, NO `: pass` style, NO `if x:` style without braces. f-strings are written `f\"..."` exactly as in Jac.
7. Do NOT include pytest or jac test blocks; the demo IS the demonstration.
8. Every edge archetype you reference — in `visit [->:T:->]` or `a +>:T:+> b` — MUST be declared at module level as `edge T { ... }`. An empty body (`edge T { }`) is fine. NEVER write a typed visit or typed-edge connection whose name has no matching `edge` declaration.
IDIOM: typed edges where the relationship carries meaning (`a +>:Owner:+> b;`), `here` for current node, `self` for walker, `visit [...]` for traversal, `disengage;` for early termination. Computed ternaries must assign a fresh name — NEVER `x = \"a\" if cond else x;`.

Think step by step before answering: for each failing assertion, reason about what the program did versus what the test expected, locate the defect, then produce the full corrected program. Output ONLY the corrected program in one ```jac fence."""

FIX_USER = """PROBLEM (the program must satisfy this):

{problem}

CURRENT PROGRAM (compiles, but fails the tests below):

```jac
{code}
```

TEST ANNEX (ground truth — main.test.jac; do NOT rewrite it):

```jac
{tests}
```

FAILING TEST OUTPUT:

```
{error}
```

{critique}Rewrite the whole program in one ```jac fence so the tests pass."""

REVIEW_SYSTEM = """You are a strict Jac code reviewer. Given a problem, a
candidate program, and the regression tests it must pass, judge whether the
program actually implements the problem's promised behavior.

Answer with ONLY a JSON object, no prose, no fence:
{"sound": true}
or
{"sound": false, "issues": ["specific defect 1", "specific defect 2"]}"""

REVIEW_USER = """PROBLEM:

{problem}

CANDIDATE PROGRAM:

```jac
{code}
```

TESTS IT MUST PASS:

```jac
{tests}
```

This candidate just FAILED the tests. Their output (context):

```
{error}
```

Identify the concrete defects to fix in the next attempt. Reply with the JSON
object only."""

_JSON_OBJ = re.compile(r"\{.*\}", re.S)


def is_offline_error(err: str | None) -> bool:
    if not err:
        return False
    return any(m in err for m in OFFLINE_MARKERS)


def local_gate(cand: str) -> str | None:
    """Offline-capable static checks — no network needed. Returns critique or None."""
    if "visit [-->]" not in cand and "visit [<--]" not in cand:
        return "missing visit [-->] — walker never traverses"
    if cand.count("Root entry") > 1:
        return "two Root entry abilities — second never fires; use visit else { report } instead"
    if "with entry" in cand and "root ++>" in cand:
        return "with entry pollutes shared root — demo will be stripped before test but prefer local anchor"
    return None


def review(code: str, problem: str, tests: str, error: str) -> list[str]:
    """Advisory reviewer: returns issues for the next fix round ([] on outage)."""
    content, err = call_glm(REVIEW_SYSTEM, REVIEW_USER.format(
        problem=problem.strip(), code=code.strip(), tests=tests.strip(),
        error=(error or "none")[:1200]))
    if err or not content:
        return []
    m = _JSON_OBJ.search(content)
    if not m:
        return []
    try:
        obj = json.loads(m.group(0))
    except json.JSONDecodeError:
        return []
    return [str(i) for i in (obj.get("issues") or [])][:5]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--rounds", type=int, default=3)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--include-variants", action="store_true")
    ap.add_argument("--retry-failed", action="store_true",
                    help="also re-attempt ids already in the failures ledger")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1)
    args = ap.parse_args()

    rows = [json.loads(l) for l in DATASET.read_text().splitlines() if l.strip()]
    latest: dict[str, dict] = {}
    with RESULTS.open() as fh:
        for line in fh:
            if line.strip():
                r = json.loads(line)
                latest[r["id"]] = r  # last row per id wins

    targets = []
    for r in rows:
        if args.include_variants or r.get("variant_idx", 0) == 0:
            res = latest.get(r["id"])
            if res is not None and res.get("verdict") == "SEMANTIC_FAIL" and res.get("tests"):
                targets.append((r, res))
    targets = targets[args.offset:]
    if args.limit:
        targets = targets[: args.limit]
    items = targets[args.shard::args.shards]

    done: set[str] = set()
    for src in [OUT] + ([] if args.retry_failed else [FAILS]):
        if src.exists():
            for line in src.read_text().splitlines():
                if line.strip():
                    done.add(json.loads(line)["id"])

    print(f"[plan] {len(items)} sem-fail records to repair "
          f"(rounds={args.rounds}, fixer={FIXER}, reviewer=glm-5.3-flash, "
          f"{len(done)} already attempted)", flush=True)

    def ledger(rid: str, round_no: int, stage: str, error: str) -> None:
        with FAILS.open("a") as fh:
            fh.write(json.dumps({"id": rid, "round": round_no, "stage": stage,
                                 "error": error[:500],
                                 "ts": datetime.now().isoformat()}) + "\n")

    def defer(rid: str, round_no: int, err: str) -> None:
        with DEFERRED.open("a") as fh:
            fh.write(json.dumps({"id": rid, "round": round_no, "error": err[:500],
                                 "ts": datetime.now().isoformat()}) + "\n")

    n_ok = n_fail = n_skip = n_defer = 0
    offline_streak = 0
    t0 = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="osp_repair_") as tmp:
        for idx, (rec, res) in enumerate(items, 1):
            rid = rec["id"]
            if rid in done:
                n_skip += 1
                continue
            problem = rec["messages"][0]["content"]
            tests = res["tests"]
            code = extract_jac(rec["messages"][1]["content"])
            if code is None:
                ledger(rid, 0, "no-fence", "solution has no jac fence")
                n_fail += 1
                continue
            work = Path(tmp) / rid.replace("/", "_")
            work.mkdir(exist_ok=True)

            test_out = res.get("detail") or ""
            critique = ""
            # offline-capable pre-check before burning network
            gate_msg = local_gate(code)
            if gate_msg:
                critique = gate_msg
                # don't burn a fix call — feed gate directly into next round's prompt
            passed = False
            for rnd in range(1, args.rounds + 1):
                # 1. FIX (reasoning model, high token budget) — durable with fallback
                if not critique or "missing visit" not in critique.lower():
                    # only call LLM if not already holding a local gate critique
                    content, err = call_or(
                        FIXER, FIX_SYSTEM,
                        FIX_USER.format(problem=problem, code=code, tests=tests,
                                        error=test_out[:1800],
                                        critique=f"REVIEWER CRITIQUE of the previous attempt:\n"
                                                 f"{chr(10).join('- ' + i for i in critique)}\n\n"
                                                 if critique else ""),
                        TIMEOUT, MAXTOK, TEMP, 1)
                    if is_offline_error(err):
                        offline_streak += 1
                        defer(rid, rnd, err or "offline")
                        n_defer += 1
                        print(f"[{idx:3d}/{len(items)}] {rid} DEFERRED (offline, streak={offline_streak}) [{n_ok} repaired / {n_fail} still-fail / {n_skip} skip / {n_defer} deferred / {time.perf_counter()-t0:.1f}s]", flush=True)
                        if offline_streak >= 3:
                            print("[offline] 3 consecutive offline — pausing wave, progress saved. Re-run when online.", flush=True)
                            print(f"\n[stats] repaired={n_ok} still_fail={n_fail} skip={n_skip} deferred={n_defer} wall={time.perf_counter()-t0:.1f}s")
                            return 0
                        break  # try next id — keep rounds intact for this one
                    offline_streak = 0
                    if err or not content:
                        ledger(rid, rnd, "fix-call", f"call: {err or 'empty'}")
                        continue
                    cand = extract_jac(content)
                    if cand is None:
                        ledger(rid, rnd, "fix-fence", "no ```jac fence in response")
                        continue
                else:
                    # use local gate's critique to drive a fix without LLM; craft cand = code (will be re-fixed next rnd)
                    cand = code
                    # clear gate critique after first use so next round actually calls LLM
                    critique = ""
                    # fall through to TEST with existing code to surface real detail if gate was stale
                # 2. TEST (authoritative gate — every candidate gets a run; strip demo)
                rc, out = jac_test(cand, tests, work)
                verdict, detail = classify(out, rc)
                if verdict == "PASS":
                    new_rec = dict(rec)
                    new_rec["messages"] = [
                        {"role": "user", "content": problem.strip()},
                        {"role": "assistant", "content": f"```jac\n{cand.rstrip()}\n```"},
                    ]
                    new_rec["run_tag"] = FIXER_TAG
                    new_rec["generation_date"] = datetime.now().isoformat()
                    new_rec["test_pass"] = True
                    new_rec["test_verdict"] = "PASS"
                    new_rec["test_detail"] = detail[:300]
                    new_rec["test_run_tag"] = res.get("run_tag")
                    new_rec["repair_rounds"] = rnd
                    with OUT.open("a") as fh:
                        fh.write(json.dumps(new_rec) + "\n")
                    passed = True
                    break

                # 3. REVIEW (advice for the next round, never a veto) — skip if offline
                test_out = out[-1800:] if rc != 124 else detail
                code = cand
                # local gate takes precedence over remote review when offline
                gate_now = local_gate(cand)
                if gate_now:
                    critique = gate_now
                    ledger(rid, rnd, "review", critique[:500])
                else:
                    issues = review(cand, problem, tests, test_out)
                    if issues:
                        critique = "; ".join(issues)
                        ledger(rid, rnd, "review", critique[:500])
                    else:
                        critique = ""
                        ledger(rid, rnd, "test", detail)

            if passed:
                n_ok += 1
                mark = "REPAIRED"
            elif n_defer and offline_streak:
                mark = "DEFERRED"
                # don't count deferred as still-fail
                n_fail -= 1 if n_fail else 0  # offset increment below
                n_defer = n_defer  # keep
                # will have already printed DEFERRED; skip second print
                continue
            else:
                n_fail += 1
                mark = "STILL-FAIL"
            elapsed = time.perf_counter() - t0
            print(f"[{idx:3d}/{len(items)}] {rid} {mark} "
                  f"[{n_ok} repaired / {n_fail} still-fail / {n_skip} skip / {n_defer} deferred / "
                  f"{elapsed:.1f}s]", flush=True)

    print(f"\n[stats] repaired={n_ok} still_fail={n_fail} skip={n_skip} deferred={n_defer} "
          f"wall={time.perf_counter() - t0:.1f}s")
    return 0  # slice completed; still-fail is a normal outcome (see ledger)


if __name__ == "__main__":
    sys.exit(main())
