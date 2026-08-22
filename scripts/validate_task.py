#!/usr/bin/env python3
"""Validate a Jac-native eval task against the Phase-1 acceptance gate.

For a task directory pair (public/dev/<id> + private/dev/<id>) this harness
proves the task actually measures what it claims, independent of any model:

  1. Reference and every alternative solution CHECK, satisfy the objective
     contracts, and PASS the hidden tests.
  2. Every negative (mutant) CHECKS (it is a compiling program) but FAILS the
     hidden tests -- i.e. the test suite kills it. A mutant that passes is a
     coverage hole and fails the gate.
  3. The reference produces identical hidden-test results across repeated runs
     (determinism / no cross-run graph bleed).

Each candidate is assembled into its own temp directory: context files copied
byte-for-byte, candidate written to `target_path`, hidden tests dropped as a
SEPARATE module `tests.jac` that imports the target. Nothing is concatenated,
so hidden-test source never enters the graded candidate. The temp dir is also
the process CWD, which the Jac runtime uses to namespace graph state, giving
per-candidate isolation for free.

Contracts are evaluated with `jac code` (compiler-backed structural query), not
regex, so comments or unused declarations cannot satisfy them.

Usage:
    python scripts/validate_task.py evals/jac_native/v0 jnv0-core-complete-001
    python scripts/validate_task.py evals/jac_native/v0 jnv0-core-complete-001 --repeats 3
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


class GateError(Exception):
    pass


def run(cmd: list[str], cwd: Path, timeout: float) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout
    )


def assemble(workdir: Path, task: dict[str, Any], public_dir: Path, private_dir: Path,
             candidate_src: str) -> None:
    """Populate an isolated workspace for one candidate."""
    for rel in task.get("context_paths", []):
        src = public_dir / "context" / Path(rel).name
        dst = workdir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
    target = workdir / task["target_path"]
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(candidate_src.rstrip() + "\n", encoding="utf-8")
    # Hidden tests as a separate annex module (imports the target).
    tests_src = (private_dir / "tests.jac").read_text(encoding="utf-8")
    (workdir / "tests.jac").write_text(tests_src, encoding="utf-8")


def jac_check(workdir: Path, target: str, jac: str, timeout: float) -> tuple[bool, str]:
    p = run([jac, "check", target], workdir, timeout)
    return p.returncode == 0, (p.stdout + p.stderr)


def jac_test(workdir: Path, jac: str, timeout: float) -> tuple[bool, str]:
    p = run([jac, "test", "tests.jac"], workdir, timeout)
    out = p.stdout + p.stderr
    return (p.returncode == 0 and "passed" in out and "failed" not in out), out


def jac_code_map(workdir: Path, jac: str, timeout: float) -> list[dict[str, Any]]:
    p = run([jac, "code", "map"], workdir, timeout)
    if p.returncode != 0:
        return []
    return json.loads(p.stdout).get("archetypes", [])


def jac_code_symbol(workdir: Path, name: str, jac: str, timeout: float) -> list[dict[str, Any]]:
    p = run([jac, "code", "symbol", name], workdir, timeout)
    if p.returncode != 0:
        return []
    return json.loads(p.stdout).get("definitions", [])


def check_contracts(workdir: Path, task: dict[str, Any], candidate_src: str,
                    jac: str, timeout: float) -> list[str]:
    """Return a list of contract-violation strings (empty == all satisfied)."""
    violations: list[str] = []
    archetypes = jac_code_map(workdir, jac, timeout)
    by_name = {a["name"]: a for a in archetypes}
    for c in task.get("contracts", []):
        kind = c["kind"]
        if kind == "public_symbol":
            name = c["name"]
            expect_kind = c.get("expect_kind")
            defn = by_name.get(name)
            if defn is None:
                syms = jac_code_symbol(workdir, name, jac, timeout)
                defn = syms[0] if syms else None
            if defn is None:
                violations.append(f"missing public symbol {name!r}")
                continue
            if expect_kind and defn.get("kind") != expect_kind:
                violations.append(
                    f"symbol {name!r} is kind {defn.get('kind')!r}, expected {expect_kind!r}"
                )
            for token in c.get("signature_contains", []):
                if token not in defn.get("signature", ""):
                    violations.append(
                        f"symbol {name!r} signature missing {token!r}: {defn.get('signature','')!r}"
                    )
        elif kind == "forbidden_test_blocks":
            # compiler-backed: a candidate must not ship its own test blocks
            if any(line.lstrip().startswith("test ") for line in candidate_src.splitlines()):
                violations.append("candidate contains a test block")
        elif kind == "forbidden_python":
            if "import:py" in candidate_src or "::py::" in candidate_src:
                violations.append("candidate uses Python import escape hatch")
        else:
            violations.append(f"unknown contract kind {kind!r}")
    return violations


def evaluate(task_root: Path, task_id: str, jac: str, repeats: int) -> int:
    public_dir = task_root / "public" / "dev" / task_id
    private_dir = task_root / "private" / "dev" / task_id
    task = json.loads((public_dir / "task.json").read_text())
    timeout = float(task.get("timeout_s", 120))
    target = task["target_path"]

    def with_workspace(src: str, fn):
        with tempfile.TemporaryDirectory(prefix=f"vt_{task_id}_") as tmp:
            wd = Path(tmp)
            assemble(wd, task, public_dir, private_dir, src)
            return fn(wd)

    failures: list[str] = []
    ok: list[str] = []

    # --- 1. Reference + alternatives must check, satisfy contracts, and pass.
    positives = [("reference", private_dir / "reference.jac")]
    alt_dir = private_dir / "alternatives"
    if alt_dir.is_dir():
        positives += [(f"alt:{p.name}", p) for p in sorted(alt_dir.glob("*.jac"))]

    for label, path in positives:
        src = path.read_text(encoding="utf-8")

        def _pos(wd: Path) -> None:
            checked, cout = jac_check(wd, target, jac, timeout)
            if not checked:
                raise GateError(f"{label}: jac check FAILED\n{cout[-400:]}")
            viol = check_contracts(wd, task, src, jac, timeout)
            if viol:
                raise GateError(f"{label}: contract violations: {viol}")
            passed, tout = jac_test(wd, jac, timeout)
            if not passed:
                raise GateError(f"{label}: hidden tests did NOT pass\n{tout[-400:]}")

        try:
            with_workspace(src, _pos)
            ok.append(f"POS {label}: check+contracts+tests pass")
        except GateError as e:
            failures.append(str(e))

    if len(positives) < 3:
        failures.append(
            f"only {len(positives)} passing solutions; gate requires reference + >=2 alternatives"
        )

    # --- 2. Every negative must check but be KILLED by the tests.
    neg_dir = private_dir / "negatives"
    negatives = sorted(neg_dir.glob("*.jac")) if neg_dir.is_dir() else []
    if not negatives:
        failures.append("no negatives/ mutants present")
    for path in negatives:
        src = path.read_text(encoding="utf-8")

        def _neg(wd: Path) -> tuple[bool, bool, str]:
            checked, cout = jac_check(wd, target, jac, timeout)
            if not checked:
                return False, False, cout
            passed, tout = jac_test(wd, jac, timeout)
            return True, passed, tout

        checked, passed, out = with_workspace(src, _neg)
        if not checked:
            failures.append(f"MUTANT {path.name}: does not compile (must be a valid program)\n{out[-300:]}")
        elif passed:
            failures.append(f"MUTANT {path.name}: SURVIVED — tests failed to kill it (coverage hole)")
        else:
            ok.append(f"NEG {path.name}: killed")

    # --- 3. Determinism: reference hidden-test outcome stable across repeats.
    ref_src = (private_dir / "reference.jac").read_text(encoding="utf-8")
    outcomes = []
    for _ in range(max(1, repeats)):
        outcomes.append(with_workspace(ref_src, lambda wd: jac_test(wd, jac, timeout)[0]))
    if len(set(outcomes)) != 1 or not outcomes[0]:
        failures.append(f"reference non-deterministic across {repeats} runs: {outcomes}")
    else:
        ok.append(f"DET reference stable across {repeats} runs")

    # --- Report.
    print(f"\n=== Task {task_id} — gate report ===")
    for line in ok:
        print(f"  \033[32mPASS\033[0m {line}")
    for line in failures:
        print(f"  \033[31mFAIL\033[0m {line}")
    if failures:
        print(f"\n{len(failures)} gate failure(s). Task is NOT eligible.\n")
        return 1
    print(f"\nAll gates green ({len(ok)} checks). Task eligible.\n")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("task_root", type=Path, help="e.g. evals/jac_native/v0")
    ap.add_argument("task_id", help="e.g. jnv0-core-complete-001")
    ap.add_argument("--jac", default="jac", help="jac binary")
    ap.add_argument("--repeats", type=int, default=3, help="determinism repetitions")
    args = ap.parse_args()
    try:
        return evaluate(args.task_root, args.task_id, args.jac, args.repeats)
    except (GateError, FileNotFoundError, json.JSONDecodeError) as e:
        print(f"gate harness error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
