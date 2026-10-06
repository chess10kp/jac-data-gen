#!/usr/bin/env python3
"""Repair jachacks .jac files until they pass `jac check` (0.36.1).

Loop: extract per-file diagnostics on clarity2 -> LLM-rewrite failing files in
parallel (pi CLI, subscription providers) -> push candidates -> re-check.
A file is green when its module summary reports 0 errors (impl/ parts inherit
their parent module verdict plus own-target diagnostics).

State lives on clarity2:~/jachacks_check/<tree> (the check tree; tree per
--edition). Candidates are mirrored locally in data/jachacks_repaired[<suffix>]/
and logged to data/jachacks_repair_results[<suffix>].jsonl.

Usage:
  python3 jachacks_repair.py --edition sf --rounds 4 --jobs 8
  python3 jachacks_repair.py --edition sf --only repo/file.jac,repo2/f.jac --rounds 2

Env knobs:
  JH_REPAIR_MODEL     pi model id      [glm-5.3-flash]
  JH_REPAIR_PROVIDER  pi provider      [zai]
  JH_REPAIR_TIMEOUT   per-call seconds [300]
  JH_REPAIR_TRIES     retries          [3]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import socket
import subprocess
import sys
import tarfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from io import BytesIO
from pathlib import Path

# This host's IPv6 route out is blackholed; force IPv4 for any httpx users.
_orig_gai = socket.getaddrinfo


def _ipv4_gai(host, port, family=0, type=0, proto=0, flags=0):
    return _orig_gai(host, port, socket.AF_INET, type, proto, flags)


socket.getaddrinfo = _ipv4_gai

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "gen"))
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from osp_minimax_generate import extract_jac  # noqa: E402

HOST = os.environ.get("JH_HOST", "clarity2")  # or "local"
RROOT = "/home/madhu/jachacks_check"
LTREE = os.environ.get("JH_LOCAL_TREE", "")  # default per edition, set in main()
MODEL = os.environ.get("JH_REPAIR_MODEL", "glm-5.3-flash")
PROVIDER = os.environ.get("JH_REPAIR_PROVIDER", "zai")
PI_CWD = "/tmp/devin_osp_workspace"
TIMEOUT = int(os.environ.get("JH_REPAIR_TIMEOUT", "300"))
TRIES = int(os.environ.get("JH_REPAIR_TRIES", "3"))
OUTDIR = REPO / "data" / "jachacks_repaired"
RESULTS = REPO / "data" / "jachacks_repair_results.jsonl"

EDITIONS = {
    # edition: (source jsonl suffixes, tree suffix, results/mirror suffix)
    "nonsf": (("spring", "2026"), "jachacks_nonsf", ""),
    "sf": (("sf",), "jachacks_sf", "_sf"),
}


def edition_paths(edition: str) -> None:
    """Point tree/results/mirror globals at the selected edition."""
    global RTREE, LTREE, OUTDIR, RESULTS
    _, tree, suffix = EDITIONS[edition]
    RTREE = f"{RROOT}/{tree}"
    LTREE = os.environ.get("JH_LOCAL_TREE", f"/tmp/{tree}")
    OUTDIR = REPO / "data" / f"jachacks_repaired{suffix}"
    RESULTS = REPO / "data" / f"jachacks_repair_results{suffix}.jsonl"

SYSTEM = """You are an expert Jac (Jaseci) engineer repairing hackathon code written against an OLD Jac dialect so it passes `jac check` (jac 0.36.1, strict static type checker).

OUTPUT CONTRACT: exactly one ```jac ... ``` fenced block containing the COMPLETE file. No prose, no diffs, no partial output.

MIGRATION RULES (old -> current):
- `import:py from X { ... }` / `import:jac ...` -> plain `import from X { ... }` / `import X;` (colon-tagged imports are removed).
- `can name: T;` used as a FIELD declaration inside an archetype -> `has name: T;`.
- `can name with <trigger> entry { ... }` is ONLY for walker/node/edge event abilities. Trigger must be a defined node/edge type or `Root`. Regular methods are `def name(...) -> T { ... }`.
- `root()` -> `root` (bare keyword, not a call). Same for `here`, `visitor`.
- Parenthesized edge filter `(?Type)` -> bracket `[?Type]`; `(?:Type)` -> `[?:Type]`.
- Stray semicolons at module level after a block are illegal -- remove them.
- `visit` forms: `visit [-->];` / `visit [<--];` / `visit [->:Edge:->]`.
- `with entry { ... }` is the module entry block.
- Keywords used as identifiers need backticks: `type`, `edge`, `node`, `entry`, `exit`, `visit`, `spawn`, `root`, `test`, `case`, `default`, `walker`. NOT for `self`/`here`/`visitor`/`init`/`super`.
- In `obj`/`node`/`walker`/`edge` bodies: `has name: T = default;` for fields; `self` is implicit (never a parameter); constructor is `def init`.
- `enum X { A, B }`; lambdas `lambda (x: T) { expr }`; no Python colon-indent blocks, no bare `def f():`.
- `spawn`: `root spawn MyWalker(args);` or `here spawn W();`.
- Dot-access on a value of Unknown type fails (E1032): if the Unknown comes from an unresolvable import, annotate the result (`x: dict = mod.f()`) or cast `x as T`. Do NOT invent stubs that change behavior.
- `for (i, x) in enumerate(xs)` needs parens around the unpack target.
- f-strings `f"..."`, bools `True/False/None`.

