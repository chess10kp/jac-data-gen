#!/usr/bin/env python3
"""Step 4 mutation-testing gate: measure whether a record's Jac test suite is
strong enough to trust as the idiomize oracle.

Coverage tools don't exist for Jac, so we measure test STRENGTH directly: take
the known-correct floor function, inject small semantics-breaking mutations one
at a time, and run `jac test`. A mutant the suite catches (tests fail) is
"killed"; one that still passes "survived" — proof the suite can't tell that
bug from correct code. mutation_score = killed / eligible.

Outcome classification per mutant (from `jac test` rc + output):
  survived     rc == 0                         -> suite MISSED the bug (bad)
  killed       rc != 0 and a test/assert fired -> suite CAUGHT the bug (good)
  stillborn    rc != 0 but it failed to COMPILE/parse (not a real test signal)
               -> excluded from the denominator; a broken mutant proves nothing
  equivalent   mutant text identical to floor  -> skipped before running

Two ways to consume the score:
  - gate  (--gate T): a record needs killed/eligible >= T to be trusted for an
    idiomatic rewrite; below T, force floor. Early-exits on the FIRST survivor
    (one survivor already means "weak"), so weak records cost ~1-2 jac runs.
  - audit (default):  run all mutants, report the full score distribution. Use
    this to CALIBRATE the mutant set + threshold before wiring the gate in.

Reusable API:  score = mutation_score(floor_fn, test_blocks, ...)
CLI (calibration):  python scripts/step4_mutation.py [--gate 0.8] [ids...]
  With no ids, runs over every *.jac in archive/2026-09/scratch/step3/guard/.
"""
from __future__ import annotations
import argparse
import concurrent.futures as cf
import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
GUARD_DIR = REPO / "data" / "step4" / "guard"

# --------------------------------------------------------------------------- #
# Mutation operators. Each site in the function body yields ONE mutant with a
# single-point change, so a killed mutant maps to a specific caught bug.
# --------------------------------------------------------------------------- #
# Token-level swaps (matched longest-first so <= is not seen as <). Applied only
# to code, never inside strings/docstrings (those are masked out first).
_OP_SWAP = {
    "<=": "<", ">=": ">", "==": "!=", "!=": "==",
    "<": ">", ">": "<",
    "+": "-", "-": "+", "*": "/", "/": "*", "%": "*",
    "and": "or", "or": "and", "True": "False", "False": "True",
}
# `-(?!>)` and `(?<!-)>` skip the `->` return arrow (signature, not logic).
_OP_RE = re.compile(r"(<=|>=|==|!=|\band\b|\bor\b|\bTrue\b|\bFalse\b|"
                    r"<|(?<!-)>|-(?!>)|[+*/%])")
# Integer literals (off-by-one). Not preceded/followed by an identifier char or
# a dot (skip floats / attribute-ish tokens).
_INT_RE = re.compile(r"(?<![\w.])(\d+)(?![\w.])")

# --- structural / semantic operators (reach functions with no arith/compare) --
_COND_RE = re.compile(r"\b(if|elif|while)\s*\(")          # negate the condition
_ISNOT_RE = re.compile(r"\bis\s+not\b")
_IS_RE = re.compile(r"\bis\b(?!\s+not)")
_NOTIN_RE = re.compile(r"\bnot\s+in\b")
# Name swaps, scoped so we never touch a type annotation: builtins only when
# CALLED (`min(` not `: int`), methods only after a dot (`.lower(`).
# NB: int<->float deliberately excluded — `int("60")` vs `float("60")` compare
# equal under `==`, so the swap is an EQUIVALENT mutant that no suite can kill;
# including it manufactures false "weak" flags. min/max/sorted/reversed are
# genuinely non-equivalent.
_CALL_SWAP = {"min": "max", "max": "min", "sorted": "reversed"}
_CALL_RE = re.compile(r"\b(min|max|sorted)\s*\(")
_METH_SWAP = {"lower": "upper", "upper": "lower",
              "startswith": "endswith", "endswith": "startswith"}
_METH_RE = re.compile(r"\.(lower|upper|startswith|endswith)\b")
# Flat (non-nested) list/tuple literal with >=2 elements -> drop first element.
_SEQ_RE = re.compile(r"([\[(])([^\[\]()]*,[^\[\]()]*)([\])])")


