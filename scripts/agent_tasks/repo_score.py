#!/usr/bin/env python3
"""Repo-quality scorer for the JacHacks hackathon repos (gold / silver / reject).

Two stages, because all jac work runs on GitHub Actions (kind `repo_score`):

  ci     (runner, sharded)  clone each repo from its GitHub URL, build up to three
         trees and `jac check` each at the pinned jac (0.37.25):
           asis      the clone as-is (vendored jaseci / node_modules dropped)
           repaired  asis + our earlier 0.36.1 repair overlay (data/jachacks_nonsf,
                     shipped as data/repo_scores/ci_input/repaired_jac.tgz)
           mech      best tree + location-driven mechanical 0.37 migration
                     (E1036 bare generic `list`/`dict`/... -> `list[any]`...)
         then on the first green tree (else the last one): `jac code map`,
         `jac run --faux` (endpoint docs), a `jac run --serve` HTTP probe and a
         plain `jac run` probe, each in its own throwaway CWD/port. Writes
         $OUT/results.jsonl and $OUT/trees/<dirname>.tgz (jac/toml/py sources of
         the final tree, used by `merge` and by the feature-task builder).

  merge  (local, text only)  read the fetched shard outputs, compute text
         metrics (idiom density, recency, slop, hollow bodies), MinHash
         near-duplicate / template-fork detection across repos, overlap with the
         eval sets under evals/, then score + tier. Writes
         data/repo_scores/jachacks_scores.jsonl and SUMMARY.md.

Usage
  repo_score.py ci --shard $SHARD/$NSHARDS --out $OUT
  repo_score.py merge runs/ci/repo_score/<run_id>
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import shutil
import signal
import socket
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
DATASET = REPO / "data" / "jachacks_all_dataset_filtered.jsonl"
REPAIRED_TGZ = REPO / "data" / "repo_scores" / "ci_input" / "repaired_jac.tgz"
OUTDIR = REPO / "data" / "repo_scores"
JAC = os.environ.get("JAC_BIN", "jac")
JAC_VERSION = os.environ.get("JAC_TARGET_VERSION", "0.36.1")  # the training pipeline's pinned jac
V37 = tuple(int(x) for x in JAC_VERSION.split(".")[:2]) >= (0, 37)  # 0.37 migrations only apply there

SKIP_DIRS = {"node_modules", ".git", ".venv", "venv", "env", "__pycache__", "dist", "build",
             ".jac", ".next", ".cache", "site-packages", ".pytest_cache", ".mypy_cache",
             "target", ".turbo", ".vercel", "coverage", ".idea", ".vscode"}
VENDOR_HINTS = ("jaseci", "jaclang", "jac-client", "jac_client", "jac-scale", "byllm", "jac-streamlit")
CODE_EXT = {".jac": "jac", ".py": "py", ".js": "js", ".jsx": "js", ".ts": "ts", ".tsx": "ts",
            ".mjs": "js", ".cjs": "js", ".vue": "js", ".svelte": "js", ".go": "go", ".rs": "rs",
            ".java": "java", ".css": "css", ".scss": "css", ".html": "html"}
KEEP_EXT = {".jac", ".toml", ".py", ".json", ".md", ".txt", ".env.example", ".css", ".js",
            ".jsx", ".ts", ".tsx", ".html", ".svg", ".yaml", ".yml", ".csv"}


def sh(cmd, cwd=None, timeout=600, env=None):
    """Run cmd in its own process group; kill the whole group on timeout."""
    t0 = time.time()
    p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         text=True, errors="replace", start_new_session=True, env=env)
    try:
        out, _ = p.communicate(timeout=timeout)
        return p.returncode, out, time.time() - t0
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL)
        out, _ = p.communicate()
        return None, out or "", time.time() - t0


# ---------------------------------------------------------------------------
# jac check parsing
# ---------------------------------------------------------------------------
ERR_RE = re.compile(r"^\s*✖\s*Error:\s*error\[(E\d+)\]:\s*(.*)$")
LOC_RE = re.compile(r"^\s*-->\s*(\S+?\.jac):(\d+):(\d+)")
FILE_STATUS_RE = re.compile(r"^(\S.*?\.jac) (ok|FAILED)\b")
SUMMARY_RE = re.compile(r"=+ (?:(\d+) passed)?(?:, )?(?:(\d+) failed)?.* in [\d.]+s")


def jac_check(tree: Path, timeout=1200) -> dict:
    rc, out, dt = sh([JAC, "check", "-n", *(["-j", "4"] if V37 else []), "."], cwd=tree, timeout=timeout)
    errors, cur = [], None
    status = {}
    for ln in out.splitlines():
        m = ERR_RE.match(ln)
        if m:
            cur = {"code": m.group(1), "msg": m.group(2).strip()[:200], "file": None, "line": None, "col": None}
            errors.append(cur)
            continue
        m = LOC_RE.match(ln)
        if m and cur is not None and cur["file"] is None:
            cur["file"], cur["line"], cur["col"] = m.group(1), int(m.group(2)), int(m.group(3))
            continue
        m = FILE_STATUS_RE.match(ln)
        if m:
            status[m.group(1)] = m.group(2)
    passed = failed = None
    for ln in reversed(out.splitlines()):
        m = SUMMARY_RE.search(ln)
        if m and ("passed" in ln or "failed" in ln):
            passed, failed = int(m.group(1) or 0), int(m.group(2) or 0)
            break
    crash = None
    if rc is None:
        crash = "timeout"
    elif passed is None:
        crash = out[-600:]
    ok = crash is None and failed == 0 and not errors
    raw = ""
    if not ok and not errors:
        keep = [l for l in out.splitlines() if re.search(r"Error|error|✖|FAILED|-->", l)]
        raw = "\n".join(keep[:40])[-3000:]
    return {"raw": raw, "ok": ok, "passed": passed, "failed": failed, "n_errors": len(errors),
            "codes": dict(Counter(e["code"] for e in errors)), "errors": errors,
            "failed_files": sorted(f for f, s in status.items() if s == "FAILED"),
            "secs": round(dt, 1), "crash": crash}


# ---------------------------------------------------------------------------
# mechanical 0.37 migration (location-driven, never guesses)
# ---------------------------------------------------------------------------
GENERIC_FILL = {"list": "list[any]", "dict": "dict[any, any]", "set": "set[any]",
                "tuple": "tuple[any, ...]", "frozenset": "frozenset[any]", "List": "list[any]",
                "Dict": "dict[any, any]", "Set": "set[any]", "Tuple": "tuple[any, ...]",
                "type": "type[any]"}
E1036_RE = re.compile(r'Generic type "(\w+)" requires explicit type arguments')


def move_pypi(t: str) -> str:
    """Move python packages listed directly under [dependencies]/[dev-dependencies]
    into [<table>.pypi] (what `jac fix dependencies` should do, but it refuses to load
    a jac.toml whose [dev-dependencies] still holds python packages)."""
    lines = t.split("\n")
    out, moved, cur = [], defaultdict(list), None
    for ln in lines:
        h = re.match(r"^\s*\[([^\]]+)\]\s*(#.*)?$", ln)
        if h:
            cur = h.group(1).strip()
            out.append(ln)
            continue
        kv = re.match(r'^\s*("?)([A-Za-z0-9_.\-\[\]]+)\1\s*=', ln)
        if cur in ("dependencies", "dev-dependencies") and kv and "/" not in kv.group(2):
            moved[cur].append(ln.strip())
            continue
        out.append(ln)
    # drop tables removed in 0.37 (deploy-only config)
    out2, skip = [], False
    for ln in out:
        h = re.match(r"^\s*\[([^\]]+)\]", ln)
        if h:
            skip = h.group(1).strip().startswith("scale.microservices")
        if not skip:
            out2.append(ln)
    out = [re.sub(r'^(\s*kind\s*=\s*)"(fullstack|web|full-stack)"', r'\1"web-app"', l) for l in out2]
    out = [re.sub(r'^(\s*kind\s*=\s*)"(api-service|api|backend)"', r'\1"service"', l) for l in out]
    for sec, kvs in moved.items():
        hdr = f"[{sec}.pypi]"
        if hdr in out:
            i = out.index(hdr)
            out[i + 1:i + 1] = kvs
        else:
            out += ["", hdr, *kvs]
    return "\n".join(out)


def config_fix(tree: Path) -> list[str]:
    """0.37 jac.toml migration: dotted entry-point, `jac fix dependencies`."""
    done = []
    for toml in tree.rglob("jac.toml"):
        t = toml.read_text(errors="replace")
        def dot(m):
            v = m.group(2)
            v2 = re.sub(r"(\.(sv|cl|na))?\.jac$", "", v).strip("./").replace("/", ".")
            return f'{m.group(1)}"{v2}"'
        t2 = move_pypi(re.sub(r'((?:entry-point|entry_point)\s*=\s*)"([^"]+\.jac)"', dot, t))
        if t2 != t:
            toml.write_text(t2)
            done.append(f"entry-point:{toml.relative_to(tree)}")
        rc, out, _ = sh([JAC, "fix", "dependencies"], cwd=toml.parent, timeout=120)
        if rc == 0 and "no change" not in out.lower() and out.strip():
            done.append(f"deps:{toml.relative_to(tree)}")
    return done


def mech_fix(tree: Path, errors: list[dict]) -> int:
    """Apply E1036 / E1116 fixes at the exact reported location. Returns #edits."""
    by_file = defaultdict(list)
    for e in errors:
        if not e["file"]:
            continue
        m = E1036_RE.search(e["msg"])
        if e["code"] == "E1036" and m and m.group(1) in GENERIC_FILL:
            by_file[e["file"]].append((e["line"], e["col"], m.group(1), GENERIC_FILL[m.group(1)]))
        elif e["code"] == "E1116" and 'got "root"' in e["msg"]:
            by_file[e["file"]].append((e["line"], e["col"], "root", "Root"))
        elif e["code"] == "E2086":
            m2 = re.search(r"Edge '(\w+)' declares no endpoints", e["msg"])
            if m2:
                by_file[e["file"]].append((e["line"], 1, "EDGE:" + m2.group(1), ""))
    n = 0
    for rel, locs in by_file.items():
        p = tree / rel
        if not p.is_file():
            continue
        lines = p.read_text(errors="replace").split("\n")
        for line, col, name, repl in sorted(set(locs), reverse=True):
            i, c = line - 1, col - 1
            if i >= len(lines):
                continue
            s = lines[i]
            if name.startswith("EDGE:"):
                en = name[5:]
                m = re.search(r"\bedge\s+" + en + r"\b(?!\s*:)", s)
                if m:
                    lines[i] = s[:m.end()] + ": any --> any" + s[m.end():]
                    n += 1
                continue
            pat = re.compile(r"(?<![\w.])" + name + (r"\b(?!\s*\[)" if repl != "Root" else r"\b"))
            m = pat.search(s, max(0, c))
            if not m:
                continue
            lines[i] = s[:m.start()] + repl + s[m.end():]
            n += 1
        p.write_text("\n".join(lines))
    return n


