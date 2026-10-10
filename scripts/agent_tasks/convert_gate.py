#!/usr/bin/env python3
"""Grader for `convert` agent tasks (Python / FARM project -> idiomatic Jac).

A candidate workspace passes only if ALL declared gates hold:

  check      `jac check` passes on every target path.
  fidelity   anti-hollow / anti-shim contract, evaluated through the compiler:
               * every API symbol in grader/gate.json "api" is DEFINED inside the
                 workspace with the declared kind (`jac code map` for
                 obj/node/edge/walker + their abilities, `jac code symbol` for
                 top-level defs) -- a re-export of the Python original or a
                 comment cannot satisfy it;
               * no target imports the module being ported (gate "forbid_imports",
                 plus the starter's python/ package) and no `::py::` block;
               * code mass of the targets >= T_MASS x the reference's (blocks
                 "one-line wrapper around stdlib" ports).
  test       hidden behavior-preserving tests (grader/tests.jac, a separate module
             that imports the target) pass under `jac test`. The Python sources
             (gate "strip", default ["python"]) are deleted first, so a Jac shim
             that imports them fails.
  start      (FARM L5) grader/smoke.py boots `jac run --serve` on the workspace and
             exercises the walker endpoints; last stdout line is a JSON verdict.

Usage:
  convert_gate.py TASK_DIR CANDIDATE_DIR      # grade a candidate workspace
  convert_gate.py TASK_DIR --reference        # grade the task's own reference
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from fix_gate import code_mass, tokens  # noqa: E402

JAC = os.environ.get("JAC_BIN", "jac")
TEST_MODULE = "grader_tests.jac"
T_MASS = 0.45


def _run(cmd: list[str], cwd: Path, timeout: float) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout,
                           stdin=subprocess.DEVNULL)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired as e:
        out = e.stdout.decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or "")
        return 124, f"TIMEOUT after {timeout}s\n{out}"


def _jac_json(ws: Path, *args: str, timeout: float = 180) -> dict:
    rc, out = _run([JAC, "code", *args], ws, timeout)
    i = out.find("{")
    try:
        return json.loads(out[i:]) if i >= 0 else {}
    except ValueError:
        return {}


def copy_ws(src: Path, dst: Path) -> None:
    shutil.copytree(src, dst, dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns(".jac", "__jac_gen__", "__pycache__", "node_modules"))


class Task:
    def __init__(self, task_dir: Path):
        self.dir = Path(task_dir)
        self.meta = json.loads((self.dir / "task.json").read_text())
        self.grader = self.dir / "grader"
        self.gate = json.loads((self.grader / "gate.json").read_text())
        self.targets: list[str] = self.meta["target_paths"]
        self.timeout = float(self.gate.get("timeout_s", 240))
        self.strip = self.gate.get("strip", ["python"])

    # ------------------------------------------------------------------ gates
    def check(self, ws: Path) -> tuple[bool, str]:
        for t in self.targets:
            if not (ws / t).exists():
                return False, f"missing target {t}"
            rc, out = _run([JAC, "check", t], ws, self.timeout)
            if rc != 0 or re.search(r"\b[1-9]\d* errors?\b", out.split("=====")[-1] if "=====" in out else ""):
                return False, f"{t}: {out[-800:]}"
        return True, ""

    def defined_symbols(self, ws: Path) -> set[str]:
        """kind:name for archetypes (+ ability:Arch.method) and def:name for top-level
        functions, restricted to files inside ws."""
        root = str(ws.resolve())
        have: set[str] = set()
        for a in _jac_json(ws, "map", timeout=self.timeout).get("archetypes", []):
            f = a.get("file", "")
            if f and not str(Path(f).resolve()).startswith(root):
                continue
            have.add(f"{a.get('kind')}:{a.get('name')}")
            for ab in a.get("abilities", []):
                have.add(f"ability:{a.get('name')}.{str(ab).split('(')[0].strip()}")
        for s in self.gate.get("api", []):
            if s["kind"] != "def":
                continue
            for d in _jac_json(ws, "symbol", s["name"], timeout=self.timeout).get("definitions", []):
                f = d.get("file", "")
                if d.get("name") != s["name"] or (f and not str(Path(f).resolve()).startswith(root)):
                    continue
                k = d.get("kind", "")
                if k == "ability" or k.startswith("func"):
                    have.add(f"def:{s['name']}")
        return have

    def imports(self, src: str) -> list[str]:
        """Module names imported by a Jac source (comments/strings ignored)."""
        toks = [v for k, v in tokens(src)]
        mods = []
        for i, v in enumerate(toks):
            if v != "import":
                continue
            j = i + 1
            if j < len(toks) and toks[j] == "from":
                j += 1
            # dotted name (possibly a list `import a, b;`)
            while j < len(toks):
                name = toks[j]
                while j + 2 < len(toks) and toks[j + 1] == ".":
                    name += "." + toks[j + 2]
                    j += 2
                mods.append(name)
                if j + 1 < len(toks) and toks[j + 1] == ",":
                    j += 2
                    continue
                break
        return mods

    def fidelity(self, ws: Path) -> tuple[bool, str, dict]:
        info: dict = {}
        reasons = []
        forbid = set(self.gate.get("forbid_imports", [])) | set(self.strip)
        mass = 0
        for t in self.targets:
            p = ws / t
            if not p.exists():
                reasons.append(f"missing {t}")
                continue
            src = p.read_text(errors="replace")
            mass += code_mass(src)
            if "::py::" in src:
                reasons.append(f"{t}: inline ::py:: block")
            for m in self.imports(src):
                if m.split(".")[0] in forbid or m in forbid:
                    reasons.append(f"{t}: imports forbidden module {m!r}")
        ref_mass = self.gate.get("ref_mass")
        if ref_mass:
            info["mass_ratio"] = round(mass / ref_mass, 3)
            if mass < T_MASS * ref_mass:
                reasons.append(f"code mass {mass} < {T_MASS} x reference {ref_mass}")
        want = [f"{s['kind']}:{s['name']}" for s in self.gate.get("api", [])]
        have = self.defined_symbols(ws)
        missing = [w for w in want if w not in have]
        info["api"] = f"{len(want) - len(missing)}/{len(want)}"
        if missing:
            reasons.append(f"api symbols not defined in workspace: {missing[:12]}")
        return not reasons, "; ".join(reasons), info

    def test(self, ws: Path) -> tuple[bool, str]:
        for d in self.strip:
            shutil.rmtree(ws / d, ignore_errors=True)
            for p in ws.glob(f"{d}.py"):
                p.unlink()
        shutil.copyfile(self.grader / "tests.jac", ws / TEST_MODULE)
        rc, out = _run([JAC, "test", TEST_MODULE], ws, self.timeout)
        tail = out.strip().splitlines()[-1:] if out.strip() else [""]
        ok = (rc == 0 and re.search(r"\b[1-9]\d* passed", out) is not None
              and re.search(r"\b[1-9]\d* (failed|errors?)\b", out) is None)
        return ok, out[-2500:] if not ok else tail[0]

    def start(self, ws: Path) -> tuple[bool, str]:
        smoke = self.grader / "smoke.py"
        rc, out = _run([sys.executable, str(smoke), str(ws)], ws, float(self.gate.get("smoke_timeout_s", 600)))
        last = out.strip().splitlines()[-1] if out.strip() else ""
        try:
            v = json.loads(last)
        except ValueError:
            v = {}
        ok = rc == 0 and bool(v.get("start")) and bool(v.get("behavioral"))
        return ok, (last if ok else out[-2000:])

    # ------------------------------------------------------------------ grade
    def grade(self, cand: Path, gates: list[str] | None = None) -> dict:
        gates = gates or self.meta["gates"]
        res: dict = {"task": self.meta["id"], "gates": {}}
        with tempfile.TemporaryDirectory(prefix=f"cvt_{self.meta['id']}_") as td:
            ws = Path(td) / "ws"
            copy_ws(cand, ws)
            if "check" in gates:
                ok, why = self.check(ws)
                res["gates"]["check"] = {"ok": ok, "detail": why[-800:]}
            if "fidelity" in gates:
                ok, why, info = self.fidelity(ws)
                res["gates"]["fidelity"] = {"ok": ok, "detail": why, **info}
            if "start" in gates:
                # serve from a pristine copy (python/ stripped, no grader files)
                with tempfile.TemporaryDirectory(prefix="cvt_srv_") as sd:
                    sw = Path(sd) / "ws"
                    copy_ws(cand, sw)
                    for d in self.strip:
                        shutil.rmtree(sw / d, ignore_errors=True)
                    ok, why = self.start(sw)
                res["gates"]["start"] = {"ok": ok, "detail": why[-1500:]}
            if "test" in gates:
                ok, why = self.test(ws)
                res["gates"]["test"] = {"ok": ok, "detail": why}
        res["pass"] = all(g["ok"] for g in res["gates"].values())
        return res


def reference_mass(task_dir: Path) -> int:
    t = Task(task_dir)
    ref = t.grader / "reference"
    return sum(code_mass((ref / p).read_text(errors="replace")) for p in t.targets if (ref / p).exists())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("task")
    ap.add_argument("candidate", nargs="?")
    ap.add_argument("--reference", action="store_true")
    ap.add_argument("--gates", help="comma list overriding task gates")
    a = ap.parse_args()
    t = Task(Path(a.task))
    cand = t.grader / "reference" if a.reference else Path(a.candidate)
    r = t.grade(cand, a.gates.split(",") if a.gates else None)
    print(json.dumps(r, indent=1))
    return 0 if r["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
