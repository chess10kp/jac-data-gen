#!/usr/bin/env python3
"""Build/validate the `convert` agent-task pool (Python / FARM -> idiomatic Jac).

Task layout (data/agent_tasks/convert/<id>/):
  task.json  request.md
  starter/            python/ (the real source being ported, + its own tests when it
                      ships them), jac.toml
  grader/reference/   solved workspace (= starter + the Jac port); authored as the
                      Jac files only, `materialize` copies the starter files in
  grader/tests.jac    hidden behavior tests (separate module importing the targets)
  grader/gate.json    {api:[{name,kind}], forbid_imports, strip, ref_mass, timeout_s}
  grader/negatives/   *.json mutants {"edits":[{file,old,new}]} of the reference
  grader/smoke.py     (L5) HTTP smoke over `jac run --serve`; uses smoke_lib.py
  grader/notes.md

Subcommands
  materialize  copy starter files into grader/reference, refresh gate.json ref_mass,
               copy smoke_lib.py next to smoke.py  (pure Python, local)
  validate     per task: starter fails hidden tests; reference passes every declared
               gate (convert_gate); body-stubbed reference is killed; every negative
               compiles and is killed; reference test outcome stable x2.
               Shardable (--shard i/n), writes <out>/convert_results.jsonl.  (CI)
  merge        fold CI shard results into data/agent_tasks/convert/build_results.jsonl
  manifest     dedup vs evals/ + peers, write manifest.jsonl (validated iff latest
               result hash matches current content AND dedup is clean)
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
from convert_gate import Task, copy_ws, reference_mass, _run, JAC  # noqa: E402
from fix_gate import stub_bodies  # noqa: E402

ROOT = REPO / "data" / "agent_tasks" / "convert"
CACHE = ROOT / "build_results.jsonl"


def task_dirs() -> list[Path]:
    return sorted(p for p in ROOT.iterdir() if (p / "task.json").exists())


def task_hash(task_dir: Path) -> str:
    h = hashlib.sha256()
    for p in sorted(task_dir.rglob("*")):
        rel = p.relative_to(task_dir)
        if p.is_file() and not {".jac", "__jac_gen__", "__pycache__"} & set(rel.parts[:-1]):
            h.update(str(rel).encode())
            h.update(p.read_bytes())
    return h.hexdigest()[:16]


# ---------------------------------------------------------------- materialize
def materialize(td: Path) -> None:
    ref = td / "grader" / "reference"
    starter = td / "starter"
    for p in sorted(starter.rglob("*")):
        rel = p.relative_to(starter)
        if p.is_file() and not (ref / rel).exists() and ".jac" not in rel.parts:
            (ref / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(p, ref / rel)
    gp = td / "grader" / "gate.json"
    gate = json.loads(gp.read_text())
    gate["ref_mass"] = reference_mass(td)
    gp.write_text(json.dumps(gate, indent=1) + "\n")
    if (td / "grader" / "smoke.py").exists():
        shutil.copyfile(HERE / "convert_smoke_lib.py", td / "grader" / "smoke_lib.py")


# ---------------------------------------------------------------- validation
def _apply_edits(ws: Path, spec: dict) -> None:
    for ed in spec["edits"]:
        f = ws / ed["file"]
        src = f.read_text()
        n = src.count(ed["old"])
        if n != 1:
            raise ValueError(f"edit anchor occurs {n}x in {ed['file']}: {ed['old'][:60]!r}")
        f.write_text(src.replace(ed["old"], ed["new"]))


def validate(td: Path, repeats: int = 2) -> dict:
    t = Task(td)
    t0 = time.time()
    ok: list[str] = []
    fail: list[str] = []
    gates = t.meta["gates"]
    ref = t.grader / "reference"

    # 0. starter must not satisfy the hidden tests
    r = t.grade(td / "starter", ["test"])
    (fail if r["pass"] else ok).append(
        "STARTER hidden tests " + ("PASS (task trivial)" if r["pass"] else "fail as expected"))

    # 1. reference passes every declared gate
    r = t.grade(ref)
    if r["pass"]:
        fid = r["gates"].get("fidelity", {})
        ok.append(f"REF passes {','.join(r['gates'])} (api {fid.get('api', '-')}, mass {fid.get('mass_ratio', '-')})")
    else:
        bad = {k: v["detail"][-900:] for k, v in r["gates"].items() if not v["ok"]}
        fail.append(f"REF fails: {json.dumps(bad)[:3000]}")

    # 2. hollow port (every body stubbed) must be killed
    with tempfile.TemporaryDirectory(prefix="cvt_stub_") as tmp:
        w = Path(tmp) / "ws"
        copy_ws(ref, w)
        for p in t.targets:
            (w / p).write_text(stub_bodies((w / p).read_text()))
        r = t.grade(w, [g for g in gates if g in ("test", "start")])
        (fail if r["pass"] else ok).append("HOLLOW stubbed reference " + ("SURVIVED" if r["pass"] else "killed"))

    # 3. negatives: compile but are killed by test/start
    negs = sorted((t.grader / "negatives").glob("*.json")) if (t.grader / "negatives").is_dir() else []
    if len(negs) < 3:
        fail.append(f"only {len(negs)} negatives; need >=3")
    for n in negs:
        with tempfile.TemporaryDirectory(prefix="cvt_neg_") as tmp:
            w = Path(tmp) / "ws"
            copy_ws(ref, w)
            try:
                _apply_edits(w, json.loads(n.read_text()))
            except ValueError as e:
                fail.append(f"NEG {n.stem}: {e}")
                continue
            c = t.grade(w, ["check"])
            if not c["pass"]:
                fail.append(f"NEG {n.stem}: stillborn (does not compile): {c['gates']['check']['detail'][-300:]}")
                continue
            r = t.grade(w, [g for g in gates if g in ("test", "start")])
            if r["pass"]:
                fail.append(f"NEG {n.stem}: SURVIVED")
            else:
                killed = [k for k, v in r["gates"].items() if not v["ok"]]
                ok.append(f"NEG {n.stem}: killed:{'+'.join(killed)}")

    # 4. determinism
    outs = [t.grade(ref, ["test"])["pass"] for _ in range(repeats)]
    if not all(outs):
        fail.append(f"DET reference test unstable: {outs}")
    else:
        ok.append(f"DET reference test stable x{repeats + 1}")

    res = {"id": t.meta["id"], "level": t.meta["level"], "hash": task_hash(td),
           "validated": not fail, "ok": ok, "fail": fail, "n_negatives": len(negs),
           "seconds": round(time.time() - t0, 1),
           "jac": _run([JAC, "--version"], td, 30)[1].strip()}
    print(f"=== {res['id']} (L{res['level']}) {'VALIDATED' if res['validated'] else 'NOT VALIDATED'} in {res['seconds']}s", flush=True)
    for line in ok:
        print(f"  PASS {line}", flush=True)
    for line in fail:
        print(f"  FAIL {line}", flush=True)
    return res


# ---------------------------------------------------------------- commands
def load_results(*paths: Path) -> dict[str, dict]:
    latest: dict[str, dict] = {}
    for path in paths:
        if path.exists():
            for line in path.read_text().splitlines():
                if line.strip():
                    r = json.loads(line)
                    latest[r["id"]] = r
    return latest


def cmd_materialize(a) -> int:
    for td in task_dirs():
        if not a.only or td.name in a.only.split(","):
            materialize(td)
            print("materialized", td.name)
    return 0


def cmd_validate(a) -> int:
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    res_path = out / "convert_results.jsonl"
    cache = load_results(CACHE, res_path)
    tasks = task_dirs()
    if a.only:
        tasks = [t for t in tasks if t.name in set(a.only.split(","))]
    shard, n = (int(x) for x in a.shard.split("/"))
    tasks = [t for i, t in enumerate(tasks) if i % n == shard]
    bad = 0
    with res_path.open("a") as fh:
        for td in tasks:
            h = task_hash(td)
            prev = cache.get(td.name)
            if not a.force and prev and prev.get("hash") == h and prev.get("validated"):
                print(f"=== {td.name}: cached VALIDATED (hash {h}), skip")
                continue
            try:
                r = validate(td, a.repeats)
            except Exception as e:  # authoring error: record and continue
                r = {"id": td.name, "level": None, "hash": h, "validated": False, "ok": [],
                     "fail": [f"harness error: {type(e).__name__}: {e}"], "n_negatives": 0}
                print(f"=== {td.name}: HARNESS ERROR {e}", flush=True)
            r["ci_run"] = a.run_id
            fh.write(json.dumps(r) + "\n")
            fh.flush()
            bad += not r["validated"]
    print(f"shard {a.shard}: {len(tasks)} tasks, {bad} not validated")
    return 0


def cmd_merge(a) -> int:
    rows = load_results(CACHE)
    n = 0
    for p in sorted(Path(a.runs).rglob("convert_results.jsonl")):
        for line in p.read_text().splitlines():
            if line.strip():
                r = json.loads(line)
                rows[r["id"]] = r
                n += 1
    CACHE.write_text("".join(json.dumps(r) + "\n" for r in rows.values()))
    print(f"merged {n} rows -> {CACHE} ({len(rows)} tasks)")
    return 0


def cmd_manifest(a) -> int:
    from native_dedup import dedup_all
    tasks = task_dirs()
    dd = dedup_all(tasks)
    res = load_results(CACHE)
    lines = []
    for td in tasks:
        meta = json.loads((td / "task.json").read_text())
        r = res.get(td.name)
        h = task_hash(td)
        d = dd[td.name]
        if r is None:
            v, why = False, "not yet validated"
        elif r.get("hash") != h:
            v, why = False, f"stale result (hash {r.get('hash')} != {h})"
        elif not r["validated"]:
            v, why = False, "; ".join(r["fail"])[:500]
        elif not d["clean"]:
            v, why = False, "dedup: " + d["reason"]
        else:
            v, why = True, "; ".join(x for x in r["ok"] if not x.startswith("NEG"))[:400] + \
                f"; {sum(x.startswith('NEG') for x in r['ok'])}/{r['n_negatives']} negatives killed"
        lines.append({"id": td.name, "level": meta["level"], "source": meta["source"],
                      "gates": meta["gates"], "license": meta.get("license"), "validated": v,
                      "reason": why, "hash": h, "ci_run": (r or {}).get("ci_run"), "dedup": d})
    (ROOT / "manifest.jsonl").write_text("".join(json.dumps(x) + "\n" for x in lines))
    from collections import Counter
    c = Counter((x["level"], x["validated"]) for x in lines)
    for lvl in sorted({x["level"] for x in lines}):
        print(f"L{lvl}: {c[(lvl, True)]} validated / {c[(lvl, True)] + c[(lvl, False)]}")
    print(f"total validated {sum(x['validated'] for x in lines)}/{len(lines)}")
    for x in lines:
        if not x["validated"]:
            print("  NOT", x["id"], x["reason"][:300])
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    m = sp.add_parser("materialize")
    m.add_argument("--only")
    v = sp.add_parser("validate")
    v.add_argument("--shard", default="0/1")
    v.add_argument("--out", default=str(REPO / "runs" / "convert_local"))
    v.add_argument("--only")
    v.add_argument("--force", action="store_true")
    v.add_argument("--repeats", type=int, default=2)
    v.add_argument("--run-id", default="local")
    g = sp.add_parser("merge")
    g.add_argument("runs", nargs="?", default=str(REPO / "runs" / "ci" / "convert"))
    sp.add_parser("manifest")
    a = ap.parse_args()
    return {"materialize": cmd_materialize, "validate": cmd_validate,
            "merge": cmd_merge, "manifest": cmd_manifest}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
