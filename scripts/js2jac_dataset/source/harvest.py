#!/usr/bin/env python3
"""Harvest: clone candidate repos, run js2jac project convert, measure yield.

Stage 2 of the sourcing front. Reads candidates.jsonl (from discover.py),
shallow-clones each repo, runs `jac tool js2jac --project`, and records the
per-file conversion outcome. This is where real-world attrition happens; the
primary output is a *yield report* plus per-repo conversion summaries.

We deliberately DO NOT run `npm install` / build: the js2jac pipeline parses
via Babel and type-checks the emitted Jac (JacProgram.build(type_check=True)),
so it needs source on disk, not a working node_modules. A build gate can be
added later as an optional quality tier.

Usage:
  python3 harvest.py --candidates candidates.jsonl --limit 15
  python3 harvest.py --candidates c.jsonl --limit 50 --workdir /tmp/harvest
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from profiles import (
    get_profile, load_profiles, match_deps, path_excluded, read_deps,
)

JAC_REPO = Path("/home/jac/repos/jac_llm_data/jaseci/jac")
HOLECONVERT = Path(__file__).resolve().parent / "holeconvert.mjs"
BUN = shutil.which("bun") or "bun"

# Run the CHECKOUT's own jac via `python -m jaclang` — see pipeline/guard_lib.py
# for the full story. Short version: the ambient `jac` binary (0.36.1 frozen
# install, Aug 31) bootstraps via jaclang.cli.cli_boot, which this checkout
# predates — from cwd=jac_repo the checkout shadows it and every invocation
# dies (sometimes silently, exit 0); from a neutral cwd it runs but has no
# js2jac tool. Source-run is the only path that is both alive and
# tool-complete, and it pins convert+gate to ONE compiler generation.
# Needs the bun runtime: the frozen install bundles it, the source tree does
# not (E7104 'Bundled bun runtime is unavailable' without JAC_BUN).
JAC_PY = sys.executable


def jac_cmd(*args: str) -> list[str]:
    return [JAC_PY, "-m", "jaclang", *args]


def jac_env() -> dict[str, str]:
    return {"JAC_BUN": os.environ.get("JAC_BUN", "/usr/sbin/bun")}

# Where TS/React client source usually lives. First existing dir wins as root.
SRC_HINTS = ["src", "app", "client", "frontend", "packages", "."]


def hole_convert(source_js: str, rel_path: str, timeout: int = 30) -> dict:
    """Standalone declaration-level fail-open conversion with hole emission.

    Project mode marks a file `reject` (floor=None) as soon as its emitted Jac
    fails the project-wide type-check / cross-file resolution (E1032 unknown
    type, dropped upstream export) — discarding a partial floor the converter
    could produce. This runs the SAME convert core standalone with emitHoles on,
    so a file whose declarations convert individually but don't survive the
    project graph still yields a scaffold: the kept declarations plus each
    unconvertible one as a `# JS2JAC-HOLE[code]` comment carrying its original
    JS. The composer then patches holes against a locked scaffold instead of
    freestyling from raw source (the salvage failure mode).

    Returns {ok, jac, keptCount, holeCount} or {ok: False, error} on failure.
    """
    try:
        r = subprocess.run(
            [BUN, str(HOLECONVERT)],
            input=json.dumps({"js": source_js, "path": rel_path}),
            capture_output=True, text=True, timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout"}
    if r.returncode != 0:
        return {"ok": False, "error": r.stderr.strip()[:200] or f"exit {r.returncode}"}
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError as e:
        return {"ok": False, "error": f"bad json: {e}"}


def sh(cmd: list[str], cwd: Path | None = None, timeout: int = 300) -> tuple[int, str, str]:
    # jac-family subprocesses get a 3GB address-space cap (Aug 20 OOM freezes;
    # same fix as step4_full_loop._run). git/bun keep their natural limits.
    is_jac = cmd[:3] == [JAC_PY, "-m", "jaclang"]
    if is_jac:
        as_cap = int(os.environ.get("JAC_RLIMIT_AS_GB", "3")) << 30
        cmd = ["prlimit", f"--as={as_cap}", "--", *cmd]
    try:
        r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout,
                           env={**os.environ, **jac_env()} if is_jac else None)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"


def clone(clone_url: str, branch: str, dest: Path) -> bool:
    code, _, err = sh(
        ["git", "clone", "--depth", "1", "--branch", branch,
         "--single-branch", clone_url, str(dest)],
        timeout=180,
    )
    if code != 0:
        # retry without branch pin (default branch mismatch is common)
        code, _, err = sh(
            ["git", "clone", "--depth", "1", "--single-branch", clone_url, str(dest)],
            timeout=180,
        )
    return code == 0


def head_sha(repo: Path) -> str:
    code, out, _ = sh(["git", "rev-parse", "HEAD"], cwd=repo, timeout=30)
    return out.strip() if code == 0 else ""


def profile_gate(repo: Path, profile: dict) -> tuple[bool, list[str]]:
    """Apply the stack profile's dep gate to a clone's package.json."""
    pj = repo / "package.json"
    if not pj.exists():
        return False, ["no:package.json"]
    return match_deps(read_deps(pj), profile)


def pick_project_root(repo: Path) -> Path:
    """Choose the directory to hand to js2jac. Prefer one containing tsx sources."""
    for hint in SRC_HINTS:
        d = repo / hint if hint != "." else repo
        if d.is_dir() and any(d.rglob("*.tsx")):
            return d
    return repo


def convert(root: Path, out_dir: Path, report: Path, fail_open: bool = False) -> dict:
    """Run the REAL write path (project validation), not dry-run.

    Returns a report dict augmented with `_write_ok` and `_err`. With
    fail_open=False this is the strict fail-closed path: one unsupported file
    aborts the whole project and writes nothing. With fail_open=True (H0)
    unsupported files degrade to per-file skips and whatever converts is emitted.

    The dry-run plan overstates yield; only the write path runs graph
    require-resolution + JacProgram.build(type_check=True).
    """
    # The jac subprocess below runs with cwd=JAC_REPO, so any RELATIVE path
    # resolves against the jac repo, not the caller's CWD. Force absolute so
    # root/out_dir/report stay anchored to the caller regardless of how the
    # pipeline invokes us (e.g. js2jac_chunk.sh passes a relative --work-dir).
    root, out_dir, report = (Path(p).resolve() for p in (root, out_dir, report))
    cmd = jac_cmd("tool", "js2jac", "--project", str(root),
                  "--out-dir", str(out_dir), "--write", "--force")
    if fail_open:
        cmd.append("--fail-open")
    cmd += ["--report", str(report)]
    code, _, err = sh(cmd, cwd=JAC_REPO, timeout=420)
    rep: dict = {}
    if report.exists():
        try:
            rep = json.loads(report.read_text())
        except Exception as e:
            rep = {"_err": f"bad report: {e}"}
    rep["_write_ok"] = code == 0 and out_dir.exists()
    if code != 0:
        # E7409 (CommonJS), E74xx etc. surface on stderr; keep first lines
        errs = [l for l in err.splitlines() if l.strip().startswith("✖")][:4]
        rep["_err"] = " | ".join(errs) or err.strip()[:200] or f"exit {code}"
    return rep


def check_emitted(out_dir: Path, profile: dict) -> tuple[int, int]:
    """jac check every emitted .jac (minus path-excluded); return (pass, fail)."""
    jacs = [j for j in out_dir.rglob("*.jac")
            if not path_excluded(str(j.relative_to(out_dir)), profile)]
    p = f = 0
    for j in jacs:
        code, _, _ = sh(jac_cmd("check", str(j)), cwd=JAC_REPO, timeout=90)
        if code == 0:
            p += 1
        else:
            f += 1
    return p, f


def summarize(rep: dict, profile: dict) -> dict:
    # Drop vendored boilerplate (e.g. shadcn components/ui/*) from the counts:
    # those files are near-dup, low-value, and fail-open already skips them, so
    # they only inflate the denominator. Excluding them yields the honest
    # app-code keep ratio.
    all_files = rep.get("files", [])
    files = [f for f in all_files
             if not path_excluded(f.get("sourcePath", ""), profile)]
    excluded = len(all_files) - len(files)
    counts: dict[str, int] = {}
    for f in files:
        counts[f.get("status", "?")] = counts.get(f.get("status", "?"), 0) + 1
    total_src = sum(1 for f in files if f.get("kind") == "source")
    convertible = counts.get("convertible", 0)
    return {
        "status_counts": counts,
        "source_files": total_src,
        "excluded_files": excluded,
        "convertible": convertible,
        "convertible_ratio": round(convertible / total_src, 3) if total_src else 0.0,
        "diagnostics": len(rep.get("diagnostics", [])),
        "error": rep.get("_error"),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--limit", type=int, default=15)
    ap.add_argument("--workdir", default=None)
    ap.add_argument("--out", default=str(Path(__file__).with_name("harvest_report.jsonl")))
    ap.add_argument("--keep", action="store_true", help="keep clones (debug)")
    ap.add_argument("--profile", default="react",
                    help=f"stack profile (from profiles.json): "
                         f"{', '.join(sorted(load_profiles()))}")
    args = ap.parse_args()

    profile = get_profile(args.profile)
    print(f"profile: {args.profile}", file=sys.stderr)

    cands = [json.loads(l) for l in Path(args.candidates).read_text().splitlines() if l.strip()]
    cands = cands[: args.limit]

    workdir = Path(args.workdir) if args.workdir else Path(tempfile.mkdtemp(prefix="harvest_"))
    workdir.mkdir(parents=True, exist_ok=True)
    outf = open(args.out, "w")

    agg = {"seen": 0, "cloned": 0, "profile_reject": 0, "converted": 0,
           "source_files": 0, "excluded_files": 0,
           "convertible_strict": 0, "convertible_open": 0,
           "projects_written_strict": 0, "projects_written_open": 0,
           "projects_clean_open": 0,
           "kept_open": 0, "skipped_open": 0,
           "checked_pass_strict": 0, "checked_pass_open": 0,
           "checked_fail_open": 0}

    for i, c in enumerate(cands):
        name = c["full_name"]
        agg["seen"] += 1
        rec: dict = {"repo": name, "commit": "", "spdx": c.get("spdx"),
                     "stars": c.get("stars"), "stage": None}
        cdir = workdir / name.replace("/", "__")
        try:
            if not clone(c["clone_url"], c.get("default_branch", "main"), cdir):
                rec["stage"] = "clone_failed"
                outf.write(json.dumps(rec) + "\n"); print(f"[{i}] {name}: clone_failed", file=sys.stderr)
                continue
            agg["cloned"] += 1
            rec["commit"] = head_sha(cdir)
            ok, why = profile_gate(cdir, profile)
            if not ok:
                rec["stage"] = "profile_reject"; rec["reject"] = why
                agg["profile_reject"] += 1
                outf.write(json.dumps(rec) + "\n")
                print(f"[{i}] {name}: profile_reject {why}", file=sys.stderr)
                continue
            root = pick_project_root(cdir)
            rec["root"] = str(root.relative_to(cdir))
            # Run BOTH strict and fail-open on the same clone for a direct delta.
            for mode, fail_open in (("strict", False), ("open", True)):
                m_out = workdir / (cdir.name + f"__out_{mode}")
                m_rep = workdir / (cdir.name + f"__report_{mode}.json")
                rep = convert(root, m_out, m_rep, fail_open=fail_open)
                summ = summarize(rep, profile)
                write_ok = bool(rep.get("_write_ok"))
                chk_pass, chk_fail = (check_emitted(m_out, profile) if write_ok else (0, 0))
                rec[f"write_ok_{mode}"] = write_ok
                rec[f"write_err_{mode}"] = rep.get("_err")
                rec[f"summary_{mode}"] = summ
                rec[f"check_pass_{mode}"] = chk_pass
                rec[f"check_fail_{mode}"] = chk_fail
                if mode == "strict":
                    agg["converted"] += 1
                    agg["source_files"] += summ["source_files"]
                    agg["excluded_files"] += summ.get("excluded_files", 0)
                    agg["convertible_strict"] += summ["convertible"]
                    if write_ok:
                        agg["projects_written_strict"] += 1
                    agg["checked_pass_strict"] += chk_pass
                else:
                    agg["convertible_open"] += summ["convertible"]
                    # kept = emitted files passing jac check; skipped = the rest
                    agg["kept_open"] += chk_pass
                    agg["skipped_open"] += summ["source_files"] - chk_pass
                    if write_ok:
                        agg["projects_written_open"] += 1
                        if chk_fail == 0 and chk_pass > 0:
                            agg["projects_clean_open"] += 1
                    agg["checked_pass_open"] += chk_pass
                    agg["checked_fail_open"] += chk_fail
            print(f"[{i}] {name}: "
                  f"strict={'OK' if rec.get('write_ok_strict') else 'FAIL'} "
                  f"({rec.get('check_pass_strict', 0)}p) | "
                  f"open={'OK' if rec.get('write_ok_open') else 'FAIL'} "
                  f"({rec.get('check_pass_open', 0)}p/{rec.get('check_fail_open', 0)}f) "
                  f"conv={rec['summary_open']['convertible']}/"
                  f"{rec['summary_open']['source_files']}", file=sys.stderr)
            outf.write(json.dumps(rec) + "\n")
        finally:
            if not args.keep and cdir.exists():
                shutil.rmtree(cdir, ignore_errors=True)

    outf.close()
    print("\n=== YIELD (strict vs fail-open) ===", file=sys.stderr)
    print(json.dumps(agg, indent=1), file=sys.stderr)
    sf = agg["source_files"]
    if sf:
        print(f"file convertible ratio: strict={agg['convertible_strict']/sf:.3f} "
              f"open={agg['convertible_open']/sf:.3f}", file=sys.stderr)
        print(f"fail-open kept/skipped:  {agg['kept_open']} kept / "
              f"{agg['skipped_open']} skipped  (keep ratio "
              f"{agg['kept_open']/sf:.3f})", file=sys.stderr)
    conv = agg["converted"]
    if conv:
        print(f"projects written: strict={agg['projects_written_strict']}/{conv} "
              f"open={agg['projects_written_open']}/{conv} "
              f"(clean: {agg['projects_clean_open']}/{conv})", file=sys.stderr)
    print(f"report -> {args.out}", file=sys.stderr)
    if not args.keep:
        shutil.rmtree(workdir, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