# ---------------------------------------------------------------------------
# repo inventory
# ---------------------------------------------------------------------------
def is_vendored(rel: Path) -> bool:
    low = [x.lower() for x in rel.parts[:-1]]
    return any(any(h == part or part.startswith(h + "-") or part.startswith(h + "_") for h in VENDOR_HINTS)
               for part in low)


def walk(root: Path):
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if d not in SKIP_DIRS and not d.startswith(".git")]
        for fn in fns:
            yield Path(dp) / fn


def loc(text: str, ext: str) -> int:
    n = 0
    for ln in text.splitlines():
        s = ln.strip()
        if not s or s.startswith("#") or s.startswith("//"):
            continue
        n += 1
    return n


def inventory(root: Path) -> dict:
    langs = Counter()
    jac_files, vendored = [], 0
    for p in walk(root):
        rel = p.relative_to(root)
        kind = CODE_EXT.get(p.suffix.lower())
        if not kind:
            continue
        if is_vendored(rel):
            vendored += 1
            continue
        try:
            if p.stat().st_size > 2_000_000:
                continue
            t = p.read_text(errors="replace")
        except OSError:
            continue
        langs[kind] += loc(t, p.suffix)
        if kind == "jac":
            jac_files.append(str(rel))
    return {"langs": dict(langs), "jac_files": sorted(jac_files), "vendored_files": vendored}


