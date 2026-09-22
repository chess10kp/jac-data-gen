#!/usr/bin/env python3
"""Write Jac test annexes with minimax/minimax-m3:free and verify every
record in data/osp_dataset.jsonl via `jac test`.

Sibling of osp_minimax_generate.py (same locked model). For each dataset
record:
  1. prompt minimax with (problem, solution) to emit a `main.test.jac`
     annex — test blocks that see the solution's symbols without imports;
  2. run `jac test main.jac` in a fresh temp dir (parallel workers, persisted
     root — hence the fresh dir per record);
  3. classify the run:
       PASS          — all tests passed                      -> test_pass=True
       SEMANTIC_FAIL — collected >0 tests, AssertionError(s) -> test_pass=False
       HARNESS       — broken/incomplete test file (syntax
                       errors, no tests collected, non-
                       assertion exceptions)                  -> repair round
     Only HARNESS is repairable and retried; SEMANTIC_FAIL is the real
     signal we are mining (the solution runs but does not do what the
     problem says).


`--retry-fails` re-tests ids whose latest verdict is not PASS, with a fresh
prompt under the current SYSTEM prompt; consumers of the results log are
last-row-wins.
Results append to data/osp_test_results.jsonl (id-idempotent); broken-test
attempts append to data/osp_testgen_failures.jsonl (repair-training material,
same convention as the generator's failure log). The dataset's `test_pass`
field is folded in later by merge_osp_tests.py once generation waves settle —
the dataset is being appended concurrently by recovery shards.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATASET = REPO / "data" / "osp_dataset.jsonl"
RESULTS = REPO / "data" / "osp_test_results.jsonl"
FAILS = REPO / "data" / "osp_testgen_failures.jsonl"
SKIP_FILE = REPO / "data" / "osp_testgen_skip.txt"

MODEL = os.environ.get("OSP_TESTGEN_MODEL", "minimax/minimax-m3:free")
TAG = ("osp_testgen_m3_free" if MODEL == "minimax/minimax-m3:free"
       else "osp_testgen_"
       + MODEL.removeprefix("pi:").removeprefix("cursor:")
             .split("/")[-1].replace(":", "_"))
assert MODEL in ("minimax/minimax-m3:free",
                 "nvidia/nemotron-3.5-lightning:free") \
    or MODEL.startswith(("pi:", "cursor:")), "model locked"
TEMP = float(os.environ.get("OSP_TESTGEN_TEMP", "0.5"))
TIMEOUT = int(os.environ.get("OSP_TESTGEN_TIMEOUT", "120"))
TRIES = int(os.environ.get("OSP_TESTGEN_TRIES", "3"))
MAXTOK = int(os.environ.get("OSP_TESTGEN_MAXTOK", "2048"))
FIX_TRIES = int(os.environ.get("OSP_TESTGEN_FIX", "2"))
JAC_TIMEOUT = int(os.environ.get("OSP_TESTGEN_JACTIMEOUT", "90"))
CURSOR_WS = os.environ.get("CURSOR_OSP_WS", "/tmp/cursor_osp_ws_empty")
CURSOR_TMP = os.environ.get("CURSOR_OSP_TMP", "/tmp/cursor_osp_tmp")
ISO_HOME = Path(os.environ.get("CURSOR_OSP_ISO_HOME", "/tmp/cursor_iso_home"))

sys.path.insert(0, str(Path(__file__).parent))
from osp_minimax_generate import _first_err, call_or, extract_jac  # noqa: E402
from jac_source import strip_top_level_with_entry  # noqa: E402

SYSTEM = """You write regression tests in the Jac language for a given Jac program.

