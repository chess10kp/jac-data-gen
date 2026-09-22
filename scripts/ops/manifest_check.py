#!/usr/bin/env python3
"""Verify data/MANIFEST.md against disk.

Checks:
  1. every file/dir path named in the manifest exists — resolved against data/,
     repo root (`../`-prefixed spans), then a pruned walk of the whole repo
  2. every top-level entry in data/ is mentioned in the manifest (brace patterns expanded)
  3. tabulated row counts match actual line counts

Exit 0 = manifest is trustworthy. Exit 1 = missing paths / unlisted entries / count drift.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATA = REPO / "data"
MANIFEST = DATA / "MANIFEST.md"
EXTS = {".jsonl", ".json", ".sqlite3", ".txt", ".md", ".html", ".jac", ".mmd", ".csv"}
SKIP_DIRS = {"__pycache__", ".pytest_cache", ".jac"}
ROW = re.compile(r"^\|\s*`([^`]+)`\s*\|\s*([\d,]+)\s*\|")


def expand_braces(tok: str) -> list[str]:
    m = re.search(r"\{([^}]+)\}", tok)
    if not m:
        return [tok]
    inner = m.group(1)
    if ".." in inner and "," not in inner:
        a, b = inner.split("..", 1)
        alts = [chr(c) for c in range(ord(a), ord(b) + 1)]
    else:
        alts = inner.split(",")
    return [s for alt in alts for s in expand_braces(tok[: m.start()] + alt + tok[m.end() :])]


def build_walk_index() -> dict[str, list[str]]:
    """name -> repo-relative paths, pruning nested repos, caches, and heavy clone dirs."""
    idx: dict[str, list[str]] = {}
    prune = {
        "jaseci", "vendor", "archive", "node_modules", ".venv", "__pycache__",
        ".pytest_cache", ".jac", ".jac309shim", ".git",
    }
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [
            d for d in dirs
            if d not in prune and not d.startswith(".") and not d.endswith("_repos")
        ]
        rel = os.path.relpath(root, REPO)
        for name in dirs + files:
            p = name if rel == "." else f"{rel}/{name}"
            idx.setdefault(name, []).append(p)
    return idx


def main() -> int:
    text = MANIFEST.read_text()
    all_spans = [s for s in re.findall(r"`([^`]+)`", text) if s and " " not in s]
    names = {n for span in all_spans for n in expand_braces(span.rstrip("/"))}
    idx = build_walk_index()

    def walk_lookup(name: str) -> Path | None:
        for rel in idx.get(name, []) + idx.get(name.rsplit("/", 1)[-1], []):
            if rel == name or rel.endswith("/" + name):
                return REPO / rel
        return None

    def resolve_name(name: str) -> Path | None:
        if name.startswith("../"):
            p = REPO / name[3:]
            return p if p.exists() else None
        for base in (DATA, REPO):
            p = base / name
            if p.exists():
                return p
        return walk_lookup(name)

    def glob_exists(e: str) -> bool:
        rel = e[3:] if e.startswith("../") else e
        p = Path(rel.rstrip("/"))
        return any((REPO / p.parent).glob(p.name)) or walk_lookup(p.name) is not None

    def check_span(span: str) -> bool:
        exps = expand_braces(span.rstrip("/"))
        if any("*" in e or "?" in e for e in exps):
            return all(glob_exists(e) for e in exps)
        if span.startswith("_"):  # suffix shorthand, e.g. `_summary.md`
            return any(resolve_name(n) for n in names if n.endswith(span))
        return all(resolve_name(e) is not None for e in exps)

    # existence: spans with a known extension, dir spans (`.../`), and `../`-anchored spans
    check_spans = [
        s for s in all_spans
        if Path(s.rstrip("/")).suffix.lower() in EXTS or s.endswith("/") or s.startswith("../")
    ]
    missing = [s for s in check_spans if not check_span(s)]

    haystack = text + "\n" + "\n".join(sorted(names))
    unlisted = sorted(
        e.name
        for e in DATA.iterdir()
        if e.name != "MANIFEST.md" and e.name not in SKIP_DIRS and e.name not in haystack
    )

    drift = []
    for line in text.splitlines():
        m = ROW.match(line)
        if not m:
            continue
        path, want = m.group(1), int(m.group(2).replace(",", ""))
        locs = [resolve_name(e) for e in expand_braces(path)]
        if not locs or any(l is None or not l.is_file() for l in locs):
            continue
        for loc in locs:
            n = sum(1 for _ in open(loc, "rb"))
            if n != want:
                drift.append(f"{loc.relative_to(REPO)}: manifest {want:,} vs disk {n:,}")

    print(f"checked {len(check_spans)} manifest path patterns")
    if missing:
        print(f"\nMISSING ({len(missing)}):")
        for s in missing:
            print(f"  {s}")
    if unlisted:
        print(f"\nUNLISTED in data/ ({len(unlisted)}):")
        for s in unlisted:
            print(f"  {s}")
    if drift:
        print(f"\nROW-COUNT DRIFT ({len(drift)}):")
        for s in drift:
            print(f"  {s}")
    if not (missing or unlisted or drift):
        print("manifest OK: all paths exist, all data/ entries indexed, counts match")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
