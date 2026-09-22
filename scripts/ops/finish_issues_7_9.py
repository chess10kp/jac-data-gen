#!/usr/bin/env python3
"""Finish issues_7 remainder + issues_9 batches."""
from __future__ import annotations

import json
import re
import subprocess
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = REPO / "data" / "osp_lifts"
IG = BASE / "issue_gen"
TIMEOUT = 300


def slug8(title: str, issue: int) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "", title.lower())[:12] or str(issue)
    return s[:8]


def lifts_for(signals: list[str], title: str) -> list[str]:
    sig = set(signals)
    lifts: list[str] = []
    if sig & {"relationship.parent_child", "traversal.recursive"} or "parent" in title.lower():
        lifts.append("C1")
    if sig & {"manual_impl.adjacency", "manual_impl.queue_walk", "traversal.bfs_dfs", "traversal.walk"} or "graph" in title.lower():
        lifts.append("C2")
    if "cascade" in title.lower() or "delete" in title.lower() or "invalidat" in title.lower():
        lifts.append("C5")
    return lifts or ["C2"]


def find_stem(owner: str, issue: int) -> str | None:
    for py in IG.glob(f"iss_{owner}__*__{issue}.py"):
        if py.name.endswith(".ref.py"):
            continue
        return py.stem
    return None


def jac_cwd() -> Path:
    """Disposable cwd for jac spawns — jac and tested code write into CWD."""
    d = BASE / ".sandbox"
    d.mkdir(parents=True, exist_ok=True)
    return d


def run(cmd: list[str], cwd: Path | None = None) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=str(cwd or BASE), capture_output=True, text=True, timeout=TIMEOUT)
        return p.returncode, (p.stdout + p.stderr)[-800:]
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def ensure_pg() -> None:
    subprocess.run(["jac", "db", "status"], cwd=IG, capture_output=True, timeout=120)


def validate_stem(stem: str) -> tuple[bool, str]:
    for label, cmd in [
        ("ref", ["python3", str(IG / f"{stem}.ref.py")]),
        ("check", ["jac", "check", str(IG / f"{stem}.jac")]),
        ("test", ["jac", "test", str(IG / f"{stem}_guard.jac")]),
    ]:
        rc, out = run(cmd, BASE if label == "ref" else jac_cwd())
        if rc != 0:
            return False, f"{label}: {out[-400:]}"
        time.sleep(0.5)
    return True, "ok"


def floor_status(stem: str) -> tuple[str | None, str]:
    floor = IG / f"{stem}.floor.jac"
    if floor.exists() and run(["jac", "check", str(floor)], jac_cwd())[0] == 0:
        return f"issue_gen/{stem}.floor.jac", "generated"
    return None, "port_failed"


def manifest_row(rec: dict, stem: str) -> dict:
    owner, name = rec["repo"].split("/", 1)
    lifts = lifts_for(rec.get("signals", []), rec.get("title", ""))
    floor_file, floor_st = floor_status(stem)
    return {
        "id": f"osp__{owner}__{name.replace('/', '__')}__{rec['issue']}__{slug8(rec.get('title', ''), rec['issue'])}",
        "track": "S",
        "category_lifts": lifts,
        "provenance": {"repo": rec["repo"], "issue": rec["issue"], "url": rec["url"]},
        "source_file": f"issue_gen/{stem}.py",
        "candidate_file": f"issue_gen/{stem}.jac",
        "guard_file": f"issue_gen/{stem}_guard.jac",
        "floor_file": floor_file,
        "floor_status": floor_st,
        "signals": rec.get("signals", []),
        "g_tier": 2 if len(set(lifts)) >= 2 else 1,
        "python_ref_pass": True,
        "jac_check": True,
        "jac_test_guard": True,
    }


def process_records(records: list[dict], manifest_path: Path, append: bool) -> tuple[int, int]:
    existing = set()
    if manifest_path.exists() and append:
        for line in manifest_path.read_text().splitlines():
            if line.strip():
                existing.add(json.loads(line)["id"])
    elif not append:
        manifest_path.write_text("")

    ok = fail = 0
    new_lines: list[str] = []
    for rec in records:
        owner, _ = rec["repo"].split("/", 1)
        stem = find_stem(owner, rec["issue"])
        label = f"{rec['repo']}#{rec['issue']}"
        print(f"  {label} ...", flush=True)
        if not stem:
            print("    MISSING stem")
            fail += 1
            continue
        good, err = validate_stem(stem)
        if not good:
            print(f"    FAIL {err[:200]}")
            fail += 1
            continue
        row = manifest_row(rec, stem)
        if row["id"] in existing:
            print("    skip (already in manifest)")
            ok += 1
            continue
        new_lines.append(json.dumps(row, separators=(",", ": ")))
        print("    OK")
        ok += 1

    if new_lines:
        with manifest_path.open("a" if append else "w") as f:
            for ln in new_lines:
                f.write(ln + "\n")
    return ok, fail


def main() -> int:
    ensure_pg()
    total_ok = total_fail = 0

    print("issues_7 remainder (append)", flush=True)
    rem = json.loads((BASE / "assignments/issues_7_remainder_assign.json").read_text())
    ok, fail = process_records(rem["records"], BASE / "issues_7.jsonl", append=True)
    total_ok += ok
    total_fail += fail
    print(f"  -> {ok} ok, {fail} fail\n", flush=True)

    print("issues_9 (rewrite)", flush=True)
    a9 = json.loads((BASE / "assignments/issues_9_assign.json").read_text())
    ok, fail = process_records(a9["records"], BASE / "issues_9.jsonl", append=False)
    total_ok += ok
    total_fail += fail
    print(f"  -> {ok} ok, {fail} fail\n", flush=True)

    c7 = sum(1 for ln in (BASE / "issues_7.jsonl").read_text().splitlines() if ln.strip())
    c9 = sum(1 for ln in (BASE / "issues_9.jsonl").read_text().splitlines() if ln.strip())
    print(f"FINAL: issues_7={c7}/10 issues_9={c9}/10 (this run ok={total_ok} fail={total_fail})")
    return 1 if total_fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
