#!/usr/bin/env python3
"""Mine RECENT graph-signal issues — recency-windowed variant of issue_miner.

Same queries / enrichment / scoring rubric as issue_miner, but the GitHub
search is constrained to issues created on/after a cutoff, so the result set
reflects what is being filed now instead of all-time relevance (the base
miner's ranking favors older, popular issues).

Output: data/graph_targets/issues_recent.jsonl — enriched, scored, sorted by
score desc — ready for downstream problem shaping (mm3_issue_problems3).

Usage:
  python3 mine_recent_issues.py --since 2026-07-01
  python3 mine_recent_issues.py --since 2026-07-01 --enrich-top 700 --max-pages 2
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import issue_miner as im  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--since", default="2026-07-01",
                    help="only issues created on/after this date (YYYY-MM-DD)")
    ap.add_argument("--max-pages", type=int, default=2,
                    help="search pages per query (100 hits/page)")
    ap.add_argument("--enrich-top", type=int, default=700,
                    help="how many top pre-scored hits get repo+comment enrichment")
    ap.add_argument("--out", default=str(im.ROOT / "data" / "graph_targets" / "issues_recent.jsonl"))
    args = ap.parse_args()

    im.BASE_QUALIFIERS = f"{im.BASE_QUALIFIERS} created:>={args.since}"
    print(f"[search] qualifiers: {im.BASE_QUALIFIERS!r}", file=sys.stderr, flush=True)

    hits = im.search_issues(max_pages=args.max_pages)
    print(f"[search] {len(hits)} unique recent hits", file=sys.stderr, flush=True)

    # pre-score on title+body to pick enrichment candidates cheaply
    for h in hits:
        im.score(h)
    hits.sort(key=lambda h: h.get("score", 0), reverse=True)

    for i, h in enumerate(hits[: args.enrich_top], 1):
        im.enrich(h)
        im.score(h)  # rescore now that comments/repo_meta are attached
        if i % 100 == 0:
            print(f"[enrich] {i}/{min(args.enrich_top, len(hits))}", file=sys.stderr, flush=True)

    hits.sort(key=lambda h: h.get("score", 0), reverse=True)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w") as fh:
        for h in hits:
            fh.write(json.dumps(h) + "\n")
    print(f"[done] wrote {len(hits)} -> {out}", file=sys.stderr, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
