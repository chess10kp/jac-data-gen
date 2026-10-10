#!/usr/bin/env python3
"""Build the `fix` kind of the agentic-task pool (data/agent_tasks/fix/).

A fix task = a real Jac workspace that fails `jac check`, plus a hidden green
reference. The agent must get `jac check` green without hollowing the code
(graded by scripts/agent_tasks/fix_gate.py).

Sources
  jachacks  hackathon repos (spring + 2026 editions). Original (old-dialect,
            failing) files: data/jachacks_{spring,2026}_jac_files_filtered.jsonl;
            repaired (0.36.1-green) tree: data/jachacks_nonsf/ (gitignored, pushed
            to CI as an extra path). A task is a module subset: a seed module the
            repair touched + its local import closure, with every file the repair
            touched reverted to its original text.
  osp       synthetic OSP programs, data/osp_repair/code_fix.jsonl: a broken
            generator attempt (starter) vs the gate+test-verified fix
            (reference) + its verified tests, rewritten as a separate hidden
            module grader/tests.jac that imports the target.

Everything is re-verified at the pinned jac (0.36.1): starter must FAIL
`jac check`, reference must PASS it (and its tests, for osp); the anti-hollowing
gate is calibrated per candidate (reference passes, body-stub fails,
delete-the-broken-files fails).

Heavy work runs on GitHub Actions (.ci/agent-tasks/fix.sh). Stages:
  candidates --shard i/n --out DIR   [CI] propose + validate + calibrate units,
                                     write DIR/cands/<cid>/ + DIR/candidates.jsonl
  select --runs runs/ci/fix/<run>    [local, no jac] dedupe/diversify, write
                                     data/agent_tasks/fix/<id>/ + manifest.jsonl
                                     (resumable: existing task dirs are kept)
  validate --shard i/n --out DIR     [CI] re-verify the final pool in place +
                                     gate calibration -> DIR/validate.jsonl
  merge-validate --runs ...          [local] fold validate results into manifest
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
import fix_gate as G  # noqa: E402

JAC_VERSION = "0.36.1"
DATA = REPO / "data"
OUT = DATA / "agent_tasks" / "fix"
MANIFEST = OUT / "manifest.jsonl"

MAX_FILES = 12
MAX_REF_CHARS = 60_000
MAX_BROKEN = 10
MAX_ERRORS = 60
UNITS_PER_REPO = 6      # evaluated in CI
TASKS_PER_REPO = 2      # kept in the pool
OSP_EVAL = 120          # osp candidates evaluated in CI
SECRET_RE = re.compile(r"(sk-(?:proj-|ant-)?[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|ghp_[A-Za-z0-9]{30,}|"
                       r"xox[bap]-[A-Za-z0-9-]{20,}|AKIA[0-9A-Z]{16}|sk-or-v1-[0-9a-f]{20,}|"
                       r"(?i:api[_-]?key|secret|token)\s*[:=]\s*[\"'][A-Za-z0-9_\-]{24,}[\"'])")


def sid(*parts: str) -> str:
    return hashlib.sha1("|".join(parts).encode()).hexdigest()[:8]


def slug(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:40]


# --------------------------------------------------------------------------
# jachacks trees + units (pure python)
# --------------------------------------------------------------------------
def load_pairs() -> dict[str, dict[str, tuple[str, str]]]:
    """repo -> {ref_rel: (orig_rel, orig_src)}."""
    orig: dict[str, str] = {}
    for s in ("spring", "2026"):
        for line in open(DATA / f"jachacks_{s}_jac_files_filtered.jsonl"):
            r = json.loads(line)
            orig[f"{r['dirname']}/{r['file_path']}"] = r["jac"]
    pairs: dict[str, dict] = {}
    for line in open(DATA / "jachacks_nonsf_jac_files_checked.jsonl"):
        r = json.loads(line)
        o_rel = r.get("renamed_from", r["file_path"])
        pairs.setdefault(r["dirname"], {})[r["file_path"]] = (o_rel, orig[f"{r['dirname']}/{o_rel}"])
    return pairs


def repo_meta() -> dict[str, dict]:
    meta = {}
    for s in ("spring", "2026"):
        for line in open(DATA / f"jachacks_{s}_jac_files_filtered.jsonl"):
            r = json.loads(line)
            meta.setdefault(r["dirname"], {"repo_url": r["github_url"], "title": r["title"],
                                           "edition": s})
    return meta


IMP_RE = re.compile(r"^\s*(?:import|include)\s+(?::\w+\s+)?(?:from\s+)?([.\w]+)", re.M)


def resolve(mod: str, frm: Path, root: Path) -> list[Path]:
    lead = len(mod) - len(mod.lstrip("."))
    parts = [p for p in mod.lstrip(".").split(".") if p]
    if lead:
        b = frm.parent
        for _ in range(lead - 1):
            b = b.parent
        bases = [b]
    else:
        bases = [frm.parent, *[a for a in frm.parent.parents if str(a).startswith(str(root))]]
    for b in bases:
        stem = b.joinpath(*parts) if parts else b
        hits = [c for c in (stem.with_name(stem.name + ".jac"), stem.with_name(stem.name + ".cl.jac"),
                            stem.with_name(stem.name + ".sv.jac"), stem / "__init__.jac")
                if c.exists()]
        if hits:
            return hits
    return []


def companions(p: Path) -> list[Path]:
    stem = p.name.split(".")[0]
    d = p.parent
    out = [c for c in d.glob(f"{stem}.*.jac") if c != p]
    if (d / "impl").is_dir():
        out += list((d / "impl").glob(f"{stem}.*jac"))
    if (d / f"{stem}.impl").is_dir():
        out += list((d / f"{stem}.impl").glob("*.jac"))
    return out


def closure(seed: Path, root: Path) -> set[Path]:
    seen, todo = set(), [seed]
    while todo:
        p = todo.pop()
        if p in seen or not p.exists():
            continue
        seen.add(p)
        todo += companions(p)
        for m in IMP_RE.finditer(p.read_text(errors="replace")):
            todo += resolve(m.group(1), p, root)
    return seen


def module_of(rel: str) -> str:
    rel = re.sub(r"(^|/)impl/", r"\1", rel)
    rel = re.sub(r"\.impl/[^/]+$", ".jac", rel)
    return re.sub(r"\.(impl|cl|sv|test)\.jac$", ".jac", rel)


def jachacks_units(nonsf: Path) -> list[dict]:
    pairs = load_pairs()
    units = []
    for repo, m in sorted(pairs.items()):
        root = nonsf / repo
        if not root.is_dir():
            continue
        ostr = {o: src for _, (o, src) in m.items()}
        changed = [r for r, (o, src) in m.items()
                   if o != r or not (root / r).exists() or (root / r).read_text() != src]
        seeds = sorted({module_of(r) for r in changed})
        repo_units = []
        for seed in seeds:
            sp = root / seed
            if not sp.exists():
                sp = next((root / r for r in changed if module_of(r) == seed and (root / r).exists()), None)
                if sp is None:
                    continue
            rels = sorted(str(p.relative_to(root)) for p in closure(sp, root))
            if any(part.startswith(".") for r in rels for part in r.split("/")):
                continue  # hidden dirs (vendored docs, tooling) -- also dropped by CI artifacts
            if len(rels) > MAX_FILES:
                continue
            chars = sum((root / r).stat().st_size for r in rels)
            if chars > MAX_REF_CHARS:
                continue
            starter_map = {}  # starter_rel -> ref_rel
            for r in rels:
                o = m.get(r, (r, None))[0]
                starter_map[o] = r
            reverted = sorted(o for o, r in starter_map.items()
                              if r in m and (o != r or ostr[o] != (root / r).read_text()))
            if not reverted:
                continue
            repo_units.append({"source": "jachacks", "repo": repo, "seed": seed, "ref_files": rels,
                               "starter_map": starter_map, "reverted": reverted, "ref_chars": chars})
        # prefer distinct, non-overlapping units; smaller first
        repo_units.sort(key=lambda u: (u["ref_chars"], u["seed"]))
        kept: list[dict] = []
        for u in repo_units:
            s = set(u["ref_files"])
            if any(len(s & set(k["ref_files"])) / len(s | set(k["ref_files"])) > 0.5 for k in kept):
                continue
            if any(set(u["reverted"]) == set(k["reverted"]) for k in kept):
                continue
            kept.append(u)
            if len(kept) >= UNITS_PER_REPO:
                break
        units += kept
    for u in units:
        u["cid"] = f"jh-{slug(u['repo'].split('__')[-1])}-{sid(u['repo'], u['seed'])}"
    return units


def materialize_jachacks(u: dict, nonsf: Path, dst: Path) -> tuple[Path, Path]:
    pairs = load_pairs_cached()[u["repo"]]
    ostr = {o: src for _, (o, src) in pairs.items()}
    ref, st = dst / "reference", dst / "starter"
    for r in u["ref_files"]:
        (ref / r).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(nonsf / u["repo"] / r, ref / r)
    for o, r in u["starter_map"].items():
        (st / o).parent.mkdir(parents=True, exist_ok=True)
        if o in u["reverted"]:
            (st / o).write_text(ostr[o])
        else:
            shutil.copy(nonsf / u["repo"] / r, st / o)
    return st, ref


_PAIRS = None


def load_pairs_cached():
    global _PAIRS
    if _PAIRS is None:
        _PAIRS = load_pairs()
    return _PAIRS


# --------------------------------------------------------------------------
# osp units
# --------------------------------------------------------------------------
def osp_units() -> list[dict]:
    rows = []
    for line in open(DATA / "osp_repair" / "code_fix.jsonl"):
        r = json.loads(line)
        b, f = r["broken"], r["fixed"]
        if not (b.get("code") and f.get("code") and f.get("jac_tests")):
            continue
        if f.get("test_verdict") != "PASS" or b["code"].strip() == f["code"].strip():
            continue
        if len(f["code"]) > 12000:
            continue
        rows.append({"source": "osp", "row_id": r["id"], "target_id": r["target_id"],
                     "prompt": r.get("prompt", ""), "broken_code": b["code"],
                     "broken_error": b.get("error", "")[:400],
                     "error_code": b.get("error_code") or "none",
                     "fixed_code": f["code"], "tests": f["jac_tests"],
                     "broken_generator": b.get("generator"),
                     "fixed_generator": f.get("generator_model_id") or f.get("generator")})
    # one per base task, stratified round-robin over the broken error code
    by_task = {}
    for r in sorted(rows, key=lambda r: r["row_id"]):
        by_task.setdefault(r["target_id"].rsplit("__", 1)[0], r)
    by_code = defaultdict(list)
    for r in by_task.values():
        by_code[r["error_code"]].append(r)
    for k in by_code:
        by_code[k].sort(key=lambda r: sid(r["row_id"]))
    picked = []
    while len(picked) < OSP_EVAL and any(by_code.values()):
        for k in sorted(by_code, key=lambda k: -len(by_code[k])):
            if by_code[k] and len(picked) < OSP_EVAL:
                picked.append(by_code[k].pop(0))
    for u in picked:
        u["cid"] = f"osp-{slug(u['target_id'].rsplit('__', 1)[0])}-{sid(u['row_id'])}"
    return picked


def osp_tests_module(fixed_code: str, tests: str) -> str:
    """Annex-style test body -> separate module importing the target (main.jac)."""
    names = sorted({n for _, n in G.toplevel_names(fixed_code, G.ALL_KINDS)})
    used = [n for n in names if re.search(rf"\b{re.escape(n)}\b", tests)]
    lines = tests.splitlines()
    # insert after the leading docstring/import block
    i = 0
    if lines and lines[0].lstrip().startswith('"""'):
        if lines[0].count('"""') >= 2:
            i = 1
        else:
            i = next((k + 1 for k in range(1, len(lines)) if '"""' in lines[k]), 1)
    imp = f"import from main {{ {', '.join(used)} }}" if used else ""
    return "\n".join(lines[:i] + ([imp] if imp else []) + lines[i:]) + "\n"


