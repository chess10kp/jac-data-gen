#!/usr/bin/env python3
"""Validate the `app` kind of the agentic-task pool and write its manifest.

Task layout (shared schema): data/agent_tasks/app/<id>/{task.json, request.md,
starter/, grader/{reference/, tests.jac, smoke.py|behavioral.py, notes.md}}.

Per task, validation does:
  1. dedup   - request.md vs every eval prompt (evals/**): domain keywords +
               word n-gram containment (pure python, cheap; runs locally).
  2. positive - workspace = starter/ overlaid with grader/reference/, then every
               gate in task.json must pass:
                 check      `jac check <target_paths>`
                 test       hidden grader/tests.jac copied in as
                            zz_hidden_acceptance.jac -> `jac test` it; for
                            levels 4-5 the workspace's OWN test blocks must
                            also exist and pass (the request asks for tests)
                 run        L3: grader/behavioral.py reports run=true
                 start      L4-5: grader/smoke.py reports start=true
                 behavioral grader/behavioral.py (L3) / smoke.py (L4-5)
  3. negative - the bare starter/ must FAIL at least one of test/behavioral
               (proves the checks are not vacuous).
Every gate runs in a fresh temp copy (jac's graph store is keyed by cwd, so a
fresh dir = empty graph).

Resumable: a per-task result keyed by a content hash of the task dir lives at
data/agent_tasks/app/.validation/<id>.json; unchanged+validated tasks are
skipped unless --force.

Heavy jac work runs on GitHub Actions (.ci/agent-tasks/app.sh):
  app_build.py validate --shard $SHARD/$NSHARDS --out $OUT
then locally:
  app_build.py merge runs/ci/app/<run_id>      # -> .validation/ + manifest.jsonl
  app_build.py dedup                            # dedup only (no jac)
  app_build.py manifest                         # rebuild manifest from .validation/
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TASKS = REPO / "data" / "agent_tasks" / "app"
VALID = TASKS / ".validation"
MANIFEST = TASKS / "manifest.jsonl"
EVALS = REPO / "evals"
HIDDEN_NAME = "zz_hidden_acceptance.jac"
SKIP_DIRS = {".jac", "node_modules", "__pycache__", ".venv", "dist"}
ALL_GATES = {"check", "run", "test", "start", "fidelity", "behavioral"}
JAC_VERSION = "0.36.1"

# --------------------------------------------------------------------------- utils


def sh(cmd: list[str], cwd: Path, timeout: int, env: dict | None = None) -> dict:
    t = time.time()
    try:
        p = subprocess.run(cmd, cwd=cwd, stdin=subprocess.DEVNULL, capture_output=True,
                           text=True, timeout=timeout, start_new_session=True,
                           env={**os.environ, **(env or {})})
        rc, out, so = p.returncode, (p.stdout + p.stderr), p.stdout
    except subprocess.TimeoutExpired as e:
        rc, out, so = 124, f"TIMEOUT after {timeout}s\n{tail(e.stdout or '')}{tail(e.stderr or '')}", ""
    return {"cmd": " ".join(cmd), "rc": rc, "secs": round(time.time() - t, 1),
            "tail": tail(out), "stdout_tail": tail(so, 5)}


def tail(s, n: int = 40) -> str:
    if isinstance(s, bytes):
        s = s.decode(errors="replace")
    lines = (s or "").splitlines()
    return "\n".join(lines[-n:])


def task_hash(d: Path) -> str:
    h = hashlib.sha256()
    for p in sorted(d.rglob("*")):
        if p.is_file() and not (set(p.relative_to(d).parts) & SKIP_DIRS):
            h.update(str(p.relative_to(d)).encode())
            h.update(p.read_bytes())
    return h.hexdigest()[:16]


def copytree(src: Path, dst: Path) -> None:
    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns(*SKIP_DIRS, ".gitkeep"))


def stage(task_dir: Path, with_reference: bool) -> Path:
    ws = Path(tempfile.mkdtemp(prefix="appws_"))
    copytree(task_dir / "starter", ws)
    if with_reference:
        copytree(task_dir / "grader" / "reference", ws)
    return ws


def fresh_copy(ws: Path) -> Path:
    d = Path(tempfile.mkdtemp(prefix="appgate_"))
    copytree(ws, d)
    return d


def load_tasks(only: list[str] | None = None) -> list[Path]:
    out = []
    for d in sorted(TASKS.iterdir()):
        if d.is_dir() and (d / "task.json").exists():
            if only and d.name not in only:
                continue
            out.append(d)
    return out


# --------------------------------------------------------------------------- dedup

FRONTEND_DOMAINS = {  # eval frontend v1 app ideas -> keyword regexes
    "counter-color-picker": r"color picker|colou?r swatch",
    "todo-list": r"\btodos?\b|to-do list",
    "markdown-previewer": r"markdown (preview|editor)",
    "habit-tracker-grid": r"habit",
    "kanban-lite": r"kanban",
    "pomodoro": r"pomodoro",
    "form-wizard": r"form wizard|multi-step form",
    "expense-tracker": r"expense",
    "storefront": r"storefront|e-?commerce|shopping cart|\bcart\b",
    "notes-app": r"\bnotes? app\b|note-taking|\bnotebook\b",
    "quiz-app": r"\bquiz",
    "dashboard-shell": r"dashboard",
    "spreadsheet-lite": r"spreadsheet",
    "canvas-drawing": r"drawing app|paint app|\bcanvas\b",
    "step-sequencer": r"sequencer|drum machine",
    "checkers-ai": r"checkers|draughts",
    "chat-ui-mock": r"\bchat\b|messenger",
    "notion-lite": r"notion|block editor",
    "figma-lite": r"figma",
    "video-player": r"video player",
}
WORD = re.compile(r"[a-z0-9_]+")


def ngrams(text: str, n: int) -> set[tuple]:
    w = WORD.findall(text.lower())
    return {tuple(w[i:i + n]) for i in range(len(w) - n + 1)}


_EVAL_DOCS: list[tuple[str, str]] | None = None


def eval_docs() -> list[tuple[str, str]]:
    global _EVAL_DOCS
    if _EVAL_DOCS is not None:
        return _EVAL_DOCS
    docs: list[tuple[str, str]] = []
    fe = EVALS / "frontend" / "v1" / "specs.json"
    if fe.exists():
        for s in json.loads(fe.read_text()):
            docs.append((f"frontend/{s['id']}",
                         " ".join([s.get("name", ""), s.get("spec", "")] + s.get("assertions", []))))
    for p in sorted((EVALS / "jac_native").rglob("prompt.md")) if (EVALS / "jac_native").exists() else []:
        docs.append((f"jac_native/{p.parent.name}", p.read_text(errors="replace")))
    for p in sorted((EVALS / "function").rglob("*.jsonl")) if (EVALS / "function").exists() else []:
        if "public" not in p.parts:
            continue
        for line in p.read_text().splitlines():
            try:
                r = json.loads(line)
            except ValueError:
                continue
            docs.append((f"function/{r.get('id')}", r.get("prompt", "")))
    _EVAL_DOCS = docs
    return docs


def dedup(task_dir: Path) -> dict:
    req = (task_dir / "request.md").read_text()
    meta = json.loads((task_dir / "task.json").read_text())
    domain = meta.get("provenance", {}).get("domain", "")
    probe = f"{domain}\n{req}".lower()
    hits = [k for k, rx in FRONTEND_DOMAINS.items() if re.search(rx, probe)]
    best = {}
    for n in (5, 8):
        mine = ngrams(req, n)
        top, top_id = 0.0, None
        if mine:
            for did, txt in eval_docs():
                o = len(mine & ngrams(txt, n)) / len(mine)
                if o > top:
                    top, top_id = o, did
        best[f"max_{n}gram_containment"] = round(top, 4)
        best[f"nearest_{n}gram"] = top_id
    ok = not hits and best["max_8gram_containment"] < 0.05 and best["max_5gram_containment"] < 0.15
    return {"pass": ok, "domain": domain, "domain_hits": hits, **best,
            "n_eval_docs": len(eval_docs())}


# --------------------------------------------------------------------------- gates

TEST_BLOCK = re.compile(r'^\s*test\s+"', re.M)
SUMMARY = re.compile(r"(\d+) (passed|failed|skipped|errors?)")


def test_ok(r: dict, expect: int | None = None) -> bool:
    """`jac test` exits 0 when the module fails to import (tests become 'skipped'),
    so require an all-passed summary (and the expected count when known)."""
    counts: dict[str, int] = {}
    for n, kind in SUMMARY.findall(r["tail"]):
        counts[kind] = counts.get(kind, 0) + int(n)
    passed = counts.get("passed", 0)
    bad = sum(v for k, v in counts.items() if k != "passed")
    return r["rc"] == 0 and passed >= max(1, expect or 0) and bad == 0


def own_test_files(ws: Path) -> list[Path]:
    out = []
    for p in sorted(ws.rglob("*.jac")):
        if set(p.relative_to(ws).parts) & SKIP_DIRS or p.name == HIDDEN_NAME:
            continue
        if TEST_BLOCK.search(p.read_text(errors="replace")):
            out.append(p)
    return out


def gate_check(ws: Path, meta: dict) -> dict:
    d = fresh_copy(ws)
    targets = [t for t in meta["target_paths"] if (d / t).exists()]
    if len(targets) != len(meta["target_paths"]):
        return {"ok": False, "why": f"missing target(s): {set(meta['target_paths']) - set(targets)}"}
    r = sh(["jac", "check", *targets], d, 300)
    return {"ok": r["rc"] == 0, **r}


def gate_test(ws: Path, task_dir: Path, meta: dict) -> dict:
    res: dict = {"steps": []}
    ok = True
    if meta["level"] >= 4:  # the request asks the agent to write tests
        d = fresh_copy(ws)
        files = own_test_files(d)
        res["own_test_files"] = [str(f.relative_to(d)) for f in files]
        if not files:
            ok = False
            res["steps"].append({"why": "no own test blocks found"})
        for f in files:
            tgt = f.with_name(f.name[:-len(".test.jac")] + ".jac") if f.name.endswith(".test.jac") else f
            r = sh(["jac", "test", str(tgt.relative_to(d))], d, 600, env={"JAC_TEST_JOBS": "0"})
            res["steps"].append(r)
            ok &= test_ok(r)
    d = fresh_copy(ws)
    shutil.copy(task_dir / "grader" / "tests.jac", d / HIDDEN_NAME)
    # serial test workers: hidden tests share one persisted root per cwd
    r = sh(["jac", "test", HIDDEN_NAME], d, 600, env={"JAC_TEST_JOBS": "0"})
    res["steps"].append(r)
    expect = len(TEST_BLOCK.findall((task_dir / "grader" / "tests.jac").read_text()))
    ok &= test_ok(r, expect)
    res["ok"] = bool(ok)
    return res


def gate_script(ws: Path, task_dir: Path, name: str) -> dict:
    script = task_dir / "grader" / name
    d = fresh_copy(ws)
    r = sh([sys.executable, str(script), str(d)], d, 900)
    verdict = {}
    for line in reversed(r["stdout_tail"].splitlines()):
        if line.startswith("{") and line.endswith("}"):
            try:
                verdict = json.loads(line)
                break
            except ValueError:
                pass
    return {"ok": r["rc"] == 0, "verdict": verdict, **r}


def run_gates(ws: Path, task_dir: Path, meta: dict) -> dict:
    gates = meta["gates"]
    out: dict = {}
    if "check" in gates:
        out["check"] = gate_check(ws, meta)
    if "test" in gates:
        out["test"] = gate_test(ws, task_dir, meta)
    script = "smoke.py" if meta["level"] >= 4 else "behavioral.py"
    if {"run", "start", "behavioral"} & set(gates):
        g = gate_script(ws, task_dir, script)
        v = g.get("verdict", {})
        for k in ("run", "start", "behavioral"):
            if k in gates:
                out[k] = {"ok": bool(g["ok"] and v.get(k, False)), "script": script, "verdict": v, "rc": g["rc"], "tail": g["tail"]}
    return out


def schema_errors(task_dir: Path, meta: dict) -> list[str]:
    errs = []
    for k in ("id", "kind", "level", "source", "gates", "target_paths", "jac_version",
              "license", "provenance"):
        if k not in meta:
            errs.append(f"task.json missing {k}")
    if meta.get("id") != task_dir.name:
        errs.append("id != dir name")
    if meta.get("kind") != "app":
        errs.append("kind != app")
    if not set(meta.get("gates", [])) <= ALL_GATES:
        errs.append("unknown gate")
    if meta.get("jac_version") != JAC_VERSION:
        errs.append("jac_version mismatch")
    for p in ("request.md", "starter", "grader/reference", "grader/tests.jac", "grader/notes.md"):
        if not (task_dir / p).exists():
            errs.append(f"missing {p}")
    lvl = meta.get("level", 0)
    need = "grader/smoke.py" if lvl >= 4 else ("grader/behavioral.py" if lvl == 3 else None)
    if need and not (task_dir / need).exists():
        errs.append(f"missing {need}")
    req = (task_dir / "request.md").read_text().lower() if (task_dir / "request.md").exists() else ""
    for leak in ("hidden test", "grader", "acceptance check", "zz_hidden"):
        if leak in req:
            errs.append(f"request.md leaks '{leak}'")
    return errs


def validate_task(task_dir: Path) -> dict:
    meta = json.loads((task_dir / "task.json").read_text())
    rec: dict = {"id": meta.get("id"), "level": meta.get("level"), "source": meta.get("source"),
                 "gates": meta.get("gates"), "hash": task_hash(task_dir),
                 "jac": subprocess.run(["jac", "--version"], capture_output=True, text=True).stdout.strip()}
    errs = schema_errors(task_dir, meta)
    rec["dedup"] = dedup(task_dir)
    if errs:
        rec.update(validated=False, reason="schema: " + "; ".join(errs))
        return rec
    t0 = time.time()
    ws = stage(task_dir, with_reference=True)
    pos = run_gates(ws, task_dir, meta)
    rec["positive"] = pos
    neg_ws = stage(task_dir, with_reference=False)
    neg = run_gates(neg_ws, task_dir, {**meta, "gates": [g for g in meta["gates"] if g in ("test", "behavioral")]})
    rec["negative"] = neg
    rec["secs"] = round(time.time() - t0, 1)
    pos_fail = [g for g, r in pos.items() if not r.get("ok")]
    neg_caught = [g for g, r in neg.items() if not r.get("ok")]
    reasons = []
    if pos_fail:
        reasons.append(f"reference fails {pos_fail}")
    if not neg_caught:
        reasons.append("starter passes all behavior gates (vacuous checks)")
    if not rec["dedup"]["pass"]:
        reasons.append(f"dedup: {rec['dedup']}")
    rec["validated"] = not reasons
    rec["reason"] = "; ".join(reasons) if reasons else (
        f"reference passes {sorted(pos)}; starter fails {sorted(neg_caught)}; dedup ok")
    shutil.rmtree(ws, ignore_errors=True)
    shutil.rmtree(neg_ws, ignore_errors=True)
    return rec


# --------------------------------------------------------------------------- commands


def manifest_line(rec: dict) -> dict:
    d = rec.get("dedup", {})
    return {"id": rec["id"], "level": rec["level"], "source": rec["source"], "gates": rec["gates"],
            "validated": bool(rec.get("validated")), "reason": rec.get("reason", ""),
            "dedup": {k: d.get(k) for k in ("pass", "domain", "domain_hits", "max_5gram_containment",
                                            "nearest_5gram", "max_8gram_containment", "nearest_8gram")},
            "hash": rec.get("hash"), "validated_with": rec.get("jac"), "run": rec.get("ci_run")}


def write_manifest() -> None:
    lines = []
    for d in load_tasks():
        meta = json.loads((d / "task.json").read_text())
        vf = VALID / f"{d.name}.json"
        rec = json.loads(vf.read_text()) if vf.exists() else None
        if rec is None or rec.get("hash") != task_hash(d):
            rec = {"id": meta["id"], "level": meta["level"], "source": meta["source"],
                   "gates": meta["gates"], "validated": False, "dedup": dedup(d),
                   "reason": "stale or not yet validated" if rec else "not yet validated",
                   "hash": task_hash(d)}
        lines.append(json.dumps(manifest_line(rec)))
    MANIFEST.write_text("\n".join(lines) + "\n")
    print(f"wrote {MANIFEST} ({len(lines)} tasks, "
          f"{sum(json.loads(l)['validated'] for l in lines)} validated)")


def cmd_validate(a) -> None:
    tasks = load_tasks(a.only)
    if a.shard:
        i, n = map(int, a.shard.split("/"))
        tasks = [t for k, t in enumerate(tasks) if k % n == i]
    out = Path(a.out) if a.out else None
    if out:
        out.mkdir(parents=True, exist_ok=True)
    for d in tasks:
        vf = VALID / f"{d.name}.json"
        if not a.force and vf.exists():
            old = json.loads(vf.read_text())
            if old.get("hash") == task_hash(d) and old.get("validated"):
                print(f"[skip] {d.name} (validated, unchanged)")
                if out:
                    with open(out / "results.jsonl", "a") as f:
                        f.write(json.dumps(old) + "\n")
                continue
        print(f"[validate] {d.name} ...", flush=True)
        rec = validate_task(d)
        rec["ci_run"] = os.environ.get("GITHUB_RUN_ID")
        print(f"  -> validated={rec['validated']} {rec['reason']} ({rec.get('secs')}s)", flush=True)
        if out:
            with open(out / "results.jsonl", "a") as f:
                f.write(json.dumps(rec) + "\n")
        else:
            VALID.mkdir(exist_ok=True)
            vf.write_text(json.dumps(rec, indent=1))
    if not out:
        write_manifest()


def cmd_merge(a) -> None:
    VALID.mkdir(exist_ok=True)
    n = 0
    for p in sorted(Path(a.dir).rglob("results.jsonl")):
        for line in p.read_text().splitlines():
            rec = json.loads(line)
            (VALID / f"{rec['id']}.json").write_text(json.dumps(rec, indent=1))
            n += 1
    print(f"merged {n} results")
    write_manifest()


def cmd_dedup(a) -> None:
    for d in load_tasks(a.only):
        r = dedup(d)
        print(d.name, json.dumps(r))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    v = sub.add_parser("validate")
    v.add_argument("--shard", help="i/n")
    v.add_argument("--out", help="write results.jsonl here (CI) instead of .validation/")
    v.add_argument("--force", action="store_true")
    v.add_argument("--only", nargs="*")
    m = sub.add_parser("merge")
    m.add_argument("dir")
    dd = sub.add_parser("dedup")
    dd.add_argument("--only", nargs="*")
    sub.add_parser("manifest")
    a = ap.parse_args()
    {"validate": cmd_validate, "merge": cmd_merge, "dedup": cmd_dedup,
     "manifest": lambda _a: write_manifest()}[a.cmd](a)


if __name__ == "__main__":
    main()
