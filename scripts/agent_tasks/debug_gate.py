#!/usr/bin/env python3
"""Grader for `debug` agent tasks (data/agent_tasks/debug/<id>/).

A debug task hands the agent a workspace that COMPILES but misbehaves (an
injected semantic bug) plus a bug report. A candidate (the agent's final
workspace) passes only if ALL declared gates hold:

  check     `jac check` on every target path
  test      hidden grader/tests.jac (dropped in as a SEPARATE module
            grader_tests.jac) passes - it contains the reported symptom AND
            regression tests for unrelated behaviour
  run       grader/gate.json run_steps (sequential `jac run` processes in one
            cwd: cross-process persistence)                       [if declared]
  start     reference-style HTTP probes against `jac run --serve`  [if declared]
  fidelity  the fix must not delete/stub the feature: compiler-backed symbol
            inventory (`jac code map` archetypes + abilities, top-level defs)
            and code mass of the target files vs grader/symbols.json. Debug
            fixes are small edits, so the thresholds are much tighter than the
            `fix` kind's.

Usage:
  debug_gate.py TASK_DIR CANDIDATE_DIR      # grade a workspace -> JSON, rc 0 iff pass
  debug_gate.py TASK_DIR --reference        # grade the task's own reference
  debug_gate.py TASK_DIR --starter          # grade the untouched (buggy) starter
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fix_gate  # noqa: E402  (compiler-backed inventory + code mass)
import native_validate as nv  # noqa: E402  (check/test/run/start primitives)

T_SYM = 0.95        # every archetype/ability/def the reference has must survive (~)
T_MASS = 0.85       # target files keep >=85% of the reference's code tokens
T_MASS_FILE = 0.75  # and no single target file drops below 75%


def inventory(ws: Path, targets: list[str]) -> dict:
    return fix_gate.inventory(ws, targets)


def fidelity(task_dir: Path, cand: Path, inv: dict | None = None) -> dict:
    inv = inv or json.loads((task_dir / "grader" / "symbols.json").read_text())
    syms = fix_gate.archetype_symbols(cand)
    names = []
    for p in fix_gate.jac_files(cand):
        names += fix_gate.toplevel_names(p.read_text(errors="replace"))
    wanted = {s.split(":", 1)[1] for s in inv["symbols"] if s.startswith(("def:", "enum:"))}
    syms += fix_gate.defined_toplevel(cand, [(k, n) for k, n in names if n in wanted])
    sym_ratio, missing = fix_gate._multiset_cover(inv["symbols"], syms)
    per_file, tot_r, tot_c = {}, 0, 0
    for rel in inv["target_paths"]:
        r = inv["mass"].get(rel, 0)
        p = cand / rel
        c = fix_gate.code_mass(p.read_text(errors="replace")) if p.exists() else 0
        tot_r += r
        tot_c += c
        if r:
            per_file[rel] = round(c / r, 3)
    mass = tot_c / max(1, tot_r)
    min_file = min(per_file.values()) if per_file else 1.0
    reasons = []
    if sym_ratio < T_SYM:
        reasons.append(f"symbols {sym_ratio:.2f} < {T_SYM} (missing {missing[:8]})")
    if mass < T_MASS:
        reasons.append(f"mass {mass:.2f} < {T_MASS}")
    if min_file < T_MASS_FILE:
        reasons.append(f"file mass {min_file:.2f} < {T_MASS_FILE}")
    return {"ok": not reasons, "symbols": round(sym_ratio, 3), "missing": missing[:25],
            "mass": round(mass, 3), "per_file": per_file, "reasons": reasons}


def grade(task_dir: Path, cand: Path, jac: str = "jac", inv: dict | None = None,
          gates: list[str] | None = None) -> dict:
    """Grade candidate workspace `cand` against task `task_dir` (copied to a fresh cwd)."""
    t = nv.Task(task_dir, jac)
    gates = gates or t.meta["gates"]
    res: dict = {"task": t.meta["id"], "gates": {}}
    with tempfile.TemporaryDirectory(prefix=f"dbg_{t.meta['id']}_") as tmp:
        wd = Path(tmp)
        nv._copytree(cand, wd)
        t._add_grader_files(wd)
        if "check" in gates:
            ok, out = t.check(wd)
            res["gates"]["check"] = {"ok": ok, "detail": out[-400:]}
        if "test" in gates:
            ok, out = t.test(wd)
            res["gates"]["test"] = {"ok": ok, "detail": out[-1200:]}
        if "run" in gates and t.gate.get("run_steps"):
            ok, out = t.run_steps(wd)
            res["gates"]["run"] = {"ok": ok, "detail": out[-400:]}
        if "start" in gates and "start" in t.gate:
            ok, out = t.start(wd)
            res["gates"]["start"] = {"ok": ok, "detail": out[-400:]}
    if "fidelity" in gates:
        res["gates"]["fidelity"] = fidelity(task_dir, cand, inv)
    res["pass"] = all(g["ok"] for g in res["gates"].values())
    return res


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("task", type=Path)
    ap.add_argument("candidate", nargs="?", type=Path)
    ap.add_argument("--reference", action="store_true")
    ap.add_argument("--starter", action="store_true")
    ap.add_argument("--jac", default="jac")
    a = ap.parse_args()
    cand = (a.task / "grader" / "reference") if a.reference else (a.task / "starter") if a.starter else a.candidate
    if cand is None:
        ap.error("candidate dir required")
    r = grade(a.task, cand, a.jac)
    print(json.dumps(r, indent=1))
    return 0 if r["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
