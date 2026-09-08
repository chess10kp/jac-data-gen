#!/usr/bin/env python3
"""Oracle synthesis: strengthen a record's hidden-test suite until the mutation
gate clears, instead of rejecting the record as `weak_oracle`.

Why: keep-rate was capped by whether humans happened to write good tests. The
floor is KNOWN-correct (it passed its hidden tests), so any test that PASSES
against the floor has correct expectations by construction — we can safely
generate tests with a model, keep only floor-passers, and iterate until the
mutation gate (killed/eligible >= threshold) clears. The gate becomes a
convergence target, not a filter.

Loop per round:
  1. score current suite (early-exit gate mode: cheap when weak)
  2. ask the model for N new edge-case test blocks (deterministic, concrete)
  3. validate each against the unmutated floor via `jac test`; drop failures
  4. append survivors, rescore; stop at gate or max_rounds

Reusable API:  suite, rounds, added = strengthen_oracle(floor_fn, test_blocks, ...)
"""
from __future__ import annotations
import os
import re
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
_SP = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(_SP / "lib"))
sys.path.insert(0, str(_SP / "gen"))
from idiomize_seam import FENCE  # noqa: E402
from step4_mutation import mutation_score, _run_test  # noqa: E402

import json  # noqa: E402
import subprocess  # noqa: E402
import time  # noqa: E402

_MODEL = os.environ.get("CURSOR_SYNTH_MODEL", "composer-2.5")
_CURSOR_WS = "/tmp/cursor_ws"
_CURSOR_TMP = "/tmp/cursor_tmp"

_SYNTH_SYSTEM = """You are an expert Jac engineer writing unit tests. HARD RULES:
1. Output ONLY ```jac fenced blocks containing `test "..." { ... }` blocks.
   Syntax: test "name" { assert (expr == expected);; } — braces + semicolons,
   exactly like the existing tests shown. NEVER Python indentation.
2. Tests must call ONLY the function shown (by its exact name) with CONCRETE
   literal arguments — no imports, no helpers, no I/O, no randomness.
3. Every assert compares against the EXACT expected value you derive from the
   Python source semantics. Be precise: full strings, exact numbers.
4. Deterministic only: same input always yields the asserted output.
5. Target UNTESTED behaviors: empty inputs, single elements, negatives, zero,
   boundary sizes, type variants, both branches of every conditional.
6. Write exactly the number of test blocks requested. No prose."""


def _synth_user(floor_fn: str, entry: str, py: str,
                existing: str, n: int) -> str:
    return (
        f"### Python source (ground truth for behavior)\n```python\n{py}\n```\n\n"
        f"### Function under test (Jac floor)\n```jac\n{floor_fn}\n```\n\n"
        f"### Existing test blocks — do NOT duplicate these cases\n"
        f"```jac\n{existing}\n```\n\n"
        f"Write {n} NEW `test` blocks for `{entry}` covering untested edge cases."
    )


def _extract_test_blocks(text: str) -> list[str]:
    """Pull `test \"...\" {...}` blocks out of model output (fenced or bare)."""
    body = "\n".join(FENCE.findall(text or "")) if "```" in (text or "") else (text or "")
    return [m.group(0).strip()
            for m in re.finditer(r'test\s+"[^"]*"\s*\{.*?\n\}', body, re.S)]


def synthesize_tests(floor_fn: str, entry: str, py: str,
                     existing: str, n: int = 4,
                     temperature: float = 0.7) -> list[str]:
    """Ask the model for n new test blocks (unvalidated) via cursor-cli."""
    from pathlib import Path as _Path
    prompt = _SYNTH_SYSTEM + "\n\n" + _synth_user(floor_fn, entry, py, existing, n)
    _Path(_CURSOR_WS).mkdir(parents=True, exist_ok=True)
    _Path(_CURSOR_TMP).mkdir(parents=True, exist_ok=True)
    argv = ["cursor-agent", "--print", "--output-format", "json", "--mode", "ask",
            "--trust", "--model", _MODEL, "--workspace", _CURSOR_WS, prompt]
    env = {**os.environ, "TMPDIR": _CURSOR_TMP}
    content = ""
    for attempt in range(3):
        try:
            p = subprocess.run(argv, capture_output=True, text=True, timeout=180, env=env)
            if p.stdout.strip():
                try:
                    d = json.loads(p.stdout)
                    content = d.get("result") or p.stdout
                except Exception:  # noqa: BLE001
                    content = p.stdout
                if content.strip():
                    break
            time.sleep(1.5 * (attempt + 1))
        except Exception:  # noqa: BLE001
            time.sleep(1.5 * (attempt + 1))
    return _extract_test_blocks(content)


def _passes_floor(floor_fn: str, test_block: str) -> bool:
    """A test block is valid iff it passes against the KNOWN-correct floor."""
    src = floor_fn.rstrip() + "\n\n" + test_block.strip() + "\n"
    rc, _out = _run_test(src)
    return rc == 0


def strengthen_oracle(floor_fn: str, test_blocks: str, entry: str, py: str,
                      gate: float = 0.80, max_rounds: int = 3,
                      tests_per_round: int = 4
                      ) -> tuple[str, int, int, float]:
    """Iteratively grow `test_blocks` until the mutation gate clears.

    Returns (final_test_blocks, rounds_used, tests_added, final_score).
    """
    suite = test_blocks.strip()

    def score_now() -> tuple[float, bool]:
        ms = mutation_score(floor_fn, suite, cap=int(
            os.environ.get("OXALPHA_MUTANT_CAP", "40")), workers=2)
        return ms.score, (ms.eligible > 0 and ms.score >= gate)

    sc, ok = score_now()
    if ok:
        return suite, 0, 0, sc

    added = 0
    for rnd in range(1, max_rounds + 1):
        cands = synthesize_tests(floor_fn, entry, py, suite, tests_per_round)
        fresh = 0
        for tb in cands:
            norm = re.sub(r"\s+", "", tb)
            if norm in re.sub(r"\s+", "", suite):
                continue                                   # duplicate case
            if _passes_floor(floor_fn, tb):
                suite = suite.rstrip() + "\n\n" + tb
                added += 1
                fresh += 1
        if fresh == 0:
            continue                                       # nothing survived; retry round
        sc, ok = score_now()
        if ok:
            return suite, rnd, added, sc
    return suite, max_rounds, added, sc


if __name__ == "__main__":                                 # manual driver
    import argparse
    from oxalpha_free_generate import build_case, DATASET
    from datasets import load_dataset

    ap = argparse.ArgumentParser()
    ap.add_argument("rid", type=int)
    ap.add_argument("--gate", type=float, default=0.80)
    ap.add_argument("--rounds", type=int, default=3)
    args = ap.parse_args()
    os.environ.setdefault("HF_HUB_OFFLINE", "1")
    ds = load_dataset(DATASET, split="train")
    rec = next(r for r in ds if r["id"] == args.rid)
    c = build_case(rec)
    assert not isinstance(c, str), c
    suite, rounds, added, sc = strengthen_oracle(
        c["floor_fn"], c["test_blocks"], c["entry"], c["python"],
        gate=args.gate, max_rounds=args.rounds)
    print(f"rid={args.rid}: rounds={rounds} added={added} score={sc:.3f}")