def make_tree(src: Path, dst: Path):
    """Copy the repo minus skip dirs, vendored subtrees and large binaries."""
    for p in walk(src):
        rel = p.relative_to(src)
        if is_vendored(rel) or p.is_symlink():
            continue
        try:
            if p.stat().st_size > 3_000_000:
                continue
        except OSError:
            continue
        q = dst / rel
        q.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(p, q)


# ---------------------------------------------------------------------------
# runtime probes
# ---------------------------------------------------------------------------
def find_entry(tree: Path, jac_files: list[str]) -> str | None:
    toml = tree / "jac.toml"
    if toml.is_file():
        try:
            import tomllib
            cfg = tomllib.loads(toml.read_text())
            for sec in ("project", "serve", "run", "app"):
                d = cfg.get(sec) or {}
                for k in ("entry-point", "entry_point", "entry", "main", "file"):
                    v = d.get(k)
                    if isinstance(v, str):
                        for cand in (v, v.replace(".", "/") + ".jac"):
                            if cand.endswith(".jac") and (tree / cand).is_file():
                                return cand
        except Exception:
            pass
    names = ["main.jac", "app.jac", "server.jac", "api.jac", "backend.jac", "index.jac"]
    core = [f for f in jac_files if not re.search(r"(^|/)(tests?|docs?|examples?|spikes?)/|test", f)]
    for depth in (0, 1, 2):
        for f in sorted(core, key=lambda x: (x.count("/"), x)):
            if f.count("/") == depth and Path(f).name in names:
                return f
    best, bw = None, 0
    for f in sorted(core, key=lambda x: (x.count("/"), x)):
        t = (tree / f).read_text(errors="replace")
        w = len(re.findall(r"^\s*walker\b", t, re.M)) + len(re.findall(r"def:pub|walker:pub", t)) \
            + (5 if re.search(r"^\s*with\s+entry\b", t, re.M) else 0)
        if w > bw:
            best, bw = f, w
    return best


def first_err(out: str) -> str:
    m = re.findall(r"✖ Error: (.{0,200})", out) or \
        re.findall(r"^\s*(?:E\s+)?(\w*(?:Error|Exception)\b:? .{0,200})$", out, re.M)
    return m[0].strip() if m else ""


def free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


def serve_probe(tree: Path, entry: str, wait=120) -> dict:
    port = free_port()
    ed = Path(entry).parent
    cmd = ([JAC, "run", "--serve", "--no-client", "-p", str(port), Path(entry).name] if V37
           else [JAC, "start", Path(entry).name, "-p", str(port), "-n"])
    p = subprocess.Popen(cmd, cwd=tree / ed, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         text=True, errors="replace", start_new_session=True)
    res = {"ok": False, "status": None, "path": None}
    t0 = time.time()
    try:
        while time.time() - t0 < wait:
            if p.poll() is not None:
                res["exited"] = p.returncode
                break
            for path in ("/", "/docs", "/healthz", "/openapi.json"):
                try:
                    with urllib.request.urlopen(f"http://127.0.0.1:{port}{path}", timeout=3) as r:
                        res.update(ok=r.status == 200, status=r.status, path=path)
                except urllib.error.HTTPError as e:
                    res.update(status=e.code, path=path)
                except Exception:
                    continue
                if res["ok"]:
                    break
            if res["status"] is not None:
                break
            time.sleep(2)
    finally:
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        out = p.communicate()[0] or ""
    res["secs"] = round(time.time() - t0, 1)
    if not res["ok"]:
        res["tail"] = out[-500:]
        res["err"] = first_err(out)
    return res


def run_probe(tree: Path, entry: str, timeout=90) -> dict:
    ed = Path(entry).parent
    rc, out, dt = sh([JAC, "run", Path(entry).name], cwd=tree / ed, timeout=timeout)
    return {"rc": rc, "secs": round(dt, 1), "tail": out[-500:], "err": first_err(out),
            "ok": rc == 0 and "Traceback" not in out and "Error" not in out[-300:]}


def faux_probe(tree: Path, entry: str) -> dict:
    ed = Path(entry).parent
    rc, out, dt = sh([JAC, "run", "--serve", "--faux", Path(entry).name] if V37 else
                     [JAC, "start", Path(entry).name, "--faux"], cwd=tree / ed, timeout=180)
    eps = len(re.findall(r"^\s*(?:GET|POST|PUT|DELETE|PATCH)\s+/", out, re.M))
    return {"rc": rc, "endpoints": eps, "secs": round(dt, 1), "head": out[:1500]}


def code_map(tree: Path) -> dict:
    rc, out, dt = sh([JAC, "code", "map"], cwd=tree, timeout=600)
    try:
        js = json.loads(out[out.index("{"):])
    except Exception:
        return {"ok": False, "tail": out[-400:]}
    arch = js.get("archetypes", [])
    kinds = Counter(a.get("kind") for a in arch)
    return {"ok": True, "kinds": dict(kinds), "genai": sum(1 for a in arch if a.get("is_genai")),
            "abilities": sum(len(a.get("abilities") or []) for a in arch),
            "names": [[a.get("kind"), a.get("name"), a.get("file", "").replace(str(tree) + "/", "")] for a in arch][:400]}


# ---------------------------------------------------------------------------
# ci stage
# ---------------------------------------------------------------------------
def load_repos() -> list[dict]:
    return [json.loads(l) for l in DATASET.open()]