def materialize_osp(u: dict, dst: Path) -> tuple[Path, Path]:
    ref, st = dst / "reference", dst / "starter"
    ref.mkdir(parents=True)
    st.mkdir(parents=True)
    (st / "main.jac").write_text(u["broken_code"])
    (ref / "main.jac").write_text(u["fixed_code"])
    (dst / "tests.jac").write_text(osp_tests_module(u["fixed_code"], u["tests"]))
    return st, ref



# --------------------------------------------------------------------------
# CI: candidates
# --------------------------------------------------------------------------
def summarize_errors(chk: dict) -> dict:
    codes = Counter(e["code"] for e in chk["errors"])
    files = sorted({e["file"] for e in chk["errors"] if e["file"]} | set(chk["failed_files"]))
    return {"n_errors": chk["n_errors"], "codes": dict(codes.most_common()),
            "broken_files": files, "crash": chk["crash"],
            "sample": [f"{e['code']} {e['file']}:{e['line']} {e['msg'][:120]}" for e in chk["errors"][:8]]}


def evaluate(u: dict, cdir: Path, nonsf: Path | None) -> dict:
    """Validate + calibrate one unit; writes cdir/{starter,reference,tests.jac,meta.json}."""
    if cdir.exists():
        shutil.rmtree(cdir)
    cdir.mkdir(parents=True)
    if u["source"] == "osp":
        st, ref = materialize_osp(u, cdir)
    else:
        st, ref = materialize_jachacks(u, nonsf, cdir)
    res = {"cid": u["cid"], "source": u["source"], "valid": False}
    clean = lambda d: [shutil.rmtree(x, ignore_errors=True) for x in d.rglob(".jac") if x.is_dir()]  # noqa: E731
    r_chk = G.run_check(ref)
    clean(ref)
    res["reference"] = summarize_errors(r_chk)
    if not r_chk["ok"]:
        res["reason"] = f"reference fails check ({r_chk['n_errors']} errors)"
        return res
    s_chk = G.run_check(st)
    clean(st)
    res["starter"] = summarize_errors(s_chk)
    if s_chk["ok"]:
        res["reason"] = "starter already green"
        return res
    if res["starter"]["n_errors"] > MAX_ERRORS or len(res["starter"]["broken_files"]) > MAX_BROKEN:
        res["reason"] = "too large"
        return res
    if s_chk["crash"]:
        res["reason"] = "starter check crashed: " + s_chk["crash"][-200:]
        return res
    if u["source"] == "osp":
        with tempfile.TemporaryDirectory() as td:
            w = Path(td) / "w"
            shutil.copytree(ref, w)
            shutil.copy(cdir / "tests.jac", w / "tests.jac")
            t = G.run_tests(w)
        res["reference_test"] = t
        if not t["ok"]:
            res["reason"] = "reference fails hidden tests: " + t["detail"]
            return res
    # targets: reference files corresponding to starter files the agent must touch
    broken_starter = sorted({_rel(f, st) for f in res["starter"]["broken_files"]})
    if u["source"] == "osp":
        targets = ["main.jac"]
    else:
        targets = sorted({u["starter_map"].get(o, o) for o in u["reverted"]})
    have = {str(p.relative_to(ref)) for p in G.jac_files(ref)}
    norm = {G._norm(h): h for h in have}
    targets = sorted({t if t in have else norm.get(G._norm(t), t) for t in targets} & have)
    inv = G.inventory(ref, targets, starter=st)
    if sum(min(inv["body"].get(t, 0), inv["starter_body"].get(G._norm(t), 0)) for t in targets) < 20:
        res["reason"] = "no function bodies in target files (nothing a stub could hollow)"
        return res
    (cdir / "symbols.json").write_text(json.dumps(inv, indent=1))
    res.update({"broken_paths": broken_starter, "target_paths": targets})
    # calibration: write a throwaway task.json so G.grade can run
    task = {"id": u["cid"], "gates": ["check", "fidelity"] + (["test"] if u["source"] == "osp" else []),
            "target_paths": targets, "broken_paths": broken_starter}
    tdir = cdir / "_gradetask"
    (tdir / "grader").mkdir(parents=True)
    (tdir / "task.json").write_text(json.dumps(task))
    shutil.copy(cdir / "symbols.json", tdir / "grader" / "symbols.json")
    if (cdir / "tests.jac").exists():
        shutil.copy(cdir / "tests.jac", tdir / "grader" / "tests.jac")
    cal = {}
    cal["reference"] = G.grade(tdir, ref, inv)
    cal["starter_profile"] = G.grade(tdir, st, inv, run_check_too=False)
    with tempfile.TemporaryDirectory() as td:
        s = Path(td) / "stub"
        G.make_stub(ref, s)
        cal["stub"] = G.grade(tdir, s, inv)
        d = Path(td) / "del"
        G.make_delete_targets(st, d, broken_starter)
        cal["delete_targets"] = G.grade(tdir, d, inv)
    shutil.rmtree(tdir)
    res["calibration"] = {k: {"pass": v["pass"], "check": v["check"]["ok"],
                              "sym": v["symbols"]["ratio"], "mass": v["mass"]["ratio"],
                              "body": v["mass"]["body_ratio"],
                              "min_file": v["mass"]["min_file"], "reasons": v["reasons"],
                              **({"test": v["test"]["ok"]} if "test" in v else {})}
                          for k, v in cal.items()}
    if not cal["reference"]["pass"]:
        res["reason"] = "gate rejects reference: " + "; ".join(cal["reference"]["reasons"])
        return res
    if cal["stub"]["pass"] or cal["delete_targets"]["pass"]:
        res["reason"] = "gate admits a hollow candidate"
        return res
    res["valid"] = True
    return res


