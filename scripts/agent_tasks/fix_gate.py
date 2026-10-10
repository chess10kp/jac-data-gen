#!/usr/bin/env python3
"""Anti-hollowing gate for `fix` agent tasks.

A `fix` task hands an agent a Jac workspace that fails `jac check`; the agent
must make it green WITHOUT hollowing it out (deleting files, stubbing bodies,
commenting code away). `jac check` alone admits all of those, so a candidate
passes only if ALL hold:

  1. check     `jac check` reports 0 errors over the whole workspace.
  2. symbols   >= T_SYM of the reference's top-level symbols survive, measured
               through the compiler (`jac code map` for obj/node/edge/walker
               archetypes + their abilities, `jac code symbol NAME` for
               top-level defs / enums). Comments and string literals never
               register, so a `# walker Foo {}` cannot satisfy the contract.
  3. mass      code mass (tokens outside comments/strings) of the task's target
               files is >= T_MASS of the reference's, and no single target file
               drops below T_MASS_FILE (stops "stub the one broken file in a big
               workspace" from hiding behind the untouched files).
  4. test      (only when the task has a grader/tests.jac) `jac test` passes with
               the hidden test module dropped next to the candidate.

The reference inventory is precomputed at build time into grader/symbols.json so
grading a candidate costs one `jac check`, one `jac code map` and a handful of
parallel `jac code symbol` calls.

Usage:
  fix_gate.py TASK_DIR CANDIDATE_DIR            # grade a candidate workspace
  fix_gate.py TASK_DIR --reference              # grade the task's own reference
  fix_gate.py TASK_DIR --stub                   # grade a body-stubbed reference
  fix_gate.py TASK_DIR --delete-targets         # grade starter minus broken files
  fix_gate.py --calibrate data/agent_tasks/fix  # all of the above, every task
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

JAC = os.environ.get("JAC_BIN", "jac")
# Calibrated with --calibrate over the pilot pool (see manifest/notes): every
# reference and every starter's symbol/mass profile sits well above these;
# body-stubs and delete-the-broken-files candidates fall well below.
T_SYM = 0.90
T_MASS = 0.70
T_MASS_FILE = 0.50
CHECK_TIMEOUT = int(os.environ.get("FIX_CHECK_TIMEOUT", "600"))
SYM_JOBS = int(os.environ.get("FIX_SYM_JOBS", "6"))

ERR_RE = re.compile(r"^\s*✖\s*Error:\s*(?:error\[(E\d+)\]:\s*)?(.*)$")
LOC_RE = re.compile(r"^\s*-->\s*(\S+?\.jac):(\d+):(\d+)")
FAILED_RE = re.compile(r"^(\S.*?\.jac) - (\d+) errors?,")
SUMMARY_RE = re.compile(r"(\d+) passed(?:, (\d+) failed)?")


# --------------------------------------------------------------------------
# jac check
# --------------------------------------------------------------------------
def run_check(ws: Path, paths: list[str] | None = None, timeout: int = CHECK_TIMEOUT) -> dict:
    """`jac check -n` inside ws. Returns {ok, n_errors, errors:[{file,code,msg}], failed_files}."""
    cmd = [JAC, "check", "-n", *(paths or ["."])]
    try:
        p = subprocess.run(cmd, cwd=ws, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return {"ok": False, "n_errors": -1, "errors": [], "failed_files": [], "crash": "timeout"}
    txt = p.stdout + p.stderr
    errors, cur = [], None
    for ln in txt.splitlines():
        m = ERR_RE.match(ln)
        if m:
            cur = {"code": m.group(1) or "E-file", "msg": m.group(2).strip(), "file": None,
                   "line": None, "col": None}
            if cur["code"] == "E-file":  # file-level error: "Error checking 'X': ..."
                mm = re.match(r"Error checking '([^']+)'", cur["msg"])
                if mm:
                    cur["file"] = mm.group(1)
            errors.append(cur)
            continue
        m = LOC_RE.match(ln)
        if m and cur is not None and cur["file"] is None:
            cur["file"], cur["line"], cur["col"] = m.group(1), int(m.group(2)), int(m.group(3))
    failed = {}
    for ln in txt.splitlines():
        m = FAILED_RE.match(ln.strip())
        if m and int(m.group(2)) > 0:
            failed[m.group(1)] = int(m.group(2))
    summ = None
    for ln in txt.splitlines()[::-1]:
        if ("passed" in ln or "failed" in ln) and "=====" in ln:
            summ = ln
            break
    crash = None
    if summ is None and not errors:
        crash = (txt[-400:] or f"rc={p.returncode}")
    n_err = max(len(errors), sum(failed.values()))
    ok = crash is None and n_err == 0 and not failed and " failed" not in (summ or "")
    return {"ok": ok, "n_errors": n_err, "errors": errors, "failed_files": sorted(failed),
            "summary": (summ or "").strip("= "), "crash": crash}


def strip_entry(src: str) -> str:
    """Drop module-level `with entry {...}` blocks (demo drivers) so importing the
    target from the hidden test module doesn't execute them."""
    toks = list(_TOK.finditer(src))
    out, i, depth, k = [], 0, 0, 0
    while k < len(toks):
        v = toks[k].group(0)
        if v in "{[(":
            depth += 1
        elif v in "}])":
            depth = max(0, depth - 1)
        elif depth == 0 and v == "with" and k + 1 < len(toks) and toks[k + 1].group(0) == "entry":
            j = k + 2
            while j < len(toks) and toks[j].group(0) != "{":
                j += 1
            d, e = 0, j
            while e < len(toks):
                w = toks[e].group(0)
                d += (w == "{") - (w == "}")
                if w == "}" and d == 0:
                    break
                e += 1
            if e < len(toks):
                out.append(src[i:toks[k].start()])
                i = toks[e].end()
                k = e + 1
                continue
        k += 1
    out.append(src[i:])
    return "".join(out)


