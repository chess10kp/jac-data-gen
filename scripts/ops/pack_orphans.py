#!/usr/bin/env python3
"""Validate complete orphan issue_gen sets and append to issues_orphans.jsonl."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = REPO / "data" / "osp_lifts"
IG = BASE / "issue_gen"
MANIFEST = BASE / "issues_orphans.jsonl"
TIMEOUT = 300


def jac_cwd() -> Path:
    """Disposable cwd for jac spawns — jac and tested code write into CWD."""
    d = BASE / ".sandbox"
    d.mkdir(parents=True, exist_ok=True)
    return d


def run(cmd: list[str], cwd: Path) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=TIMEOUT)
        return p.returncode, (p.stdout + p.stderr)[-2500:]
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def manifest_stems() -> set[str]:
    stems: set[str] = set()
    for mf in BASE.glob("issues_*.jsonl"):
        for line in mf.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            sf = rec.get("source_file", "")
            if sf:
                stems.add(Path(sf).stem)
    return stems


def parse_stem(stem: str) -> tuple[str, str, int] | None:
    m = re.match(r"iss_(.+?)__(\d+)$", stem)
    if not m:
        return None
    body, issue_s = m.group(1), m.group(2)
    if "__" not in body:
        return None
    owner, name = body.split("__", 1)
    return owner, name.replace("__", "/"), int(issue_s)


def slug8(title: str, issue: int) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "", title.lower())[:12] or str(issue)
    return s[:8]


def lifts_for(title: str) -> list[str]:
    t = title.lower()
    lifts: list[str] = []
    if "parent" in t or "hierarch" in t or "tree" in t:
        lifts.append("C1")
    if "graph" in t or "travers" in t or "reach" in t or "bfs" in t:
        lifts.append("C2")
    if "cascade" in t or "delete" in t or "invalidat" in t:
        lifts.append("C5")
    return lifts or ["C2"]


def complete_stems() -> list[str]:
    known = manifest_stems()
    out: list[str] = []
    for py in sorted(IG.glob("iss_*.py")):
        if py.name.endswith(".ref.py"):
            continue
        stem = py.stem
        if stem in known:
            continue
        need = [IG / f"{stem}.ref.py", IG / f"{stem}.jac", IG / f"{stem}_guard.jac"]
        if all(p.exists() for p in need):
            out.append(stem)
    return out


def validate_stem(stem: str) -> tuple[bool, str]:
    for label, cmd in [
        ("ref", ["python3", str(IG / f"{stem}.ref.py")]),
        ("check", ["jac", "check", str(IG / f"{stem}.jac")]),
        ("test", ["jac", "test", str(IG / f"{stem}_guard.jac")]),
    ]:
        rc, out = run(cmd, BASE if label == "ref" else jac_cwd())
        if rc != 0:
            return False, f"{label}: {out[-300:]}"
    return True, "ok"


def floor_status(stem: str) -> tuple[str | None, str]:
    floor = IG / f"{stem}.floor.jac"
    if floor.exists() and run(["jac", "check", str(floor)], jac_cwd())[0] == 0:
        return f"issue_gen/{stem}.floor.jac", "generated"
    return None, "port_failed"


def main() -> int:
    dry = "--dry-run" in sys.argv
    existing_ids: set[str] = set()
    if MANIFEST.exists():
        for line in MANIFEST.read_text().splitlines():
            if line.strip():
                existing_ids.add(json.loads(line)["id"])

    stems = complete_stems()
    print(f"complete orphans: {len(stems)}")
    ok_n = fail_n = 0
    lines: list[str] = []

    for stem in stems:
        parsed = parse_stem(stem)
        if not parsed:
            print(f"  skip unparseable stem {stem}")
            continue
        owner, name, issue = parsed
        repo = f"{owner}/{name}"
        good, err = validate_stem(stem)
        if not good:
            fail_n += 1
            print(f"  FAIL {stem}: {err[:80]}")
            continue
        floor_file, floor_st = floor_status(stem)
        rid = f"osp__{owner}__{name.replace('/', '__')}__{issue}__{slug8('', issue)}"
        if rid in existing_ids:
            ok_n += 1
            continue
        row = {
            "id": rid,
            "track": "S",
            "category_lifts": lifts_for(""),
            "provenance": {"repo": repo, "issue": issue,
                           "url": f"https://github.com/{repo}/issues/{issue}"},
            "source_file": f"issue_gen/{stem}.py",
            "candidate_file": f"issue_gen/{stem}.jac",
            "guard_file": f"issue_gen/{stem}_guard.jac",
            "floor_file": floor_file,
            "floor_status": floor_st,
            "signals": [],
            "g_tier": 1,
            "python_ref_pass": True,
            "jac_check": True,
            "jac_test_guard": True,
        }
        lines.append(json.dumps(row, separators=(",", ": ")))
        ok_n += 1
        print(f"  OK {stem}")

    if lines and not dry:
        with MANIFEST.open("a") as f:
            for ln in lines:
                f.write(ln + "\n")
        print(f"wrote {len(lines)} lines -> {MANIFEST}")

    print(f"TOTAL: {ok_n} ok, {fail_n} fail, {len(lines)} new lines")
    return 1 if fail_n else 0


if __name__ == "__main__":
    sys.exit(main())