def r_chk_files(res: dict) -> list[str]:
    return res["starter"]["broken_files"]


def _rel(f: str, ws: Path) -> str:
    p = Path(f)
    if p.is_absolute():
        try:
            return str(p.resolve().relative_to(ws.resolve()))
        except ValueError:
            return f
    return f


def shard_of(items: list, spec: str) -> list:
    i, n = map(int, spec.split("/"))
    return items[i::n]


def cmd_candidates(a) -> None:
    out = Path(a.out)
    (out / "cands").mkdir(parents=True, exist_ok=True)
    nonsf = Path(a.nonsf)
    if nonsf.suffix == ".gz":  # CI: staged, secret-redacted .jac-only snapshot
        x = Path(tempfile.mkdtemp(prefix="nonsf_"))
        import tarfile
        with tarfile.open(nonsf) as tf:
            tf.extractall(x, filter="data")
        nonsf = x / "jachacks_nonsf"
    units = jachacks_units(nonsf) + osp_units()
    units.sort(key=lambda u: u["cid"])
    mine = shard_of(units, a.shard)
    print(f"{len(units)} units total, {len(mine)} in shard {a.shard}", flush=True)
    done = set()
    resf = out / "candidates.jsonl"
    if resf.exists():
        done = {json.loads(l)["cid"] for l in open(resf)}
    with open(resf, "a") as g:
        for u in mine:
            if u["cid"] in done:
                continue
            cdir = out / "cands" / u["cid"]
            try:
                res = evaluate(u, cdir, nonsf)
            except Exception as e:  # keep the shard going
                res = {"cid": u["cid"], "source": u["source"], "valid": False, "reason": f"exc: {e!r}"}
            unit_meta = {k: v for k, v in u.items() if k not in ("broken_code", "fixed_code", "tests")}
            res["unit"] = unit_meta
            if not res["valid"] and cdir.exists():
                shutil.rmtree(cdir)
            elif cdir.exists():
                (cdir / "meta.json").write_text(json.dumps(res, indent=1))
            g.write(json.dumps(res) + "\n")
            g.flush()
            print(f"  {u['cid']}: valid={res['valid']} {res.get('reason', '')} "
                  f"err={res.get('starter', {}).get('n_errors')}", flush=True)


