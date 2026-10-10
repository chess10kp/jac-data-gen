#!/usr/bin/env python3
"""Unified grader for agent-task candidate workspaces (all kinds).

    grade(task_dir, candidate_ws) -> {"passed": bool, "gates": {name: {"ok": bool, ...}}, "detail": str, ...}

Thin adapters over each kind's own validator (never edited here):
  native   native_validate.Task primitives: check, contracts, hidden test, run_steps, start
  app      app_build.run_gates (check, hidden test [+ own tests at L4-5], behavioral/smoke scripts)
  fix      fix_gate.grade (check + symbol/mass anti-hollowing [+ hidden tests])
  debug    debug_gate.grade
  others   the kind's CLI `<gate>.py TASK CANDIDATE` -> JSON on stdout, rc 0 iff pass
           (convert_gate, testgen_grade, refactor_gate; feature: feature_gate if present)

The candidate is always first copied into a fresh temp dir (skipping .jac/,
__jac_gen__, __pycache__, node_modules): jac's graph store is keyed by cwd,
so state the agent left behind cannot leak into the gates, and graders that
work in place never touch the recorded workspace.

CLI:
  grade.py TASK_DIR CANDIDATE_DIR [--json]           grade one workspace (rc 0 iff pass)
  grade.py --sanity [--kinds native,app] [--per-kind 3] [--out FILE]
      reference must pass, starter must fail, for the first N validated tasks per kind
"""
from __future__ import annotations

import argparse
import contextlib
import io
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
TASKS = REPO / "data" / "agent_tasks"
sys.path.insert(0, str(HERE))

SKIP = ("__jac_gen__", ".jac", "__pycache__", "node_modules", ".venv")
# Kinds whose grader/reference is an overlay on starter/ (not a full workspace).
REF_OVERLAY = {"app"}
CLI_GATES = {  # kind -> (script, argv builder)
    "convert": ("convert_gate.py", lambda t, c: [str(t), str(c)]),
    "testgen": ("testgen_grade.py", lambda t, c: [str(t), str(c)]),
    "refactor": ("refactor_gate.py", lambda t, c: [str(c), "--task", str(t)]),
    "feature": ("feature_gate.py", lambda t, c: [str(t), str(c)]),
}


def copy_ws(src: Path, dst: Path) -> None:
    shutil.copytree(src, dst, dirs_exist_ok=True, symlinks=False,
                    ignore=shutil.ignore_patterns(*SKIP))


def _tail(s: str, n: int = 1200) -> str:
    return (s or "")[-n:]


# --------------------------------------------------------------------------- adapters
def _grade_native(task_dir: Path, cand: Path) -> dict:
    import native_validate as nv
    t = nv.Task(task_dir, "jac")
    declared = set(t.meta["gates"])
    gates: dict = {}
    with tempfile.TemporaryDirectory(prefix="grade_nat_") as tmp:
        wd = Path(tmp)
        nv._copytree(cand, wd)
        t._add_grader_files(wd)
        ok, out = t.check(wd)
        gates["check"] = {"ok": ok, "detail": _tail(out, 600)}
        if t.gate.get("contracts"):
            ok, out = t.contracts(wd)
            gates["contracts"] = {"ok": ok is not False, "detail": _tail(out, 300)}
        ok, out = t.test(wd)
        gates["test"] = {"ok": ok, "detail": _tail(out)}
        if t.gate.get("run_steps"):
            ok, out = t.run_steps(wd)
            gates["run"] = {"ok": ok, "detail": _tail(out, 600)}
        if "start" in declared and "start" in t.gate:
            ok, out = t.start(wd)
            gates["start"] = {"ok": ok, "detail": _tail(out, 600)}
    return {"gates": gates}


