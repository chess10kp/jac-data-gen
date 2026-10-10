#!/usr/bin/env python3
"""Hidden grader for a `testgen` agent task (gates: check + mutation).

    python scripts/agent_tasks/testgen_grade.py <task_dir> <candidate_workspace> [--jac jac] [--jobs N]

The candidate's test files (task.json target_paths, plus any NEW .jac files it
added) are overlaid onto a pristine copy of the original code
(grader/reference/ minus the reference test files), so editing the code under
test can never help. Then:

  check     `jac check` passes on every candidate test file
  original  `jac test <test file>` passes on the untouched code
            (>=1 test passed, 0 failed/errors)
  mutation  each mutant in grader/mutants.jsonl is applied in a FRESH temp
            workspace (fresh CWD => isolated graph store) and the suite is run;
            the mutant is killed iff the suite does not pass (assert failure,
            crash, or timeout). kill_rate = killed / len(mutants) must be
            >= task.json mutation.threshold (default 0.8).

Prints a JSON verdict; exit 0 iff all gates pass.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from testgen_mutants import apply_mutant, load_jsonl  # noqa: E402

IGNORE = shutil.ignore_patterns("__jac_gen__", ".jac", "__pycache__", "*.session*")
TIMEOUT = 90


def _run(cmd: list[str], cwd: Path, timeout: float = TIMEOUT) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        return 124, f"TIMEOUT after {timeout}s"


_PASSED = re.compile(r"\b([1-9]\d*) passed")
_FAILED = re.compile(r"\b[1-9]\d* (failed|errors?)\b")


def suite_passes(rc: int, out: str) -> bool:
    return rc == 0 and _PASSED.search(out) is not None and _FAILED.search(out) is None


class TaskSpec:
    def __init__(self, task_dir: Path):
        self.dir = task_dir
        self.meta = json.loads((task_dir / "task.json").read_text())
        self.grader = task_dir / "grader"
        self.tests: list[str] = self.meta["target_paths"]           # test files the agent writes
        mut = self.meta.get("mutation", {})
        self.threshold: float = float(mut.get("threshold", 0.8))
        self.code_files: list[str] = mut["code_files"]             # files under test (never overlaid)

    def base_workspace(self) -> tempfile.TemporaryDirectory:
        """Original code only (reference minus the reference's test files)."""
        tmp = tempfile.TemporaryDirectory(prefix=f"tg_{self.meta['id']}_")
        wd = Path(tmp.name)
        shutil.copytree(self.dir / "starter", wd, dirs_exist_ok=True, ignore=IGNORE)
        for t in self.tests:                      # drop any starter stub of the test file(s)
            (wd / t).unlink(missing_ok=True)
        for f in self.code_files:                 # code always from the pristine reference
            shutil.copyfile(self.grader / "reference" / f, wd / f)
        return tmp

    def overlay_suite(self, wd: Path, suite_dir: Path) -> list[str]:
        """Copy the suite's test files (+ new helper .jac files) into wd."""
        added = []
        for p in sorted(suite_dir.rglob("*.jac")):
            rel = p.relative_to(suite_dir).as_posix()
            if "__jac_gen__" in rel or rel.startswith(".jac/") or rel in self.code_files:
                continue
            if rel in self.tests or not (self.dir / "starter" / rel).exists():
                (wd / rel).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(p, wd / rel)
                added.append(rel)
        return added

    def mutants(self, path: Path | None = None) -> list[dict]:
        return load_jsonl(path or self.grader / "mutants.jsonl")


def run_suite(spec: TaskSpec, suite_dir: Path, jac: str, mutant: dict | None) -> tuple[bool, str]:
    """True iff the suite PASSES on (original | mutant)."""
    with spec.base_workspace() as tmp:
        wd = Path(tmp)
        spec.overlay_suite(wd, suite_dir)
        if mutant is not None:
            apply_mutant(wd, mutant)
        outs = []
        for t in spec.tests:
            if not (wd / t).exists():
                return False, f"missing test file {t}"
            rc, out = _run([jac, "test", t], wd)
            outs.append(out[-1200:])
            if not suite_passes(rc, out):
                return False, "\n".join(outs)
        return True, "\n".join(outs)


def check_suite(spec: TaskSpec, suite_dir: Path, jac: str) -> tuple[bool, str]:
    with spec.base_workspace() as tmp:
        wd = Path(tmp)
        spec.overlay_suite(wd, suite_dir)
        for t in spec.tests:
            if not (wd / t).exists():
                return False, f"missing test file {t}"
            rc, out = _run([jac, "check", t], wd)
            if rc != 0:
                return False, f"{t}: {out[-800:]}"
    return True, ""


def grade(task_dir: Path, suite_dir: Path, jac: str = "jac", jobs: int = 3,
          mutants: list[dict] | None = None, early_exit: bool = False) -> dict:
    spec = TaskSpec(task_dir)
    muts = mutants if mutants is not None else spec.mutants()
    res: dict = {"id": spec.meta["id"], "threshold": spec.threshold, "n_mutants": len(muts)}
    ok, msg = check_suite(spec, suite_dir, jac)
    res["check"] = ok
    if not ok:
        res.update(passed=False, reason=f"check failed: {msg}")
        return res
    ok, msg = run_suite(spec, suite_dir, jac, None)
    res["original_pass"] = ok
    if not ok:
        res.update(passed=False, reason=f"suite does not pass on the original code:\n{msg[-1500:]}")
        return res
    killed, survived = [], []
    need = spec.threshold * len(muts)
    with cf.ThreadPoolExecutor(max_workers=jobs) as ex:
        futs = {ex.submit(run_suite, spec, suite_dir, jac, m): m for m in muts}
        for f in cf.as_completed(futs):
            m = futs[f]
            passed, _ = f.result()
            (survived if passed else killed).append(m["id"])
    res["killed"] = sorted(killed)
    res["survived"] = sorted(survived)
    res["kill_rate"] = round(len(killed) / len(muts), 4) if muts else 0.0
    res["passed"] = bool(muts) and len(killed) >= need
    res["reason"] = f"killed {len(killed)}/{len(muts)} mutants (need >= {spec.threshold:.0%})"
    return res


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("task_dir")
    ap.add_argument("candidate")
    ap.add_argument("--jac", default="jac")
    ap.add_argument("--jobs", type=int, default=3)
    a = ap.parse_args()
    r = grade(Path(a.task_dir), Path(a.candidate), a.jac, a.jobs)
    print(json.dumps(r, indent=1))
    return 0 if r["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