# --------------------------------------------------------------------------
# local: select
# --------------------------------------------------------------------------
REQ_JH = [
    "This project stopped compiling after we upgraded jac. Can you get `jac check` passing again "
    "for the whole workspace? Don't remove functionality to make it pass — the walkers, nodes "
    "and functions should all still be there and do what they did.",
    "I pulled this code out of our hackathon repo ({title}) and it no longer type-checks with the "
    "current Jac toolchain. Please fix it so `jac check` is clean. Keep the behaviour and the "
    "public names intact; other modules import from these files.",
    "`jac check` is throwing a pile of errors on this module and the code it imports. It was written "
    "against an older Jac dialect. Migrate it to current Jac syntax so it checks clean, without "
    "stubbing anything out.",
    "Our CI runs `jac check` and it's red on this part of the {title} codebase. Could you fix the "
    "errors? Please make real fixes (syntax/type/import migrations), not deletions — every "
    "archetype and ability should survive.",
    "Can you bring this Jac code up to date? It fails `jac check` right now. I need it green, with "
    "the existing logic preserved as-is wherever possible.",
    "Hey — picked up this {title} code again and the compiler hates it now. Get `jac check` "
    "to zero errors. Don't delete or hollow out functions/walkers to get there; port them.",
]
REQ_OSP = [
    "I wrote this Jac program (main.jac) but it doesn't compile — `jac check` fails. Please fix it "
    "so it checks clean and still does what it's supposed to. Here's what it's for:\n\n> {prompt}",
    "`main.jac` fails `jac check`. Fix the errors without changing what the program does or "
    "removing any of its nodes, edges, walkers or functions. Context from the original request:\n\n> {prompt}",
    "Can you debug main.jac? The compiler rejects it. I need it passing `jac check`, and the "
    "graph logic has to keep working. Background:\n\n> {prompt}",
]