You output ONLY a Jac test annex: the contents of `main.test.jac`, inside one
```jac fence. The annex attaches to the given program; test blocks see the
program's node/edge/walker/obj/def names directly — NEVER import them, NEVER
redeclare them. The ONLY imports allowed are Python stdlib (`import io;`,
`import from contextlib { redirect_stdout }`) for output capture.

Idioms (verified against jac 0.36):
- Build a fresh graph per test: `root ++> Node(f=...);` creates and links;
  `a +>:EdgeType:+> b;` adds a typed edge.
- Match the spawn target to the ability signature: `can x with Root entry`
  fires via `res = root spawn Walker(...);` — `can x with Book entry` fires
  only via `b = Book(...); res = b spawn Walker(...);` (or on a visited node
  of that type). Spawning on the wrong type silently fires nothing.
- Spawn returns the walker instance: reporter-style walkers put nodes/values
  in `res.reports` (list, in order); walker `has` fields mutated during the
  walk are readable (`res.outcome`).
- MOST programs PRINT instead of report. Capture stdout:
    import io;
    import from contextlib { redirect_stdout }
    ...
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Librarian(shelf_label="Sci-Fi");
    }
    out = buf.getvalue();
    assert "[OUT]" in out, f"missing OUT marker: {out}";
- Assert graph shape directly: `len([root-->])`, `child in [rt ->:DependsOn:->]`,
  `[-->][?:Issue]`.
- CHAIN vs FAN-OUT: `X ++> Y ++> Z ++> W` is a chain — each `++>` links its
  left operand to its right operand (X->Y, Y->Z, Z->W). After
  `root ++> a ++> b ++> c`, root has exactly ONE direct child
  (`len([root-->]) == 1`), with 3 nodes reachable in total. For N direct
  children, write N separate `root ++> ...;` statements.
- Every assert carries a message: `assert cond, f"got {res.outcome}";`.

Hard rules:
- 2 to 5 test blocks, each `test "behavior name" { ... }`, each building its
  OWN graph (tests run in parallel isolated workers, any order).
- Test the BEHAVIOR THE PROBLEM SPECIFIES: edge directions, counts, flags,
  defaults, traversal outcomes, fail-closed vs fail-open semantics — not
  incidental details.
- No non-stdlib imports, no exec/eval, no reading files.
- `True`/`False`/`None` capitalized; no `pass` statement; tuple patterns in
  `for` need parens; `visit`/`edge`/`with` are reserved — never use them as
  variable names.
- The harness DELETES the program's demo `with entry` block before
  `jac test` — it NEVER runs. Strings printed only there never appear in
  captured output; graph state built only there never exists. NEVER assert
  on output or graph state that only the `with entry` block produces:
  build all test state explicitly in each test and expect output only from
  walkers YOU spawn on state YOU built.
- Use only symbols and `has` fields the program actually declares (they are
  listed exactly as written). If a walker takes init args, only pass fields
  it declares.
"""


def load_jsonl(path: Path) -> list[dict]:
    out = []
    if path.exists():
        for line in path.read_text().splitlines():
            if line.strip():
                out.append(json.loads(line))
    return out


def classify(out: str, rc: int) -> tuple[str, str]:
    """Map pytest output to (verdict, first-error-line)."""
    if rc == 0 and re.search(r"\d+ passed", out):
        n = re.search(r"(\d+) passed", out)
        return "PASS", f"{n.group(1)} passed"
    if "collected 0 items" in out or "no tests ran" in out:
        return "HARNESS", "no tests collected"
    e_lines = [ln.strip() for ln in out.splitlines()
               if re.match(r"^E\s+\S", ln.strip())]
    if any(ln.startswith("E   AssertionError") for ln in e_lines):
        first = next(ln for ln in e_lines if ln.startswith("E   AssertionError"))
        return "SEMANTIC_FAIL", first[4:][:160]
    first = e_lines[0][4:][:160] if e_lines else _first_err(
        subprocess.CompletedProcess([], rc, out, ""), "test-harness-fail")
    return "HARNESS", first


def jac_test(code: str, tests: str, work: Path) -> tuple[int, str]:
    try:
        test_code, _ = strip_top_level_with_entry(code)
    except ValueError as exc:
        return 125, f"entry-strip-fail: {exc}"
    (work / "main.jac").write_text(test_code)
    (work / "main.test.jac").write_text(tests)
    try:
        r = subprocess.run(["jac", "test", "main.jac"], capture_output=True,
                           text=True, timeout=JAC_TIMEOUT, cwd=work)
    except subprocess.TimeoutExpired:
        return 124, "test-timeout (solution or tests exceeded budget)"
    out = (r.stdout or "") + (r.stderr or "")
    return r.returncode, out


def call_pi(model: str, system: str, user: str, timeout: int,
            tries: int = 2) -> tuple[str | None, str | None]:
    """One-shot completion via the pi CLI (codex OAuth from ~/.pi/agent/auth.json)."""
    last = "not attempted"
    for _ in range(tries):
        try:
            r = subprocess.run(
                ["pi", "-p", "--provider", "openai-codex", "--model", model,
                 "--no-session", "--system-prompt", system, user],
                capture_output=True, text=True, timeout=timeout)
        except subprocess.TimeoutExpired:
            last = f"pi timeout after {timeout}s"
            continue
        out = (r.stdout or "").strip()
        if r.returncode == 0 and out:
            return out, None
        last = f"pi rc={r.returncode}: {(r.stderr or out)[-300:]}"
    return None, last

def call_cursor(model: str, system: str, user: str, timeout: int,
                tries: int = 2) -> tuple[str | None, str | None]:
    """One-shot completion via cursor-agent (Cursor subscription).
    Runs in the composer generator's isolated HOME (drops the heavy MCP)."""
    from osp_agent_generate import _ensure_iso_home
    last = "not attempted"
    for _ in range(tries):
        try:
            _ensure_iso_home()
            env = {**os.environ, "HOME": str(ISO_HOME),
                   "XDG_CONFIG_HOME": str(ISO_HOME / ".config"),
                   "TMPDIR": CURSOR_TMP}
            Path(CURSOR_WS).mkdir(parents=True, exist_ok=True)
            Path(CURSOR_TMP).mkdir(parents=True, exist_ok=True)
            r = subprocess.run(
                ["cursor-agent", "--print", "--output-format", "json",
                 "--mode", "ask", "--trust", "--model", model,
                 "--workspace", CURSOR_WS, f"{system}\n\n---\n\n{user}"],
                capture_output=True, text=True, timeout=timeout, env=env)
        except subprocess.TimeoutExpired:
            last = f"cursor timeout after {timeout}s"
            continue
        try:
            d = json.loads((r.stdout or "").strip() or "{}")
        except json.JSONDecodeError as e:
            last = f"cursor parse_error: {e}: {(r.stdout or '')[:150]}"
            continue
        out = (d.get("result") or "").strip()
        if not d.get("is_error") and out:
            return out, None
        last = f"cursor is_error: {str(d.get('error'))[:200] or out[:200]}"
    return None, last

def _user(problem: str, code: str) -> str:
    return (
        "PROBLEM (the program must implement this):\n\n"
        f"{problem.strip()}\n\n"
        "PROGRAM UNDER TEST (main.jac, passed all compile/run gates):\n\n"
        "```jac\n"
        f"{code.strip()}\n"
        "```\n\n"
        "Write the test annex `main.test.jac` now. Test what the PROBLEM "
        "promises, using exactly the symbols above."
    )