def run_tests(ws: Path, test_file: str = "tests.jac", timeout: int = 300) -> dict:
    """Run the hidden test module inside ws (a scratch copy: main.jac gets its
    `with entry` driver stripped first)."""
    m = ws / "main.jac"
    if m.exists():
        m.write_text(strip_entry(m.read_text(errors="replace")))
    res = {"ok": False, "detail": "not run"}
    for attempt in range(2):
        if attempt:  # native codespace miscompiles some programs; retry pinned to server
            if (ws / "jac.toml").exists():
                break
            (ws / "jac.toml").write_text('[build]\ndefault_codespace = "server"\n')
        try:
            p = subprocess.run([JAC, "test", test_file], cwd=ws, capture_output=True,
                               text=True, timeout=timeout)
        except subprocess.TimeoutExpired:
            res = {"ok": False, "detail": "timeout"}
            continue
        txt = p.stdout + p.stderr
        m = re.findall(r"(\d+) passed", txt)
        f = re.findall(r"(\d+) failed", txt)
        ok = p.returncode == 0 and bool(m) and not any(int(x) for x in f)
        tail = [l for l in txt.strip().splitlines() if "passed" in l or "failed" in l or "Error" in l]
        res = {"ok": ok, "detail": (tail[-1] if tail else txt[-200:])[:200]}
        if ok:
            break
    return res


# --------------------------------------------------------------------------
# source scanning (comments / strings stripped)
# --------------------------------------------------------------------------
_TOK = re.compile(
    r'(?P<bc>#\*.*?\*#)|(?P<lc>#[^\n]*)'
    r'|(?P<s>[rbfRBF]{0,2}("""|\'\'\')(?:\\.|(?!\4).)*?\4|[rbfRBF]{0,2}"(?:\\.|[^"\\\n])*"|[rbfRBF]{0,2}\'(?:\\.|[^\'\\\n])*\')'
    r'|(?P<id>`?[A-Za-z_]\w*)|(?P<num>\d[\w.]*)|(?P<op>[^\s\w])',
    re.S)