def level_of(st: dict) -> int:
    n, k, f = st["n_errors"], len(st["codes"]), len(st["broken_files"])
    score = n + 2 * k + 2 * (f - 1)
    for lvl, cap in ((1, 4), (2, 10), (3, 22), (4, 40)):
        if score <= cap:
            return lvl
    return 5


def eval_lines() -> set[str]:
    """Normalized non-trivial lines appearing anywhere in evals/ (overlap guard)."""
    lines: set[str] = set()

    def walk(v):
        if isinstance(v, str):
            if len(v) > 80:
                for ln in v.splitlines():
                    ln = re.sub(r"\s+", " ", ln).strip()
                    if len(ln) > 30:
                        lines.add(ln)
        elif isinstance(v, dict):
            for x in v.values():
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)

    for p in (REPO / "evals").rglob("*"):
        if p.suffix in (".jsonl",):
            for l in open(p, errors="replace"):
                try:
                    walk(json.loads(l))
                except Exception:
                    pass
        elif p.suffix in (".json",):
            try:
                walk(json.loads(p.read_text(errors="replace")))
            except Exception:
                pass
        elif p.suffix in (".jac", ".py", ".md"):
            walk(p.read_text(errors="replace"))
    return lines


def overlap(ref: Path, ev: set[str]) -> float:
    tot = hit = 0
    for p in G.jac_files(ref):
        for ln in p.read_text(errors="replace").splitlines():
            ln = re.sub(r"\s+", " ", ln).strip()
            if len(ln) > 30:
                tot += 1
                hit += ln in ev
    return hit / max(1, tot)