def score_repo_ci(r: dict, repaired_root: Path | None, out: Path) -> dict:
    d = r["dirname"]
    res = {"dirname": d, "id": r["id"], "source": r["source"], "github_url": r.get("github_url"),
           "title": r.get("title"), "jac_version": JAC_VERSION}
    work = Path(tempfile.mkdtemp(prefix=f"rs_{d[:20]}_"))
    try:
        clone = work / "clone"
        rc, o, _ = sh(["git", "clone", "-q", "--depth", "1", r["github_url"], str(clone)], timeout=300,
                      env={**os.environ, "GIT_TERMINAL_PROMPT": "0", "GIT_LFS_SKIP_SMUDGE": "1"})
        if rc != 0:
            res.update(stage="clone_failed", detail=o[-300:])
            return res
        res["sha"] = sh(["git", "rev-parse", "HEAD"], cwd=clone, timeout=30)[1].strip()
        inv = inventory(clone)
        res["inventory"] = {k: v for k, v in inv.items() if k != "jac_files"}
        res["jac_files"] = inv["jac_files"]
        res["repo_markers"] = sorted(x for x in (".cursor", ".codex", "CLAUDE.md", "AGENTS.md", ".claude",
                                                 "jac.toml", "requirements.txt", "package.json", "Dockerfile")
                                     if (clone / x).exists())
        if not inv["jac_files"]:
            res.update(stage="no_jac")
            return res
        asis = work / "asis"
        make_tree(clone, asis)
        shutil.rmtree(clone, ignore_errors=True)
        res["asis_text"] = text_metrics({str(p.relative_to(asis)): p.read_text(errors="replace")
                                         for p in walk(asis) if p.suffix == ".jac"})
        res["config_fix"] = config_fix(asis) if V37 else []
        trees = [("asis", asis)]
        rep_src = repaired_root / d if repaired_root else None
        if rep_src and rep_src.is_dir():
            rep = work / "repaired"
            shutil.copytree(asis, rep)
            n_over = n_diff = 0
            for p in rep_src.rglob("*.jac"):
                if not p.is_file():
                    continue
                rel = p.relative_to(rep_src)
                q = rep / rel
                n_over += 1
                if not q.exists() or q.read_bytes() != p.read_bytes():
                    n_diff += 1
                    q.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(p, q)
            # the 0.36.1 repair renamed some X.cl.jac / X.sv.jac -> X.jac; drop the stale originals
            n_drop = 0
            for q in list(rep.rglob("*.jac")):
                rel = q.relative_to(rep)
                base = re.sub(r"\.(cl|sv|na)\.jac$", ".jac", str(rel))
                if base != str(rel) and not (rep_src / rel).exists() and (rep_src / base).exists():
                    q.unlink()
                    n_drop += 1
            res["repair_overlay"] = {"files": n_over, "changed": n_diff, "dropped_renamed": n_drop}
            trees.append(("repaired", rep))
        checks = {}
        final = None
        for name, t in trees:
            c = jac_check(t)
            checks[name] = c
            if c["ok"]:
                final = (name, t)
                break
        if final is None and V37:
            name, t = trees[-1]
            mech = work / "mech"
            shutil.copytree(t, mech)
            edits = 0
            mig = []
            for tgt in ("placement", "access"):
                rc, o2, _ = sh([JAC, "fix", tgt], cwd=mech, timeout=300)
                mig.append({"fix": tgt, "rc": rc, "tail": o2[-200:]})
                if rc == 0:
                    edits += 1
            res["jac_fix"] = mig
            c = jac_check(mech)
            for _ in range(5):
                n = mech_fix(mech, c["errors"])
                if not n:
                    break
                edits += n
                c = jac_check(mech)
                if c["ok"] or not any(e["code"] in ("E1036", "E1116", "E2086") for e in c["errors"]):
                    break
            if edits:
                checks["mech"] = c
                res["mech_edits"] = edits
                trees.append(("mech", mech))
                if c["ok"]:
                    final = ("mech", mech)
        for c in checks.values():  # keep output small
            c["errors"] = c["errors"][:60]
        res["checks"] = checks
        fname, ftree = final or trees[-1]
        # 0.37 runtime migration: the byllm package now ships as jaclang.byllm
        nb, orig = 0, {}
        for p in (walk(ftree) if V37 else []):
            if p.suffix == ".jac":
                t = p.read_text(errors="replace")
                t2 = re.sub(r"\bimport\s+from\s+byllm(?:\.lib|\.llm)?\s*\{", "import from jaclang.byllm.lib {", t)
                if t2 != t:
                    orig[p] = t
                    p.write_text(t2)
                    nb += 1
        if nb:
            res["byllm_rewrite"] = nb
            if final is not None:
                c = jac_check(ftree)
                c["errors"] = c["errors"][:30]
                res["byllm_check"] = {k: c[k] for k in ("ok", "codes")}
                if not c["ok"]:  # keep the green tree; record that the rewrite broke it
                    for p, t in orig.items():
                        p.write_text(t)
                    res["byllm_rewrite"] = 0
        res["final_tree"] = fname
        res["green"] = final is not None
        res["code_map"] = code_map(ftree)
        entry = find_entry(ftree, sorted(str(p.relative_to(ftree)) for p in walk(ftree) if p.suffix == ".jac"))
        res["entry"] = entry
        if entry and final is not None:
            res["faux"] = faux_probe(ftree, entry)
            res["serve"] = serve_probe(ftree, entry)
            src = (ftree / entry).read_text(errors="replace")
            if "with entry" in src:
                res["run"] = run_probe(ftree, entry)
        # ship the final tree's sources (small text only)
        tdir = out / "trees"
        tdir.mkdir(parents=True, exist_ok=True)
        with tarfile.open(tdir / f"{d}.tgz", "w:gz") as tf:
            total = 0
            for p in sorted(walk(ftree)):
                rel = p.relative_to(ftree)
                if p.suffix.lower() not in KEEP_EXT and p.name not in ("jac.toml", ".env.example"):
                    continue
                if p.name == ".env" or p.name.startswith(".env.") and p.name != ".env.example":
                    continue
                sz = p.stat().st_size
                if sz > 400_000 or total + sz > 25_000_000:
                    continue
                total += sz
                tf.add(p, arcname=str(rel))
        res["stage"] = "done"
        return res
    except Exception as e:  # never let one repo kill the shard
        res.update(stage="error", detail=repr(e)[:400])
        return res
    finally:
        shutil.rmtree(work, ignore_errors=True)


