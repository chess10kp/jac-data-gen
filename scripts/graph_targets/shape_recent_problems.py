#!/usr/bin/env python3
"""Shape freshly mined issues into an OSP conversion problem pool.

Turns scored/enriched miner output (data/graph_targets/issues_recent.jsonl)
into {id, problem} records for scripts/gen/osp_minimax_generate.py
(--problems). Problems already consumed by any earlier pool or present in
the dataset are excluded, so each wave converts only unseen issues.

The problem text mirrors the mm3_issue_problems* format exactly:

    A maintainer on the project <owner>/<name> (<lang>) filed this issue
    about hand-rolled graph machinery causing pain:

    Issue #<n>: <title>

    <body>

    <task instruction>

Usage:
  python3 shape_recent_problems.py                        # default bar: score>=9
  python3 shape_recent_problems.py --min-score 10 --out data/osp_lifts/mm5_issue_problems.jsonl
"""
from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MINED = REPO / "data" / "graph_targets" / "issues_recent.jsonl"
OUT = REPO / "data" / "osp_lifts" / "mm4_issue_problems.jsonl"
EXCLUDES = sorted(glob.glob(str(REPO / "data" / "osp_lifts" / "mm3_*.jsonl"))) + [
    str(REPO / "data" / "osp_dataset.jsonl"),
]
MIN_BODY = 100  # stub bodies ("see title") burn free-tier calls for nothing

# Constant task instruction appended verbatim to every problem — byte-identical
# across all mm3_issue_problems* pools (the m3 waves' proven contract).
TASK = (
    "Write a small self-contained Jac demo program that models the essential "
    "scenario from this issue natively: pick the 2-4 core entity types as node "
    "archetypes with typed has fields, connect instances with edges (typed edges "
    "where the relationship carries meaning), and implement walker(s) that "
    "perform the traversal the issue complains about (e.g. recursion over "
    "parents/children, cascade delete or invalidation, dependency ordering, "
    "cycle detection, reachability). Wire a small demonstration graph in a "
    "`with entry` block and spawn the walker(s). No I/O, no external libraries, "
    "no pytest blocks."
)


def issue_key(h: dict) -> str:
    slug = (h.get("repo") or "").rstrip("/").split("/")
    return f"iss_{slug[-2]}__{slug[-1]}__{h['number']}"


def shape(h: dict) -> str:
    slug = (h.get("repo") or "").rstrip("/").split("/")
    owner, name = slug[-2], slug[-1]
    lang = (h.get("repo_meta") or {}).get("language") or "unknown"
    return (
        f"A maintainer on the project {owner}/{name} ({lang}) filed this issue "
        f"about hand-rolled graph machinery causing pain:\n\n"
        f"Issue #{h['number']}: {h['title']}\n\n{h.get('body') or ''}"
        f"\n\n{TASK}"
    )


def used_ids() -> set[str]:
    used: set[str] = set()
    for pattern in EXCLUDES:
        for path in glob.glob(pattern):
            with open(path) as fh:
                for line in fh:
                    if not line.strip():
                        continue
                    try:
                        used.add(json.loads(line)["id"])
                    except (json.JSONDecodeError, KeyError):
                        continue
    return used


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--min-score", type=int, default=9)
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()

    used = used_ids()
    seen: set[str] = set()
    rows: list[dict] = []
    n_scored = n_dup = n_used = n_body = 0
    with MINED.open() as fh:
        for line in fh:
            if not line.strip():
                continue
            h = json.loads(line)
            key = issue_key(h)
            if key in seen:
                n_dup += 1
                continue
            seen.add(key)
            if key in used:
                n_used += 1
                continue
            if h.get("score", 0) < args.min_score:
                n_scored += 1
                continue
            if len((h.get("body") or "").strip()) < MIN_BODY:
                n_body += 1
                continue
            rows.append({"id": key, "problem": shape(h)})

    rows.sort(key=lambda r: r["id"])
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w") as fh:
        for r in rows:
            fh.write(json.dumps(r) + "\n")
    print(f"[shape] wrote {len(rows)} -> {out} "
          f"(score>={args.min_score}; skipped: {n_scored} low-score, "
          f"{n_used} already used, {n_body} thin-body, {n_dup} dupes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