def _grade_app(task_dir: Path, cand: Path) -> dict:
    import app_build as ab
    meta = json.loads((task_dir / "task.json").read_text())
    with contextlib.redirect_stdout(io.StringIO()):
        res = ab.run_gates(cand, task_dir, meta)
    gates = {}
    for k, r in res.items():
        detail = r.get("tail") or ""
        if not detail and r.get("steps"):
            detail = "\n".join(str(s.get("tail") or s.get("why") or "") for s in r["steps"])
        g = {"ok": bool(r.get("ok")), "detail": _tail(detail)}
        if "verdict" in r:
            g["verdict"] = r["verdict"]
        if "own_test_files" in r:
            g["own_test_files"] = r["own_test_files"]
        gates[k] = g
    return {"gates": gates}


def _grade_fix(task_dir: Path, cand: Path) -> dict:
    import fix_gate
    with contextlib.redirect_stdout(io.StringIO()):
        r = fix_gate.grade(task_dir, cand)
    gates = {"check": {"ok": bool(r["check"]["ok"]), "n_errors": r["check"].get("n_errors")}}
    reasons = r.get("reasons", [])
    gates["fidelity"] = {"ok": not any(x.startswith(("symbols", "mass", "body mass", "file body")) for x in reasons),
                         "symbols": r.get("symbols"), "mass": r.get("mass")}
    if "test" in r:
        gates["test"] = {"ok": bool(r["test"].get("ok")), "detail": _tail(str(r["test"].get("detail", "")))}
    return {"gates": gates, "passed_native": bool(r.get("pass")), "reasons": reasons}


def _grade_debug(task_dir: Path, cand: Path) -> dict:
    import debug_gate
    with contextlib.redirect_stdout(io.StringIO()):
        r = debug_gate.grade(task_dir, cand)
    gates = {}
    for k, g in r.get("gates", {}).items():
        gates[k] = {**{kk: vv for kk, vv in g.items() if kk != "detail"}, "ok": bool(g.get("ok")),
                    "detail": _tail(str(g.get("detail", "")), 600)}
    return {"gates": gates, "passed_native": bool(r.get("pass"))}


def _grade_cli(kind: str, task_dir: Path, cand: Path) -> dict:
    script, argv = CLI_GATES[kind]
    path = HERE / script
    if not path.exists():
        return {"gates": {"grader": {"ok": False, "detail": f"no grader for kind {kind!r} ({script} missing)"}}}
    try:
        p = subprocess.run([sys.executable, str(path), *argv(task_dir, cand)], capture_output=True,
                           text=True, timeout=3600, stdin=subprocess.DEVNULL)
        rc, out, err = p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired:
        rc, out, err = 124, "", "grader timeout"
    verdict = None
    i = out.find("{")
    while i >= 0 and verdict is None:
        try:
            verdict = json.loads(out[i:])
        except ValueError:
            i = out.find("{", i + 1)
    gates = {}
    if isinstance(verdict, dict) and isinstance(verdict.get("gates"), dict):
        for k, g in verdict["gates"].items():
            ok = g.get("ok", g.get("pass")) if isinstance(g, dict) else bool(g)
            gates[k] = {"ok": bool(ok)}
    gates["grader_rc"] = {"ok": rc == 0, "detail": _tail(err or out, 600)}
    return {"gates": gates, "verdict": verdict}


def grade(task_dir: Path | str, candidate_ws: Path | str) -> dict:
    task_dir, candidate_ws = Path(task_dir).resolve(), Path(candidate_ws).resolve()
    meta = json.loads((task_dir / "task.json").read_text())
    kind = meta["kind"]
    t0 = time.time()
    with tempfile.TemporaryDirectory(prefix="grade_cand_") as tmp:
        cand = Path(tmp) / "ws"
        copy_ws(candidate_ws, cand)
        missing = [p for p in meta.get("target_paths", []) if not (cand / p).exists()]
        try:
            if kind == "native":
                r = _grade_native(task_dir, cand)
            elif kind == "app":
                r = _grade_app(task_dir, cand)
            elif kind == "fix":
                r = _grade_fix(task_dir, cand)
            elif kind == "debug":
                r = _grade_debug(task_dir, cand)
            elif kind in CLI_GATES:
                r = _grade_cli(kind, task_dir, cand)
            else:
                r = {"gates": {"grader": {"ok": False, "detail": f"unknown kind {kind!r}"}}}
        except Exception as e:  # a grader crash is a failed grade, never a pass
            r = {"gates": {"grader": {"ok": False, "detail": f"{type(e).__name__}: {e}"}}}
    gates = r.pop("gates")
    passed = bool(gates) and all(g.get("ok") for g in gates.values())
    if "passed_native" in r:
        passed = passed and r["passed_native"]
    failed = [k for k, g in gates.items() if not g.get("ok")]
    return {"task_id": meta["id"], "kind": kind, "level": meta.get("level"), "passed": passed,
            "gates": gates, "failed_gates": failed, "missing_targets": missing,
            "detail": "" if passed else "; ".join(f"{k}: {str(gates[k].get('detail', ''))[-200:]}" for k in failed),
            "secs": round(time.time() - t0, 1), **r}