def cmd_ci(a):
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    i, n = map(int, a.shard.split("/"))
    have = sh([JAC, "--version"], timeout=120)[1]
    print("jac:", have.strip()[-60:], "target:", JAC_VERSION, flush=True)
    if JAC_VERSION not in have:
        sys.exit(f"jac on PATH is not the target {JAC_VERSION}: {have!r}")
    repos = [r for k, r in enumerate(load_repos()) if k % n == i]
    if a.only:
        repos = [r for r in load_repos() if r["dirname"] in a.only.split(",")]
    rep_root = None
    if REPAIRED_TGZ.is_file():
        rep_root = Path(tempfile.mkdtemp(prefix="repaired_"))
        with tarfile.open(REPAIRED_TGZ) as tf:
            tf.extractall(rep_root, filter="data")
    import atexit
    if rep_root:
        atexit.register(shutil.rmtree, rep_root, True)
    resf = out / "results.jsonl"
    done = set()
    if resf.exists():
        done = {json.loads(l)["dirname"] for l in resf.open()}
    with ThreadPoolExecutor(a.jobs) as ex:
        futs = [ex.submit(score_repo_ci, r, rep_root, out) for r in repos if r["dirname"] not in done]
        for f in futs:
            res = f.result()
            with resf.open("a") as fh:
                fh.write(json.dumps(res) + "\n")
            print(f"[{res['dirname']}] stage={res.get('stage')} green={res.get('green')} "
                  f"final={res.get('final_tree')} checks={ {k: (v['passed'], v['failed']) for k, v in (res.get('checks') or {}).items()} }",
                  flush=True)


# ---------------------------------------------------------------------------
# merge stage (local, text-only)
# ---------------------------------------------------------------------------
def read_tree(tgz: Path) -> dict[str, str]:
    files = {}
    with tarfile.open(tgz) as tf:
        for m in tf.getmembers():
            if m.isfile() and m.name.endswith(".jac"):
                files[m.name] = tf.extractfile(m).read().decode("utf-8", "replace")
    return files