def _match_paren(s: str, open_idx: int) -> int | None:
    """Index of the `)` matching the `(` at open_idx, or None."""
    depth = 0
    for i in range(open_idx, len(s)):
        if s[i] == "(":
            depth += 1
        elif s[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    return None
# String / docstring spans to mask so operators inside them are never mutated.
_STR_RE = re.compile(r'"""(?:.|\n)*?"""|\'\'\'(?:.|\n)*?\'\'\'|"[^"\n]*"|\'[^\'\n]*\'')


def _mask_strings(src: str) -> str:
    """Replace string spans with same-length filler so op offsets stay aligned
    but no operator inside a literal is ever matched."""
    return _STR_RE.sub(lambda m: " " * (m.end() - m.start()), src)


@dataclass
class Mutant:
    desc: str          # e.g. "op < -> > @142"
    src: str           # full mutated function source


def generate_mutants(floor_fn: str, cap: int = 40) -> list[Mutant]:
    """One single-point mutant per eligible site in the function body."""
    masked = _mask_strings(floor_fn)
    seen: set[str] = set()
    mutants: list[Mutant] = []
    # Body starts at the first `{` after `def` — never mutate the signature
    # (params, return type) or the docstring above it; that's not logic.
    _def = floor_fn.find("def ")
    body_start = floor_fn.find("{", _def) if _def != -1 else 0

    def add(start: int, end: int, repl: str, desc: str):
        if start < body_start:
            return
        mutated = floor_fn[:start] + repl + floor_fn[end:]
        if mutated == floor_fn or mutated in seen:
            return
        seen.add(mutated)
        mutants.append(Mutant(desc, mutated))

    def line_prefix(i: int) -> str:
        return masked[masked.rfind("\n", 0, i) + 1:i].rstrip()

    for m in _OP_RE.finditer(masked):
        tok = m.group(0)
        repl = _OP_SWAP.get(tok)
        if repl is None:
            continue
        if tok == "%":
            # Skip the string-format `%`: after masking, a modulo has an
            # operand (alnum/`)`/`]`/`}`) to its left; a format string has
            # none. Look back over whitespace/newlines so multi-line format
            # expressions (`...\n% setting`) still mutate (2026-08-21: the
            # same-line-only check zeroed out entire records).
            pre = masked[:m.start()].rstrip()
            if not pre or not (pre[-1].isalnum() or pre[-1] in ")]}_"):
                continue
        add(m.start(), m.end(), repl, f"op {tok}->{repl} @{m.start()}")

    for m in _INT_RE.finditer(masked):
        val = int(m.group(1))
        add(m.start(), m.end(), str(val + 1), f"int {val}->{val + 1} @{m.start()}")

    # Condition negation: if/elif/while (COND) -> (not (COND)).
    for m in _COND_RE.finditer(masked):
        op = m.end() - 1                       # index of '('
        close = _match_paren(masked, op)
        if close is None:
            continue
        inner = floor_fn[op + 1:close]
        add(op, close + 1, f"(not ({inner}))", f"negate {m.group(1)} @{op}")

    # is / is-not / not-in swaps.
    for m in _ISNOT_RE.finditer(masked):
        add(m.start(), m.end(), "is", f"is-not->is @{m.start()}")
    for m in _IS_RE.finditer(masked):
        add(m.start(), m.end(), "is not", f"is->is-not @{m.start()}")
    for m in _NOTIN_RE.finditer(masked):
        add(m.start(), m.end(), "in", f"not-in->in @{m.start()}")

    # Called-builtin and method-name swaps (annotation-safe).
    for m in _CALL_RE.finditer(masked):
        name = m.group(1)
        add(m.start(1), m.end(1), _CALL_SWAP[name], f"call {name}->{_CALL_SWAP[name]} @{m.start(1)}")
    for m in _METH_RE.finditer(masked):
        name = m.group(1)
        add(m.start(1), m.end(1), _METH_SWAP[name], f"meth {name}->{_METH_SWAP[name]} @{m.start(1)}")

    # Drop the first element of a flat list/tuple literal (rescues constant
    # collection returns that have no operators to mutate).
    for m in _SEQ_RE.finditer(masked):
        body = floor_fn[m.start(2):m.end(2)]
        rest = body.split(",", 1)[1].lstrip()  # everything after the 1st element
        add(m.start(2), m.end(2), rest, f"drop-elem @{m.start(2)}")

    return mutants[:cap]


# --------------------------------------------------------------------------- #
# Running mutants through `jac test`.
# --------------------------------------------------------------------------- #
# A nonzero rc whose output shows a compile/parse failure means the mutant never
# ran — it proves nothing about the suite, so we exclude it (stillborn).
_COMPILE_ERR = re.compile(
    r"SyntaxError|JacParseError|jac\.core|ParseError|not defined|"
    r"unexpected|invalid syntax|compilation failed", re.I)
_ASSERT_HIT = re.compile(r"assert|fail|error", re.I)


def _classify(rc: int, out: str) -> str:
    if rc == 0:
        return "survived"
    if _COMPILE_ERR.search(out) and not re.search(r"AssertionError", out):
        return "stillborn"
    return "killed"


def _run_test(src: str) -> tuple[int, str]:
    # 3GB address-space cap per mutant run: see step4_full_loop._run — a runaway
    # `jac test` must die with MemoryError, not OOM-freeze the box (Aug 20).
    cap = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30
    with tempfile.TemporaryDirectory(prefix="mut_") as tmp:
        f = Path(tmp) / "m.jac"
        f.write_text(src)
        # Skip the doomed native-lowering attempt: mutant floors are
        # py2jac-derived and demote anyway; the attempt burned ~24s CPU each
        # (measured 2026-08-21, see oxalpha_free_generate.jac_test).
        (Path(tmp) / "jac.toml").write_text(
            '[build]\ndefault_codespace = "server"\n')  # [placement] is legacy/dropped (2026-08-31 jac rebuild)
        try:
            p = subprocess.run(["prlimit", f"--as={cap}", "--",
                                JAC, "test", str(f)], capture_output=True,
                               text=True, cwd=tmp, timeout=120)
        except subprocess.TimeoutExpired:
            return 1, "timeout"          # a hang counts as caught (killed)
        return p.returncode, (p.stdout + p.stderr)


@dataclass
class ScoreResult:
    killed: int = 0
    survived: int = 0
    stillborn: int = 0
    survivors: list[str] = field(default_factory=list)
    total_run: int = 0

    @property
    def eligible(self) -> int:
        return self.killed + self.survived

    @property
    def score(self) -> float:
        return self.killed / self.eligible if self.eligible else 0.0


def mutation_score(floor_fn: str, test_blocks: str, *, cap: int = 40,
                   gate: float | None = None, workers: int = 8) -> ScoreResult:
    """Run mutants of `floor_fn` against `test_blocks`.

    gate is None  -> audit: run all mutants, full distribution.
    gate is a float -> stop at the FIRST survivor (record already fails the gate);
                       cheap for weak records.
    """
    mutants = generate_mutants(floor_fn, cap=cap)
    res = ScoreResult()

    def make_file(mut: Mutant) -> str:
        return mut.src.rstrip() + "\n\n" + test_blocks.strip() + "\n"

    if gate is not None:
        # Sequential + early-exit: bail the moment a mutant survives.
        for mut in mutants:
            rc, out = _run_test(make_file(mut))
            res.total_run += 1
            cls = _classify(rc, out)
            if cls == "survived":
                res.survived += 1
                res.survivors.append(mut.desc)
                return res
            if cls == "stillborn":
                res.stillborn += 1
            else:
                res.killed += 1
        return res

    # Audit: run everything, in parallel.
    with cf.ThreadPoolExecutor(max_workers=workers) as ex:
        for mut, (rc, out) in zip(mutants, ex.map(lambda m: _run_test(make_file(m)), mutants)):
            res.total_run += 1
            cls = _classify(rc, out)
            if cls == "survived":
                res.survived += 1
                res.survivors.append(mut.desc)
            elif cls == "stillborn":
                res.stillborn += 1
            else:
                res.killed += 1
    return res


def split_guard(guard_src: str) -> tuple[str, str]:
    """A guard file is `<function>\\n\\ntest "..." {...}...`. Split at first test."""
    m = re.search(r'\ntest\s+"', guard_src)
    if not m:
        return guard_src.rstrip(), ""
    return guard_src[: m.start()].rstrip(), guard_src[m.start():].strip()


# --------------------------------------------------------------------------- #
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="*", help="record ids; default = all guard/*.jac")
    ap.add_argument("--gate", type=float, default=None,
                    help="gate mode threshold (early-exit on first survivor)")
    ap.add_argument("--cap", type=int, default=40, help="max mutants per record")
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--json", type=Path, help="write per-record results here")
    args = ap.parse_args()

    if args.ids:
        files = [GUARD_DIR / f"{i}.jac" for i in args.ids]
    else:
        files = sorted((p for p in GUARD_DIR.glob("*.jac") if p.stem.isdigit()),
                       key=lambda p: int(p.stem))

    rows = []
    print(f"{'id':>8}  {'score':>6}  {'kill/elig':>9}  {'still':>5}  survivors")
    print("-" * 72)
    for f in files:
        if not f.exists():
            print(f"{f.stem:>8}  MISSING"); continue
        floor_fn, tests = split_guard(f.read_text())
        r = mutation_score(floor_fn, tests, cap=args.cap, gate=args.gate,
                           workers=args.workers)
        surv = ", ".join(r.survivors[:4]) + ("…" if len(r.survivors) > 4 else "")
        print(f"{f.stem:>8}  {r.score:6.0%}  {r.killed:>4}/{r.eligible:<4}  "
              f"{r.stillborn:>5}  {surv}")
        rows.append({"id": int(f.stem), "score": round(r.score, 3),
                     "killed": r.killed, "survived": r.survived,
                     "eligible": r.eligible, "stillborn": r.stillborn,
                     "total_run": r.total_run, "survivors": r.survivors})

    if rows:
        scored = [x for x in rows if x["eligible"] > 0]
        if scored:
            mean = sum(x["score"] for x in scored) / len(scored)
            weak = [x for x in scored if x["score"] < (args.gate or 0.8)]
            print("-" * 72)
            print(f"records={len(rows)}  scored={len(scored)}  "
                  f"mean_score={mean:.0%}  "
                  f"weak(<{args.gate or 0.8:.0%})={len(weak)} "
                  f"-> {[x['id'] for x in weak]}")
    if args.json and rows:
        args.json.write_text("\n".join(json.dumps(x) for x in rows) + "\n")
        print(f"wrote {args.json}")


if __name__ == "__main__":
    main()