def cmd_select(a) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cands = []
    for run in a.runs:
        for f in Path(run).rglob("candidates.jsonl"):
            for l in open(f):
                r = json.loads(l)
                if r["valid"]:
                    r["_dir"] = str(f.parent / "cands" / r["cid"])
                    cands.append(r)
    print(f"{len(cands)} valid candidates")
    existing = {}
    if MANIFEST.exists():
        existing = {json.loads(l)["id"]: json.loads(l) for l in open(MANIFEST)}
    meta = repo_meta()
    ev = eval_lines()

    # dedupe: identical (repo, starter error signature) = near-identical task
    def sig(repo, st):
        return sid(repo or "", json.dumps(st["codes"], sort_keys=True), str(st["n_errors"]))

    seen_sig, per_repo = set(), Counter()
    for tid in existing:
        tj = OUT / tid / "task.json"
        if tj.exists():
            t = json.loads(tj.read_text())
            repo = t["provenance"].get("repo", "")
            seen_sig.add(sig(repo, t["starter_errors"]))
            per_repo[repo] += 1
    n_osp = round(a.target * a.osp_share)
    n_jh = a.target - n_osp
    have = Counter(("osp" if r.get("source", "").startswith("osp") else
                    "jh")
                   for r in existing.values() if r.get("validated"))

    def pref(c):  # medium first, then error-code variety
        n = c["starter"]["n_errors"]
        return (not 2 <= n <= 40, -len(c["starter"]["codes"]), n, c["cid"])

    def masked(c):  # retired .cl/.sv marker hides every other diagnostic in the file
        return all(e.startswith("E-file") and "marker was retired" in e for e in c["starter"]["sample"])

    def internal_crash(c):
        return any("list index out of range" in e or "Traceback" in e for e in c["starter"]["sample"])

    for c in cands:
        c["_level"] = max(level_of(c["starter"]), 3 if masked(c) else 1)
    seeds_used = {(json.loads((OUT / t / "task.json").read_text())["provenance"].get("repo"),
                   json.loads((OUT / t / "task.json").read_text())["provenance"].get("seed_module"))
                  for t in existing if (OUT / t / "task.json").exists()}
    n_masked = 0
    picked: list[dict] = []
    for bucket, pool, cap in (("jh", [c for c in cands if c["source"] == "jachacks"], n_jh),):
        pool = [c for c in pool if not internal_crash(c) and c["cid"] not in existing]
        got = have[bucket]
        lvl = 0
        stall = 0
        while got < cap and stall < 5:
            lvl = lvl % 5 + 1
            opts = [c for c in pool if c["_level"] == lvl
                    and per_repo[c["unit"]["repo"]] < TASKS_PER_REPO
                    and sig(c["unit"]["repo"], c["starter"]) not in seen_sig
                    and (c["unit"]["repo"], c["unit"]["seed"]) not in seeds_used
                    and not (masked(c) and n_masked >= 4)]
            if not opts:
                stall += 1
                continue
            stall = 0
            c = min(opts, key=lambda c: (per_repo[c["unit"]["repo"]], pref(c)))
            pool.remove(c)
            picked.append(c)
            per_repo[c["unit"]["repo"]] += 1
            seen_sig.add(sig(c["unit"]["repo"], c["starter"]))
            seeds_used.add((c["unit"]["repo"], c["unit"]["seed"]))
            n_masked += masked(c)
            got += 1
    code_seen = Counter()
    got = have["osp"]
    lvl_seen = Counter()
    osp_pool = [c for c in cands if c["source"] == "osp" and c["cid"] not in existing]
    while got < n_osp and osp_pool:
        # least-represented level first, then fresh error codes
        c = min(osp_pool, key=lambda c: (code_seen[c["unit"]["error_code"]] >= 2,
                                         lvl_seen[c["_level"]], code_seen[c["unit"]["error_code"]], c["cid"]))
        osp_pool.remove(c)
        if code_seen[c["unit"]["error_code"]] >= 2:
            break
        code_seen[c["unit"]["error_code"]] += 1
        lvl_seen[c["_level"]] += 1
        picked.append(c)
        got += 1
    random_req = lambda c, pool: pool[int(sid(c["cid"]), 16) % len(pool)]  # noqa: E731

    rows = dict(existing)
    for c in picked:
        tid = c["cid"]
        if tid in existing:
            continue
        src = Path(c["_dir"])
        tdir = OUT / tid
        ov = overlap(src / "reference", ev)
        if ov > 0.2:
            rows[tid] = {"id": tid, "validated": False, "reason": f"eval overlap {ov:.2f}"}
            continue
        blob = "".join(p.read_text(errors="replace") for p in G.jac_files(src))
        if SECRET_RE.search(blob):
            rows[tid] = {"id": tid, "validated": False, "reason": "secret-like string; skipped"}
            continue
        if tdir.exists():
            shutil.rmtree(tdir)
        (tdir / "grader").mkdir(parents=True)
        ign = shutil.ignore_patterns(".jac", "__pycache__", "__jac_gen__", "jac.toml")
        shutil.copytree(src / "starter", tdir / "starter", ignore=ign)
        shutil.copytree(src / "reference", tdir / "grader" / "reference", ignore=ign)
        # 0.36.1 native codespace gives silently wrong answers: ship the server pin
        for d in (tdir / "starter", tdir / "grader" / "reference"):
            if not any(d.glob("**/jac.toml")):
                (d / "jac.toml").write_text(G.JAC_TOML)
        shutil.copy(src / "symbols.json", tdir / "grader" / "symbols.json")
        u = c["unit"]
        st = c["starter"]
        level = c["_level"]
        gates = ["check", "fidelity"]
        if c["source"] == "osp":
            gates = ["check", "test", "fidelity"]
            shutil.copy(src / "tests.jac", tdir / "grader" / "tests.jac")
            prompt = u["prompt"].strip().split("\n\n")[0][:700]
            req = random_req(c, REQ_OSP).format(prompt=prompt.replace("\n", "\n> "))
            prov = {"dataset": "data/osp_repair/code_fix.jsonl", "row_id": u["row_id"],
                    "target_id": u["target_id"], "broken_generator": u["broken_generator"],
                    "fixed_generator": u["fixed_generator"],
                    "original_error": u["broken_error"][:300]}
            lic = "synthetic (generated in-house; repo license)"
            source = "osp_repair_code_fix"
        else:
            rm = meta.get(u["repo"], {})
            pool = REQ_JH
            req = random_req(c, pool).format(title=rm.get("title", "our"), jv=JAC_VERSION)
            prov = {"repo": u["repo"], "repo_url": rm.get("repo_url"), "edition": rm.get("edition"),
                    "seed_module": u["seed"], "reverted_files": u["reverted"],
                    "original": "data/jachacks_{spring,2026}_jac_files_filtered.jsonl",
                    "reference": "data/jachacks_nonsf (0.36.1 repair, green at 0.36.1)",
                    "starter": "hackathon original for reverted files, 0.36.1 repair elsewhere"}
            lic = "upstream repo license (public hackathon submission; see repo_url)"
            source = f"jachacks_{rm.get('edition', 'nonsf')}"
        task = {"id": tid, "kind": "fix", "level": level, "source": source, "gates": gates,
                "target_paths": c["target_paths"], "broken_paths": c["broken_paths"],
                "jac_version": JAC_VERSION, "license": lic, "provenance": prov,
                "starter_errors": {"n_errors": st["n_errors"], "codes": st["codes"],
                                   "n_files": len(st["broken_files"])},
                "gate_thresholds": {"symbols": G.T_SYM, "mass": G.T_MASS, "body": G.T_BODY,
                                    "body_file": G.T_BODY_FILE}}
        (tdir / "task.json").write_text(json.dumps(task, indent=1) + "\n")
        (tdir / "request.md").write_text(req.strip() + "\n")
        notes = [f"# {tid}", "", f"Source: {source}. Level {level}.", "",
                 f"Starter at jac {JAC_VERSION}: {st['n_errors']} errors in "
                 f"{len(st['broken_files'])} file(s); codes {st['codes']}.", "",
                 "Sample diagnostics:", *[f"- `{s}`" for s in st["sample"]], "",
                 f"Reference = grader/reference (green at jac {JAC_VERSION}). Grade with:",
                 f"`python scripts/agent_tasks/fix_gate.py data/agent_tasks/fix/{tid} <workspace>`", "",
                 "Calibration at build time (CI):"]
        for k, v in c["calibration"].items():
            notes.append(f"- {k}: pass={v['pass']} check={v['check']} sym={v['sym']} "
                         f"mass={v['mass']} body={v.get('body')} min_file_body={v['min_file']}"
                         + (f" test={v['test']}" if "test" in v else ""))
        if c["source"] == "osp":
            notes += ["", "grader/tests.jac is the verified annex test suite rewritten as a separate "
                      "module (`import from main {...}`); run `jac test tests.jac` with it copied "
                      "next to the candidate main.jac."]
        (tdir / "grader" / "notes.md").write_text("\n".join(notes) + "\n")
        rows[tid] = {"id": tid, "level": level, "source": source, "gates": gates,
                     "validated": True, "reason": "ci-candidates: starter fails, reference passes, "
                     "gate calibrated"}
    with open(MANIFEST, "w") as g:
        for r in sorted(rows.values(), key=lambda r: r["id"]):
            g.write(json.dumps(r) + "\n")
    n_ok = sum(1 for r in rows.values() if r.get("validated"))
    print(f"manifest: {len(rows)} rows, {n_ok} validated")