_STR = re.compile(r'"""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'')
_COM = re.compile(r"#\*[\s\S]*?\*#|#[^\n]*")


def strip_code(src: str) -> str:
    return _STR.sub('""', _COM.sub("", src))


IDIOMS = {
    "by_llm": r"\bby\s+llm\b",
    "sem": r"^\s*sem\s+[\w.]+\s*=",
    "spawn": r"\bspawn\b",
    "visit": r"\bvisit\b",
    "connect": r"\+\+>|<\+\+>|<\+\+|\+>:|:\+>",
    "traverse": r"\[\s*(?:root|here|self|[\w.]+)?\s*-[-\w:>\[]*>|-->\s*\]|\[\s*-->",
    "filter": r"\(\?:|\[\?:",
    "report": r"\breport\b",
    "here": r"\bhere\b",
    "cl_block": r"^\s*cl\s*(\{|import|def|obj|glob)",
    "sv_block": r"^\s*sv\s*(\{|import|def|walker|obj|node)",
    "pub": r":pub\b",
    "test_blk": r"^\s*test\s+[\w\"]",
    "impl": r"^\s*impl\s+[\w.]+",
    "has": r"^\s*has\s+\w+",
    "entry_ab": r"\bwith\s+[\w`|\s]+\s+entry\b",
}
OLD_DIALECT = {
    "import_py": r"\bimport:py\b|\bimport:jac\b",
    "can_plain": r"^\s*can\s+\w+\s*\([^)]*\)\s*(->\s*[^{]+)?\{",
    "root_call": r"\broot\(\)",
    "old_spawn": r"\bspawn\s+here\b|\b:g:\b",
    "old_filter": r"\(`\?|`\?\w",
}
SLOP = {
    "emoji": r"[\U0001F300-\U0001FAFF\u2705\u2714\u274C\u26A0\u2728]",
    "banner": r"^\s*#\s*[=\-#*]{10,}",
    "todo": r"\b(TODO|FIXME|XXX|placeholder|stub|mock data|dummy)\b",
}
HOLLOW_RE = re.compile(r"(?:\bdef|\bcan)\s+\w+[^{;]*\{\s*(?:pass\s*;?|return\s*(?:None|\"\"|\[\]|\{\})?\s*;|raise\s+NotImplementedError[^;]*;)?\s*\}")
FUNC_RE = re.compile(r"(?:\bdef|\bcan)\s+\w+[^{;]*\{")


def text_metrics(files: dict[str, str]) -> dict:
    code = {f: strip_code(t) for f, t in files.items()}
    all_code = "\n".join(code.values())
    all_raw = "\n".join(files.values())
    jac_loc = sum(loc(t, ".jac") for t in code.values())
    m = {"jac_loc": jac_loc, "n_jac": len(files)}
    m["idioms"] = {k: len(re.findall(v, all_code, re.M)) for k, v in IDIOMS.items()}
    m["idioms"]["cl_files"] = sum(1 for f in files if f.endswith(".cl.jac"))
    m["idioms"]["sv_files"] = sum(1 for f in files if f.endswith(".sv.jac"))
    m["idioms"]["impl_files"] = sum(1 for f in files if f.endswith(".impl.jac"))
    m["old"] = {k: len(re.findall(v, all_code, re.M)) for k, v in OLD_DIALECT.items()}
    # archetype counts from source (fallback when `jac code map` returns nothing, e.g. 0.36.1)
    m["decls"] = {k: len(re.findall(r"^\s*(?:async\s+)?" + k + r"\s*(?::\w+\s*)?\b[A-Za-z_]\w*", all_code, re.M))
                  for k in ("node", "edge", "walker", "obj")}
    m["slop"] = {k: len(re.findall(v, all_raw, re.M)) for k, v in SLOP.items()}
    nf = len(FUNC_RE.findall(all_code))
    nh = len(HOLLOW_RE.findall(all_code))
    m["funcs"], m["hollow_funcs"] = nf, nh
    lines = [l.strip() for l in all_code.splitlines() if len(l.strip()) > 30]
    c = Counter(lines)
    m["dup_line_frac"] = round(sum(v - 1 for v in c.values() if v > 1) / max(1, len(lines)), 3)
    side = [f for f in files if re.search(r"(^|/)(docs?|spikes?|scratch|examples?|tmp|old|archive|backup)/|_v\d|copy|_old\b|test", f, re.I)]
    m["side_file_frac"] = round(len(side) / max(1, len(files)), 3)
    return m


def shingles(text: str, k=7) -> set[int]:
    toks = re.findall(r"\w+|[^\s\w]", strip_code(text))
    return {int(hashlib.blake2b(" ".join(toks[i:i + k]).encode(), digest_size=8).hexdigest(), 16)
            for i in range(0, max(0, len(toks) - k + 1))}


NPERM = 128
_P = (1 << 61) - 1


def minhash(sh: set[int]) -> list[int]:
    import random
    rnd = random.Random(1234)
    perms = [(rnd.randrange(1, _P), rnd.randrange(0, _P)) for _ in range(NPERM)]
    if not sh:
        return [_P] * NPERM
    return [min((a * x + b) % _P for x in sh) for a, b in perms]


def eval_shingles() -> tuple[set[int], set[str]]:
    texts = []
    for p in (REPO / "evals").rglob("*"):
        if p.suffix == ".jac":
            texts.append(p.read_text(errors="replace"))
        elif p.suffix == ".jsonl":
            for l in p.open(errors="replace"):
                try:
                    o = json.loads(l)
                except Exception:
                    continue
                stack = [o]
                while stack:
                    x = stack.pop()
                    if isinstance(x, dict):
                        stack.extend(x.values())
                    elif isinstance(x, list):
                        stack.extend(x)
                    elif isinstance(x, str) and len(x) > 80 and ("{" in x and (";" in x or "def " in x)):
                        texts.append(x)
    sh_all, lines = set(), set()
    for t in texts:
        sh_all |= shingles(t, 12)
        lines |= {re.sub(r"\s+", " ", l.strip()) for l in strip_code(t).splitlines() if len(l.strip()) > 40}
    return sh_all, lines


def sat(x, half):
    """Saturating 0..1 curve: x == half -> 0.5."""
    return x / (x + half) if x > 0 else 0.0


def score(r: dict) -> tuple[float, dict]:
    tm = r["text"]
    kloc = max(tm["jac_loc"], 1) / 1000
    km = r.get("code_map", {}).get("kinds", {}) if r.get("code_map", {}).get("ok") else {}
    if not km:
        km = tm.get("decls", {})
    nodes, edges, walkers = km.get("node", 0), km.get("edge", 0), km.get("walker", 0)
    idi = dict(tm["idioms"])
    at = (r.get("asis_text") or {}).get("idioms", {})
    for k in ("cl_files", "sv_files", "cl_block", "sv_block"):
        idi[k] = max(idi.get(k, 0), at.get(k, 0))
    parts = {}
    # idiom density (40)
    graph_density = (nodes + 2 * edges + 2 * walkers) / kloc
    trav_density = (idi["visit"] + idi["spawn"] + idi["connect"] + idi["traverse"] + idi["filter"]) / kloc
    ai = (r.get("code_map", {}).get("genai", 0) + idi["by_llm"] + idi["sem"]) / kloc
    split = 1.0 if (idi["cl_files"] + idi["cl_block"]) and (idi["sv_files"] + idi["sv_block"] + idi["pub"] + walkers) else 0.0
    parts["idiom"] = round(16 * sat(graph_density, 8) + 14 * sat(trav_density, 10) + 6 * sat(ai, 2) + 4 * split, 2)
    # runs (15)
    run_pts = 0.0
    if (r.get("serve") or {}).get("ok"):
        run_pts += 10
    elif (r.get("serve") or {}).get("status"):
        run_pts += 6
    if (r.get("run") or {}).get("ok"):
        run_pts += 5
    if (r.get("faux") or {}).get("rc") == 0:
        run_pts += 3 + min(2, (r["faux"].get("endpoints", 0)) / 5)
    parts["runs"] = round(min(15, run_pts), 2)
    # size / shape (20)
    langs = r.get("inventory", {}).get("langs", {})
    other = sum(v for k, v in langs.items() if k in ("py", "js", "ts", "go", "rs", "java"))
    jac_share = tm["jac_loc"] / max(1, tm["jac_loc"] + other)
    parts["shape"] = round(6 * min(1, tm["n_jac"] / 6) + 8 * sat(tm["jac_loc"], 800) * 2 * 0.5 + 6 * jac_share, 2)
    # recency (15): green as-is beats repaired beats mech
    ft = r.get("final_tree")
    parts["recency"] = {"asis": 12, "repaired": 7, "mech": 9}.get(ft, 0)
    if ft == "mech" and r.get("checks", {}).get("repaired"):
        parts["recency"] = 5
    rep = r.get("repair_frac", 0)
    parts["recency"] -= round(6 * rep, 2)
    old = sum(tm["old"].values()) / kloc
    parts["recency"] += 3 * (1 - sat(old, 3))
    parts["recency"] = round(max(0, parts["recency"]), 2)
    # slop (-15 .. 0) + clean bonus (10)
    sl = tm["slop"]
    slop = 4 * sat(sl["emoji"] / kloc, 5) + 3 * sat(sl["banner"] / kloc, 6) + 3 * sat(sl["todo"] / kloc, 4) \
        + 3 * min(1, tm["dup_line_frac"] * 3) + 2 * tm["side_file_frac"]
    hollow = tm["hollow_funcs"] / max(1, tm["funcs"])
    slop += 5 * min(1, hollow * 4)
    parts["slop"] = -round(min(15, slop), 2)
    parts["clean"] = 10.0
    total = round(sum(parts.values()), 1)
    return total, parts


def cmd_merge(a):
    run_dir = Path(a.run_dir)
    res = {}
    trees = {}
    for f in sorted(run_dir.rglob("results.jsonl")):
        for l in f.open():
            o = json.loads(l)
            prev = res.get(o["dirname"])
            if prev is None or (prev.get("stage") != "done" and o.get("stage") == "done"):
                res[o["dirname"]] = o
    for t in run_dir.rglob("trees/*.tgz"):
        trees[t.stem] = t
    repos = load_repos()
    # repair fraction from our 0.36.1 repair provenance (non-SF)
    rep_by = defaultdict(lambda: [0, 0])
    nonsf = REPO / "data" / "jachacks_nonsf_jac_files_checked.jsonl"
    if nonsf.exists():
        for l in nonsf.open():
            o = json.loads(l)
            rep_by[o["dirname"]][0] += 1
            rep_by[o["dirname"]][1] += 1 if o.get("repaired_by") else 0
    print("eval shingles ...", file=sys.stderr)
    ev_sh, ev_lines = eval_shingles()
    rows = []
    sigs = {}
    shs = {}
    for r in repos:
        d = r["dirname"]
        o = res.get(d, {"dirname": d, "stage": "missing"})
        o.setdefault("id", r["id"]); o.setdefault("source", r["source"]); o.setdefault("title", r.get("title"))
        o.setdefault("github_url", r.get("github_url"))
        files = read_tree(trees[d]) if d in trees else {}
        o["text"] = text_metrics(files) if files else None
        tot, rp = rep_by.get(d, [0, 0])
        if o.get("final_tree") == "asis":
            o["repair_frac"] = 0.0
        else:
            o["repair_frac"] = round(rp / tot, 3) if tot else (0.0 if o.get("final_tree") != "mech" else 0.0)
        if files:
            s = set().union(*(shingles(t) for t in files.values()))
            shs[d] = s
            sigs[d] = minhash(s)
            s12 = set().union(*(shingles(t, 12) for t in files.values()))
            o["eval_overlap"] = round(len(s12 & ev_sh) / max(1, len(s12)), 4)
            rl = {re.sub(r"\s+", " ", l.strip()) for t in files.values() for l in strip_code(t).splitlines() if len(l.strip()) > 40}
            o["eval_line_overlap"] = round(len(rl & ev_lines) / max(1, len(rl)), 4)
        rows.append(o)
    # boilerplate shingles: present in >= 15% of repos (jac-client templates, etc.)
    df = Counter()
    for s in shs.values():
        df.update(s)
    common = {x for x, c in df.items() if c >= max(4, 0.15 * len(shs))}
    for o in rows:
        d = o["dirname"]
        if d in shs:
            o["unique_frac"] = round(1 - len(shs[d] & common) / max(1, len(shs[d])), 3)
    # near-duplicates via MinHash
    names = sorted(sigs)
    dup_of = {}
    for i, x in enumerate(names):
        for y in names[i + 1:]:
            j = sum(1 for p, q in zip(sigs[x], sigs[y]) if p == q) / NPERM
            if j >= 0.5:
                # keep the larger repo, mark the other
                keep, drop = (x, y) if len(shs[x]) >= len(shs[y]) else (y, x)
                dup_of.setdefault(drop, (keep, round(j, 2)))
    for o in rows:
        reasons = []
        t = o.get("text")
        if o.get("stage") != "done":
            reasons.append(o.get("stage") or "missing")
        elif not o.get("green"):
            last = list(o.get("checks", {}).values())[-1] if o.get("checks") else {}
            reasons.append(f"not_green@{JAC_VERSION} ({last.get('failed')} files failing, codes {dict(Counter(last.get('codes', {})).most_common(3))})")
        if t:
            langs = o.get("inventory", {}).get("langs", {})
            other = sum(v for k, v in langs.items() if k in ("py", "js", "ts", "go", "rs", "java"))
            o["jac_share"] = round(t["jac_loc"] / max(1, t["jac_loc"] + other), 3)
            if t["jac_loc"] < 150:
                reasons.append(f"too_little_jac ({t['jac_loc']} LOC)")
            elif o["jac_share"] < 0.25:
                reasons.append(f"mostly_non_jac (jac share {o['jac_share']})")
            if t["funcs"] >= 5 and t["hollow_funcs"] / t["funcs"] > 0.3:
                reasons.append(f"hollow_stubs ({t['hollow_funcs']}/{t['funcs']})")
            if o.get("unique_frac", 1) < 0.35:
                reasons.append(f"template_fork (unique {o['unique_frac']})")
        if o["dirname"] in dup_of:
            k, j = dup_of[o["dirname"]]
            reasons.append(f"near_duplicate_of {k} (J~{j})")
        if o.get("eval_overlap", 0) > 0.05 or o.get("eval_line_overlap", 0) > 0.10:
            reasons.append(f"eval_overlap ({o.get('eval_overlap')}/{o.get('eval_line_overlap')})")
        o["reject_reasons"] = reasons
        if t and o.get("stage") == "done":
            o["score"], o["score_parts"] = score(o)
        else:
            o["score"], o["score_parts"] = 0.0, {}
    ok = sorted([o for o in rows if not o["reject_reasons"]], key=lambda o: -o["score"])
    gold_cut = a.gold_cut
    for o in rows:
        if o["reject_reasons"]:
            o["tier"] = "reject"
        elif o["score"] >= gold_cut and o["text"]["jac_loc"] >= 200 and o["text"]["n_jac"] >= 2:
            o["tier"] = "gold"
        else:
            o["tier"] = "silver"
    OUTDIR.mkdir(parents=True, exist_ok=True)
    keep_keys = ["dirname", "id", "source", "title", "github_url", "sha", "tier", "score", "score_parts",
                 "reject_reasons", "green", "final_tree", "repair_frac", "mech_edits", "repair_overlay", "config_fix", "jac_fix",
                 "jac_share", "unique_frac", "eval_overlap", "eval_line_overlap", "entry", "inventory",
                 "repo_markers", "text"]
    with (OUTDIR / "jachacks_scores.jsonl").open("w") as fh:
        for o in sorted(rows, key=lambda o: (-o["score"], o["dirname"])):
            row = {k: o.get(k) for k in keep_keys}
            row["checks"] = {k: {kk: v.get(kk) for kk in ("ok", "passed", "failed", "n_errors", "codes", "secs", "crash")}
                             for k, v in (o.get("checks") or {}).items()}
            cm = o.get("code_map") or {}
            row["code_map"] = {k: cm.get(k) for k in ("ok", "kinds", "genai", "abilities")}
            row["serve"] = {k: (o.get("serve") or {}).get(k) for k in ("ok", "status", "path", "secs", "err")} if o.get("serve") else None
            row["run"] = {k: (o.get("run") or {}).get(k) for k in ("ok", "rc", "secs", "err")} if o.get("run") else None
            row["faux"] = {k: (o.get("faux") or {}).get(k) for k in ("rc", "endpoints")} if o.get("faux") else None
            fh.write(json.dumps(row) + "\n")
    write_summary(rows, a)
    print(Counter(o["tier"] for o in rows))


def why(o) -> str:
    t, cm = o["text"], (o.get("code_map") or {}).get("kinds", {}) or o["text"].get("decls", {})
    bits = [f"{t['n_jac']} files/{t['jac_loc']} LOC", f"jac share {o.get('jac_share')}",
            f"{cm.get('node', 0)}N/{cm.get('edge', 0)}E/{cm.get('walker', 0)}W",
            f"trav {t['idioms']['visit'] + t['idioms']['spawn'] + t['idioms']['connect']}"]
    if t["idioms"]["by_llm"]:
        bits.append(f"by llm x{t['idioms']['by_llm']}")
    at = (o.get("asis_text") or {}).get("idioms", {})
    if t["idioms"]["cl_files"] or t["idioms"]["cl_block"] or at.get("cl_files") or at.get("cl_block"):
        bits.append("cl/sv split")
    bits.append(f"green:{o.get('final_tree')}")
    s = o.get("serve") or {}
    bits.append(f"serve:{s.get('status')}" if s else "serve:-")
    if (o.get("run") or {}).get("ok"):
        bits.append("run ok")
    return ", ".join(bits)


def write_summary(rows, a):
    tiers = Counter(o["tier"] for o in rows)
    rej = Counter()
    for o in rows:
        for r in o["reject_reasons"]:
            rej[r.split(" ")[0].split("@")[0]] += 1
    fin = Counter(o.get("final_tree") for o in rows if o.get("green"))
    L = ["# JacHacks repo-quality scores", "",
         f"Scored {len(rows)} repos from `data/jachacks_all_dataset_filtered.jsonl` at jac {JAC_VERSION} "
         f"(GitHub Actions kind `repo_score`, run `{Path(a.run_dir).name}`). Scorer: `scripts/agent_tasks/repo_score.py`.", "",
         "## Tiers", "", "| tier | repos |", "|---|---|"]
    L += [f"| {k} | {tiers.get(k, 0)} |" for k in ("gold", "silver", "reject")]
    L += ["", f"Green trees: as-is {fin.get('asis', 0)}, after 0.36.1 repair overlay {fin.get('repaired', 0)}, "
          f"after mechanical 0.37 migration {fin.get('mech', 0)}.", "",
          "Reject reasons (a repo can have several): " + ", ".join(f"{k} {v}" for k, v in rej.most_common()), "",
          f"Gold = no hard-gate failure, score >= {a.gold_cut}, >= 200 jac LOC, >= 2 files.", "",
          "## Score distribution (non-reject)", "", "| bucket | n |", "|---|---|"]
    b = Counter(int(o["score"] // 10) * 10 for o in rows if o["tier"] != "reject")
    L += [f"| {k}-{k + 9} | {b[k]} |" for k in sorted(b)]
    L += ["", "## Top 15", "", "| # | repo | tier | score | why |", "|---|---|---|---|---|"]
    top = sorted([o for o in rows if o["tier"] != "reject"], key=lambda o: -o["score"])[:15]
    for i, o in enumerate(top, 1):
        L.append(f"| {i} | {o['dirname']} | {o['tier']} | {o['score']} | {why(o)} |")
    L += ["", "## Method", "",
          "- Hard gates: green on `jac check` at 0.37.25 (as-is, with our 0.36.1 repair overlay, or after a location-driven "
          "mechanical E1036 migration); >=150 jac LOC and jac >=25% of code LOC; no MinHash near-duplicate (J>=0.5, keep larger); "
          "unique (non-boilerplate) shingle fraction >=0.35; eval-set overlap <=5% (12-token shingles) / <=10% (lines); hollow bodies <=30%.",
          "- Score (max ~100): idiom density 40 (`jac code map` nodes/edges/walkers per KLOC, traversal/spawn/connect/filter per KLOC, "
          "by llm/sem, cl/sv split) + runs 15 (`jac run --serve` HTTP probe, `jac run`, `jac run --faux` endpoints) + shape 20 "
          "(files, LOC, jac share) + recency 15 (as-is > mech > repaired; minus repaired fraction, old-dialect residue) + clean 10 "
          "minus slop up to 15 (emoji, banners, TODO/stub words, duplicate lines, side/spike files, hollow bodies).", ""]
    (OUTDIR / "SUMMARY.md").write_text("\n".join(L))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("ci")
    c.add_argument("--shard", default="0/1")
    c.add_argument("--out", default=os.environ.get("OUT", "ci_out"))
    c.add_argument("--jobs", type=int, default=2)
    c.add_argument("--only", default="")
    m = sub.add_parser("merge")
    m.add_argument("run_dir")
    m.add_argument("--gold-cut", type=float, default=60)
    a = ap.parse_args()
    {"ci": cmd_ci, "merge": cmd_merge}[a.cmd](a)


if __name__ == "__main__":
    main()
