#!/usr/bin/env python3
"""Build + validate the `debug` agent-task pool (data/agent_tasks/debug/).

A debug task: the code COMPILES (`jac check` green) but behaves wrong. The agent
gets a realistic bug report (request.md, never the bug location) and must find
and fix the root cause.

Construction (no jac needed): every spec in debug_specs.SPECS names a VALIDATED
source task of another kind (native/<id> or app/<id>), whose grader/reference is
a solved workspace. We inject 1 (levels 1-3) or 2 interacting (levels 4-5)
semantic bugs as exact old->new edits:

  <id>/task.json         kind=debug, gates check+test+fidelity (+run/start from source)
  <id>/request.md        the bug report
  <id>/starter/          source reference with the bug edits applied (+ optional visible repro)
  <id>/grader/reference/ source reference (+ the same repro file) = the fixed workspace
  <id>/grader/tests.jac  source hidden tests (regressions) + spec extra_tests (the symptom)
  <id>/grader/bugs/<n>.json  each injected bug as an edit list against reference/
  <id>/grader/{gate.json,probes/}  copied from the source (run/start gates)
  <id>/grader/symbols.json  fidelity inventory (filled from the CI validation)
  <id>/grader/notes.md   root cause(s) + fix, hidden

Validation (jac; runs on GitHub Actions, see .ci/agent-tasks/debug.sh):
  REF       reference passes every gate (check/test/run/start/fidelity), x2 determinism
  STARTER   compiles (`jac check`), FAILS the hidden tests (bug is observable)
  BUG_i     (multi-bug) each bug alone compiles and is killed by the hidden tests
  FIDELITY  starter (a minimal edit away from correct) passes fidelity; a
            body-stubbed reference fails it
  REPRO     (if the starter ships one) fails on the starter, passes on the reference

Commands:
  debug_build.py build [--only ID,..]           materialize task dirs from specs
  debug_build.py validate --shard i/n --out DIR  (CI) -> DIR/debug_results.jsonl
  debug_build.py merge runs/ci/debug/<run_id>    -> .validation/, symbols.json, manifest
  debug_build.py manifest                        rebuild manifest (+dedup, source validated?)
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import debug_gate  # noqa: E402
import fix_gate  # noqa: E402
import native_validate as nv  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
ROOT = REPO / "data" / "agent_tasks"
OUT = ROOT / "debug"
VALID = OUT / ".validation"
MANIFEST = OUT / "manifest.jsonl"
JAC_VERSION = "0.36.1"
IGNORE = shutil.ignore_patterns(".jac", "__jac_gen__", "__pycache__", "node_modules", "*.log")


def specs() -> list[dict]:
    import importlib
    import debug_specs
    importlib.reload(debug_specs)
    return debug_specs.SPECS


def task_hash(d: Path) -> str:
    h = hashlib.sha256()
    for p in sorted(d.rglob("*")):
        if p.is_file() and ".jac" not in p.relative_to(d).parts[:-1] and p.name != "symbols.json":
            h.update(str(p.relative_to(d)).encode())
            h.update(p.read_bytes())
    return h.hexdigest()[:16]


def ref_hash(d: Path) -> str:
    """Content hash of a source reference (ignoring caches) - detects source drift."""
    h = hashlib.sha256()
    for p in sorted(d.rglob("*")):
        if p.is_file() and not ({".jac", "__jac_gen__", "__pycache__"} & set(p.relative_to(d).parts[:-1])):
            h.update(str(p.relative_to(d)).encode())
            h.update(p.read_bytes())
    return h.hexdigest()[:16]


def apply_edits(ws: Path, edits: list[dict], label: str) -> None:
    for ed in edits:
        f = ws / ed["file"]
        src = f.read_text()
        n = src.count(ed["old"])
        if n != 1:
            raise ValueError(f"{label}: anchor occurs {n}x in {ed['file']}: {ed['old'][:70]!r}")
        f.write_text(src.replace(ed["old"], ed["new"]))


# --------------------------------------------------------------------------- build
def build_one(s: dict) -> Path:
    src = ROOT / s["src"]
    smeta = json.loads((src / "task.json").read_text())
    d = OUT / s["id"]
    if d.exists():
        shutil.rmtree(d)
    (d / "grader" / "bugs").mkdir(parents=True)
    ref = d / "grader" / "reference"
    shutil.copytree(src / "grader" / "reference", ref, ignore=IGNORE)
    if smeta["kind"] == "app":  # app references overlay their starter
        tmp = d / "_ref"
        shutil.copytree(src / "starter", tmp, ignore=IGNORE)
        shutil.copytree(ref, tmp, dirs_exist_ok=True)
        shutil.rmtree(ref)
        tmp.rename(ref)
    repro = s.get("repro")
    if repro:
        (ref / repro["file"]).write_text(repro["content"].lstrip("\n"))
    starter = d / "starter"
    shutil.copytree(ref, starter)
    for i, b in enumerate(s["bugs"]):
        apply_edits(starter, b["edits"], f"{s['id']} bug{i}")
        # each bug must also apply alone to the reference
        with tempfile.TemporaryDirectory() as t:
            shutil.copytree(ref, Path(t) / "w")
            apply_edits(Path(t) / "w", b["edits"], f"{s['id']} bug{i} (alone)")
        (d / "grader" / "bugs" / f"bug{i}.json").write_text(json.dumps(b, indent=1) + "\n")
    tests = (src / "grader" / "tests.jac").read_text().rstrip() + "\n"
    if s.get("extra_tests"):
        tests += "\n" + s["extra_tests"].strip("\n") + "\n"
    (d / "grader" / "tests.jac").write_text(tests)
    gate = {}
    if (src / "grader" / "gate.json").exists():
        gate = json.loads((src / "grader" / "gate.json").read_text())
    gate.pop("contracts", None)  # fidelity supersedes archetype contracts
    if repro:
        gate["repro"] = {k: v for k, v in repro.items() if k != "content"}
    (d / "grader" / "gate.json").write_text(json.dumps(gate, indent=1) + "\n")
    if (src / "grader" / "behavioral.py").exists():
        shutil.copy(src / "grader" / "behavioral.py", d / "grader" / "behavioral.py")
    if (src / "grader" / "probes").is_dir():
        shutil.copytree(src / "grader" / "probes", d / "grader" / "probes", ignore=IGNORE)
    gates = ["check", "test"]
    if gate.get("run_steps"):
        gates.append("run")
    if "start" in gate:
        gates.append("start")
    if (d / "grader" / "behavioral.py").exists():
        gates.append("behavioral")
    gates.append("fidelity")
    task = {
        "id": s["id"], "kind": "debug", "level": s["level"], "source": f"injected-bug:{s['src']}",
        "gates": gates, "target_paths": smeta["target_paths"], "jac_version": JAC_VERSION,
        "license": smeta.get("license", "original-authored (jac_llm_data agent-task pool)"),
        "provenance": {
            "source_task": s["src"], "source_level": smeta["level"],
            "source_ref_hash": ref_hash(src / "grader" / "reference"),
            "title": s.get("title", smeta.get("provenance", {}).get("title", "")),
            "domain": smeta.get("provenance", {}).get("domain", ""),
            "n_bugs": len(s["bugs"]), "bug_classes": [b["cls"] for b in s["bugs"]],
            "visible_repro": bool(repro), "author": "claude (debug-kind builder)", "created": "2026-10-10",
        },
    }
    (d / "task.json").write_text(json.dumps(task, indent=1) + "\n")
    (d / "request.md").write_text(s["request"].strip() + "\n")
    notes = [f"# {s['id']}  (debug, L{s['level']}, from {s['src']})", ""]
    for i, b in enumerate(s["bugs"]):
        notes.append(f"## bug{i} [{b['cls']}]: {b['why']}")
        for ed in b["edits"]:
            notes += [f"- {ed['file']}: fix by restoring", "```", ed["old"].rstrip(), "```",
                      "(injected as)", "```", ed["new"].rstrip(), "```"]
        notes.append("")
    if s.get("notes"):
        notes.append(s["notes"].strip())
    (d / "grader" / "notes.md").write_text("\n".join(notes) + "\n")
    return d


def cmd_build(a) -> None:
    only = set(a.only.split(",")) if a.only else None
    OUT.mkdir(parents=True, exist_ok=True)
    seen = set()
    for s in specs():
        assert s["id"] not in seen, s["id"]
        seen.add(s["id"])
        if only and s["id"] not in only:
            continue
        assert (s["level"] >= 4) == (len(s["bugs"]) >= 2), f"{s['id']}: L4-5 <=> 2 bugs"
        try:
            build_one(s)
            print("built", s["id"])
        except Exception as e:
            print("FAILED", s["id"], e)
            shutil.rmtree(OUT / s["id"], ignore_errors=True)
    stale = {p.name for p in OUT.iterdir() if p.is_dir() and not p.name.startswith((".", "_"))} - seen
    for n in sorted(stale):
        print("stale task dir (no spec):", n)


# --------------------------------------------------------------------------- validate
def _fails(t: nv.Task, wd: Path) -> tuple[str, str]:
    """Run gates on a bugged workspace: 'stillborn' | 'killed:test' | 'killed:run' | 'survived'."""
    c, cout = t.check(wd)
    if not c:
        return "stillborn", cout[-500:]
    p, tout = t.test(wd)
    if not p:
        return "killed:test", tout
    if t.gate.get("run_steps"):
        r, rout = t.run_steps(wd)
        if not r:
            return "killed:run", rout
    if "behavioral" in t.meta["gates"]:
        r, rout = debug_gate.behavioral(t.dir, wd, t.timeout)
        if not r:
            return "killed:behavioral", rout
    return "survived", tout


FAILED_TEST_RE = re.compile(r"(?:FAIL|✖|ERROR)[:\s]+(?:test\s+)?[\"']?([^\n\"']{3,80})")


def _ws(src: Path, t: nv.Task) -> tempfile.TemporaryDirectory:
    tmp = tempfile.TemporaryDirectory(prefix=f"dbgv_{t.meta['id']}_")
    nv._copytree(src, Path(tmp.name))
    t._add_grader_files(Path(tmp.name))
    return tmp


def _repro(t: nv.Task, wd: Path, spec: dict) -> tuple[bool, str]:
    """True = repro shows the problem is GONE (passes)."""
    if spec["kind"] == "test":
        rc, out = nv._run([t.jac, "test", spec["file"]], wd, t.timeout)
        ok = rc == 0 and re.search(r"\b[1-9]\d* passed", out) is not None and \
            re.search(r"\b[1-9]\d* (failed|errors?)\b", out) is None
        return ok, out[-800:]
    rc, out = nv._run([t.jac, "run", spec["file"]], wd, t.timeout)
    ok = rc == 0 and all(x in out for x in spec.get("expect", []))
    return ok, out[-800:]


def validate_one(d: Path, jac: str = "jac") -> dict:
    t = nv.Task(d, jac)
    t0 = time.time()
    ok, fail = [], []
    ref, starter = d / "grader" / "reference", d / "starter"
    with tempfile.TemporaryDirectory() as tmp:
        w = Path(tmp) / "ref"
        nv._copytree(ref, w)
        inv = debug_gate.inventory(w, t.targets)
    for rep in range(2):
        g = debug_gate.grade(d, ref, jac, inv)
        if g["pass"]:
            ok.append(f"REF pass {'+'.join(g['gates'])} (run {rep + 1})")
        else:
            fail.append(f"REF run {rep + 1} FAILED: " + json.dumps({k: v for k, v in g["gates"].items() if not v["ok"]})[:1500])
            break
    with _ws(starter, t) as wd:
        status, out = _fails(t, Path(wd))
    failed_tests = sorted(set(m.strip() for m in FAILED_TEST_RE.findall(out)))[:12] if status.startswith("killed") else []
    if status == "killed:test":
        ok.append(f"STARTER compiles and fails hidden tests ({len(failed_tests)} failing lines)")
    else:
        fail.append(f"STARTER {status}: {out[-600:]}")
    bugs = sorted((d / "grader" / "bugs").glob("bug*.json"))
    if len(bugs) > 1:
        for b in bugs:
            spec = json.loads(b.read_text())
            with tempfile.TemporaryDirectory() as tmp:
                w = Path(tmp) / "w"
                nv._copytree(ref, w)
                apply_edits(w, spec["edits"], b.stem)
                t._add_grader_files(w)
                st, out2 = _fails(t, w)
            (ok if st == "killed:test" else fail).append(f"BUG {b.stem} alone: {st}" + ("" if st == "killed:test" else f" {out2[-300:]}"))
    fs = debug_gate.fidelity(d, starter, inv)
    (ok if fs["ok"] else fail).append(f"FIDELITY starter (minimal-edit profile) {'passes' if fs['ok'] else 'FAILS: ' + str(fs['reasons'])} sym={fs['symbols']} mass={fs['mass']}")
    with tempfile.TemporaryDirectory() as tmp:
        s = Path(tmp) / "stub"
        fix_gate.make_stub(ref, s)
        fstub = debug_gate.fidelity(d, s, inv)
    (fail if fstub["ok"] else ok).append(f"FIDELITY stubbed reference {'PASSES (gate too weak)' if fstub['ok'] else 'rejected'} sym={fstub['symbols']} mass={fstub['mass']}")
    rspec = t.gate.get("repro")
    if rspec:
        with _ws(starter, t) as wd:
            s_ok, s_out = _repro(t, Path(wd), rspec)
        with _ws(ref, t) as wd:
            r_ok, r_out = _repro(t, Path(wd), rspec)
        if not s_ok and r_ok:
            ok.append(f"REPRO {rspec['file']}: fails on starter, passes on reference")
        else:
            fail.append(f"REPRO {rspec['file']}: starter_ok={s_ok} ref_ok={r_ok}\nSTARTER:{s_out[-400:]}\nREF:{r_out[-400:]}")
    res = {"id": t.meta["id"], "level": t.meta["level"], "hash": task_hash(d), "validated": not fail,
           "ok": ok, "fail": fail, "starter_failing": failed_tests, "starter_test_tail": out[-1500:],
           "symbols": inv, "seconds": round(time.time() - t0, 1),
           "jac": nv._run([jac, "--version"], d, 30)[1].strip()[:60]}
    print(f"=== {res['id']} {'VALIDATED' if res['validated'] else 'NOT VALIDATED'} {res['seconds']}s", flush=True)
    for x in ok:
        print("  PASS", x)
    for x in fail:
        print("  FAIL", x[:800])
    return res


def task_dirs() -> list[Path]:
    return sorted(p for p in OUT.iterdir() if (p / "task.json").exists())


def cmd_validate(a) -> None:
    i, n = map(int, a.shard.split("/"))
    ds = [p for k, p in enumerate(task_dirs()) if k % n == i]
    if a.only:
        ds = [p for p in ds if p.name in set(a.only.split(","))]
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "debug_results.jsonl", "a") as f:
        for d in ds:
            print(f"--- start {d.name} {time.strftime('%H:%M:%S')}", flush=True)
            try:
                r = validate_one(d, a.jac)
            except Exception as e:
                r = {"id": d.name, "validated": False, "fail": [f"crash: {e!r}"], "ok": [], "hash": task_hash(d)}
            f.write(json.dumps(r) + "\n")
            f.flush()


# --------------------------------------------------------------------------- merge/manifest
def source_validated() -> dict[str, str]:
    """source -> "" if usable, else why not. Usable = its kind's manifest says
    validated:true, the source task targets jac 0.36.1, and the manifest row's
    hash matches the source dir as it is NOW (validation is of current content)."""
    import app_build
    hashers = {"native": nv.task_hash, "app": app_build.task_hash}
    st: dict[str, str] = {}
    for kind in ("native", "app"):
        m = ROOT / kind / "manifest.jsonl"
        if not m.exists():
            continue
        for line in m.read_text().splitlines():
            if not line.strip():
                continue
            r = json.loads(line)
            d = ROOT / kind / r["id"]
            why = []
            if not r.get("validated"):
                why.append("not validated")
            if d.exists():
                if json.loads((d / "task.json").read_text()).get("jac_version") != JAC_VERSION:
                    why.append(f"not on jac {JAC_VERSION}")
                if r.get("hash") and r["hash"] != hashers[kind](d):
                    why.append("changed since its validation")
            st[f"{kind}/{r['id']}"] = ", ".join(why)
    return st


def cmd_merge(a) -> None:
    VALID.mkdir(parents=True, exist_ok=True)
    run_id = Path(a.run_dir).name
    n = 0
    for f in Path(a.run_dir).rglob("debug_results.jsonl"):
        for line in f.read_text().splitlines():
            r = json.loads(line)
            d = OUT / r["id"]
            if not d.exists():
                continue
            r["ci_run"] = run_id
            if r.get("symbols"):
                (d / "grader" / "symbols.json").write_text(json.dumps(r["symbols"], indent=1) + "\n")
            if r.get("hash") != task_hash(d):
                r["stale"] = True
            (VALID / f"{r['id']}.json").write_text(json.dumps(r, indent=1) + "\n")
            n += 1
    print(f"merged {n} results from {run_id}")
    cmd_manifest(a)


def dedup(ds: list[Path]) -> dict[str, dict]:
    import native_dedup as nd
    return nd.dedup_all(ds)


def cmd_manifest(a) -> None:
    srcv = source_validated()
    ds = task_dirs()
    dd = dedup(ds)
    rows = []
    for d in ds:
        meta = json.loads((d / "task.json").read_text())
        v = VALID / f"{d.name}.json"
        r = json.loads(v.read_text()) if v.exists() else {}
        h = task_hash(d)
        src = meta["provenance"]["source_task"]
        reasons = []
        if not r:
            reasons.append("not yet validated")
        elif r.get("hash") != h:
            reasons.append("task changed since validation")
        elif not r.get("validated"):
            reasons.append("; ".join(x.splitlines()[0][:200] for x in r.get("fail", [])))
        if meta["provenance"].get("source_ref_hash") != ref_hash(ROOT / src / "grader" / "reference"):
            reasons.append("source reference changed since this task was built (rebuild)")
        sv = srcv.get(src, "not in its manifest")
        if sv:
            reasons.append(f"source {src}: {sv}")
        if not dd[d.name]["clean"]:
            reasons.append("dedup: " + dd[d.name]["reason"])
        ok = not reasons
        rows.append({"id": d.name, "level": meta["level"], "source": meta["source"], "gates": meta["gates"],
                     "validated": ok,
                     "reason": "; ".join(reasons) if reasons else
                     f"ref passes {'/'.join(meta['gates'])} x2; starter compiles + fails hidden tests; "
                     f"{meta['provenance']['n_bugs']} bug(s) each killed:test; stub rejected by fidelity"
                     + ("; visible repro fails->passes" if meta["provenance"]["visible_repro"] else ""),
                     "n_bugs": meta["provenance"]["n_bugs"], "bug_classes": meta["provenance"]["bug_classes"],
                     "visible_repro": meta["provenance"]["visible_repro"],
                     "hash": h, "ci_run": r.get("ci_run"), "dedup": dd[d.name]})
    MANIFEST.write_text("".join(json.dumps(x) + "\n" for x in rows))
    from collections import Counter
    c = Counter((x["level"], x["validated"]) for x in rows)
    print(f"manifest: {sum(x['validated'] for x in rows)}/{len(rows)} validated;",
          {f"L{lv}": f"{c[(lv, True)]}/{c[(lv, True)] + c[(lv, False)]}" for lv in sorted({x['level'] for x in rows})})
    for x in rows:
        if not x["validated"]:
            print("  -", x["id"], ":", x["reason"][:300])


def main() -> int:
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    b = sp.add_parser("build")
    b.add_argument("--only")
    v = sp.add_parser("validate")
    v.add_argument("--shard", default="0/1")
    v.add_argument("--out", default="runs/debug_local")
    v.add_argument("--only")
    v.add_argument("--jac", default="jac")
    m = sp.add_parser("merge")
    m.add_argument("run_dir")
    sp.add_parser("manifest")
    a = ap.parse_args()
    {"build": cmd_build, "validate": cmd_validate, "merge": cmd_merge, "manifest": cmd_manifest}[a.cmd](a)
    return 0


if __name__ == "__main__":
    sys.exit(main())