def tokens(src: str) -> list[tuple[str, str]]:
    out = []
    for m in _TOK.finditer(src):
        k = m.lastgroup
        if k in ("bc", "lc"):
            continue
        out.append((k, m.group(0) if k != "s" else '""'))
    return out


def code_mass(src: str) -> int:
    """Tokens outside comments; each string literal counts as one token."""
    return len(tokens(src))


DEF_KINDS = ("def", "can", "enum")
ALL_KINDS = DEF_KINDS + ("node", "edge", "walker", "obj", "class", "glob")


def toplevel_names(src: str, kinds: tuple = DEF_KINDS) -> list[tuple[str, str]]:
    """(kind, name) for module-level decls, found on comment/string-stripped tokens."""
    toks = tokens(src)
    out, depth, i = [], 0, 0
    while i < len(toks):
        k, v = toks[i]
        if v in "{[(":
            depth += 1
        elif v in "}])":
            depth = max(0, depth - 1)
        elif depth == 0 and k == "id" and v in kinds:
            j = i + 1
            if j < len(toks) and toks[j][1] == ":":  # access tag  def:pub
                j += 2
            if j < len(toks) and toks[j][0] == "id":
                kd = "def" if v in ("def", "can") else v
                out.append((kd, toks[j][1].lstrip("`")))
        i += 1
    return out


def jac_files(ws: Path) -> list[Path]:
    return sorted(p for p in ws.rglob("*.jac") if p.is_file()
                  and ".jac" not in p.relative_to(ws).parts[:-1] and "__jac_gen__" not in p.parts)


# --------------------------------------------------------------------------
# compiler-backed symbol inventory
# --------------------------------------------------------------------------
def _jac_json(ws: Path, *args: str, timeout: int = 180) -> dict:
    try:
        p = subprocess.run([JAC, "code", *args], cwd=ws, capture_output=True, text=True,
                           timeout=timeout)
        i = p.stdout.find("{")
        return json.loads(p.stdout[i:]) if i >= 0 else {}
    except Exception:
        return {}


def archetype_symbols(ws: Path) -> list[str]:
    d = _jac_json(ws, "map")
    syms = []
    for a in d.get("archetypes", []):
        f = a.get("file", "")
        if f and not str(Path(f).resolve()).startswith(str(ws.resolve())):
            continue  # stdlib / outside workspace
        syms.append(f"{a['kind']}:{a['name']}")
        for ab in a.get("abilities", []):
            syms.append(f"ability:{a['name']}.{ab.split('(')[0]}")
    return syms


def defined_toplevel(ws: Path, names: list[tuple[str, str]]) -> list[str]:
    """Ask the compiler which of (kind,name) are really defined in ws."""
    ws_res = str(ws.resolve())
    uniq = sorted(set(n for _, n in names))

    def one(name: str) -> list[str]:
        d = _jac_json(ws, "symbol", name)
        hits = []
        for df in d.get("definitions", []):
            if df.get("name") != name:
                continue
            f = df.get("file", "")
            if f and not str(Path(f).resolve()).startswith(ws_res):
                continue
            kind = df.get("kind", "")
            if kind in ("ability", "enum") or kind.startswith("func"):
                hits.append(f"{'enum' if kind == 'enum' else 'def'}:{name}")
        return hits

    with ThreadPoolExecutor(SYM_JOBS) as ex:
        res = list(ex.map(one, uniq))
    return [h for r in res for h in r]


def inventory(ws: Path, target_paths: list[str] | None = None) -> dict:
    """Reference-side inventory: compiler symbols + per-file mass."""
    names = []
    mass = {}
    for p in jac_files(ws):
        src = p.read_text(errors="replace")
        rel = str(p.relative_to(ws))
        mass[rel] = code_mass(src)
        names += toplevel_names(src)
    syms = archetype_symbols(ws) + defined_toplevel(ws, names)
    return {"symbols": sorted(syms), "toplevel_names": sorted(set(n for _, n in names)),
            "mass": mass, "target_paths": target_paths or sorted(mass)}


