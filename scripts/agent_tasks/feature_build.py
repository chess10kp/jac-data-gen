#!/usr/bin/env python3
"""Build + validate the `feature` kind of the agentic-task pool (data/agent_tasks/feature/).

A feature task = a real gold-tier JacHacks repo (starter/) plus a natural feature
request (request.md). Hidden grader:
  grader/reference/      solved workspace (starter + the reference implementation)
  grader/tests.jac       new-behaviour checks + regression checks, imports the target
                         modules through the interface named in the request
  grader/regression.jac  regression-only subset (must pass on the untouched starter)
  grader/smoke.py        optional HTTP check (gate "start"): python smoke.py <ws>
  grader/notes.md        what is checked and why

Authoring (by hand): create data/agent_tasks/feature/<id>/ with task.json
(id, level, gates, provenance.repo, provenance.test_dest, ...), request.md,
grader/tests.jac, grader/regression.jac, grader/notes.md and ONLY the changed /
new files under grader/reference/. `materialize` then fills starter/ from the
repo's 0.37.25-green tree (shipped by the repo_score CI run) and copies every
untouched file into grader/reference/ — it never overwrites an authored file,
so re-running is safe (resumable).

Stages
  materialize   (local, no jac)  fill starter/ + reference/, compute target_paths
  validate      (CI, sharded)    per task, in throwaway dirs outside the repo:
                  reference: jac check green, tests.jac pass, regression.jac pass
                  starter:   jac check green, regression.jac pass, tests.jac FAIL
                  (+ smoke.py: pass on reference, fail on starter, when gate "start")
  manifest RUN  (local)          merge fetched CI results into manifest.jsonl

Usage
  feature_build.py materialize [--trees runs/ci/repo_score/<run_id>]
  feature_build.py validate --shard $SHARD/$NSHARDS --out $OUT
  feature_build.py manifest runs/ci/feature/<run_id>
"""
from __future__ import annotations

import argparse
import filecmp
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
ROOT = REPO / "data" / "agent_tasks" / "feature"
MANIFEST = ROOT / "manifest.jsonl"
JAC = os.environ.get("JAC_BIN", "jac")
JAC_VERSION = "0.37.25"
DROP = re.compile(r"(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|\.env|\.env\.local)$")
SECRET = re.compile(r"(sk-(proj-|ant-)?[A-Za-z0-9_-]{24,}|AIza[0-9A-Za-z_-]{30,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|xox[bp]-[0-9A-Za-z-]{10,})")


def sh(cmd, cwd=None, timeout=600, env=None):
    p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                         errors="replace", start_new_session=True, env=env)
    try:
        out, _ = p.communicate(timeout=timeout)
        return p.returncode, out
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL)
        return None, (p.communicate()[0] or "") + "\n[timeout]"


def tasks() -> list[Path]:
    return sorted(p.parent for p in ROOT.glob("*/task.json"))


# ---------------------------------------------------------------------------
# materialize
# ---------------------------------------------------------------------------
def find_tree(trees_dir: Path, dirname: str) -> Path | None:
    hits = sorted(trees_dir.rglob(f"trees/{dirname}.tgz"))
    return hits[0] if hits else None


def files_of(d: Path) -> set[str]:
    return {str(p.relative_to(d)) for p in d.rglob("*") if p.is_file()}


def materialize(a):
    trees_dir = Path(a.trees)
    for t in tasks():
        tj = json.loads((t / "task.json").read_text())
        prov = tj.setdefault("provenance", {})
        starter = t / "starter"
        if not starter.exists():
            tgz = find_tree(trees_dir, prov["repo"])
            if not tgz:
                print(f"[{t.name}] no tree for {prov['repo']}", file=sys.stderr)
                continue
            starter.mkdir()
            with tarfile.open(tgz) as tf:
                for m in tf.getmembers():
                    if m.isfile() and not DROP.search(m.name):
                        tf.extract(m, starter, filter="data")
            prov["tree_run"] = tgz.parts[-4] if len(tgz.parts) >= 4 else str(tgz)
        ref = t / "grader" / "reference"
        ref.mkdir(parents=True, exist_ok=True)
        authored = files_of(ref)
        for rel in files_of(starter):
            q = ref / rel
            if not q.exists():
                q.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(starter / rel, q)
        s_files, r_files = files_of(starter), files_of(ref)
        changed = sorted(f for f in r_files if f not in s_files or not filecmp.cmp(starter / f, ref / f, shallow=False))
        removed = sorted(s_files - r_files)
        tj["target_paths"] = changed
        if removed:
            prov["removed_paths"] = removed
        tj.setdefault("kind", "feature")
        tj.setdefault("jac_version", JAC_VERSION)
        tj["id"] = t.name
        (t / "task.json").write_text(json.dumps(tj, indent=2) + "\n")
        leaks = [str(p) for p in t.rglob("*") if p.is_file() and p.suffix in (".jac", ".py", ".toml", ".md", ".json", ".js", ".ts")
                 and SECRET.search(p.read_text(errors="replace"))]
        print(f"[{t.name}] starter={len(s_files)} files, target_paths={changed}"
              + (f" SECRET? {leaks}" if leaks else ""))


# ---------------------------------------------------------------------------
# validate (CI)
# ---------------------------------------------------------------------------
SUMMARY = re.compile(r"(\d+) passed|(\d+) failed|(\d+) errors?")


def check(ws: Path) -> dict:
    rc, out = sh([JAC, "check", "-n", "."], cwd=ws, timeout=1200)
    m = re.search(r"=+ (.*?) in [\d.]+s =+", out)
    summ = m.group(1) if m else ""
    ok = rc is not None and bool(m) and "failed" not in summ and "✖ Error" not in out
    return {"ok": ok, "summary": summ, "tail": "" if ok else out[-1500:]}


