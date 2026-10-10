#!/usr/bin/env python3
"""Build/validate the `native` agent-task pool and write its manifest.

Subcommands
  validate  run native_validate on every task (optionally one shard), append
            results to <out>/native_results.jsonl. Resumable: a task whose
            content hash already has a validated result in the results cache
            (data/agent_tasks/native/build_results.jsonl or --out file) is skipped.
  merge     fold CI shard results (runs/ci/native/<run>/**/native_results.jsonl)
            into data/agent_tasks/native/build_results.jsonl.
  manifest  run the dedup check and (re)write data/agent_tasks/native/manifest.jsonl
            from the latest result per task (validated only if the result's hash
            matches the task's current content AND dedup is clean).

Heavy work (validate) runs on GitHub Actions via .ci/agent-tasks/native.sh;
merge + manifest are pure Python and run locally.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
from native_validate import task_hash, validate  # noqa: E402
from native_dedup import dedup_all  # noqa: E402

ROOT = REPO / "data" / "agent_tasks" / "native"
CACHE = ROOT / "build_results.jsonl"


def task_dirs() -> list[Path]:
    return sorted(p for p in ROOT.iterdir() if (p / "task.json").exists())


def load_results(*paths: Path) -> dict[str, dict]:
    latest: dict[str, dict] = {}
    for path in paths:
        if not path.exists():
            continue
        for line in path.read_text().splitlines():
            if line.strip():
                r = json.loads(line)
                latest[r["id"]] = r
    return latest


def cmd_validate(a) -> int:
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    res_path = out / "native_results.jsonl"
    cache = load_results(CACHE, res_path)
    tasks = task_dirs()
    if a.only:
        tasks = [t for t in tasks if t.name in set(a.only.split(","))]
    shard, n = (int(x) for x in a.shard.split("/"))
    tasks = [t for i, t in enumerate(tasks) if i % n == shard]
    import subprocess
    jac_ver = subprocess.run([a.jac, "--version"], capture_output=True, text=True).stdout.strip()
    bad = 0
    with res_path.open("a") as fh:
        for t in tasks:
            h = task_hash(t)
            prev = cache.get(t.name)
            if not a.force and prev and prev.get("hash") == h and prev.get("validated") and prev.get("jac") == jac_ver:
                print(f"=== {t.name}: cached VALIDATED (hash {h}), skip")
                continue
            try:
                r = validate(t, a.jac, a.repeats)
            except Exception as e:  # harness/authoring error: record, keep going
                r = {"id": t.name, "level": None, "hash": h, "validated": False, "ok": [],
                     "fail": [f"harness error: {type(e).__name__}: {e}"], "n_alternatives": 0, "n_negatives": 0}
                print(f"=== {t.name}: HARNESS ERROR {e}")
            fh.write(json.dumps(r) + "\n")
            fh.flush()
            bad += not r["validated"]
    print(f"shard {a.shard}: {len(tasks)} tasks, {bad} not validated")
    return 0


REQUIRED_TASK_KEYS = ["id", "kind", "level", "source", "gates", "target_paths", "jac_version", "license", "provenance"]
ALLOWED_GATES = {"check", "run", "test", "start", "fidelity", "behavioral"}


def lint_task(t: Path) -> list[str]:
    """Cheap static checks (no jac): schema, files, mutant anchors."""
    errs: list[str] = []
    try:
        meta = json.loads((t / "task.json").read_text())
    except Exception as e:
        return [f"task.json: {e}"]
    errs += [f"task.json missing {k}" for k in REQUIRED_TASK_KEYS if k not in meta]
    if meta.get("id") != t.name:
        errs.append("id != dir name")
    if meta.get("kind") != "native" or meta.get("level") not in (1, 2, 3, 4, 5):
        errs.append("bad kind/level")
    if not set(meta.get("gates", [])) <= ALLOWED_GATES:
        errs.append(f"bad gates {meta.get('gates')}")
    for f in ["request.md", "grader/tests.jac", "grader/notes.md"]:
        if not (t / f).exists():
            errs.append(f"missing {f}")
    if not (t / "starter").is_dir():
        errs.append("missing starter/")
    ref = t / "grader" / "reference"
    for tp in meta.get("target_paths", []):
        if not (ref / tp).exists():
            errs.append(f"reference missing {tp}")
    for alt in (t / "grader" / "alternatives").glob("*"):
        for tp in meta.get("target_paths", []):
            if not (alt / tp).exists() and not (t / "starter" / tp).exists():
                errs.append(f"alt {alt.name} missing {tp}")
    for neg in (t / "grader" / "negatives").glob("*.json"):
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
    for w in ("hidden test", "grader", "mutant", "negatives/"):
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


def cmd_merge(a) -> int:
    files = sorted(Path(a.run_dir).rglob("native_results.jsonl"))
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
    results = load_results(CACHE)
    dd = dedup_all([t for t in task_dirs()])
    lines = []
    for t in task_dirs():
        meta = json.loads((t / "task.json").read_text())
        r = results.get(t.name)
        d = dd[t.name]
        h = task_hash(t)
        if r is None:
            validated, reason = False, "not yet validated"
        elif r["hash"] != h:
            validated, reason = False, f"stale result (task changed since hash {r['hash']})"
        elif not r["validated"]:
            validated, reason = False, "; ".join(x.splitlines()[0] for x in r["fail"])[:400]
        elif not d["clean"]:
            validated, reason = False, f"dedup: {d['reason']}"
        else:
            n_neg = sum(1 for x in r["ok"] if x.startswith("NEG"))
            validated = True
            reason = (f"ref+{r['n_alternatives']} alt pass gates {'/'.join(meta['gates'])}; "
                      f"{n_neg}/{r['n_negatives']} mutants killed; deterministic x3; starter fails hidden tests")
        lines.append({
            "id": meta["id"], "level": meta["level"], "source": meta["source"], "gates": meta["gates"],
            "validated": validated, "reason": reason, "hash": h, "ci_run": (r or {}).get("ci_run"),
            "dedup": d,
        })
    (ROOT / "manifest.jsonl").write_text("".join(json.dumps(x) + "\n" for x in lines))
    by = {}
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
            print(f"  - {x['id']}: {x['reason'][:200]}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    sp = ap.add_subparsers(dest="cmd", required=True)
    v = sp.add_parser("validate")
    v.add_argument("--shard", default="0/1")
    v.add_argument("--out", default=str(ROOT / "_local_out"))
    v.add_argument("--jac", default="jac")
    v.add_argument("--repeats", type=int, default=3)
    v.add_argument("--only", default="")
    v.add_argument("--force", action="store_true")
    m = sp.add_parser("merge")
    m.add_argument("run_dir")
    m.add_argument("--run-id", default="")
    sp.add_parser("manifest")
    sp.add_parser("lint")
    a = ap.parse_args()
    return {"validate": cmd_validate, "merge": cmd_merge, "manifest": cmd_manifest, "lint": cmd_lint}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