RULES:
- Preserve behavior and the module's public surface (names other files import). Do not rename public symbols, do not delete functionality.
- Fix every diagnostic shown for THIS file. If a diagnostic points at a sibling file, adjust THIS file only if it is the compatible side; never rewrite the sibling (it is being fixed separately).
- If the file is a `.cl.jac` / `.sv.jac` / `.impl.jac` companion, keep its companion role.
- Output the whole file even if only a few lines changed.
"""


SUM_RE = re.compile(r"^(\S.*?\.jac) - (\d+) errors?,")
TGT_RE = re.compile(r"^\s*-->\s*(\S+?\.jac):\d+:\d+")
DIAG_START = re.compile(r"^\s*[✖⚠]")


def ssh(cmd: str, timeout: int = 900) -> str:
    p = subprocess.run(["ssh", "-o", "BatchMode=yes", HOST, cmd],
                       capture_output=True, text=True, timeout=timeout)
    return p.stdout + p.stderr


def parse_log(txt: str, repo: str, modfail: dict, diags: dict) -> None:
    lines = txt.splitlines()
    blocks, cur = [], None
    for ln in lines:
        if DIAG_START.match(ln):
            if cur:
                blocks.append(cur)
            cur = [ln]
        elif cur is not None:
            if re.match(r"^\S", ln):
                blocks.append(cur)
                cur = None
            else:
                cur.append(ln)
    if cur:
        blocks.append(cur)
    for b in blocks:
        if not b[0].lstrip().startswith("✖"):
            continue
        t = [TGT_RE.match(x) for x in b]
        t = [m.group(1) for m in t if m]
        if not t:
            continue
        pp = t[0]
        i = pp.find(repo + "/")
        if i < 0:
            continue
        rel = pp[i + len(repo) + 1:]
        diags.setdefault(repo, {}).setdefault(rel, []).append("\n".join(b[:14]))
    for ln in lines:
        m = SUM_RE.match(ln.strip())
        if m and int(m.group(2)) > 0:
            pth = m.group(1)
            pth = pth[len(repo) + 1:] if pth.startswith(repo + "/") else pth
            modfail.setdefault(repo, []).append(pth)


def local_recheck(repos: list[str] | None = None) -> dict:
    tree = Path(LTREE)
    allr = sorted(d.name for d in tree.iterdir() if d.is_dir())
    modfail: dict[str, list] = {}
    diags: dict[str, dict] = {}
    for repo in allr:
        if repos and repo not in repos:
            continue
        p = subprocess.run(["jac", "check", "-j", "8", repo],
                           cwd=LTREE, capture_output=True, text=True, timeout=600)
        parse_log(p.stdout + p.stderr, repo, modfail, diags)
    # merge: repos not rechecked keep prior state
    state_f = Path("/tmp/jachacks_recheck_state.json")
    if repos and state_f.exists():
        old = json.loads(state_f.read_text())
        for repo in set(old.get("modfail", {})) | set(old.get("diags", {})):
            if repo not in repos:
                if repo in old.get("modfail", {}):
                    modfail.setdefault(repo, old["modfail"][repo])
                if repo in old.get("diags", {}):
                    diags.setdefault(repo, old["diags"][repo])
    state = {"modfail": modfail, "diags": diags}
    state_f.write_text(json.dumps(state))
    return state


def remote_recheck(repos: list[str] | None = None) -> dict:
    if HOST == "local":
        return local_recheck(repos)
    tree = Path(RTREE).name
    args = f"--tree {tree} --state recheck_state_{tree}.json"
    if repos:
        args += " " + " ".join(repos)
    ssh(f"python3 {RROOT}/recheck.py {args}", timeout=3600)
    out = ssh(f"cat {RROOT}/recheck_state_{tree}.json")
    i = out.find("{")
    return json.loads(out[i:out.rfind("}") + 1])


def push_files(files: dict[str, str]) -> None:
    if HOST == "local":
        for rel, src in files.items():
            p = Path(LTREE) / rel
            p.write_text(src)
        return
    buf = BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tf:
        for rel, src in files.items():
            b = src.encode()
            ti = tarfile.TarInfo(rel)
            ti.size = len(b)
            tf.addfile(ti, BytesIO(b))
    buf.seek(0)
    p = subprocess.run(
        ["ssh", "-o", "BatchMode=yes", HOST, f"cd {RTREE} && tar xzf -"],
        input=buf.read(), timeout=300)
    assert p.returncode == 0


def pi_call(system: str, user: str) -> tuple[str | None, str | None]:
    last = "not attempted"
    for attempt in range(TRIES):
        try:
            r = subprocess.run(
                ["pi", "-p", "--provider", PROVIDER, "--model", MODEL,
                 "--no-session", "--system-prompt", system, user],
                stdin=subprocess.DEVNULL, cwd=PI_CWD,
                capture_output=True, text=True, timeout=TIMEOUT)
        except subprocess.TimeoutExpired:
            last = f"pi timeout {TIMEOUT}s"
            time.sleep(2 ** attempt)
            continue
        out = (r.stdout or "").strip()
        if r.returncode == 0 and out:
            return out, None
        last = f"pi rc={r.returncode}: {(r.stderr or out)[-200:]}"
        time.sleep(2 ** attempt)
    return None, last


def fix_one(rel: str, src: str, diags: list[str], siblings: list[str]) -> tuple[str | None, str | None]:
    capped = diags[:40]
    user = (
        f"File: {rel}\n"
        f"Sibling modules in repo: {', '.join(siblings[:40])}\n\n"
        f"Compiler diagnostics for this file ({len(diags)} total, showing {len(capped)}):\n"
        + "\n\n".join(capped)
        + "\n\n--- CURRENT SOURCE ---\n```jac\n" + src + "\n```\n"
        + "\nEmit the complete repaired file."
    )
    text, err = pi_call(SYSTEM, user)
    if err or not text:
        return None, err or "empty"
    cand = extract_jac(text)
    if cand is None:
        return None, "no-fence"
    if len(cand) < len(src) * 0.3:
        return None, "suspicious-shrink"
    return cand, None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rounds", type=int, default=4)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--only", default="")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--edition", choices=sorted(EDITIONS), default="nonsf")
    args = ap.parse_args()
    only = set(filter(None, args.only.split(",")))
    edition_paths(args.edition)
    sources = EDITIONS[args.edition][0]

    # load records -> rel path -> source (current, evolves across rounds)
    records: dict[str, dict] = {}
    for src in sources:
        for line in open(REPO / "data" / f"jachacks_{src}_jac_files_filtered.jsonl"):
            r = json.loads(line)
            records[f"{r['dirname']}/{r['file_path']}"] = r

    OUTDIR.mkdir(parents=True, exist_ok=True)
    done_ids = set()
    if RESULTS.exists():
        for line in open(RESULTS):
            r = json.loads(line)
            if r.get("status") == "pass":
                done_ids.add(r["rel"])

    state = remote_recheck()
    log_f = open(RESULTS, "a")

    for rnd in range(1, args.rounds + 1):
        # failing set = modfail files + diag-targeted files (impl parts)
        failing: dict[str, list[str]] = {}
        for repo, files in state["modfail"].items():
            for f in files:
                failing[f"{repo}/{f}"] = state["diags"].get(repo, {}).get(f, [])
        for repo, files in state["diags"].items():
            for f, ds in files.items():
                rel = f"{repo}/{f}"
                if rel not in failing:
                    failing[rel] = ds
        failing = {k: v for k, v in failing.items() if k in records}
        todo = sorted(r for r in failing if r not in done_ids
                      and (not only or r in only))
        if args.limit:
            todo = todo[: args.limit]
        if not todo:
            print(f"round {rnd}: nothing left to fix")
            break
        print(f"round {rnd}: {len(todo)} failing files", flush=True)

        fixed: dict[str, str] = {}

        def work(rel: str):
            repo = rel.split("/")[0]
            cur = records[rel].get("_cur", records[rel]["jac"])
            sibs = [k.split("/", 1)[1] for k in records
                    if k.startswith(repo + "/") and k != rel]
            diags = failing.get(rel) or []
            if not diags:
                diags = [b for f, ds in state["diags"].get(repo, {}).items()
                         for b in ds][:30]
            return rel, *fix_one(rel, cur, diags, sibs)

        n_ok = n_err = 0
        with ThreadPoolExecutor(args.jobs) as ex:
            for fut in as_completed([ex.submit(work, r) for r in todo]):
                rel, cand, err = fut.result()
                if cand is None:
                    n_err += 1
                    print(f"  {rel}: LLM fail {err}", flush=True)
                    continue
                n_ok += 1
                fixed[rel] = cand
                records[rel]["_cur"] = cand
        print(f"  produced {n_ok} candidates, {n_err} llm failures", flush=True)
        if not fixed:
            break
        push_files(fixed)
        for rel, cand in fixed.items():
            p = OUTDIR / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(cand)

        repos = sorted({r.split("/")[0] for r in fixed})
        state = remote_recheck(repos)
        newfail = {f"{rp}/{f}" for rp, fs in state["modfail"].items() for f in fs}
        for repo, files in state["diags"].items():
            for f in files:
                newfail.add(f"{repo}/{f}")
        for rel, cand in fixed.items():
            status = "fail" if rel in newfail else "pass"
            if status == "pass":
                done_ids.add(rel)
            log_f.write(json.dumps({"rel": rel, "status": status,
                                    "round": rnd, "model": MODEL}) + "\n")
        log_f.flush()
        print(f"  after recheck: {len(newfail)} files still failing overall", flush=True)
    log_f.close()
    print("done; green files:", len(done_ids))
    return 0


if __name__ == "__main__":
    sys.exit(main())