# --------------------------------------------------------------------------
# CI: validate the final pool in place
# --------------------------------------------------------------------------
def cmd_validate(a) -> None:
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    tasks = sorted(d for d in OUT.iterdir() if (d / "task.json").exists())
    with open(out / "validate.jsonl", "w") as g:
        for td in shard_of(tasks, a.shard):
            task = json.loads((td / "task.json").read_text())
            r = {"id": task["id"]}
            with tempfile.TemporaryDirectory() as tmp:
                st = Path(tmp) / "st"
                shutil.copytree(td / "starter", st)
                s = G.run_check(st)
                r["starter_fails"] = not s["ok"]
                r["starter_errors"] = s["n_errors"]
                cal = {"reference": G.grade(td, td / "grader" / "reference")}
                sb = Path(tmp) / "stub"
                G.make_stub(td / "grader" / "reference", sb)
                cal["stub"] = G.grade(td, sb)
                dl = Path(tmp) / "del"
                G.make_delete_targets(td / "starter", dl, task["broken_paths"])
                cal["delete_targets"] = G.grade(td, dl)
                cal["starter_profile"] = G.grade(td, td / "starter", run_check_too=False)
            r["calibration"] = {k: {"pass": v["pass"], "check": v["check"]["ok"],
                                    "sym": v["symbols"]["ratio"], "mass": v["mass"]["ratio"],
                              "body": v["mass"]["body_ratio"],
                                    "min_file": v["mass"]["min_file"], "reasons": v["reasons"]}
                                for k, v in cal.items()}
            r["validated"] = (r["starter_fails"] and cal["reference"]["pass"]
                              and not cal["stub"]["pass"] and not cal["delete_targets"]["pass"])
            g.write(json.dumps(r) + "\n")
            g.flush()
            print(json.dumps({"id": r["id"], "validated": r["validated"]}), flush=True)