# --------------------------------------------------------------------------
# grading
# --------------------------------------------------------------------------
def _norm(rel: str) -> str:
    """Path key tolerant to companion-suffix renames (foo.cl.jac -> foo.jac)."""
    return re.sub(r"\.(cl|sv|na)\.jac$", ".jac", rel)


def _multiset_cover(ref: list[str], cand: list[str]) -> tuple[float, list[str]]:
    from collections import Counter
    rc, cc = Counter(ref), Counter(cand)
    kept = sum(min(n, cc[s]) for s, n in rc.items())
    missing = sorted(s for s, n in rc.items() if cc[s] < n)
    if not rc:
        return 1.0, []
    return kept / sum(rc.values()), missing


def grade(task_dir: Path, cand: Path, inv: dict | None = None, run_check_too: bool = True) -> dict:
    task_dir, cand = Path(task_dir), Path(cand)
    task = json.loads((task_dir / "task.json").read_text())
    inv = inv or json.loads((task_dir / "grader" / "symbols.json").read_text())
    res: dict = {"task": task["id"]}

    if run_check_too:
        chk = run_check(cand)
        res["check"] = {"ok": chk["ok"], "n_errors": chk["n_errors"], "crash": chk["crash"]}
    else:
        res["check"] = {"ok": None}

    # symbols
    cand_syms = archetype_symbols(cand)
    names = []
    for p in jac_files(cand):
        names += toplevel_names(p.read_text(errors="replace"))
    wanted = {s.split(":", 1)[1] for s in inv["symbols"] if s.startswith(("def:", "enum:"))}
    names = [(k, n) for k, n in names if n in wanted]
    cand_syms += defined_toplevel(cand, names)
    sym_ratio, missing = _multiset_cover(inv["symbols"], cand_syms)
    res["symbols"] = {"ratio": round(sym_ratio, 3), "ref": len(inv["symbols"]),
                      "missing": missing[:25]}

    # mass over target files
    cmass = {}
    for p in jac_files(cand):
        cmass.setdefault(_norm(str(p.relative_to(cand))), 0)
        cmass[_norm(str(p.relative_to(cand)))] += code_mass(p.read_text(errors="replace"))
    tot_r = tot_c = 0
    per_file = {}
    for rel in inv["target_paths"]:
        r = inv["mass"].get(rel, 0)
        c = cmass.get(_norm(rel), 0)
        tot_r += r
        tot_c += c
        if r:
            per_file[rel] = round(c / r, 3)
    mass_ratio = tot_c / max(1, tot_r)
    min_file = min(per_file.values()) if per_file else 1.0
    res["mass"] = {"ratio": round(mass_ratio, 3), "min_file": min_file,
                   "ref_tokens": tot_r, "cand_tokens": tot_c}

    if (task_dir / "grader" / "tests.jac").exists() and "test" in task.get("gates", []):
        with tempfile.TemporaryDirectory(prefix="fixgate_") as td:
            w = Path(td) / "ws"
            shutil.copytree(cand, w)
            shutil.copy(task_dir / "grader" / "tests.jac", w / "tests.jac")
            res["test"] = run_tests(w)

    reasons = []
    if run_check_too and not res["check"]["ok"]:
        reasons.append(f"check: {res['check']['n_errors']} errors")
    if sym_ratio < T_SYM:
        reasons.append(f"symbols {sym_ratio:.2f} < {T_SYM}")
    if mass_ratio < T_MASS:
        reasons.append(f"mass {mass_ratio:.2f} < {T_MASS}")
    if min_file < T_MASS_FILE:
        reasons.append(f"file mass {min_file:.2f} < {T_MASS_FILE}")
    if "test" in res and not res["test"]["ok"]:
        reasons.append("test: " + res["test"]["detail"])
    res["pass"] = not reasons
    res["reasons"] = reasons
    return res


