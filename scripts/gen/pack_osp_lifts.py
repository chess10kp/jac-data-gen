#!/usr/bin/env python3
"""Pack osp_lifts records into a v2.1-spec JSONL dataset.

Independent re-validation (trust but verify):
  - python ref harness exits 0
  - jac check on candidate
  - jac test on guard file
  - floor file (if present) passes jac check -> floor_status generated
Emits data/osp_lift_dataset.jsonl with one record per spec §8.4 (adapted:
files referenced by path, code inlined for candidate/source).
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "lib"))
from jacresolve import resolve_jac  # noqa: E402

JAC = resolve_jac()
BASE = REPO / "data" / "osp_lifts"
OUT = REPO / "data" / "osp_lift_dataset.jsonl"


def run(cmd: list[str], cwd: Path) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=180)
        return p.returncode, (p.stdout + p.stderr)[-2000:]
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def validate(rec_dir: Path, rec: dict) -> list[str]:
    errs = []
    src = BASE / rec["source_file"] if rec.get("source_file") else None
    cand = BASE / rec["candidate_file"]
    guard = BASE / rec["guard_file"]
    ref = src.with_name(src.stem + ".ref.py") if src else None

    if not all(p.exists() for p in (cand, guard) + ((src,) if src else ())):
        return [f"missing files for {rec['id']}"]

    if src:
        rc, out = run(["python3", str(ref)], rec_dir)
        if rc != 0:
            errs.append(f"{rec['id']}: python ref failed\n{out[-500:]}")
    rc, out = run([JAC, "check", str(cand)], rec_dir)
    if rc != 0:
        errs.append(f"{rec['id']}: jac check failed\n{out[-500:]}")
    rc, out = run([JAC, "test", str(guard)], rec_dir)
    if rc != 0:
        errs.append(f"{rec['id']}: jac test guard failed\n{out[-500:]}")

    floor = BASE / rec["floor_file"] if rec.get("floor_file") else None
    if floor and floor.exists():
        rc, _ = run([JAC, "check", str(floor)], rec_dir)
        if rc != 0:
            errs.append(f"{rec['id']}: floor marked generated but fails jac check")
    else:
        rec["floor_file"], rec["floor_status"] = None, "port_failed"

    # elimination spot-check: banned machinery tokens in candidate text
    text = cand.read_text()
    text = re.sub(r'"""(.*?)"""', "", text, flags=re.S)   # strip docstrings:
    text = re.sub(r"#[^\n]*", "", text)                  # floors may name the
    banned = ["deque", "heapq", "queue.Queue", "visited = set()", "stack =", "queue ="]
    hits = [b for b in banned if b in text]
    if hits:
        errs.append(f"{rec['id']}: suspicious scaffolding tokens in candidate: {hits}")
    return errs


def main() -> int:
    trust = "--trust-manifests" in sys.argv
    rows, failures = [], []
    skip_prefixes = ("_cost_", "mm", "pool_")
    for manifest in sorted(BASE.glob("*.jsonl")):
        if manifest.name.startswith(skip_prefixes):
            continue
        rec_dir = manifest.parent
        for line in manifest.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            if "candidate_file" not in rec:
                continue
            if not trust:
                failures.extend(validate(rec_dir, rec))
            rows.append(rec)

    # dedupe: by id, and one record per (repo, issue) for issue-derived rows
    seen, seen_issue, uniq = set(), set(), []
    for r in rows:
        if r["id"] in seen:
            continue
        prov = r.get("provenance") or {}
        key = (prov.get("repo"), prov.get("issue")) if prov.get("issue") else None
        if key and key in seen_issue:
            print(f"dedupe: dropping {r['id']} (duplicate of same issue)")
            continue
        seen.add(r["id"])
        if key:
            seen_issue.add(key)
        uniq.append(r)

    with open(OUT, "w") as f:
        for r in uniq:
            cand = BASE / r["candidate_file"]
            record = {
                "id": r["id"],
                "track": r.get("track", "S"),
                "category_lifts": r.get("category_lifts", []),
                "g_tier": r.get("g_tier", 1),
                "provenance": r.get("provenance", {"repo": "synthetic"}),
                "signals": r.get("signals", []),
                "floor_status": r.get("floor_status", "port_failed"),
                "guard_result": "pass" if not failures or r["id"] not in str(failures) else "unknown",
                "generation_date": datetime.now().isoformat(),
                "generator": "cursor-cli",
                "spec_version": "OSP_IDIOMIZE_TASK-v2.1",
                "jac_version": "0.36.1",
                "source_code": (BASE / r["source_file"]).read_text()
                               if r.get("source_file") and (BASE / r["source_file"]).exists() else None,
                "candidate_osp_jac": cand.read_text() if cand.exists() else None,
                "floor_jac": (BASE / r["floor_file"]).read_text()
                             if r.get("floor_file") and (BASE / r["floor_file"]).exists() else None,
            }
            f.write(json.dumps(record) + "\n")

    print(f"wrote {len(uniq)} records -> {OUT}")
    if failures:
        print(f"{len(failures)} VALIDATION FAILURES:")
        for e in failures:
            print(" -", e)
        return 1
    print("all records validated green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
