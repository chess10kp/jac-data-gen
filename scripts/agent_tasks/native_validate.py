#!/usr/bin/env python3
"""Validate one `native` agent task (data/agent_tasks/native/<id>/).

Adapted from scripts/eval/validate_task.py (the Jac-native eval Phase-1 gate)
for the agent-task layout:

    <id>/task.json  request.md  starter/  grader/{reference/, tests.jac,
         alternatives/<name>/, negatives/<name>.json|<name>/, probes/, gate.json, notes.md}

Every candidate is assembled in its own temp workspace (which is also the
process CWD, so the Jac graph store is isolated per candidate):

  starter      -> copy of starter/
  reference    -> copy of grader/reference/ (the solved workspace)
  alternative  -> starter/ overlaid with grader/alternatives/<name>/
  negative     -> reference with the edits in negatives/<name>.json applied
                  (or starter overlaid with negatives/<name>/)

The hidden suite is dropped in as a SEPARATE module `grader_tests.jac` that
imports the target (never concatenated). Run-gate probes are copied next to it.

Gates (all must hold for validated=true):
  starter_fails   hidden tests do NOT pass on the untouched starter
  check           `jac check` passes on every target path (ref + alts)
  test            hidden tests pass (ref + alts)
  run             grader/gate.json run_steps pass, executed sequentially in ONE
                  workspace as separate `jac run` processes (cross-process
                  persistence for OSP tasks)                       [if declared]
  start           reference served with `jac run --serve`; HTTP probes pass  [if declared]
  contracts       `jac code map` archetype contracts (ref + alts)  [if declared]
  negatives       each mutant passes `jac check` but is killed by test/run gates
  determinism     reference hidden-test outcome stable across repeats
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path
from typing import Any, Callable

TEST_MODULE = "grader_tests.jac"


class GateError(Exception):
    pass


def task_hash(task_dir: Path) -> str:
    h = hashlib.sha256()
    for p in sorted(task_dir.rglob("*")):
        if p.is_file() and "__jac_gen__" not in p.parts and ".jac" not in p.parts:
            h.update(str(p.relative_to(task_dir)).encode())
            h.update(p.read_bytes())
    return h.hexdigest()[:16]


def _run(cmd: list[str], cwd: Path, timeout: float) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"") if isinstance(e.stdout, bytes) else (e.stdout or "")
        return 124, f"TIMEOUT after {timeout}s\n{out}"


def _copytree(src: Path, dst: Path) -> None:
    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns("__jac_gen__", ".jac", "__pycache__"))


LOG_DIR: Path | None = Path(os.environ["NATIVE_LOG_DIR"]) if os.environ.get("NATIVE_LOG_DIR") else None


def save_log(task_id: str, label: str, text: str) -> None:
    if LOG_DIR is None:
        return
    d = LOG_DIR / task_id
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{label.replace(':', '_')}.txt").write_text(text)


class Task:
    def __init__(self, task_dir: Path, jac: str):
        self.dir = task_dir
        self.jac = jac
        self.meta = json.loads((task_dir / "task.json").read_text())
        self.grader = task_dir / "grader"
        gp = self.grader / "gate.json"
        self.gate = json.loads(gp.read_text()) if gp.exists() else {}
        self.timeout = float(self.gate.get("timeout_s", 180))
        self.targets: list[str] = self.meta["target_paths"]

    # ---- workspace assembly -------------------------------------------------
    def _add_grader_files(self, wd: Path) -> None:
        shutil.copyfile(self.grader / "tests.jac", wd / TEST_MODULE)
        probes = self.grader / "probes"
        if probes.is_dir():
            for p in probes.iterdir():
                if p.is_file():
                    shutil.copyfile(p, wd / p.name)

    def workspace(self, kind: str, name: str = "") -> tempfile.TemporaryDirectory:
        tmp = tempfile.TemporaryDirectory(prefix=f"nat_{self.meta['id']}_{kind}_")
        wd = Path(tmp.name)
        if kind == "starter":
            _copytree(self.dir / "starter", wd)
        elif kind == "reference":
            _copytree(self.grader / "reference", wd)
        elif kind == "alt":
            _copytree(self.dir / "starter", wd)
            _copytree(self.grader / "alternatives" / name, wd)
        elif kind == "neg":
            spec_path = self.grader / "negatives" / f"{name}.json"
            if spec_path.exists():
                _copytree(self.grader / "reference", wd)
                spec = json.loads(spec_path.read_text())
                for ed in spec["edits"]:
                    f = wd / ed["file"]
                    src = f.read_text()
                    n = src.count(ed["old"])
                    if n != 1:
                        tmp.cleanup()
                        raise GateError(f"negative {name}: edit anchor occurs {n}x in {ed['file']}: {ed['old'][:60]!r}")
                    f.write_text(src.replace(ed["old"], ed["new"]))
            else:
                _copytree(self.dir / "starter", wd)
                _copytree(self.grader / "negatives" / name, wd)
        else:
            raise ValueError(kind)
        self._add_grader_files(wd)
        return tmp

    def alternatives(self) -> list[str]:
        d = self.grader / "alternatives"
        return sorted(p.name for p in d.iterdir() if p.is_dir()) if d.is_dir() else []

    def negatives(self) -> list[str]:
        d = self.grader / "negatives"
        if not d.is_dir():
            return []
        names = {p.stem for p in d.glob("*.json")} | {p.name for p in d.iterdir() if p.is_dir()}
        return sorted(names)

    # ---- primitive gates ----------------------------------------------------
    def check(self, wd: Path) -> tuple[bool, str]:
        for t in self.targets:
            if not (wd / t).exists():
                return False, f"missing target {t}"
            rc, out = _run([self.jac, "check", t], wd, self.timeout)
            if rc != 0:
                return False, f"{t}: {out[-600:]}"
        return True, ""

    def test(self, wd: Path) -> tuple[bool, str]:
        rc, out = _run([self.jac, "test", TEST_MODULE], wd, self.timeout)
        import re
        # Never trust the exit code alone (an unimportable target reports "1 skipped", rc 0):
        # require exactly as many passes as declared test blocks, and no fail/error/skip.
        expected = len(re.findall(r'^test\s+"', (self.grader / "tests.jac").read_text(), re.M))
        m = re.search(r"\b(\d+) passed", out)
        ok = (rc == 0 and m is not None and int(m.group(1)) == expected
              and re.search(r"\b[1-9]\d* (failed|errors?|skipped)\b", out) is None)
        self.last_test_out = out
        return ok, out[-1500:]

    def run_steps(self, wd: Path) -> tuple[bool, str]:
        for i, step in enumerate(self.gate.get("run_steps", [])):
            rc, out = _run([self.jac, "run", step["file"], *step.get("args", [])], wd, self.timeout)
            if rc != 0:
                return False, f"step {i} {step['file']}: rc={rc}\n{out[-600:]}"
            for s in step.get("expect", []):
                if s not in out:
                    return False, f"step {i} {step['file']}: expected {s!r} in output\n{out[-600:]}"
            for s in step.get("forbid", []):
                if s in out:
                    return False, f"step {i} {step['file']}: forbidden {s!r} in output\n{out[-600:]}"
        return True, ""

    def start(self, wd: Path) -> tuple[bool, str]:
        spec = self.gate["start"]
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            port = s.getsockname()[1]
        log = open(wd / "serve.log", "w")
        proc = subprocess.Popen([self.jac, "run", "--serve", "--no-client", "-p", str(port), spec["entry"]],
                                cwd=wd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        base = f"http://127.0.0.1:{port}"
        try:
            deadline = time.time() + float(spec.get("boot_s", 120))
            up = False
            while time.time() < deadline:
                if proc.poll() is not None:
                    break
                try:
                    with urllib.request.urlopen(base + "/healthz", timeout=3) as r:
                        up = r.status == 200
                        if up:
                            break
                except Exception:
                    time.sleep(1)
            if not up:
                log.flush()
                return False, "server did not come up\n" + (wd / "serve.log").read_text()[-800:]
            for i, rq in enumerate(spec.get("requests", [])):
                data = json.dumps(rq.get("json", {})).encode()
                req = urllib.request.Request(base + rq["path"], data=data, method=rq.get("method", "POST"),
                                             headers={"Content-Type": "application/json"})
                try:
                    with urllib.request.urlopen(req, timeout=30) as r:
                        body = r.read().decode()
                except urllib.error.HTTPError as e:
                    body = e.read().decode()
                flat = "".join(body.split())
                for s in rq.get("expect", []):
                    if "".join(s.split()) not in flat:
                        return False, f"request {i} {rq['path']}: expected {s!r} in {body[:500]}"
            return True, f"served on :{port}, {len(spec.get('requests', []))} probes ok"
        finally:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
                proc.wait(timeout=15)
            except Exception:
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except Exception:
                    pass
            log.close()

    def contracts(self, wd: Path) -> tuple[bool | None, str]:
        want = self.gate.get("contracts", [])
        if not want:
            return True, ""
        rc, out = _run([self.jac, "code", "map"], wd, self.timeout)
        try:
            arch = json.loads(out[out.index("{"):]).get("archetypes", []) if rc == 0 else None
        except Exception:
            arch = None
        if arch is None:
            return None, f"jac code map unavailable (rc={rc}): {out[-300:]}"
        have = {(a.get("name"), a.get("kind")) for a in arch}
        missing = [c for c in want if (c["name"], c["kind"]) not in have]
        if missing:
            return False, f"missing archetypes: {missing}"
        return True, ""


def validate(task_dir: Path, jac: str = "jac", repeats: int = 3, log: Callable[[str], None] = print) -> dict[str, Any]:
    t = Task(task_dir, jac)
    t0 = time.time()
    ok: list[str] = []
    fail: list[str] = []
    gates_declared = set(t.meta["gates"])
    has_run = bool(t.gate.get("run_steps"))
    has_start = "start" in t.gate

    def ws(kind: str, name: str, fn):
        with t.workspace(kind, name) as tmp:
            return fn(Path(tmp))

    # 0. starter must not already satisfy the task.
    def _starter(wd: Path):
        c, _ = t.check(wd) if all((wd / x).exists() for x in t.targets) else (False, "")
        passed, _ = t.test(wd)
        return c, passed
    s_check, s_pass = ws("starter", "", _starter)
    (fail if s_pass else ok).append(f"STARTER hidden tests {'PASS (task trivial)' if s_pass else 'fail as expected'}; starter check={'ok' if s_check else 'fails/incomplete'}")

    # 1. positives
    positives = [("reference", "")] + [("alt", a) for a in t.alternatives()]
    if len(positives) < 2:
        fail.append("need reference + >=1 structurally different alternative")
    for kind, name in positives:
        label = kind if not name else f"alt:{name}"

        def _pos(wd: Path):
            c, cout = t.check(wd)
            if not c:
                raise GateError(f"{label}: jac check FAILED\n{cout}")
            con, conout = t.contracts(wd)
            if con is False:
                raise GateError(f"{label}: contracts: {conout}")
            p, tout = t.test(wd)
            if not p:
                save_log(t.meta["id"], label + "_test", t.last_test_out)
                raise GateError(f"{label}: hidden tests FAILED\n{tout}")
            if has_run:
                r, rout = t.run_steps(wd)
                if not r:
                    raise GateError(f"{label}: run gate FAILED\n{rout}")
            extra = ""
            if has_start and kind == "reference":
                s, sout = t.start(wd)
                if not s:
                    raise GateError(f"{label}: start gate FAILED\n{sout}")
                extra = f"; start: {sout}"
            return ("contracts n/a: " + conout[:80]) if con is None else "", extra
        try:
            note, extra = ws(kind, name, _pos)
            ok.append(f"POS {label}: check+test{'+run' if has_run else ''}{'+contracts' if t.gate.get('contracts') else ''} pass{extra}{(' ['+note+']') if note else ''}")
        except GateError as e:
            fail.append(str(e))

    # 2. negatives
    negs = t.negatives()
    if len(negs) < 3:
        fail.append(f"only {len(negs)} negatives; need >=3")
    for name in negs:
        def _neg(wd: Path):
            c, cout = t.check(wd)
            if not c:
                return "stillborn", cout
            p, tout = t.test(wd)
            if not p:
                return "killed:test", ""
            if has_run:
                r, _ = t.run_steps(wd)
                if not r:
                    return "killed:run", ""
            return "survived", tout
        try:
            status, out = ws("neg", name, _neg)
        except GateError as e:
            fail.append(str(e))
            continue
        if status == "stillborn":
            fail.append(f"NEG {name}: does not compile (mutants must be valid programs)\n{out[-400:]}")
        elif status == "survived":
            fail.append(f"NEG {name}: SURVIVED (coverage hole)")
        else:
            ok.append(f"NEG {name}: {status}")

    # 3. determinism
    outcomes = []
    for i in range(max(1, repeats)):
        outcomes.append(ws("reference", "", lambda wd: t.test(wd)[0]))
        if not outcomes[-1]:
            save_log(t.meta["id"], f"det_{i}", t.last_test_out)
    if len(set(outcomes)) != 1 or not outcomes[0]:
        fail.append(f"DET reference unstable across {repeats} runs: {outcomes}")
    else:
        ok.append(f"DET reference stable across {repeats} runs")

    # Gate bookkeeping: declared gates must be backed by an actual check.
    backing = {"check": True, "test": True, "run": has_run, "start": has_start}
    for g in gates_declared:
        if not backing.get(g, False):
            fail.append(f"declared gate {g!r} has no backing check")

    res = {
        "id": t.meta["id"], "level": t.meta["level"], "hash": task_hash(task_dir),
        "validated": not fail, "ok": ok, "fail": fail,
        "n_alternatives": len(positives) - 1, "n_negatives": len(negs),
        "seconds": round(time.time() - t0, 1), "jac": _run([jac, "--version"], task_dir, 30)[1].strip(),
    }
    log(f"=== {res['id']} (L{res['level']}) {'VALIDATED' if res['validated'] else 'NOT VALIDATED'} in {res['seconds']}s")
    for line in ok:
        log(f"  PASS {line}")
    for line in fail:
        log(f"  FAIL {line}")
    return res


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("task_dir", type=Path)
    ap.add_argument("--jac", default="jac")
    ap.add_argument("--repeats", type=int, default=3)
    a = ap.parse_args()
    r = validate(a.task_dir, a.jac, a.repeats)
    return 0 if r["validated"] else 1


if __name__ == "__main__":
    sys.exit(main())