def cmd_merge_validate(a) -> None:
    res = {}
    for run in a.runs:
        for f in Path(run).rglob("validate.jsonl"):
            for l in open(f):
                r = json.loads(l)
                res[r["id"]] = r
    rows = [json.loads(l) for l in open(MANIFEST)]
    with open(MANIFEST, "w") as g:
        for row in rows:
            v = res.get(row["id"])
            if v:
                row["validated"] = v["validated"]
                row["reason"] = ("ci-validate: starter fails ({} errors), reference passes check+gate, "
                                 "stub+delete rejected".format(v["starter_errors"]) if v["validated"]
                                 else "ci-validate failed: " + json.dumps(v["calibration"])[:300])
            g.write(json.dumps(row) + "\n")
    with open(OUT / "calibration.jsonl", "w") as g:
        for k in sorted(res):
            g.write(json.dumps({"id": k, **res[k]["calibration"]}) + "\n")
    print(f"merged {len(res)} validate rows; validated={sum(r['validated'] for r in res.values())}")


def cmd_stage_src(a) -> None:
    """Pack data/jachacks_nonsf (.jac only, secrets redacted) for CI."""
    import tarfile
    dst = OUT / "_src" / "nonsf.tar.gz"
    dst.parent.mkdir(parents=True, exist_ok=True)
    src = DATA / "jachacks_nonsf"
    n = red = 0
    with tarfile.open(dst, "w:gz") as tf:
        for p in sorted(src.rglob("*.jac")):
            if not p.is_file() or ".jac" in p.relative_to(src).parts[:-1]:
                continue
            txt = p.read_text(errors="replace")
            txt2 = SECRET_RE.sub("REDACTED", txt)
            red += txt2 != txt
            import io
            b = txt2.encode()
            ti = tarfile.TarInfo(str(Path("jachacks_nonsf") / p.relative_to(src)))
            ti.size = len(b)
            tf.addfile(ti, io.BytesIO(b))
            n += 1
    print(f"staged {n} files ({red} redacted) -> {dst} ({dst.stat().st_size // 1024} KiB)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["candidates", "select", "validate", "merge-validate", "units", "stage-src"])
    ap.add_argument("--shard", default="0/1")
    ap.add_argument("--out", default="ci_out")
    ap.add_argument("--nonsf", default=str(DATA / "jachacks_nonsf"))
    ap.add_argument("--runs", nargs="*", default=[])
    ap.add_argument("--target", type=int, default=40)
    ap.add_argument("--osp-share", type=float, default=0.3)
    a = ap.parse_args()
    if a.stage == "units":
        ju, ou = jachacks_units(Path(a.nonsf)), osp_units()
        print(f"jachacks units: {len(ju)} over {len({u['repo'] for u in ju})} repos; osp units: {len(ou)}")
        print(Counter(u['error_code'] for u in ou).most_common())
        return 0
    {"candidates": cmd_candidates, "select": cmd_select, "validate": cmd_validate,
     "merge-validate": cmd_merge_validate, "stage-src": cmd_stage_src}[a.stage](a)
    return 0


if __name__ == "__main__":
    sys.exit(main())
