#!/usr/bin/env python3
"""Extract Beanie/ODMantic model files from GitHub -> farm_models.jsonl.

Stage 0 of the FARM burndown. Collapses discover+harvest into one pass because
ODM model files are small: GitHub code-search finds candidate files, the contents
API fetches each, and we KEEP only files that lift to >=1 gate-able node via
mongo_odm_to_jac.analyze (so junk/non-schema hits are dropped at the source).

Output row (matches the js2jac corpus shape):
  {"id","repo","path","commit","spdx","source","nodes"}

`id` = "<owner>__<repo>__<path-slug>" (stable, dedup key). `source` is the raw
models.py text -> farm_prep.py consumes it directly.

Auth: uses `gh` (GitHub CLI). Code search ~10 req/min; contents ~5000/hr. We pace
search pages and cache per-repo license lookups.

Usage:
  ./farm_discover.py --out farm_models.jsonl --limit 200
  ./farm_discover.py --out farm_models.jsonl --limit 500 --queries beanie,odmantic
"""
from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import mongo_odm_to_jac as odm

# distinctive user-facing imports of each typed ODM (the deterministic core)
# + query VARIANTS per ODM: GitHub code search ranks per query string, so a
# different marker surface (canonical import, ObjectId type, decorator, base
# class) returns a DIFFERENT file subset — that's how the 603-model pool got
# re-expanded after the 08-19 exhaustion (kept 0/897 scanned on base queries).
QUERIES = {
    "beanie":        '"from beanie import" "Document" language:python',
    "beanie_doc":    '"from beanie import Document" language:python',
    "beanie_pid":    'beanie PydanticObjectId language:python',
    "beanie_idx":    'beanie Indexed language:python',
    "odmantic":      '"from odmantic import" "Model" language:python',
    "odmantic_emb":  'odmantic EmbeddedModel language:python',
    "odmantic_aio":  'odmantic AIOEngine language:python',
    "mongoengine":   '"from mongoengine" "Document" language:python',
    "mongoengine_emb": 'mongoengine EmbeddedDocument language:python',
    "mongoengine_imp": '"import mongoengine" language:python',
}


def gh_json(args: list[str]):
    p = subprocess.run(["gh", "api", *args], capture_output=True, text=True)
    if p.returncode != 0:
        return None
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError:
        return None


def search_code(query: str, pages: int, per_page: int, pause: float):
    """Yield code-search items across pages (GitHub caps code search at ~10 pages)."""
    for page in range(1, pages + 1):
        d = gh_json(["-X", "GET", "search/code",
                     "-f", f"q={query}", "-f", f"per_page={per_page}",
                     "-f", f"page={page}"])
        items = (d or {}).get("items") or []
        if not items:
            return
        for it in items:
            yield it
        if len(items) < per_page:
            return
        time.sleep(pause)          # respect code-search 10/min


_LICENSE_CACHE: dict[str, str] = {}


def repo_license(full_name: str) -> str:
    if full_name in _LICENSE_CACHE:
        return _LICENSE_CACHE[full_name]
    d = gh_json([f"repos/{full_name}"]) or {}
    lic = ((d.get("license") or {}).get("spdx_id")) or "NOASSERTION"
    _LICENSE_CACHE[full_name] = lic
    return lic


# Files that are never real ODM schema material — pure repo boilerplate.
# NOTE: disabled for now (user: drop the filtering); kept for quick re-enable.
BOGUS_PATH_SUBSTR: tuple[str, ...] = ()  # e.g. ("license", "readme", "changelog")


def fetch_content(item: dict) -> str | None:
    """Fetch and decode the file body via the contents URL on the search item."""
    url = item.get("url")
    if not url:
        return None
    fpath = item.get("path") or ""
    if any(b in fpath.lower() for b in BOGUS_PATH_SUBSTR):
        return None                    # boilerplate -> skip
    fpath = item.get("path") or ""
    if any(b in fpath.lower() for b in BOGUS_PATH_SUBSTR):
        return None                    # LICENSE/README/… boilerplate -> skip
    # item.url is a full api URL; `gh api <path>` accepts the path after the host
    path = url.split("github.com/", 1)[-1]
    d = gh_json([path])
    if not d or d.get("encoding") != "base64" or not d.get("content"):
        return None
    if (d.get("size") or 0) > 200_000:        # skip pathological files
        return None
    try:
        return base64.b64decode(d["content"]).decode("utf-8", "replace")
    except Exception:  # noqa: BLE001
        return None


def slug(s: str) -> str:
    return "".join(c if c.isalnum() else "_" for c in s).strip("_")


def discover(out_path: str, which: list[str], limit: int,
             pages: int, per_page: int, pause: float, want_license: bool) -> int:
    out = Path(out_path)
    seen = set()
    if out.exists():
        for ln in out.read_text().splitlines():
            if ln.strip():
                seen.add(json.loads(ln)["id"])
    fh = out.open("a")
    kept = scanned = 0
    try:
        for odm_name in which:
            q = QUERIES[odm_name]
            print(f"[discover] {odm_name}: {q}", flush=True)
            for it in search_code(q, pages, per_page, pause):
                if kept >= limit:
                    break
                repo = (it.get("repository") or {}).get("full_name")
                fpath = it.get("path")
                if not repo or not fpath:
                    continue
                rid = f"{slug(repo)}__{slug(fpath)}"
                if rid in seen:
                    continue
                scanned += 1
                src = fetch_content(it)
                if not src:
                    continue
                try:
                    _arch, specs = odm.analyze(src)
                except SyntaxError:
                    continue
                gateable = [s["node"] for s in specs
                            if s["scalar_fields"] and s["tag_field"]]
                if not gateable:
                    continue                  # no liftable/gate-able node -> drop
                rec = {
                    "id": rid, "repo": repo, "path": fpath,
                    "commit": it.get("sha"),
                    "spdx": repo_license(repo) if want_license else "SKIPPED",
                    "source": src, "nodes": gateable,
                    "odm": odm_name,
                }
                fh.write(json.dumps(rec) + "\n"); fh.flush()
                seen.add(rid); kept += 1
                if kept % 10 == 0:
                    print(f"  kept {kept} (scanned {scanned})", flush=True)
            if kept >= limit:
                break
    finally:
        fh.close()
    print(f"[discover] done: kept {kept} model files (scanned {scanned}) -> {out_path}")
    return kept


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(Path(__file__).resolve().parent / "farm_models.jsonl"))
    ap.add_argument("--queries", default="",
                    help="comma list of QUERIES keys; empty = all of them")
    ap.add_argument("--limit", type=int, default=200)
    ap.add_argument("--pages", type=int, default=10)
    ap.add_argument("--per-page", type=int, default=50)
    ap.add_argument("--pause", type=float, default=7.0)
    ap.add_argument("--no-license", action="store_true",
                    help="skip per-repo SPDX lookup (faster; spdx='SKIPPED')")
    args = ap.parse_args()
    which = ([q.strip() for q in args.queries.split(",")
             if q.strip() in QUERIES] or list(QUERIES))
    discover(args.out, which, args.limit, args.pages, args.per_page,
             args.pause, not args.no_license)
    return 0


if __name__ == "__main__":
    sys.exit(main())