# --------------------------------------------------------------------------- sanity
def validated_tasks(kind: str) -> list[Path]:
    man = TASKS / kind / "manifest.jsonl"
    if not man.exists():
        return []
    out = []
    for line in man.read_text().splitlines():
        if line.strip():
            d = json.loads(line)
            if d.get("validated") and (TASKS / kind / d["id"]).is_dir():
                out.append(TASKS / kind / d["id"])
    return sorted(out)


def reference_ws(task_dir: Path, dst: Path) -> Path:
    kind = json.loads((task_dir / "task.json").read_text())["kind"]
    if kind in REF_OVERLAY:
        copy_ws(task_dir / "starter", dst)
    copy_ws(task_dir / "grader" / "reference", dst)
    return dst


def sanity(kinds: list[str], per_kind: int, out: Path | None) -> int:
    bad = 0
    rows = []
    for kind in kinds:
        tasks = validated_tasks(kind)
        # spread picks over levels: every k-th task
        step = max(1, len(tasks) // max(1, per_kind))
        for td in tasks[::step][:per_kind]:
            with tempfile.TemporaryDirectory(prefix="sanity_") as tmp:
                ref = reference_ws(td, Path(tmp) / "ref")
                rr = grade(td, ref)
                st = Path(tmp) / "starter"
                copy_ws(td / "starter", st)
                rs = grade(td, st)
            ok = rr["passed"] and not rs["passed"]
            bad += not ok
            row = {"task_id": td.name, "kind": kind, "ok": ok, "ref_passed": rr["passed"],
                   "starter_passed": rs["passed"], "ref_failed": rr["failed_gates"],
                   "starter_failed": rs["failed_gates"], "ref_detail": rr["detail"][:600],
                   "secs": round(rr["secs"] + rs["secs"], 1)}
            rows.append(row)
            print(f"SANITY {'OK ' if ok else 'BAD'} {kind:8s} {td.name:40s} ref={'pass' if rr['passed'] else 'FAIL'} "
                  f"starter={'PASS' if rs['passed'] else 'fail'} {row['secs']}s"
                  + ("" if ok else f"  ref_failed={rr['failed_gates']} {rr['detail'][:300]!r}"), flush=True)
    if out:
        out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("a") as f:
            for r in rows:
                f.write(json.dumps(r) + "\n")
    print(f"SANITY {len(rows) - bad}/{len(rows)} ok")
    return 1 if bad else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("task", nargs="?", type=Path)
    ap.add_argument("candidate", nargs="?", type=Path)
    ap.add_argument("--json", action="store_true", help="print the full verdict as one JSON line")
    ap.add_argument("--sanity", action="store_true")
    ap.add_argument("--kinds", default="native,app")
    ap.add_argument("--per-kind", type=int, default=3)
    ap.add_argument("--out", type=Path)
    a = ap.parse_args()
    if a.sanity:
        return sanity([k for k in a.kinds.split(",") if k], a.per_kind, a.out)
    if not (a.task and a.candidate):
        ap.error("TASK_DIR and CANDIDATE_DIR required (or --sanity)")
    r = grade(a.task, a.candidate)
    if a.json:
        print(json.dumps(r))
    else:
        print(json.dumps(r, indent=1))
    return 0 if r["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
