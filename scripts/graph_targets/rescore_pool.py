#!/usr/bin/env python3
"""Rescore the mined issue pool with the refit rubric — no API calls.

Applies issue_miner.score() (post signal-refit) to every stored row of
data/graph_targets/issues.jsonl and writes issues_rescored.jsonl with
{'score' -> new, 'old_score', 'delta'} added. Marks rows already consumed
by osp_lifts assignments.

Usage:
  python3 scripts/graph_targets/rescore_pool.py            # full rescore
  python3 scripts/graph_targets/rescore_pool.py --top 40   # preview only
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import issue_miner as im  # noqa: E402

POOL = ROOT / "data" / "graph_targets" / "issues.jsonl"
OUT = ROOT / "data" / "graph_targets" / "issues_rescored.jsonl"


def used_keys() -> set[tuple[str, int]]:
    used: set[tuple[str, int]] = set()
    for f in (ROOT / "data" / "osp_lifts" / "assignments").glob("issues_*_assign.json"):
        for r in json.loads(f.read_text()).get("records", []):
            used.add((r["repo"], r["issue"]))
    return used


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=0, help="print top N unassigned")
    args = ap.parse_args()
    used = used_keys()

    n_new = 0
    out_lines: list[str] = []
    preview: list[dict] = []
    with POOL.open() as fh:
        for line in fh:
            if not line.strip():
                continue
            hit = json.loads(line)
            slug = im.repo_slug(hit.get("repo") or "")
            hit["old_score"] = hit.get("score", 0)
            im.score(hit)  # mutates: score, matched
            hit["delta"] = hit["score"] - hit["old_score"]
            hit["used"] = (slug, int(hit.get("number", 0))) in used
            if not hit["used"]:
                n_new += 1
                preview.append(hit)
            out_lines.append(json.dumps(hit) + "\n")

    OUT.write_text("".join(out_lines))
    avail = sum(1 for h in preview if h["score"] >= 8)
    print(f"rescored {len(out_lines)} rows -> {OUT}")
    print(f"unassigned: {n_new} ({avail} at new-score >= 8)")
    if args.top:
        preview.sort(key=lambda h: -h["score"])
        print(f"\ntop {args.top} unassigned (new | old | repo#issue | title):")
        for h in preview[: args.top]:
            slug = im.repo_slug(h["repo"])
            print(f"  {h['score']:3d} | {h['old_score']:3d} | {slug}#{h['number']} | "
                  f"{(h.get('title') or '')[:70]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
