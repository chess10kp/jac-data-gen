#!/usr/bin/env python3
"""Create OSP assignment shards from mined graph_targets issues.

Usage:
  python3 scripts/ops/make_assignments.py 26 27 28   # batches 26-28 (10 issues each)
  python3 scripts/ops/make_assignments.py --from 26 --count 20  # batches 26-45
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MINED = REPO / "data" / "graph_targets" / "issues.jsonl"
ASSIGN_DIR = REPO / "data" / "osp_lifts" / "assignments"


def norm_repo(raw: str) -> str:
    if raw.startswith("https://"):
        return raw.split("repos/")[-1].rstrip("/")
    return raw


def used_issues() -> set[tuple[str, int]]:
    used: set[tuple[str, int]] = set()
    for path in ASSIGN_DIR.glob("*.json"):
        data = json.loads(path.read_text())
        for rec in data.get("records", []):
            used.add((rec["repo"], rec["issue"]))
    return used


def stem_exists(repo: str, issue: int) -> bool:
    owner, name = repo.split("/", 1)
    safe = name.replace("/", "__")
    gen = REPO / "data" / "osp_lifts" / "issue_gen"
    # jac-only records never produce a .py — check all artifact shapes,
    # otherwise repo-renamed issues (e.g. prisma/prisma -> prisma/orm)
    # re-enter the pool as "fresh" and get lifted twice.
    return any(
        (gen / f"iss_{owner}__{safe}__{issue}{suffix}").exists()
        for suffix in (".py", ".jac", "_guard.jac")
    )


def load_pool(min_score: int, used: set[tuple[str, int]]) -> list[dict]:
    pool: list[dict] = []
    for line in MINED.read_text().splitlines():
        if not line.strip():
            continue
        m = json.loads(line)
        repo = norm_repo(m.get("repo", ""))
        num = int(m.get("number", 0))
        score = int(m.get("score", 0))
        if not repo or not num or score < min_score:
            continue
        if (repo, num) in used:
            continue
        if stem_exists(repo, num):
            continue
        pool.append(m)
    pool.sort(key=lambda x: (-int(x.get("score", 0)), x.get("html_url", "")))
    return pool


def to_record(m: dict) -> dict:
    repo = norm_repo(m["repo"])
    return {
        "repo": repo,
        "issue": int(m["number"]),
        "url": m.get("html_url", f"https://github.com/{repo}/issues/{m['number']}"),
        "title": m.get("title", ""),
        "score": int(m.get("score", 0)),
        "signals": m.get("signals", m.get("matched", [])),
        "body": m.get("body", "")[:12000],
    }


def write_batch(batch: int, records: list[dict]) -> Path:
    ASSIGN_DIR.mkdir(parents=True, exist_ok=True)
    out = ASSIGN_DIR / f"issues_{batch}_assign.json"
    payload = {"manifest": f"issues_{batch}.jsonl", "records": records}
    out.write_text(json.dumps(payload, indent=2) + "\n")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("batches", nargs="*", type=int, help="batch numbers to create")
    ap.add_argument("--from", dest="from_batch", type=int, default=26)
    ap.add_argument("--count", type=int, default=0, help="number of batches from --from")
    ap.add_argument("--min-score", type=int, default=8)
    args = ap.parse_args()

    batches = args.batches
    if not batches and args.count:
        batches = list(range(args.from_batch, args.from_batch + args.count))
    if not batches:
        batches = [args.from_batch]

    used = used_issues()
    pool = load_pool(args.min_score, used)
    need = len(batches) * 10
    if len(pool) < need:
        print(f"WARN: pool has {len(pool)} issues, need {need} for {len(batches)} batches")

    idx = 0
    for batch in batches:
        assign_path = ASSIGN_DIR / f"issues_{batch}_assign.json"
        if assign_path.exists():
            print(f"issues_{batch}: assignment exists, skip")
            continue
        recs = [to_record(pool[idx + i]) for i in range(10) if idx + i < len(pool)]
        idx += len(recs)
        if len(recs) < 10:
            print(f"issues_{batch}: only {len(recs)} issues available")
        path = write_batch(batch, recs)
        print(f"issues_{batch}: wrote {len(recs)} records -> {path}")

    print(f"remaining pool after assignment: {max(0, len(pool) - idx)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