# --------------------------------------------------------------------------
# synthetic hollow candidates (for calibration)
# --------------------------------------------------------------------------
def stub_bodies(src: str) -> str:
    """Empty every def/can/impl body (keeps signatures). The canonical hollow fix."""
    out, i, n = [], 0, len(src)
    toks = list(_TOK.finditer(src))
    k = 0
    while k < len(toks):
        m = toks[k]
        if m.lastgroup == "id" and m.group(0) in ("def", "can", "impl"):
            # find the opening brace of the body at paren-depth 0, stop at ';'
            j, par = k + 1, 0
            while j < len(toks):
                v = toks[j].group(0)
                if v in "([":
                    par += 1
                elif v in ")]":
                    par -= 1
                elif par == 0 and v in (";", "{"):
                    break
                j += 1
            if j < len(toks) and toks[j].group(0) == "{":
                depth, e = 0, j
                while e < len(toks):
                    v = toks[e].group(0)
                    if v == "{":
                        depth += 1
                    elif v == "}":
                        depth -= 1
                        if depth == 0:
                            break
                    e += 1
                if e < len(toks):
                    out.append(src[i:toks[j].end()])
                    out.append("}")
                    i = toks[e].end()
                    k = e + 1
                    continue
        k += 1
    out.append(src[i:])
    return "".join(out)


def make_stub(ref: Path, dst: Path) -> None:
    shutil.copytree(ref, dst)
    for p in jac_files(dst):
        p.write_text(stub_bodies(p.read_text(errors="replace")))


def make_delete_targets(starter: Path, dst: Path, targets: list[str]) -> None:
    shutil.copytree(starter, dst)
    for rel in targets:
        for p in (dst / rel, dst / re.sub(r"\.jac$", ".cl.jac", rel)):
            if p.exists():
                p.unlink()


def calibrate(root: Path, out: Path | None = None) -> list[dict]:
    rows = []
    for td in sorted(d for d in root.iterdir() if (d / "task.json").exists()):
        task = json.loads((td / "task.json").read_text())
        inv = json.loads((td / "grader" / "symbols.json").read_text())
        row = {"id": td.name}
        row["reference"] = grade(td, td / "grader" / "reference", inv)
        # starter profile: what legit, minimal edits look like (check skipped)
        row["starter_profile"] = grade(td, td / "starter", inv, run_check_too=False)
        with tempfile.TemporaryDirectory(prefix="fixcal_") as tmp:
            s = Path(tmp) / "stub"
            make_stub(td / "grader" / "reference", s)
            row["stub"] = grade(td, s, inv)
            d = Path(tmp) / "del"
            make_delete_targets(td / "starter", d, task.get("broken_paths", task["target_paths"]))
            row["delete_targets"] = grade(td, d, inv)
        rows.append(row)
        print(json.dumps({k: (v if k == "id" else {"pass": v["pass"],
                          "sym": v["symbols"]["ratio"], "mass": v["mass"]["ratio"],
                          "min_file": v["mass"]["min_file"], "check": v["check"]["ok"]})
                          for k, v in row.items()}), flush=True)
    if out:
        out.write_text("\n".join(json.dumps(r) for r in rows) + "\n")
    return rows


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("task", nargs="?")
    ap.add_argument("candidate", nargs="?")
    ap.add_argument("--reference", action="store_true")
    ap.add_argument("--stub", action="store_true")
    ap.add_argument("--delete-targets", action="store_true")
    ap.add_argument("--calibrate", metavar="ROOT")
    ap.add_argument("--out")
    a = ap.parse_args()
    if a.calibrate:
        calibrate(Path(a.calibrate), Path(a.out) if a.out else None)
        return 0
    td = Path(a.task)
    task = json.loads((td / "task.json").read_text())
    with tempfile.TemporaryDirectory(prefix="fixgate_") as tmp:
        if a.reference:
            cand = td / "grader" / "reference"
        elif a.stub:
            cand = Path(tmp) / "c"
            make_stub(td / "grader" / "reference", cand)
        elif a.delete_targets:
            cand = Path(tmp) / "c"
            make_delete_targets(td / "starter", cand, task.get("broken_paths", task["target_paths"]))
        else:
            cand = Path(a.candidate)
        r = grade(td, cand)
    print(json.dumps(r, indent=1))
    return 0 if r["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
