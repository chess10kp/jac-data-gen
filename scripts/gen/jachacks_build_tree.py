#!/usr/bin/env python3
"""Materialize a jachacks check tree from a *_jac_files_filtered.jsonl.

Usage: jachacks_build_tree.py EDITION OUTDIR
  EDITION in {sf, spring, 2026, nonsf}  (nonsf = spring + 2026)
Writes OUTDIR/<dirname>/<file_path> for every record.
"""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EDITIONS = {
    "sf": ("sf",),
    "spring": ("spring",),
    "2026": ("2026",),
    "nonsf": ("spring", "2026"),
}


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] not in EDITIONS:
        print(__doc__)
        return 2
    edition, outdir = sys.argv[1], Path(sys.argv[2])
    n = 0
    for src in EDITIONS[edition]:
        for line in open(REPO / "data" / f"jachacks_{src}_jac_files_filtered.jsonl"):
            r = json.loads(line)
            p = outdir / r["dirname"] / r["file_path"]
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(r["jac"])
            n += 1
    print(f"{edition}: wrote {n} files under {outdir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
