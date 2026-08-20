#!/usr/bin/env python3
"""Discover candidate TS/React repos for the js2jac corpus.

Stage 1 of the sourcing front: GitHub search -> candidates.jsonl.
No cloning here; this is the cheap pre-filter that produces a work list for
harvest.py (clone -> build -> convert -> record).

GitHub caps any single search query at 1000 returned results, so we sweep tiles
of (license x star-band) to get past that ceiling. Uses the authenticated `gh`
CLI (no token juggling).

Usage:
  python3 discover.py                       # default sweep -> candidates.jsonl
  python3 discover.py --max 2000            # cap total candidates
  python3 discover.py --out cands.jsonl
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

from profiles import get_profile, load_profiles

# Pacing: GitHub's search API caps authenticated users at 30 requests/min.
# We space calls just under that and retry-on-rate-limit, so the full sweep
# can actually finish instead of stalling after a few tiles.
SEARCH_MIN_INTERVAL = 2.1  # seconds between search requests (~28.5/min)
_last_search_ts = 0.0


def _throttle() -> None:
    """Block until enough time has passed since the last search request."""
    global _last_search_ts
    wait = SEARCH_MIN_INTERVAL - (time.monotonic() - _last_search_ts)
    if wait > 0:
        time.sleep(wait)
    _last_search_ts = time.monotonic()


def _search_reset_in() -> int:
    """Seconds until the GitHub search rate-limit window resets (+ buffer)."""
    try:
        res = subprocess.run(
            ["gh", "api", "-X", "GET", "rate_limit", "--jq", ".resources.search.reset"],
            capture_output=True, text=True, timeout=30,
        )
        if res.returncode == 0 and res.stdout.strip().isdigit():
            return max(1, int(res.stdout.strip()) - int(time.time()) + 2)
    except subprocess.TimeoutExpired:
        pass
    return 62  # conservative fallback if the check itself fails


def _is_rate_limited(stderr: str) -> bool:
    return "rate limit" in (stderr or "").lower()


# Star bands tile the space so no single query exceeds GitHub's 1000-result cap.
# Low bands are huge (lots of small repos); high bands are sparse. Adjust freely.
STAR_BANDS = [
    "10..25", "26..40", "41..60", "61..90", "91..140",
    "141..250", "251..500", "501..1200", "1201..5000", ">5000",
]

# Keep repos small enough to actually convert & verify. size is in KB (GitHub).
SIZE_QUALIFIER = "size:<8000"

# React-family signal. topic:react is high-precision; we re-check deps at clone.
BASE_QUALIFIERS = "topic:react language:TypeScript archived:false template:false"


def _gh_search_page(query: str, page: int, per_page: int) -> tuple[str, list[str]]:
    """One throttled attempt at a single page. Returns (status, raw_lines)."""
    _throttle()
    try:
        res = subprocess.run(
            [
                "gh", "api", "-X", "GET", "search/repositories",
                "-f", f"q={query}",
                "-f", "sort=stars",
                "-f", "order=desc",
                "-f", f"per_page={per_page}",
                "-f", f"page={page}",
                "--jq", ".items[] | {full_name, default_branch, "
                        "stars:.stargazers_count, size, "
                        "license:.license.key, pushed:.pushed_at, "
                        "clone_url}",
            ],
            capture_output=True, text=True, timeout=60,
        )
    except subprocess.TimeoutExpired:
        print(f"  ! timeout on page {page}", file=sys.stderr)
        return "error", []
    if res.returncode != 0:
        if _is_rate_limited(res.stderr):
            return "rate_limited", []
        print(f"  ! gh error: {res.stderr.strip()[:200]}", file=sys.stderr)
        return "error", []
    return "ok", [ln for ln in res.stdout.splitlines() if ln.strip()]


def gh_search(query: str, per_page: int = 100, max_pages: int = 10) -> list[dict]:
    """Page through a single GitHub repo-search query (<=1000 results).

    Retries on rate-limit by sleeping until the search window resets, so a long
    sweep no longer stalls partway.
    """
    out: list[dict] = []
    for page in range(1, max_pages + 1):
        while True:
            status, lines = _gh_search_page(query, page, per_page)
            if status == "rate_limited":
                wait = _search_reset_in()
                print(f"  ! search rate-limited on page {page}; sleeping {wait}s",
                      file=sys.stderr)
                time.sleep(wait)
                continue
            if status == "error":
                return out
            if not lines:
                return out  # no results for this page
            for ln in lines:
                try:
                    out.append(json.loads(ln))
                except json.JSONDecodeError:
                    continue
            if len(lines) < per_page:
                return out  # last page
            break  # success -> next page
    return out


def sweep(max_total: int, extra_qualifiers: str = "", bands: list[str] | None = None) -> dict[str, dict]:
    """Sweep star-band tiles; dedupe by full_name.

    No license filter — the repo's license is recorded (spdx field) but not
    gated. Check later if you need training-safe licensing.

    `extra_qualifiers` are profile-specific GitHub search terms (e.g.
    `topic:shadcn-ui`) that bias discovery toward the target stack. discover
    can't read package.json (no clone), so topic qualifiers are the only
    stack lever here; harvest/wall_probe apply the real dep gate at clone time.

    `bands` overrides STAR_BANDS (e.g. a raised high-star re-sweep).
    """
    extra = f" {extra_qualifiers}" if extra_qualifiers else ""
    seen: dict[str, dict] = {}
    for band in (bands or STAR_BANDS):
        if len(seen) >= max_total:
            return seen
        q = f"{BASE_QUALIFIERS}{extra} {SIZE_QUALIFIER} stars:{band}"
        rows = gh_search(q)
        new = 0
        for r in rows:
            name = r.get("full_name")
            if not name or name in seen:
                continue
            r["spdx"] = (r.get("license") or "").upper()
            seen[name] = r
            new += 1
        print(f"[{band:10}] +{new:4} (total {len(seen)})", file=sys.stderr)
    return seen


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(Path(__file__).with_name("candidates.jsonl")))
    ap.add_argument("--fresh", action="store_true",
                    help="overwrite instead of merging with existing candidates")
    ap.add_argument("--max", type=int, default=100_000)
    ap.add_argument("--profile", default="react",
                    help=f"stack profile (from profiles.json): "
                         f"{', '.join(sorted(load_profiles()))}")
    ap.add_argument("--bands", default=None,
                    help="comma-separated star bands to sweep instead of the "
                         "default tiling (e.g. '100..300,301..800,>800')")
    args = ap.parse_args()

    prof = get_profile(args.profile)
    extra = " ".join(prof.get("github_qualifiers", []))
    if extra:
        print(f"profile {args.profile!r}: +qualifiers [{extra}]", file=sys.stderr)

    bands = [b.strip() for b in args.bands.split(",")] if args.bands else None
    cands = sweep(args.max, extra, bands=bands)
    outp = Path(args.out)
    # merge with existing candidates: dedupe by full_name, keep old order first,
    # append fresh discoveries at the end (grind consumes by offset; this keeps
    # already-processed offsets stable while feeding new repos after them).
    seen_order: list[dict] = []
    seen: set[str] = set()
    if outp.exists() and not args.fresh:
        for ln in outp.read_text().splitlines():
            if not ln.strip():
                continue
            try:
                r = json.loads(ln)
            except json.JSONDecodeError:
                continue
            if r.get("full_name") not in seen:
                seen.add(r["full_name"])
                seen_order.append(r)
    for r in cands.values():
        if r["full_name"] not in seen:
            seen.add(r["full_name"])
            r["profile"] = args.profile
            seen_order.append(r)
    with outp.open("w") as f:
        for r in seen_order:
            f.write(json.dumps(r, sort_keys=True) + "\n")
    print(f"\nWrote {len(seen_order)} candidates -> {outp} "
          f"({len(seen_order) - len(cands) + len([r for r in cands.values()]) - len(seen_order) + len(seen) if False else len(seen)} unique)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
