#!/usr/bin/env python3
"""Validate and write issues_17/18/19 manifests (10 records each)."""
from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = REPO / "data" / "osp_lifts"
IG = BASE / "issue_gen"
TIMEOUT = 360


def slug8(title: str, issue: int) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "", title.lower())[:12] or str(issue)
    return s[:8]


def lifts_for(signals: list[str], title: str) -> list[str]:
    sig = set(signals)
    lifts: list[str] = []
    if sig & {"relationship.parent_child", "traversal.recursive"} or "parent" in title.lower():
        lifts.append("C1")
    if sig & {
        "manual_impl.adjacency",
        "manual_impl.queue_walk",
        "manual_impl.visited_set",
        "manual_impl.recursive_cte",
        "traversal.bfs_dfs",
        "traversal.walk",
        "relationship.depends",
        "traversal.path_reach",
        "traversal.cycle",
        "traversal.ordering",
    } or "graph" in title.lower() or "depend" in title.lower():
        lifts.append("C2")
    if "cascade" in title.lower() or "delete" in title.lower() or "invalidat" in title.lower():
        lifts.append("C5")
    return lifts or ["C2"]


def find_stem(owner: str, issue: int) -> str | None:
    key = owner.replace("-", "_").lower()
    for py in IG.glob(f"iss_*__{issue}.py"):
        if py.name.endswith(".ref.py"):
            continue
        if key in py.name.replace("-", "_").lower():
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
    subprocess.run(["jac", "db", "status"], cwd=BASE, capture_output=True, timeout=120)


def validate_stem(stem: str) -> tuple[bool, str]:
    for label, cmd in [
        ("ref", ["python3", str(IG / f"{stem}.ref.py")]),
        ("check", ["jac", "check", str(IG / f"{stem}.jac")]),
        ("test", ["jac", "test", str(IG / f"{stem}_guard.jac")]),
    ]:
        rc, out = run(cmd, BASE if label == "ref" else jac_cwd())
        if rc != 0:
            return False, f"{label}: {out[-400:]}"
        time.sleep(1)
    return True, "ok"


def floor_status(stem: str) -> tuple[str | None, str]:
    floor = IG / f"{stem}.floor.jac"
    if floor.exists() and run(["jac", "check", str(IG / f"{stem}.floor.jac")], jac_cwd())[0] == 0:
        return f"issue_gen/{stem}.floor.jac", "generated"
    return None, "port_failed"


def load_id_templates() -> dict[tuple[str, int], str]:
    out: dict[tuple[str, int], str] = {}
    for mf in BASE.glob("issues_1*.jsonl"):
        for line in mf.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            prov = rec.get("provenance", {})
            if prov.get("repo") and prov.get("issue"):
                out[(prov["repo"], prov["issue"])] = rec["id"]
    return out


def manifest_row(rec: dict, stem: str, id_templates: dict[tuple[str, int], str]) -> dict:
    owner, name = rec["repo"].split("/", 1)
    lifts = lifts_for(rec.get("signals", []), rec.get("title", ""))
    floor_file, floor_st = floor_status(stem)
    key = (rec["repo"], rec["issue"])
    rec_id = id_templates.get(key) or (
        f"osp__{owner}__{name}__{rec['issue']}__{slug8(rec.get('title', ''), rec['issue'])}"
    )
    return {
        "id": rec_id,
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


def process_batch(assign_name: str, manifest_name: str, id_templates: dict) -> tuple[int, int, list[dict]]:
    records = json.loads((BASE / "assignments" / f"{assign_name}_assign.json").read_text())["records"]
    ok = fail = 0
    rows: list[dict] = []
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
            print(f"    FAIL {err[:220]}")
            fail += 1
            continue
        rows.append(manifest_row(rec, stem, id_templates))
        print("    OK")
        ok += 1
    path = BASE / manifest_name
    path.write_text("\n".join(json.dumps(r, separators=(",", ": ")) for r in rows) + "\n")
    return ok, fail, rows


def main() -> int:
    ensure_pg()
    id_templates = load_id_templates()
    total_ok = total_fail = 0
    for assign, manifest in [
        ("issues_17", "issues_17.jsonl"),
        ("issues_18", "issues_18.jsonl"),
        ("issues_19", "issues_19.jsonl"),
    ]:
        print(f"{assign} -> {manifest}", flush=True)
        ok, fail, _ = process_batch(assign, manifest, id_templates)
        total_ok += ok
        total_fail += fail
        print(f"  -> {ok}/10 ok, {fail} fail\n", flush=True)

    print(f"FINAL ok={total_ok} fail={total_fail}")
    for manifest in ("issues_17.jsonl", "issues_18.jsonl", "issues_19.jsonl"):
        n = sum(1 for ln in (BASE / manifest).read_text().splitlines() if ln.strip())
        print(f"  {manifest}: {n}/10 lines")
    return 1 if total_fail else 0


if __name__ == "__main__":
    sys.exit(main())