def run_test(ws: Path, src: Path, dest: str) -> dict:
    q = ws / dest
    q.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, q)
    rc, out = sh([JAC, "test", dest], cwd=ws, timeout=600)
    q.unlink()
    tail = out[-600:]
    passed = sum(int(x) for x in re.findall(r"(\d+) passed", tail))
    failed = sum(int(x) for x in re.findall(r"(\d+) (?:failed|errors?|skipped)\b", tail))
    # jac test exits 0 with "1 skipped" when the target import fails: require the
    # exact expected test count to pass
    expected = len(re.findall(r'^\s*test\s+(?:"[^"]*"|\w+)\s*\{', src.read_text(), re.M))
    ok = rc == 0 and failed == 0 and passed == expected and expected > 0
    return {"ok": ok, "rc": rc, "passed": passed, "failed": failed, "expected": expected, "tail": out[-2500:]}


def run_smoke(ws: Path, smoke: Path) -> dict:
    rc, out = sh([sys.executable, str(smoke), str(ws)], timeout=600)
    return {"ok": rc == 0, "rc": rc, "tail": out[-1500:]}


def validate_task(t: Path) -> dict:
    tj = json.loads((t / "task.json").read_text())
    g = t / "grader"
    dest = tj["provenance"].get("test_dest", "tests_feature.jac")
    res = {"id": t.name, "level": tj.get("level"), "gates": tj.get("gates")}
    for side in ("reference", "starter"):
        src = g / "reference" if side == "reference" else t / "starter"
        ws = Path(tempfile.mkdtemp(prefix=f"ft_{side}_")) / "ws"
        shutil.copytree(src, ws)
        r = {"check": check(ws)}
        if (g / "regression.jac").exists():
            r["regression"] = run_test(ws, g / "regression.jac", dest.replace(".jac", "_reg.jac"))
        if (g / "tests.jac").exists():
            r["tests"] = run_test(ws, g / "tests.jac", dest)
        if "start" in (tj.get("gates") or []) and (g / "smoke.py").exists():
            r["smoke"] = run_smoke(ws, g / "smoke.py")
        res[side] = r
        shutil.rmtree(ws.parent, ignore_errors=True)
    R, S = res["reference"], res["starter"]
    why = []
    if not R["check"]["ok"]:
        why.append("reference not green")
    if "tests" in R and not R["tests"]["ok"]:
        why.append("reference fails tests")
    if "regression" in R and not R["regression"]["ok"]:
        why.append("reference fails regression")
    if "smoke" in R and not R["smoke"]["ok"]:
        why.append("reference fails smoke")
    if not S["check"]["ok"]:
        why.append("starter not green")
    if "regression" in S and not S["regression"]["ok"]:
        why.append("starter fails regression")
    if "tests" in S and S["tests"]["ok"]:
        why.append("starter passes new tests")
    if "smoke" in S and S["smoke"]["ok"]:
        why.append("starter passes smoke")
    res["validated"] = not why
    res["reason"] = "; ".join(why) or "reference passes all; starter green + regression ok, new checks fail"
    return res


def validate(a):
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    i, n = map(int, a.shard.split("/"))
    ts = [t for k, t in enumerate(tasks()) if k % n == i]
    if a.only:
        ts = [t for t in tasks() if t.name in a.only.split(",")]
    with (out / "results.jsonl").open("a") as fh:
        for t in ts:
            t0 = time.time()
            try:
                r = validate_task(t)
            except Exception as e:
                r = {"id": t.name, "validated": False, "reason": f"error {e!r}"[:300]}
            r["secs"] = round(time.time() - t0, 1)
            fh.write(json.dumps(r) + "\n")
            fh.flush()
            print(f"[{t.name}] validated={r['validated']} {r['reason']}", flush=True)


# ---------------------------------------------------------------------------
# manifest
# ---------------------------------------------------------------------------
def manifest(a):
    res = {}
    for f in sorted(Path(a.run_dir).rglob("results.jsonl")):
        for l in f.open():
            o = json.loads(l)
            res[o["id"]] = o
    old = {}
    if MANIFEST.exists():
        old = {json.loads(l)["id"]: json.loads(l) for l in MANIFEST.open()}
    rows = []
    for t in tasks():
        tj = json.loads((t / "task.json").read_text())
        r = res.get(t.name)
        if r is None and t.name in old:
            rows.append(old[t.name])
            continue
        rows.append({"id": t.name, "level": tj["level"], "source": tj["source"], "gates": tj["gates"],
                     "validated": bool(r and r["validated"]),
                     "reason": (r or {}).get("reason", "not validated yet"),
                     "ci_run": Path(a.run_dir).name if r else None})
    MANIFEST.write_text("".join(json.dumps(r) + "\n" for r in rows))
    v = [r for r in rows if r["validated"]]
    print(f"{len(v)}/{len(rows)} validated")
    for r in rows:
        if not r["validated"]:
            print("  ", r["id"], r["reason"])


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("materialize")
    m.add_argument("--trees", default=str(REPO / "runs" / "ci" / "repo_score"))
    v = sub.add_parser("validate")
    v.add_argument("--shard", default="0/1")
    v.add_argument("--out", default=os.environ.get("OUT", "ci_out"))
    v.add_argument("--only", default="")
    mf = sub.add_parser("manifest")
    mf.add_argument("run_dir")
    a = ap.parse_args()
    {"materialize": materialize, "validate": validate, "manifest": manifest}[a.cmd](a)


if __name__ == "__main__":
    main()
