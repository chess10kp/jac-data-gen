#!/usr/bin/env python3
"""Build/validate the `refactor` agent-task pool and write its manifest.

A refactor task = working-but-unidiomatic Jac starter + a request to make it
idiomatic while preserving behaviour. Layout (data/agent_tasks/refactor/<id>/):

    task.json   usual schema + "idiom_targets": [{metric, op, value, desc}, ...]
    request.md  the lead-dev style ask (target design, not a spec)
    starter/    the un-idiomatic but WORKING workspace
    grader/reference/          the idiomatic rewrite (full workspace)
    grader/alternatives/<n>/   optional other idiomatic rewrites (full workspaces)
    grader/negatives/<n>.json  reference mutants {"edits":[{file,old,new}]}: must
                               compile and be KILLED by the hidden tests
    grader/tests.jac           hidden behaviour tests (separate module)
    grader/notes.md

Gates checked per task (all must hold for validated=true):
  starter   jac check ok + hidden tests PASS (it is working code) + idiom gate FAILS
  reference jac check ok + hidden tests PASS + idiom gate PASSES     (same for alts)
  negatives >=3, each compiles and is killed by the hidden tests
  determinism  reference + starter hidden-test outcome stable across repeats

Subcommands: validate [--shard i/n --out DIR] | merge RUN_DIR | manifest | lint
Heavy work (validate) runs on GitHub Actions via .ci/agent-tasks/refactor.sh.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
from native_validate import TEST_MODULE, GateError, _copytree, _run, task_hash  # noqa: E402
from refactor_gate import gate as idiom_gate, module_files  # noqa: E402

KIND = "refactor"
ROOT = REPO / "data" / "agent_tasks" / KIND
CACHE = ROOT / "build_results.jsonl"
RESULTS_NAME = "refactor_results.jsonl"


def task_dirs() -> list[Path]:
    return sorted(p for p in ROOT.iterdir() if (p / "task.json").exists())


class RTask:
    def __init__(self, d: Path, jac: str):
        self.dir, self.jac = d, jac
        self.meta = json.loads((d / "task.json").read_text())
        self.grader = d / "grader"
        self.targets = self.meta["idiom_targets"]
        self.timeout = float(self.meta.get("timeout_s", 240))

    def workspace(self, kind: str, name: str = "") -> tempfile.TemporaryDirectory:
        tmp = tempfile.TemporaryDirectory(prefix=f"ref_{self.meta['id']}_{kind}_")
        wd = Path(tmp.name)
        if kind == "starter":
            _copytree(self.dir / "starter", wd)
        elif kind == "reference":
            _copytree(self.grader / "reference", wd)
        elif kind == "alt":
            _copytree(self.grader / "alternatives" / name, wd)
        elif kind == "neg":
            _copytree(self.grader / "reference", wd)
            spec = json.loads((self.grader / "negatives" / f"{name}.json").read_text())
            for ed in spec["edits"]:
                f = wd / ed["file"]
                src = f.read_text()
                if src.count(ed["old"]) != 1:
                    tmp.cleanup()
                    raise GateError(f"negative {name}: anchor x{src.count(ed['old'])} in {ed['file']}: {ed['old'][:60]!r}")
                f.write_text(src.replace(ed["old"], ed["new"]))
        shutil.copyfile(self.grader / "tests.jac", wd / TEST_MODULE)
        return tmp

    def check(self, wd: Path) -> tuple[bool, str]:
        mods = module_files(wd)
        if not mods:
            return False, "no .jac modules"
        for f in mods:
            rc, out = _run([self.jac, "check", str(f.relative_to(wd))], wd, self.timeout)
            if rc != 0:
                return False, f"{f.relative_to(wd)}: {out[-600:]}"
        return True, ""

    def test(self, wd: Path) -> tuple[bool, str]:
        import re
        rc, out = _run([self.jac, "test", TEST_MODULE], wd, self.timeout)
        # exit code alone is not trusted (an unimportable target = "1 skipped", rc 0):
        # require exactly the expected number of passes and nothing failed/skipped.
        n = len(re.findall(r'^\s*test\s+"', (wd / TEST_MODULE).read_text(), re.M))
        ok = rc == 0 and re.search(rf"\b{n} passed", out) is not None \
            and re.search(r"\b[1-9]\d* (failed|errors?|skipped)\b", out) is None
        return ok, out[-1500:]


def _fails(g: dict) -> list[str]:
    return [f"{r['metric']} {r['op']} {r['want']} (got {r['got']})" for r in g["results"] if not r["ok"]] + g["errors"]


def validate(d: Path, jac: str = "jac", repeats: int = 2, log=print) -> dict[str, Any]:
    t = RTask(d, jac)
    t0 = time.time()
    ok: list[str] = []
    fail: list[str] = []
    info: dict[str, Any] = {}

    def ws(kind, name, fn):
        with t.workspace(kind, name) as tmp:
            return fn(Path(tmp))

    # starter: compiles, behaves, but is not idiomatic
    def _starter(wd: Path):
        c, cout = t.check(wd)
        p, tout = t.test(wd)
        g = idiom_gate(wd, t.targets, jac)
        return c, cout, p, tout, g
    c, cout, p, tout, g = ws("starter", "", _starter)
    info["starter_metrics"] = g["metrics"]
    n_tgt = len(t.targets)
    n_miss = sum(not r["ok"] for r in g["results"])
    info["starter_targets_missed"] = n_miss
    (ok if c else fail).append(f"STARTER check {'ok' if c else 'FAILED: ' + cout}")
    (ok if p else fail).append(f"STARTER hidden tests {'pass (behaviour baseline)' if p else 'FAILED: ' + tout}")
    if g["errors"]:
        fail.append(f"STARTER idiom gate errors: {g['errors']}")
    elif n_miss == 0:
        fail.append("STARTER already meets every idiom target (task trivial)")
    else:
        ok.append(f"STARTER idiom gate fails {n_miss}/{n_tgt} targets: {_fails(g)[:6]}")

    # positives
    alts_dir = t.grader / "alternatives"
    positives = [("reference", "")] + ([("alt", a.name) for a in sorted(alts_dir.iterdir()) if a.is_dir()]
                                       if alts_dir.is_dir() else [])
    for kind, name in positives:
        label = kind if not name else f"alt:{name}"

        def _pos(wd: Path):
            c, cout = t.check(wd)
            if not c:
                raise GateError(f"{label}: jac check FAILED\n{cout}")
            p, tout = t.test(wd)
            if not p:
                raise GateError(f"{label}: hidden tests FAILED\n{tout}")
            g = idiom_gate(wd, t.targets, jac)
            if not g["ok"]:
                raise GateError(f"{label}: idiom gate FAILED: {_fails(g)}")
            return g["metrics"]
        try:
            info[f"{label}_metrics"] = ws(kind, name, _pos)
            ok.append(f"POS {label}: check+test+idiom({n_tgt}/{n_tgt}) pass")
        except GateError as e:
            fail.append(str(e))

    # negatives (behaviour mutants of the reference)
    negs = sorted(p.stem for p in (t.grader / "negatives").glob("*.json")) if (t.grader / "negatives").is_dir() else []
    if len(negs) < 3:
        fail.append(f"only {len(negs)} negatives; need >=3")
    for name in negs:
        def _neg(wd: Path):
            c, cout = t.check(wd)
            if not c:
                return "stillborn", cout
            p, tout = t.test(wd)
            return ("survived", tout) if p else ("killed", "")
        try:
            st, out = ws("neg", name, _neg)
        except GateError as e:
            fail.append(str(e))
            continue
        if st == "stillborn":
            fail.append(f"NEG {name}: does not compile\n{out[-400:]}")
        elif st == "survived":
            fail.append(f"NEG {name}: SURVIVED (coverage hole)")
        else:
            ok.append(f"NEG {name}: killed")

    # determinism
    for kind in ("reference", "starter"):
        outs = [ws(kind, "", lambda wd: t.test(wd)[0]) for _ in range(max(1, repeats))]
        if len(set(outs)) != 1 or not outs[0]:
            fail.append(f"DET {kind} unstable/failing across {repeats} runs: {outs}")
        else:
            ok.append(f"DET {kind} stable x{repeats}")

    res = {"id": t.meta["id"], "level": t.meta["level"], "hash": task_hash(d), "validated": not fail,
           "ok": ok, "fail": fail, "n_alternatives": len(positives) - 1, "n_negatives": len(negs),
           "n_targets": n_tgt, "info": info, "seconds": round(time.time() - t0, 1),
           "jac": _run([jac, "--version"], d, 30)[1].strip()}
    log(f"=== {res['id']} (L{res['level']}) {'VALIDATED' if res['validated'] else 'NOT VALIDATED'} in {res['seconds']}s")
    for x in ok:
        log(f"  PASS {x}")
    for x in fail:
        log(f"  FAIL {x}")
    return res


def load_results(*paths: Path) -> dict[str, dict]:
    latest: dict[str, dict] = {}
    for path in paths:
        if path.exists():
            for line in path.read_text().splitlines():
                if line.strip():
                    r = json.loads(line)
                    latest[r["id"]] = r
    return latest


def cmd_validate(a) -> int:
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    res_path = out / RESULTS_NAME
    cache = load_results(CACHE, res_path)
    tasks = task_dirs()
    if a.only:
        tasks = [t for t in tasks if t.name in set(a.only.split(","))]
    shard, n = (int(x) for x in a.shard.split("/"))
    tasks = [t for i, t in enumerate(tasks) if i % n == shard]
    bad = 0
    with res_path.open("a") as fh:
        for t in tasks:
            h = task_hash(t)
            prev = cache.get(t.name)
            if not a.force and prev and prev.get("hash") == h and prev.get("validated"):
                print(f"=== {t.name}: cached VALIDATED (hash {h}), skip")
                continue
            try:
                r = validate(t, a.jac, a.repeats)
            except Exception as e:
                r = {"id": t.name, "level": None, "hash": h, "validated": False, "ok": [],
                     "fail": [f"harness error: {type(e).__name__}: {e}"], "n_alternatives": 0, "n_negatives": 0}
                print(f"=== {t.name}: HARNESS ERROR {e}")
            fh.write(json.dumps(r) + "\n")
            fh.flush()
            bad += not r["validated"]
    print(f"shard {a.shard}: {len(tasks)} tasks, {bad} not validated")
    return 0


REQUIRED = ["id", "kind", "level", "source", "gates", "target_paths", "jac_version", "license", "provenance",
            "idiom_targets"]
METRICS = {"arch.node", "arch.edge", "arch.walker", "arch.obj", "arch.class", "enums", "edge_refs", "edge_filters",
           "visits", "spawns", "connects", "reports", "isinstance_calls", "dict_fields", "glob_collections",
           "impl_defs", "annex_impls", "modules"}


def lint_task(t: Path) -> list[str]:
    errs: list[str] = []
    try:
        meta = json.loads((t / "task.json").read_text())
    except Exception as e:
        return [f"task.json: {e}"]
    errs += [f"task.json missing {k}" for k in REQUIRED if k not in meta]
    if meta.get("id") != t.name:
        errs.append("id != dir name")
    if meta.get("kind") != KIND or meta.get("level") not in (1, 2, 3, 4, 5):
        errs.append("bad kind/level")
    if not set(meta.get("gates", [])) <= {"check", "run", "test", "start", "fidelity", "behavioral", "mutation"}:
        errs.append(f"bad gates {meta.get('gates')}")
    for tg in meta.get("idiom_targets", []):
        m = tg.get("metric", "")
        if not (m in METRICS or m.startswith("field:") or m.startswith("has_arch:")):
            errs.append(f"unknown metric {m}")
        if tg.get("op") not in (">=", "<=", "==", "!=", ">", "<"):
            errs.append(f"bad op {tg}")
        if not tg.get("desc"):
            errs.append(f"target without desc {m}")
    for f in ["request.md", "grader/tests.jac", "grader/notes.md"]:
        if not (t / f).exists():
            errs.append(f"missing {f}")
    for d in ["starter", "grader/reference"]:
        if not (t / d).is_dir() or not list((t / d).rglob("*.jac")):
            errs.append(f"missing/empty {d}/")
    ref = t / "grader" / "reference"
    for tp in meta.get("target_paths", []):
        if not (ref / tp).exists():
            errs.append(f"reference missing target {tp}")
    for neg in sorted((t / "grader" / "negatives").glob("*.json")):
        try:
            spec = json.loads(neg.read_text())
        except Exception as e:
            errs.append(f"{neg.name}: {e}")
            continue
        for ed in spec["edits"]:
            src = (ref / ed["file"]).read_text() if (ref / ed["file"]).exists() else ""
            if src.count(ed["old"]) != 1:
                errs.append(f"{neg.name}: anchor x{src.count(ed['old'])} in {ed['file']}: {ed['old'][:50]!r}")
    req = (t / "request.md").read_text().lower() if (t / "request.md").exists() else ""
    for w in ("hidden test", "grader", "mutant", "idiom gate", "idiom_targets", "reference solution"):
        if w in req:
            errs.append(f"request.md leaks {w!r}")
    return errs


def cmd_lint(a) -> int:
    bad = 0
    for t in task_dirs():
        errs = lint_task(t)
        bad += bool(errs)
        print(f"{'OK ' if not errs else 'ERR'} {t.name}" + "".join(f"\n    {e}" for e in errs))
    return 1 if bad else 0


def cmd_gate(a) -> int:
    """Local light check: idiom gate on starter + reference of one task (no jac test)."""
    for t in task_dirs():
        if a.only and t.name not in a.only.split(","):
            continue
        meta = json.loads((t / "task.json").read_text())
        for kind, src in (("starter", t / "starter"), ("reference", t / "grader" / "reference")):
            g = idiom_gate(src.resolve(), meta["idiom_targets"], a.jac)
            print(f"{t.name} {kind}: ok={g['ok']} fails={_fails(g)}")
    return 0


def cmd_merge(a) -> int:
    files = sorted(Path(a.run_dir).rglob(RESULTS_NAME))
    merged = load_results(CACHE)
    n = 0
    for f in files:
        for line in f.read_text().splitlines():
            if line.strip():
                r = json.loads(line)
                r["ci_run"] = a.run_id or Path(a.run_dir).name
                merged[r["id"]] = r
                n += 1
    CACHE.write_text("".join(json.dumps(merged[k]) + "\n" for k in sorted(merged)))
    print(f"merged {n} results from {len(files)} files -> {CACHE}")
    return 0


def cmd_manifest(a) -> int:
    from native_dedup import dedup_all
    results = load_results(CACHE)
    tasks = task_dirs()
    dd = dedup_all(tasks)
    lines = []
    for t in tasks:
        meta = json.loads((t / "task.json").read_text())
        r = results.get(t.name)
        d = dd[t.name]
        h = task_hash(t)
        lint = lint_task(t)
        if lint:
            validated, reason = False, "lint: " + "; ".join(lint)
        elif r is None:
            validated, reason = False, "not yet validated"
        elif r["hash"] != h:
            validated, reason = False, f"stale result (task changed since hash {r['hash']})"
        elif not r["validated"]:
            validated, reason = False, "; ".join(x.splitlines()[0] for x in r["fail"])[:400]
        elif not d["clean"]:
            validated, reason = False, f"dedup: {d['reason']}"
        else:
            validated = True
            reason = (f"starter: check ok, behaviour tests pass, misses {r['info']['starter_targets_missed']}/"
                      f"{r['n_targets']} idiom targets; ref+{r['n_alternatives']} alt: check+test+idiom pass; "
                      f"{r['n_negatives']}/{r['n_negatives']} behaviour mutants killed; deterministic")
        lines.append({"id": meta["id"], "level": meta["level"], "source": meta["source"], "gates": meta["gates"],
                      "validated": validated, "reason": reason, "hash": h, "ci_run": (r or {}).get("ci_run"),
                      "idiom_targets": [x["desc"] for x in meta["idiom_targets"]], "dedup": d})
    (ROOT / "manifest.jsonl").write_text("".join(json.dumps(x) + "\n" for x in lines))
    by: dict[int, list[int]] = {}
    for x in lines:
        by.setdefault(x["level"], [0, 0])
        by[x["level"]][0] += 1
        by[x["level"]][1] += x["validated"]
    print("level  tasks  validated")
    for lv in sorted(by):
        print(f"  L{lv}   {by[lv][0]:5d}  {by[lv][1]:9d}")
    print(f"  all  {len(lines):5d}  {sum(x['validated'] for x in lines):9d}")
    for x in lines:
        if not x["validated"]:
            print(f"  - {x['id']}: {x['reason'][:220]}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    v = sp.add_parser("validate")
    v.add_argument("--shard", default="0/1")
    v.add_argument("--out", default=str(ROOT / "_local_out"))
    v.add_argument("--jac", default="jac")
    v.add_argument("--repeats", type=int, default=2)
    v.add_argument("--only", default="")
    v.add_argument("--force", action="store_true")
    m = sp.add_parser("merge")
    m.add_argument("run_dir")
    m.add_argument("--run-id", default="")
    sp.add_parser("manifest")
    sp.add_parser("lint")
    g = sp.add_parser("gate")
    g.add_argument("--only", default="")
    g.add_argument("--jac", default="jac")
    a = ap.parse_args()
    return {"validate": cmd_validate, "merge": cmd_merge, "manifest": cmd_manifest, "lint": cmd_lint,
            "gate": cmd_gate}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
