#!/usr/bin/env python3
"""Codemod dialect-drift failures in data/osp_merged_corpus.jsonl and re-gate.

Deterministic, compiler-in-the-loop repair of gate-failed records.jac grew
new keywords / removed syntax between generation and revalidation; the failure
clusters (from the 2026-09-19 rebuild) are purely mechanical:

  E0013  identifier now collides with a keyword  -> backtick-escape the name
         (attribute access `.x` -> `["x"]` subscript; name-preserving)
  E0014  stale backtick on a non-keyword         -> strip the backtick
  E0048  removed parenthesized filter `(?F)`     -> bracket filter `[?F]`

Strategy: per record, run `jac check`, read diagnostics (error code +
file:line:col), apply surgical edits, repeat (max rounds). Nothing is guessed
from text patterns alone -- every edit is driven by a compiler diagnostic, so
archetype syntax (`with entry {`) is never touched. Records whose errors are
not one of the three classes bail out untouched (evidence preserved).

Rows with no stored jac_check evidence (aux tiers packed with gates skipped)
are put through a fresh-check sweep first: green rows get their jac_check
evidence backfilled in place, failing rows enter repair as compile-only jobs.
Compile-only success means a clean `jac check` only -- such rows keep their
tier (no guard can run without tests, so they are never promoted to
test_verified) and gain fresh gate evidence plus a dialect_repairs marker.
A compile-only repair whose candidate still trips the elimination token scan
is retained (it compiles) but flagged via gates.dialect_codemod.blocked and
dialect_repairs.elimination_dirty; gate-bearing rows in that situation roll
back untouched and never promote.

After repair, gates are re-run (jac check + guard jac test, elimination scan
refreshed). Newly-green test-bearing records are promoted in the corpus:
  legacy -> legacy_test_verified, v21 -> v21_gold.
v21 on-disk record files (candidate + guard) are updated too, so the pipeline
dirs stay canonical. Timeouts, missing-test guards ("No tests ran"), and
semantic assertion failures are out of scope -- they stay held.

Usage: python3 scripts/gen/codemod_jac_dialect.py [--ids id1,id2] [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
CORPUS = REPO / "data" / "osp_merged_corpus.jsonl"
SUMMARY = REPO / "data" / "osp_merged_corpus_summary.json"
LIFT_BASE = REPO / "data" / "osp_lifts"
XDG_CACHE = Path("/tmp/jac_xdg_codemod_cache")

MAX_ROUNDS = 6

DIAG_RE = re.compile(
    r"error\[(E0013|E0014|E0048)\]:.*?\n\s*--> (\S+):(\d+):(\d+)", re.S)
E0013_NAME = re.compile(r"error\[E0013\]: '(\w+)' is a keyword")
CAND_BANNED = ["deque", "heapq", "queue.Queue", "visited = set()", "stack =",
               "queue ="]


RETRYABLE = ("no writable cache directory", "Setting up Jac for first use")


def run_jac(cmd: list[str], cwd: Path, timeout: int = 120) -> tuple[int, str]:
    env = dict(os.environ)
    XDG_CACHE.mkdir(exist_ok=True)
    env["XDG_CACHE_HOME"] = str(XDG_CACHE)
    out = ""
    for _ in range(2):
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd,
                               timeout=timeout, env=env)
            out = (p.stdout or "") + (p.stderr or "")
            if p.returncode == 0 or not any(s in out for s in RETRYABLE):
                return p.returncode, out
        except subprocess.TimeoutExpired:
            return 124, "timeout"
    return p.returncode, out


def warm_cache() -> None:
    """Serialize the one-time compiler cache build before the pool races on it."""
    XDG_CACHE.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="jac_warm_") as td:
        (Path(td) / "warm.jac").write_text("obj Warm { has x: int = 0; }\n")
        run_jac([JAC, "check", "warm.jac"], Path(td), timeout=300)


def diagnostics(out: str, fname: str) -> list[dict]:
    """[(code, line, col, name)] for the given file, deduped, stable order."""
    seen, outv = set(), []
    for m in DIAG_RE.finditer(out):
        code, path, ln, col = m.group(1), m.group(2), int(m.group(3)), int(m.group(4))
        if Path(path).name != fname:
            continue
        nm = E0013_NAME.search(m.group(0))
        key = (code, ln, col)
        if key not in seen:
            seen.add(key)
            outv.append({"code": code, "line": ln, "col": col,
                         "name": nm.group(1) if nm else None})
    return outv


def apply_edits(text: str, diags: list[dict]) -> tuple[str, list[str]]:
    """Apply one round of edits; positions applied last-to-first per line."""
    lines = text.split("\n")
    edits = []
    # bucket by line, process within a line right-to-left
    by_line: dict[int, list[dict]] = {}
    for d in diags:
        by_line.setdefault(d["line"], []).append(d)
    for ln, ds in sorted(by_line.items(), reverse=True):
        if ln - 1 >= len(lines):
            continue
        s = lines[ln - 1]
        for d in sorted(ds, key=lambda d: -d["col"]):
            col = d["col"] - 1
            if d["code"] == "E0013":
                nm = d["name"] or _ident_at(s, col)
                if nm is None:
                    continue
                if col > 0 and s[col - 1] == ".":
                    end = col + len(nm)
                    s = s[:col - 1] + f'["{nm}"]' + s[end:]
                    edits.append(f"attr->{nm}@{ln}:{col}")
                elif s[col - 1:col] == "`":
                    continue  # already escaped
                else:
                    s = s[:col] + "`" + s[col:]
                    edits.append(f"tick->{nm}@{ln}:{col}")
            elif d["code"] == "E0014":
                if s[col:col + 1] == "`":
                    s = s[:col] + s[col + 1:]
                    edits.append(f"untick@{ln}:{col}")
            elif d["code"] == "E0048":
                new, ok = _paren_filter(s, col)
                if ok:
                    s = new
                    edits.append(f"filter@{ln}:{col}")
        lines[ln - 1] = s
    return "\n".join(lines), edits


def _ident_at(s: str, col: int) -> str | None:
    m = re.match(r"\w+", s[col:])
    return m.group(0) if m else None


def _paren_filter(s: str, col: int) -> tuple[str, bool]:
    """`(?...)` at col -> `[?...]` with balanced-paren scan (string-aware)."""
    if s[col:col + 2] != "(?":
        return s, False
    depth, i, n = 0, col, len(s)
    while i < n:
        c = s[i]
        if c in "\"'":
            q = c
            i += 1
            while i < n and s[i] != q:
                i += 2 if s[i] == "\\" else 1
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return s[:col] + "[?" + s[col + 2:i] + "]" + s[i + 1:], True
        i += 1
    return s, False


def repair_text(text: str, fname: str, work: Path) -> tuple[str, list[str], str]:
    """Compiler-in-the-loop repair of one jac file. Returns (text, edits, bail)."""
    path = work / fname
    all_edits: list[str] = []
    bail = ""
    for _ in range(MAX_ROUNDS):
        path.write_text(text)
        rc, out = run_jac([JAC, "check", fname], work)
        if rc == 0:
            return text, all_edits, ""
        diags = diagnostics(out, fname)
        if not diags:
            first = next((l.strip() for l in out.splitlines()
                          if "error" in l.lower()), "")
            return text, all_edits, first[:200]  # non-codemod-able: bail
        text, edits = apply_edits(text, diags)
        if not edits:
            return text, all_edits, "no-edit-applied"
        all_edits.extend(edits)
    return text, all_edits, "max-rounds"


def repair_record(job: dict) -> dict:
    res: dict = {"id": job["id"], "edits": [], "check": "fail", "guard": None,
                 "repaired": False, "cand_out": None, "tail_out": None,
                 "compile_only": bool(job.get("compile_only"))}
    with tempfile.TemporaryDirectory(prefix="codemod_") as td:
        work = Path(td)
        if job["ns"] == "v21":
            res["candidate_file"] = job["candidate_file"]
            res["guard_file"] = job["guard_file"]
            cand = Path(job["candidate_file"]).read_text()
            guard = Path(job["guard_file"]).read_text()
            tail = guard[len(job["cand_prefix"]):]  # separator + hidden tests
        else:
            cand, tail = job["candidate"], (job["jac_tests"] or "")
        cand, edits, bail = repair_text(cand, "main.jac", work)
        res["cand_in"] = job.get("candidate") if job["ns"] == "legacy" else None
        res["edits"].extend(edits)
        res["check"] = "pass" if _check_ok(cand, work) else "fail"
        res["check_bail"] = bail if res["check"] != "pass" else ""
        if res["check"] != "pass":
            return res
        res["cand_out"] = cand
        if res["compile_only"]:
            # No tests -> no guard can run; a clean check is the whole
            # contract. Row keeps its tier and is never promoted.
            res["repaired"] = True
            return res
        if tail.strip():
            tail, t_edits, bail = repair_text(tail, "main.test.jac", work)
            res["edits"].extend(t_edits)
            res["tail_bail"] = bail
        res["tail_out"] = tail
        res["guard"] = _guard_gate(cand, tail, work, job["ns"])
        res["repaired"] = res["guard"] == "pass"
    return res


def _check_ok(cand: str, work: Path) -> bool:
    (work / "main.jac").write_text(cand)
    rc, _ = run_jac([JAC, "check", "main.jac"], work)
    return rc == 0


def _guard_gate(cand: str, tail: str, work: Path, ns: str) -> str:
    if ns == "legacy":
        from jac_source import strip_top_level_with_entry
        try:
            stripped, _ = strip_top_level_with_entry(cand)
        except ValueError:
            return "fail"
        (work / "main.jac").write_text(stripped)
        (work / "main.test.jac").write_text(tail)
        rc, _ = run_jac([JAC, "test", "main.jac"], work, timeout=180)
    else:
        (work / "guard.jac").write_text(cand + tail)
        rc, _ = run_jac([JAC, "test", "guard.jac"], work, timeout=180)
    return "timeout" if rc == 124 else ("pass" if rc == 0 else "fail")


def fresh_check(job: dict) -> dict:
    """Fresh jac check for a row with no stored gate evidence."""
    with tempfile.TemporaryDirectory(prefix="codemod_sweep_") as td:
        work = Path(td)
        (work / "main.jac").write_text(job["candidate"] or "")
        rc, out = run_jac([JAC, "check", "main.jac"], work)
    status = "pass" if rc == 0 else ("timeout" if rc == 124 else "fail")
    return {"id": job["id"], "status": status, "detail": out[-800:]}


def _elimination(cand: str | None) -> dict:
    text = re.sub(r'"""(.*?)"""', "", cand or "", flags=re.S)
    text = re.sub(r"#[^\n]*", "", text)
    hits = [b for b in CAND_BANNED if b in text]
    return {"scan": "token_v1 (text scan; §8.2 AST detector not implemented)",
            "candidate_hits": hits, "clean": not hits}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ids", default="", help="comma-separated id filter (smoke)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--workers", type=int,
                    default=min(12, __import__("os").cpu_count() or 8))
    args = ap.parse_args()
    sys.path.insert(0, str(Path(__file__).parent))
    ids = set(filter(None, args.ids.split(",")))

    now = datetime.now().isoformat()
    recs = [json.loads(l) for l in CORPUS.open() if l.strip()]
    by_id = {r["id"]: r for r in recs}
    jobs, skip, sweep = [], Counter(), []
    for r in recs:
        if ids and r["id"] not in ids:
            continue
        g = r["validation"]["gates"]
        stored = g.get("jac_check") or {}
        gstore = g.get("guard_test") or {}
        chk_bad = stored.get("status") == "fail"
        grd_bad = gstore.get("status") == "fail"
        no_tests = not r.get("jac_tests")
        if not chk_bad and not grd_bad:
            if stored.get("status") == "pass" or \
                    r["corpus_ns"] != "legacy" or not no_tests:
                skip["green"] += 1
            else:
                sweep.append(r["id"])  # evidence-less: fresh check decides
            continue
        if stored.get("rc") == 124 or "timeout" in (stored.get("detail") or "") \
                or gstore.get("rc") == 124 or "timeout" in gstore.get("detail", ""):
            skip["timeout"] += 1
            continue
        if "No tests ran" in gstore.get("detail", ""):
            skip["no_tests"] += 1
            continue
        if r["corpus_ns"] == "v21":
            m = _manifest(r["id"])
            if not m:
                skip["no_manifest"] += 1
                continue
            gp, cp = LIFT_BASE / m["guard_file"], LIFT_BASE / m["candidate_file"]
            if not gp.exists() or not cp.exists():
                skip["missing_files"] += 1
                continue
            gt = gp.read_text()
            cand_prefix = cp.read_text()
            if not gt.startswith(cand_prefix):
                skip["guard_integrity"] += 1
                continue
            jobs.append({"id": r["id"], "ns": "v21",
                         "candidate_file": str(cp), "guard_file": str(gp),
                         "cand_prefix": cand_prefix})
        else:
            if stored.get("status") not in ("fail", "pass") or \
                    r["candidate_osp_jac"] is None:
                skip["no_candidate"] += 1
                continue
            jobs.append({"id": r["id"], "ns": "legacy",
                         "compile_only": no_tests,
                         "candidate": r["candidate_osp_jac"],
                         "jac_tests": r["jac_tests"]})

    # ---- fresh-check sweep over evidence-less aux rows
    if sweep:
        print(f"fresh sweep: {len(sweep)} rows with no stored gate evidence",
              flush=True)
        warm_cache()
        done = 0
        with ProcessPoolExecutor(max_workers=args.workers) as ex:
            futs = [ex.submit(fresh_check, {"id": i,
                                            "candidate": by_id[i]["candidate_osp_jac"]})
                    for i in sweep]
            for fut in as_completed(futs):
                res = fut.result()
                done += 1
                if done % 250 == 0 or done == len(futs):
                    print(f"  swept {done}/{len(futs)}", flush=True)
                r = by_id[res["id"]]
                g = r["validation"]["gates"]
                if res["status"] == "pass":
                    g["jac_check"] = {"status": "pass", "rc": 0, "detail":
                                      "fresh sweep (no gate evidence at pack time)",
                                      "attempts": 1}
                    skip["fresh_green"] += 1
                elif res["status"] == "timeout":
                    g["jac_check"] = {"status": "fail", "rc": 124,
                                      "detail": "timeout", "attempts": 1}
                    skip["timeout"] += 1
                else:
                    jobs.append({"id": res["id"], "ns": "legacy",
                                 "compile_only": not r.get("jac_tests"),
                                 "candidate": r["candidate_osp_jac"],
                                 "jac_tests": r["jac_tests"]})

    print(f"repair candidates: {len(jobs)}  skipped: {dict(skip)}", flush=True)
    if jobs:
        warm_cache()

    results = {}
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(repair_record, j) for j in jobs]
        for i, fut in enumerate(as_completed(futs)):
            r = fut.result()
            results[r["id"]] = r
            if (i + 1) % 25 == 0:
                print(f"  repaired {i+1}/{len(futs)}", flush=True)

    promoted, failed, compile_clean = [], [], []
    for r in recs:
        rep = results.get(r["id"])
        if not rep:
            continue
        g = r["validation"]["gates"]
        if rep["repaired"]:
            elim = _elimination(rep["cand_out"])
            dirty = not elim["clean"]
            if dirty or (r["corpus_ns"] == "legacy" and rep["check"] != "pass"):
                # Candidate violates the elimination contract (or did not end
                # green): gate-bearing rows roll back untouched and never
                # promote; compile-only rows keep the compile-clean candidate
                # in their aux tier, flagged as elimination-dirty.
                if not rep.get("compile_only"):
                    r["validation"]["elimination"] = _elimination(rep.get("cand_in"))
                    if not (g.get("jac_check") or {}).get("status"):
                        g["jac_check"] = {"status": "fail", "rc": 1, "detail":
                                          "repair blocked: elimination regression",
                                          "attempts": 1}
                    g["dialect_codemod"] = {"attempted_at": now, "edits": rep["edits"],
                                            "check": rep["check"], "guard": rep["guard"],
                                            "blocked": "elimination regression"}
                    failed.append(r["id"])
                    continue
                g["dialect_codemod"] = {"attempted_at": now, "edits": rep["edits"],
                                        "check": rep["check"], "guard": None,
                                        "blocked": "elimination regression; "
                                                   "compile-clean candidate retained"}
            r["validation"]["elimination"] = elim
            r["candidate_osp_jac"] = rep["cand_out"]
            g["jac_check"] = {
                "status": "pass", "rc": 0, "detail": "codemod repair", "attempts": 1}
            r["validation"]["dialect_repairs"] = {
                "repaired_at": now, "edits": rep["edits"],
                "codemod": "scripts/gen/codemod_jac_dialect.py"}
            if dirty:
                r["validation"]["dialect_repairs"]["elimination_dirty"] = True
            if rep.get("compile_only"):
                # compile-clean aux row: tier and SFT exclusion unchanged,
                # no guard claim (no tests to run)
                compile_clean.append(r["id"])
                continue
            g["guard_test"] = {
                "status": "pass", "rc": 0, "detail": "codemod repair", "attempts": 1}
            if r["corpus_ns"] == "legacy":
                if rep["tail_out"]:
                    r["jac_tests"] = rep["tail_out"]
                    r["test_hash"] = _th(rep["tail_out"])
                r["tier"] = "legacy_test_verified"
                r["sft_excluded_reason"] = (
                    "tier legacy_test_verified: v2.1 gates green after "
                    "deterministic dialect codemod (evidence recorded); "
                    "excluded from lift-SFT release (legacy task contract)")
            else:
                r["tier"] = "v21_gold"
                r["sft_excluded"] = False
                r["sft_excluded_reason"] = None
                r["jac_tests"] = rep["tail_out"] or None
                r["test_hash"] = _th(rep["tail_out"])
            r["validation"]["current"] = True
            if not args.dry_run and r["corpus_ns"] == "v21":
                Path(rep["candidate_file"]).write_text(rep["cand_out"])
                Path(rep["guard_file"]).write_text(
                    rep["cand_out"] + (rep["tail_out"] or ""))
            promoted.append(r["id"])
        else:
            if not (g.get("jac_check") or {}).get("status"):
                g["jac_check"] = {"status": "fail", "rc": 1,
                                  "detail": (rep.get("check_bail") or "repair bail")[:200],
                                  "attempts": 1}
            g.setdefault("dialect_codemod", {
                "attempted_at": now,
                "edits": rep["edits"], "check": rep["check"], "guard": rep["guard"]})
            failed.append(r["id"])

    if not args.dry_run:
        tmp = CORPUS.with_suffix(".jsonl.pack_tmp")
        with tmp.open("w") as f:
            for r in recs:
                f.write(json.dumps(r) + "\n")
        tmp.replace(CORPUS)
        if SUMMARY.exists():
            s = json.loads(SUMMARY.read_text())
            s["codemod_repair"] = {"at": now, "promoted": len(promoted),
                                   "compile_clean": len(compile_clean),
                                   "fresh_green_backfill": skip.get("fresh_green", 0),
                                   "still_failing": len(failed),
                                   "skipped": dict(skip)}
            SUMMARY.write_text(json.dumps(s, indent=2) + "\n")
    print(json.dumps({"promoted": len(promoted),
                      "compile_clean": len(compile_clean),
                      "compile_clean_ids": compile_clean[:10],
                      "fresh_green_backfill": skip.get("fresh_green", 0),
                      "still_failing": len(failed),
                      "skipped": dict(skip), "promoted_ids": promoted[:10],
                      "failed": [
                          {"id": i, "check": results[i]["check"],
                           "check_bail": results[i].get("check_bail", ""),
                           "tail_bail": results[i].get("tail_bail", ""),
                           "guard": results[i]["guard"],
                           "edits": len(results[i]["edits"])}
                          for i in failed[:20]]}, indent=2))
    return 0


def _th(text: str | None) -> str | None:
    import hashlib
    return hashlib.sha256("".join((text or "").split()).encode()).hexdigest()[:8] \
        if text else None


def _manifest(rid: str) -> dict | None:
    for mf in sorted(LIFT_BASE.glob("*.jsonl")):
        if mf.name.startswith(("_cost_", "mm", "pool_")):
            continue
        for line in mf.read_text().splitlines():
            if line.strip():
                m = json.loads(line)
                if m.get("id") == rid and "candidate_file" in m:
                    return m
    return None


if __name__ == "__main__":
    sys.exit(main())
