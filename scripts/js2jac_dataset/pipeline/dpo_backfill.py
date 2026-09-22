#!/usr/bin/env python3
"""Backfill DPO preference pairs from artifacts already on disk (no generation).

The guard only pairs failures at guard time; every other pairable artifact
used to be discarded. This tool re-derives pairs from existing runs:

  runs   unbanked candidates in runs/<TAG>/ (floors from work/ meta, or from
         repair_work items when the work dir is gone):
           - candidate fails jac check            -> (floor, broken)  check-fail
           - candidate compiles but ORM-gates out -> (floor, hollow)  hollow-orm
         Chosen side is the record's floor, re-verified with jac check NOW.
         Ids already resolved good in a master (source=js2jac_cleaned/floor)
         are skipped; floor_fallback ids still pair (guard-time pair may have
         been lost, e.g. archive runs).
  idiom  idiomize runs (runs/idiom_*): equal-correctness pairs against the
         pre-idiom master. chosen = changed idiomized jac (banked) or the
         pre jac (candidate broke), rejected = the other side. No-op rewrites
         (candidate == pre jac) are SKIPPED — zero preference signal.

Pairs dedupe by id against every dpo_pairs.jsonl under the pkg root and
archive. Append-only; --dry-run reports without writing.

Usage (from scripts/js2jac_dataset):
  python3 pipeline/dpo_backfill.py runs  [--run-root runs] [--dry-run]
  python3 pipeline/dpo_backfill.py idiom [--pre-master PATH] [--dry-run]
  python3 pipeline/dpo_backfill.py all   [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from guard_lib import Checker, jsonl, load_meta, load_repair_meta, orm_reject  # noqa: E402

PKG = Path(__file__).resolve().parents[1]
REPO = PKG.parents[1]
DEFAULT_PRE_MASTER = REPO / "data" / "js2jac_dataset_idiomatic.jsonl"
RESOLVED_GOOD = {"js2jac_cleaned", "js2jac_floor"}


def collect_existing_pair_ids() -> set[str]:
    ids: set[str] = set()
    for pat in (PKG / "dpo_pairs.jsonl",
                *PKG.glob("runs/*/dpo_pairs.jsonl"),
                *REPO.glob("archive/**/dpo_pairs.jsonl")):
        for r in jsonl(pat):
            ids.add(r["id"])
    return ids


def master_index() -> dict[str, dict]:
    idx: dict[str, dict] = {}
    for p in (PKG / "js2jac_dataset.jsonl", *REPO.glob("archive/**/js2jac_dataset.jsonl")):
        for r in jsonl(p):
            idx.setdefault(r["id"], r)
    return idx


def backfill_runs(run_root: Path, ck: Checker, paired: set[str], dry: bool) -> dict:
    masters = master_index()
    stats: dict[str, int] = {}
    for run in sorted(run_root.glob("*")):
        if not (run / "candidates.jsonl").exists():
            continue
        meta = load_meta(run / "work") if (run / "work").exists() else {}
        for rid, m in load_repair_meta(run).items():   # floors survive repair_work
            meta.setdefault(rid, m)
        if not meta:
            continue
        banked = {r["id"] for r in jsonl(run / "dataset.jsonl")}
        pairs: list[dict] = []
        for c in jsonl(run / "candidates.jsonl"):
            rid, code = c["id"], c.get("candidate")
            if (rid in banked or rid in paired or not code or code == "REJECT"
                    or rid not in meta):
                continue
            m_row = masters.get(rid)
            if m_row and m_row.get("source") in RESOLVED_GOOD:
                continue  # candidate side already banked as good elsewhere
            floor = meta[rid].get("floor_jac")
            if not floor or not ck.ok(floor):
                continue  # no compiling chosen side -> not pairable
            if not ck.ok(code):
                pairs.append({"id": rid, "chosen": floor, "rejected": code,
                              "why": "check-fail"})
            else:
                rej, _why = orm_reject(meta[rid], code, ck)
                if rej:
                    pairs.append({"id": rid, "chosen": floor, "rejected": code,
                                  "why": "hollow-orm"})
        if pairs:
            stats[run.name] = len(pairs)
            paired |= {p["id"] for p in pairs}
            if not dry:
                with open(run / "dpo_pairs.jsonl", "a") as fh:
                    for p in pairs:
                        fh.write(json.dumps(p) + "\n")
    return stats


def backfill_idiom(run_root: Path, pre_master_path: Path,
                   ck: Checker, paired: set[str], dry: bool) -> dict:
    pre = {r["id"]: r["jac"] for r in jsonl(pre_master_path)}
    stats: dict[str, int] = {}
    for run in sorted(run_root.glob("idiom_*")):
        banked = {r["id"]: r["jac"] for r in jsonl(run / "dataset.jsonl")}
        cand = {r["id"]: r.get("candidate") for r in jsonl(run / "candidates.jsonl")}
        pairs: list[dict] = []
        for rid, new in banked.items():
            old = pre.get(rid)
            if not old or new == old or rid in paired or not ck.ok(old) or not ck.ok(new):
                continue
            pairs.append({"id": rid, "chosen": new, "rejected": old,
                          "why": "idiom-upgrade"})
        for rid, code in cand.items():
            old = pre.get(rid)
            if (not old or rid in banked or rid in paired or code == old
                    or not code or code == "REJECT" or ck.ok(code)):
                continue  # only pair candidates that actually broke
            if not ck.ok(old):
                continue
            pairs.append({"id": rid, "chosen": old, "rejected": code,
                          "why": "idiom-regression"})
        if pairs:
            stats[run.name] = len(pairs)
            paired |= {p["id"] for p in pairs}
            if not dry:
                with open(run / "dpo_pairs.jsonl", "a") as fh:
                    for p in pairs:
                        fh.write(json.dumps(p) + "\n")
    return stats


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["runs", "idiom", "all"])
    ap.add_argument("--run-root", type=Path, default=PKG / "runs")
    ap.add_argument("--pre-master", type=Path, default=DEFAULT_PRE_MASTER)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    paired = collect_existing_pair_ids()
    print(f"{len(paired)} pairs already exist (dedup baseline)")
    ck = Checker()
    if a.mode in ("runs", "all"):
        s = backfill_runs(a.run_root, ck, paired, a.dry_run)
        print(f"runs: {sum(s.values())} pairs {dict(s)}{' (dry)' if a.dry_run else ''}")
    if a.mode in ("idiom", "all"):
        s = backfill_idiom(a.run_root, a.pre_master, ck, paired, a.dry_run)
        print(f"idiom: {sum(s.values())} pairs {dict(s)}{' (dry)' if a.dry_run else ''}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
