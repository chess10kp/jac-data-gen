#!/usr/bin/env python3
"""Measurement-only guard for the holes-records salvage pilot.
For each candidate: jac-check the candidate AND its floor (baseline), and
flag remaining holes / hollow (identity-map) fills. No master append."""
import json, subprocess, tempfile, os, re, sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

RUN = Path(__file__).parent
JAC_REPO = sys.argv[1] if len(sys.argv) > 1 else str(Path.home() / "repos" / "jac")

meta = {}
for f in (RUN / "work").glob("*.json"):
    if f.name == "report.json": continue
    r = json.load(open(f)); meta[r["id"]] = r

cands = [json.loads(l) for l in open(RUN / "pilot_candidates.jsonl") if l.strip()]

# markers that mean an unfilled hole survived into the candidate
HOLE_RE = re.compile(r"\bTODO\b|<HOLE|HOLE>|\bpass\s*;?\s*#\s*hole|__HOLE__|\.\.\.\s*#", re.I)

def jac_check(code: str) -> bool:
    if not code or code == "REJECT":
        return False
    with tempfile.NamedTemporaryFile("w", suffix=".jac", delete=False) as tf:
        tf.write(code); tp = tf.name
    try:
        p = subprocess.run(["jac", "check", tp], cwd=JAC_REPO,
                           capture_output=True, timeout=90)
        return p.returncode == 0
    except Exception:
        return False
    finally:
        os.unlink(tp)

def work(c):
    m = meta.get(c["id"], {})
    code = c.get("candidate")
    cand_pass = jac_check(code)
    floor = m.get("floor_jac") or ""
    base_pass = jac_check(floor) if floor else False
    holes_left = bool(code and HOLE_RE.search(code))
    # hollow signal: candidate barely larger than floor, or floor was empty
    grew = (len(code) - len(floor)) if code else -1
    return {
        "id": c["id"], "path": m.get("path"), "floor_mode": m.get("floor_mode"),
        "status_in": m.get("status"), "reject": (not code or code == "REJECT"),
        "cand_pass": cand_pass, "base_pass": base_pass,
        "holes_left": holes_left, "grew": grew, "cand_len": len(code or ""),
    }

with ThreadPoolExecutor(max_workers=8) as ex:
    rows = list(ex.map(work, cands))

json.dump(rows, open(RUN / "pilot_guard.json", "w"), indent=0)

n = len(rows)
kept   = [r for r in rows if r["cand_pass"] and not r["reject"]]
rej    = [r for r in rows if r["reject"]]
fail   = [r for r in rows if not r["cand_pass"] and not r["reject"]]
base_ok = [r for r in rows if r["base_pass"]]
rescued = [r for r in kept if not r["base_pass"]]          # NEW passes
holes_in_kept = [r for r in kept if r["holes_left"]]
fmodes = {}
for r in rows: fmodes[r["floor_mode"]] = fmodes.get(r["floor_mode"], 0) + 1

print(f"population: {n} candidates | floor_modes: {fmodes}")
print(f"baseline (floor compiles): {len(base_ok)}/{n}")
print(f"GUARD  kept {len(kept)}  check-fail {len(fail)}  reject {len(rej)}")
print(f"  -> keep ratio {len(kept)/n*100:.1f}%")
print(f"RESCUE (kept AND floor did NOT compile): {len(rescued)}")
print(f"quality: kept-with-holes-still-present {len(holes_in_kept)}")
print(f"         median grew (cand_len - floor_len) among kept: "
      f"{sorted(r['grew'] for r in kept)[len(kept)//2] if kept else 'n/a'}")