def _fix_user(problem: str, code: str, tests: str, error: str) -> str:
    return (
        "PROBLEM:\n\n"
        f"{problem.strip()}\n\n"
        "PROGRAM UNDER TEST:\n\n"
        "```jac\n"
        f"{code.strip()}\n"
        "```\n\n"
        "Your test annex failed to RUN — this is a defect in the TEST, not "
        "the program:\n\n"
        f"```\n{error[:1500]}\n```\n\n"
        "Rewrite the whole annex `main.test.jac` fixed. Keep testing the "
        "problem's promised behavior. Output only the ```jac fence."
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--shard", type=int, default=0)
    ap.add_argument("--shards", type=int, default=1)
    ap.add_argument("--retry-fails", action="store_true",
                    help="re-test ids whose latest verdict is not PASS")
    ap.add_argument("--skip-file", default=str(SKIP_FILE),
                    help="ids (one per line) never to re-test — permanently "
                         "harness-broken records")
    ap.add_argument("--skip-touched-after", metavar="TS",
                    help="skip ids with any results row at/after this ISO ts")
    args = ap.parse_args()

    rows = load_jsonl(DATASET)
    rows = rows[args.offset:]
    if args.limit:
        rows = rows[: args.limit]
    results_rows = load_jsonl(RESULTS)
    if args.skip_touched_after:
        done = {r["id"] for r in results_rows
                if r.get("ts", "") >= args.skip_touched_after
                or r.get("verdict") == "PASS"}
    else:
        done = {r["id"] for r in results_rows
                if not args.retry_fails or r.get("verdict") == "PASS"}
    blocked: set[str] = set()
    if args.skip_file and Path(args.skip_file).exists():
        blocked = {ln.strip() for ln in Path(args.skip_file).read_text().splitlines()
                   if ln.strip()}

    print(f"[plan] {len(rows)} records, model={MODEL}, temp={TEMP}, "
          f"{len(done)} already tested, {len(blocked)} blocklisted", flush=True)
    if args.dry_run:
        for r in rows[:20]:
            mark = "done" if r["id"] in done else "todo"
            print(f"  [{mark}] {r['id']}")
        return 0

    RESULTS.parent.mkdir(parents=True, exist_ok=True)
    items = [r for r in rows[args.shard::args.shards] if r["id"] not in blocked]

    def log_failure(rid: str, stage: str, error: str, tests: str | None) -> None:
        row = {"id": rid, "stage": stage, "error": error[:500],
               "ts": datetime.now().isoformat()}
        if tests is not None:
            row["tests"] = tests
        with FAILS.open("a") as fh:
            fh.write(json.dumps(row) + "\n")

    n_pass = n_sem = n_harness = n_skip = 0
    t0 = time.perf_counter()
    with tempfile.TemporaryDirectory(prefix="osp_testgen_") as tmp:
        for idx, rec in enumerate(items, 1):
            rid = rec["id"]
            if rid in done:
                n_skip += 1
                continue
            problem = rec["messages"][0]["content"]
            code = extract_jac(rec["messages"][1]["content"])
            if code is None:
                log_failure(rid, "no-fence", "solution has no jac fence", None)
                print(f"[{idx:3d}/{len(items)}] {rid} no-fence", flush=True)
                n_harness += 1
                continue
            work = Path(tmp) / rid.replace("/", "_")
            work.mkdir(exist_ok=True)

            tests: str | None = None
            last_err = "not attempted"
            verdict = "HARNESS"
            detail = ""
            for attempt in range(1 + FIX_TRIES):
                prompt = (_user(problem, code) if attempt == 0 else
                          _fix_user(problem, code, tests or "", last_err))
                if MODEL.startswith("pi:"):
                    content, err = call_pi(MODEL.removeprefix("pi:"),
                                           SYSTEM, prompt, TIMEOUT)
                elif MODEL.startswith("cursor:"):
                    content, err = call_cursor(MODEL.removeprefix("cursor:"),
                                               SYSTEM, prompt, TIMEOUT)
                else:
                    content, err = call_or(MODEL, SYSTEM, prompt,
                                           TIMEOUT, MAXTOK, TEMP, TRIES)
                if err or not content:
                    last_err = f"call: {err or 'empty response'}"
                    continue
                cand = extract_jac(content)
                if cand is None:
                    last_err = "no ```jac fence in response"
                    continue
                tests = cand
                rc, out = jac_test(code, cand, work)
                if "main.jac failed to compile" in out:
                    verdict, detail = "HARNESS", "solution failed to compile"
                    break  # the SOLUTION is broken; test repairs cannot help
                verdict, detail = classify(out, rc)
                if verdict == "PASS":
                    break
                # SEMANTIC_FAIL and recoverable HARNESS: repair the TESTS with
                # the failure fed back, instead of leaving it to blind re-rolls
                # in later sweeps (per-attempt pass rate was ~25% blind).
                last_err = out[-1800:] if rc != 124 else detail
                stage = "harness" if verdict == "HARNESS" else "semantic"
                log_failure(rid, f"{stage}{attempt}", detail, cand)
                print(f"[{idx:3d}/{len(items)}] {rid} {stage} "
                      f"{attempt + 1}/{1 + FIX_TRIES} ({detail})", flush=True)

            if verdict == "HARNESS":
                log_failure(rid, "final",
                            detail if tests is not None else (last_err or detail),
                            tests)
                n_harness += 1
                print(f"[{idx:3d}/{len(items)}] {rid} HARNESS-FAIL ({detail})",
                      flush=True)
                continue
            test_pass = verdict == "PASS"
            with RESULTS.open("a") as fh:
                fh.write(json.dumps({
                    "id": rid, "test_pass": test_pass,
                    "verdict": verdict, "detail": detail[:300],
                    "tests": tests,
                    "run_tag": TAG,
                    "ts": datetime.now().isoformat(),
                }) + "\n")
            if test_pass:
                n_pass += 1
            else:
                n_sem += 1
            label = "TEST-OK" if test_pass else "SEM-FAIL"
            elapsed = time.perf_counter() - t0
            print(f"[{idx:3d}/{len(items)}] {rid} {label} ({detail}) "
                  f"[{n_pass} pass / {n_sem} sem-fail / {n_harness} harness "
                  f"/ {n_skip} skip / {elapsed:.1f}s]", flush=True)

    total = time.perf_counter() - t0
    print(f"\n[stats] pass={n_pass} semantic_fail={n_sem} "
          f"harness_fail={n_harness} skip={n_skip} wall={total:.1f}s")
    return 0 if n_harness == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
