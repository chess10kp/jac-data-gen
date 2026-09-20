#!/usr/bin/env python3
"""Audit ALL generated jac data in the repo against the vendored compiler.

Read-only sweep (no edits, no promotion): every generated candidate is
compiled with vendor/jac/bin/jac (jac 0.36.1, the compiler the corpus was
gated with); candidates carrying tests are additionally guard-tested with
the exact gate semantics of the corpus:

  osp_merged_corpus  legacy rows  -> gate_legacy (entry-strip + annex)
                     v21 rows     -> raw check + (candidate + tests) guard
  composer_dataset   jac field, check only
  js2jac_dataset_idiomatic  jac field, check only
  farm_dataset / farm_handler_dataset  archetype + walkers, check only
  osp_examples/**/*.jac  check only

Output: data/audit_generated_report.json + a stdout table.
Usage: python3 scripts/ops/audit_all_generated.py [--workers 10] [--limit N]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import tempfile
from collections import Counter
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "gen"))
import pack_merged_corpus as PMC  # noqa: E402  (gives JAC + run + gate_legacy)

ERR_CODE = re.compile(r"error\[(E\d+)\]")
NO_GUARD = False

DATASETS = [
    {"name": "osp_merged_corpus", "kind": "merged"},
    {"name": "composer_dataset", "kind": "field",
     "path": "data/composer_dataset.jsonl", "field": "jac"},
    {"name": "js2jac_dataset_idiomatic", "kind": "field",
     "path": "data/js2jac_dataset_idiomatic.jsonl", "field": "jac"},
    {"name": "farm_dataset", "kind": "farm",
     "path": "data/farm_dataset.jsonl"},
    {"name": "farm_handler_dataset", "kind": "farm",
     "path": "data/farm_handler_dataset.jsonl"},
    {"name": "osp_examples", "kind": "files",
     "glob": "data/osp_examples/**/*.jac"},
]


def _full_run(cmd: list[str], work: Path, timeout: int = 180) -> tuple[int, str]:
    """Run one gate command, keeping FULL stdout+stderr (diagnostics can be
    printed after the pytest-style summary, so tail-truncated detail loses
    error codes). Single retry on infra flake, as in pack_merged_corpus.

    The child runs in its own process group and the WHOLE group is killed on
    timeout: jac's runtime leaves orphaned grandchildren (postgres) holding
    the stdout pipe, which would otherwise hang communicate() forever even
    after the direct child is killed.
    """
    for _ in range(2):
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, text=True, cwd=work,
                             start_new_session=True)
        try:
            out_b, err_b = p.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            p.kill()
            p.communicate()
            return 124, "timeout"
        out = (out_b or "") + (err_b or "")
        if p.returncode == 0 or not any(s in out for s in PMC.RETRYABLE):
            return p.returncode, out
    return p.returncode, out


def _cls(rc: int) -> str:
    return "pass" if rc == 0 else ("timeout" if rc == 124 else "fail")


def check_text(tag: str, code: str) -> dict:
    """jac check one candidate text with the vendored compiler."""
    with tempfile.TemporaryDirectory(prefix="audit_chk_") as td:
        work = Path(td)
        (work / "main.jac").write_text(code)
        rc, out = _full_run([PMC.JAC, "check", "main.jac"], work)
    return {"tag": tag, "check": _cls(rc), "codes": ERR_CODE.findall(out)}


def gate_merged_row(rec: dict) -> dict:
    """Fresh gates for one merged-corpus record, honoring its ns semantics.

    Guard semantics: either-side pass. The default (native) codespace has
    miscompilation bugs (segfault on `set()` call args; silent for-loop /
    f-string drops in walker abilities — spec §2), so a failing guard is
    retried with `default_codespace = "server"` pinned. Conversely some
    records' hidden tests pin unspecified traversal order that only matches
    under the native codespace, so unpinned runs first and a pass is final.
    """
    rid = rec["id"]
    cand = rec.get("candidate_osp_jac")
    if not cand:
        return {"tag": rid, "check": "no_candidate", "codes": [],
                "guard": "skipped"}
    tail = "" if NO_GUARD else (rec.get("jac_tests") or "")
    with tempfile.TemporaryDirectory(prefix="audit_v21_") as td:
        work = Path(td)
        (work / "main.jac").write_text(cand)
        rc, out = _full_run([PMC.JAC, "check", "main.jac"], work)
        codes = ERR_CODE.findall(out)
        if not tail:
            return {"tag": rid, "check": _cls(rc), "codes": codes,
                    "guard": "skipped"}
        if rec.get("corpus_ns") == "legacy":
            try:
                stripped, _ = PMC.strip_top_level_with_entry(cand)
            except ValueError:
                return {"tag": rid, "check": _cls(rc), "codes": codes,
                        "guard": "fail"}
            main_txt, test_txt, target = stripped, tail, "main.jac"
        else:
            main_txt, test_txt, target = cand, tail, "guard.jac"

        def run_guard(pinned: bool) -> tuple[int, str]:
            with tempfile.TemporaryDirectory(prefix="audit_guard_") as gd:
                work2 = Path(gd)
                if pinned:
                    (work2 / "jac.toml").write_text(
                        '[build]\ndefault_codespace = "server"\n')
                (work2 / target).write_text(main_txt + test_txt)
                return _full_run([PMC.JAC, "test", target], work2, timeout=200)

        grc, _ = run_guard(pinned=False)
        if grc != 0:
            grc_p, _ = run_guard(pinned=True)
            if grc_p == 0:
                grc = 0
        return {"tag": rid, "check": _cls(rc), "codes": codes,
                "guard": "timeout" if grc == 124
                else ("pass" if grc == 0 else "fail")}


def load_jobs(limit: int | None) -> list[tuple[str, str, dict]]:
    """(dataset, kind, payload) for every generated unit."""
    jobs: list[tuple[str, str, dict]] = []
    for ds in DATASETS:
        kind = ds["kind"]
        if kind == "merged":
            for ln in (REPO / "data" / "osp_merged_corpus.jsonl").read_text().splitlines():
                if ln.strip():
                    jobs.append(("osp_merged_corpus", "merged",
                                 {"rec": json.loads(ln)}))
        elif kind == "field":
            for ln in (REPO / ds["path"]).read_text().splitlines():
                if not ln.strip():
                    continue
                r = json.loads(ln)
                code = r.get(ds["field"])
                if code and code.strip():
                    jobs.append((ds["name"], "check", {"code": code}))
        elif kind == "farm":
            for ln in (REPO / ds["path"]).read_text().splitlines():
                if not ln.strip():
                    continue
                r = json.loads(ln)
                code = (r.get("archetype") or "").strip()
                walkers = (r.get("walkers") or "").strip()
                if code or walkers:
                    jobs.append((ds["name"], "check",
                                 {"code": code + "\n" + walkers}))
        elif kind == "files":
            for p in sorted(REPO.glob(ds["glob"])):
                code = p.read_text()
                if code.strip():
                    jobs.append((ds["name"], "check",
                                 {"code": code, "tag": str(p.relative_to(REPO))}))
    if limit:
        # thin each dataset proportionally for smoke runs
        per_ds: dict[str, list] = {}
        for j in jobs:
            per_ds.setdefault(j[0], []).append(j)
        jobs = [j for v in per_ds.values()
                for j in v[:max(1, limit // len(per_ds))]]
    return jobs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=10)
    ap.add_argument("--limit", type=int, default=None,
                    help="smoke mode: first N//6 rows per dataset")
    ap.add_argument("--datasets", type=str, default=None,
                    help="comma list of dataset names to include")
    ap.add_argument("--no-guard", action="store_true",
                    help="skip guard tests (check only)")
    ap.add_argument("--units-out", default=str(REPO / "data" / "audit_generated_units.jsonl"))
    ap.add_argument("--report-out", default=str(REPO / "data" / "audit_generated_report.json"))
    args = ap.parse_args()

    jobs = load_jobs(args.limit)
    if args.datasets:
        keep = set(args.datasets.split(","))
        jobs = [j for j in jobs if j[0] in keep]
    global NO_GUARD
    NO_GUARD = args.no_guard
    print(f"auditing {len(jobs)} generated units with {PMC.JAC}", flush=True)

    results = []
    units_out = Path(args.units_out).open("w")
    with ProcessPoolExecutor(max_workers=args.workers) as ex:
        futs = {}
        for ds_name, kind, payload in jobs:
            if kind == "merged":
                futs[ex.submit(gate_merged_row, payload["rec"])] = (
                    ds_name, payload["rec"]["id"])
            else:
                futs[ex.submit(check_text, payload.get("tag", ""),
                               payload["code"])] = (ds_name, "")
        done = 0
        for fut in as_completed(futs):
            r = fut.result()
            ds_name, rid = futs[fut]
            r["dataset"] = ds_name
            if rid:
                r["id"] = rid
            results.append(r)
            units_out.write(json.dumps(r) + "\n")
            done += 1
            if done % 1000 == 0:
                print(f"  {done}/{len(jobs)}", flush=True)
    units_out.close()

    report: dict[str, dict] = {}
    for r in results:
        d = report.setdefault(r["dataset"], {
            "units": 0, "no_candidate": 0, "check_pass": 0, "check_fail": 0,
            "guard_pass": 0, "guard_fail": 0, "guard_timeout": 0,
            "guard_skipped": 0, "codes": Counter()})
        d["units"] += 1
        if r["check"] == "no_candidate":
            d["no_candidate"] += 1
        elif r["check"] == "pass":
            d["check_pass"] += 1
        else:
            d["check_fail"] += 1
            for c in r.get("codes", []):
                d["codes"][c] += 1
        g = r.get("guard")
        if g == "pass":
            d["guard_pass"] += 1
        elif g == "fail":
            d["guard_fail"] += 1
        elif g == "timeout":
            d["guard_timeout"] += 1
        elif g == "skipped":
            d["guard_skipped"] += 1

    out = {"jac": PMC.JAC, "total_units": len(results), "datasets": {}}
    print(f"\n{'dataset':28s} {'units':>6s} {'noCand':>7s} {'chkOK':>6s} "
          f"{'chkBad':>6s} {'grdOK':>6s} {'grdBad':>6s} {'grdT/O':>6s}  top codes")
    for name, d in sorted(report.items()):
        codes = ", ".join(f"{c}x{n}" for c, n in d["codes"].most_common(4))
        print(f"{name:28s} {d['units']:6d} {d['no_candidate']:7d} "
              f"{d['check_pass']:6d} {d['check_fail']:6d} "
              f"{d['guard_pass']:6d} {d['guard_fail']:6d} "
              f"{d['guard_timeout']:6d}  {codes}")
        out["datasets"][name] = {**{k: v for k, v in d.items() if k != "codes"},
                                 "codes": dict(d["codes"])}
    dest = Path(args.report_out)
    dest.write_text(json.dumps(out, indent=2) + "\n")
    print(f"\nreport: {dest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
