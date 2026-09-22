#!/usr/bin/env python3
"""Sequentially validate OSP issue_gen records and write manifest lines."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = REPO / "data" / "osp_lifts"
IG = BASE / "issue_gen"
ASSIGN = BASE / "assignments"
TIMEOUT = 300
PG_MAIN = Path.home() / ".cache" / "jac" / "pg" / "main"
PG_LOCK = Path.home() / ".cache" / "jac" / "pg" / "main.lock"


def pg_reset() -> None:
    """Clear stale embedded-postgres state (use sparingly — full restart is slow)."""
    import os
    import shutil
    import time

    pg = Path.home() / ".cache" / "jac" / "pg"
    os.system(f"pkill -9 -u {os.getuid()} -f 'jac/pg' 2>/dev/null")
    time.sleep(1)
    main = pg / "main"
    lock = pg / "main.lock"
    if main.exists():
        shutil.rmtree(main, ignore_errors=True)
    lock.unlink(missing_ok=True)
    time.sleep(1)


def jac_cwd() -> Path:
    """Disposable cwd for jac spawns — jac and tested code write into CWD."""
    d = BASE / ".sandbox"
    d.mkdir(parents=True, exist_ok=True)
    return d


def run_with_retry(cmd: list[str], cwd: Path, reset_on_fail: bool = False) -> tuple[int, str]:
    rc, out = run(cmd, cwd)
    if reset_on_fail and rc != 0 and any(
        s in out for s in ("initdb failed", "postgres failed", "postgres not ready", "PgWireError")
    ):
        pg_reset()
        rc, out = run(cmd, cwd)
    return rc, out


def run(cmd: list[str], cwd: Path) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=TIMEOUT)
        return p.returncode, (p.stdout + p.stderr)[-2500:]
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def find_stem(owner: str, issue: int) -> str | None:
    for jac in IG.glob(f"iss_{owner}__*__{issue}.jac"):
        if jac.name.endswith("_guard.jac") or jac.name.endswith(".floor.jac"):
            continue
        return jac.stem
    return None


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


def validate_stem(stem: str) -> tuple[bool, str]:
    for label, cmd in [
        ("check", ["jac", "check", str(IG / f"{stem}.jac")]),
        ("test", ["jac", "test", str(IG / f"{stem}_guard.jac")]),
    ]:
        if label == "test":
            rc, out = run_with_retry(cmd, jac_cwd(), reset_on_fail=True)
        else:
            rc, out = run(cmd, jac_cwd())
        if rc != 0:
            return False, f"{label}: {out[-400:]}"
    return True, "ok"


def process_batch(batch: int, append: bool = False) -> tuple[int, int, list[str]]:
    assign_path = ASSIGN / f"issues_{batch}_assign.json"
    if not assign_path.exists():
        print(f"issues_{batch}: no assignment file, skip")
        return 0, 0, []
    data = json.loads(assign_path.read_text())
    manifest_path = BASE / f"issues_{batch}.jsonl"
    existing = set()
    if manifest_path.exists() and not append:
        manifest_path.write_text("")
    elif manifest_path.exists():
        for line in manifest_path.read_text().splitlines():
            if line.strip():
                existing.add(json.loads(line)["id"])

    ok_n, fail_n = 0, 0
    failures: list[str] = []
    lines: list[str] = []

    for i, rec in enumerate(data["records"], 1):
        owner, name = rec["repo"].split("/", 1)
        stem = find_stem(owner, rec["issue"])
        print(f"[issues_{batch} {i}/10] {rec['repo']}#{rec['issue']} ...", flush=True)
        if not stem:
            fail_n += 1
            failures.append(f"{rec['repo']}#{rec['issue']}: no stem")
            print("  MISSING stem")
            continue
        good, err = validate_stem(stem)
        if not good:
            fail_n += 1
            failures.append(f"{stem}: {err[:200]}")
            print(f"  FAIL {err[:120]}")
            continue
        lifts = lifts_for(rec.get("signals", []), rec.get("title", ""))
        rid = f"osp__{owner}__{name.replace('/', '__')}__{rec['issue']}__{slug8(rec.get('title', ''), rec['issue'])}"
        if rid in existing:
            print("  skip (already in manifest)")
            ok_n += 1
            continue
        row = {
            "id": rid,
            "track": "S",
            "category_lifts": lifts,
            "provenance": {"repo": rec["repo"], "issue": rec["issue"], "url": rec["url"]},
            "candidate_file": f"issue_gen/{stem}.jac",
            "guard_file": f"issue_gen/{stem}_guard.jac",
            "signals": rec.get("signals", []),
            "g_tier": 2 if len(set(lifts)) >= 2 else 1,
            "jac_check": True,
            "jac_test_guard": True,
        }
        lines.append(json.dumps(row, separators=(",", ": ")))
        ok_n += 1
        print("  OK")

    if lines:
        with manifest_path.open("a" if append else "w") as f:
            for ln in lines:
                f.write(ln + "\n")
    print(f"issues_{batch}: {ok_n} ok, {fail_n} fail, {len(lines)} lines written")
    return ok_n, fail_n, failures


def main() -> int:
    batches = [int(x) for x in sys.argv[1:] if not x.startswith("-")]
    append = "--append" in sys.argv
    if batches and not append:
        pg_reset()
    total_ok = total_fail = 0
    all_fail: list[str] = []
    for b in batches:
        ok, fail, errs = process_batch(b, append=append)
        total_ok += ok
        total_fail += fail
        all_fail.extend(errs)
    print(f"\nTOTAL: {total_ok} ok, {total_fail} fail")
    if all_fail:
        print("FAILURES:")
        for e in all_fail:
            print(" -", e)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
