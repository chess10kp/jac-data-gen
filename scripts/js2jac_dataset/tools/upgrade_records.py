#!/usr/bin/env python3
"""Backfill floor_mode + holes-floors onto already-harvested work records, so the
new salvage path can be exercised WITHOUT re-cloning the repos (every source_js is
saved). Idempotent: rewrites each work/*.json in place with floor_mode set.
  full  = convertible record that already had a floor_jac
  holes = reject record whose standalone hole-convert keeps >=1 declaration
  none  = reject record with nothing to anchor (stays floor_jac=None)
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "source"))
import harvest

work = Path(sys.argv[1])
counts = {"full": 0, "holes": 0, "none": 0, "skip": 0}
for f in sorted(work.glob("*.json")):
    if f.name == "report.json":
        continue
    r = json.load(open(f))
    if "floor_mode" in r and r.get("_upgraded"):
        counts["skip"] += 1
        continue
    if r.get("status") == "convertible" and r.get("floor_jac"):
        r["floor_mode"] = "full"
    elif r.get("status") == "reject":
        hc = harvest.hole_convert(r.get("source_js", ""), r.get("path", "x.ts"))
        if hc.get("ok") and hc.get("keptCount", 0) >= 1 and hc.get("jac"):
            r["floor_jac"] = hc["jac"]; r["floor_mode"] = "holes"
        else:
            r["floor_mode"] = "none"
    else:
        r["floor_mode"] = "none"
    r["_upgraded"] = True
    counts[r["floor_mode"]] = counts.get(r["floor_mode"], 0) + 1
    f.write_text(json.dumps(r))
print("floor_mode:", counts)
