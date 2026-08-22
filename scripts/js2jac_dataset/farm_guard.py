#!/usr/bin/env python3
"""FARM burndown guard: behaviorally gate composer walker candidates.

Mirrors the composer guard step, but the arbiter is behavioral_gate (execution +
persistence deltas), NOT `jac check`. For each composer candidate:

  gated_src = <deterministic archetype>  +  <composer walker-set>
  keep <=> behavioral_gate.run_gate(gated_src, work.manifest).ok

Kept records are appended to the master dataset with full provenance and the gate
verdict, so the corpus is behavior-verified by construction.

Input:
  --work-dir   dir of prep records (<rid>.json)   -> archetype + manifest per id
  --candidates candidates.jsonl {"id","candidate"} from farm_composer_batch
  --out        master dataset.jsonl (append, dedup by id)

Usage: ./farm_guard.py --work-dir WORK --candidates CAND.jsonl --out data/farm_dataset.jsonl
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import behavioral_gate as gate


def load_done(out_path: Path) -> set[str]:
    done = set()
    if out_path.exists():
        for ln in out_path.read_text().splitlines():
            if ln.strip():
                done.add(json.loads(ln)["id"])
    return done


def guard(work_dir: str, cand_path: str, out_path: str) -> tuple[int, int]:
    out = Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    done = load_done(out)
    kept = rejected = skipped = 0
    reasons: dict[str, int] = {}

    fh = out.open("a")
    try:
        for ln in Path(cand_path).read_text().splitlines():
            if not ln.strip():
                continue
            c = json.loads(ln)
            rid, candidate = c["id"], c.get("candidate")
            if rid in done:
                continue
            if not candidate or candidate == "REJECT":
                # a composer REJECT/empty is a real outcome — count it loudly so
                # an all-empty run is visible instead of looking like success
                skipped += 1
                continue
            wf = Path(work_dir, f"{rid}.json")
            if not wf.exists():
                skipped += 1
                print(f"guard: WARNING no work record for candidate {rid}",
                      flush=True)
                continue
            work = json.loads(wf.read_text())
            gated_src = work["archetype"].rstrip() + "\n\n" + candidate.strip() + "\n"
            res = gate.run_gate(gated_src, work["manifest"])
            if res["ok"]:
                fh.write(json.dumps({
                    "id": rid,
                    "node": work["node"],
                    "archetype": work["archetype"],
                    "walkers": candidate.strip(),
                    "manifest": work["manifest"],
                    "gate": {"stage": res["stage"], "reason": res["reason"]},
                    "source_ref": work["source_ref"],
                }) + "\n")
                fh.flush()
                done.add(rid)
                kept += 1
            else:
                rejected += 1
                key = f"{res['stage']}:{res['reason'][:48]}"
                reasons[key] = reasons.get(key, 0) + 1
    finally:
        fh.close()

    total = kept + rejected + skipped
    print(f"guard: kept {kept}, rejected {rejected}, empty/rejected-by-composer "
          f"{skipped}  (master now {len(done)})")
    if total and kept == 0:
        print("guard: ALERT — zero records kept this pass; inspect reject "
              "reasons above before running more chunks", flush=True)
    if reasons:
        print("  reject reasons:")
        for k, n in sorted(reasons.items(), key=lambda kv: -kv[1]):
            print(f"    {n:4d}  {k}")
    return kept, rejected


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--candidates", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    guard(args.work_dir, args.candidates, args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
