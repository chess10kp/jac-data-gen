#!/usr/bin/env python3
"""FARM burndown prep: Mongo ODM model files -> per-node walker-gen work records.

Mirrors agent_idiomize_prep.py's role in the composer pipeline, but the unit of
work is a NODE TYPE (not a function): each record asks composer to write the CRUD
walker-set for one lifted node, and carries everything the behavioral gate needs to
keep/reject it deterministically.

Input:  a JSONL of ODM model files:  {"id","repo","path","source"}   (source = the
        models.py text; Beanie/ODMantic/mongoengine Document classes)
Output: one work record per gate-able node into --work-dir/<rid>.json:
        {
          "id":        "<fileid>::<Node>",
          "node":      "Todo",
          "archetype": "<full node/edge block for this schema (deterministic)>",
          "tag_field": "title",
          "manifest":  { ...behavioral_gate manifest, fully derived... },
          "source_ref":{"repo","path"}
        }

A node is gate-able (kept) only if it has a `tag_field` (a way to identify a probe
node). Nodes with no scalar fields are skipped.

Usage: ./farm_prep.py --models models.jsonl --work-dir WORK [--offset N --limit M]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import mongo_odm_to_jac as odm


def probe_value(name: str, jtype: str, tag_field: str, bool_field: str | None):
    """A JSON-encodable probe value for a create arg (gate substitutes <TAG>)."""
    if name == tag_field:
        return "<TAG>"
    base = jtype.replace(" | None", "").strip()
    if name == bool_field:
        return False                     # created False so complete_*->True is observable
    if base == "bool":
        return False
    if base == "int":
        return 1
    if base == "float":
        return 1.0
    if base.startswith("list"):
        return []
    if base == "dict":
        return {}
    if base == "bytes":
        return ""
    return "probe"                        # str and anything unmapped


def pick_update_field(spec: dict):
    """Choose a field the update-gate can flip to an observable sentinel.

    Prefer a bool (created False -> flip True); else a str/int field that isn't the
    tag (created "probe"/1 -> set to a sentinel). Returns (field, jtype, sentinel)
    or (None, None, None) if nothing settable -> update op is omitted (create/list/
    delete still gate hollowness).
    """
    tag = spec["tag_field"]
    if spec["bool_field"]:
        return spec["bool_field"], "bool", True
    for n, t, _hd in spec["scalar_fields"]:
        base = t.replace(" | None", "").strip()
        if n == tag:
            continue
        if base == "str":
            return n, "str", "__updated__"     # created "probe" -> observable change
        if base == "int":
            return n, "int", 999               # created 1 -> observable change
    return None, None, None


def derive_manifest(node: str, spec: dict) -> dict | None:
    tag = spec["tag_field"]
    if not tag:
        return None
    b = spec["bool_field"]
    create_args = {n: probe_value(n, t, tag, b) for n, t, _hd in spec["scalar_fields"]}
    man = {
        "node": node,
        "tag_field": tag,
        "create": {"walker": f"create_{node}", "args": create_args},
        "list":   {"walker": f"list_{node}"},
        "delete": {"walker": f"delete_{node}"},
    }
    ufield, _ujt, sentinel = pick_update_field(spec)
    if ufield:
        man["update"] = {"walker": f"update_{node}",
                         "update_field": ufield,        # composer prompt reads this
                         "args": {"val": sentinel},
                         "asserts": {ufield: sentinel}}
    return man


def _rid(fileid: str, node: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.:-]", "_", f"{fileid}::{node}")


def prep(models_path: str, work_dir: str, offset: int, limit: int) -> int:
    os.makedirs(work_dir, exist_ok=True)
    lines = [ln for ln in Path(models_path).read_text().splitlines() if ln.strip()]
    lines = lines[offset:offset + limit] if limit else lines[offset:]
    made = 0
    for ln in lines:
        rec = json.loads(ln)
        try:
            archetype, specs = odm.analyze(rec["source"])
        except SyntaxError:
            continue                      # not parseable python -> skip file
        by_name = {s["node"]: s for s in specs}
        for node, spec in by_name.items():
            if not spec["scalar_fields"]:
                continue
            man = derive_manifest(node, spec)
            if man is None:
                continue
            rid = _rid(str(rec.get("id", rec.get("path", "f"))), node)
            work = {
                "id": rid,
                "node": node,
                "archetype": archetype,
                "tag_field": spec["tag_field"],
                "scalar_fields": spec["scalar_fields"],
                "bool_field": spec["bool_field"],
                "update_field": man.get("update", {}).get("update_field"),
                "manifest": man,
                "source_ref": {"repo": rec.get("repo"), "path": rec.get("path")},
            }
            Path(work_dir, f"{rid}.json").write_text(json.dumps(work))
            made += 1
    print(f"prep: {len(lines)} files -> {made} node work-records in {work_dir}")
    return made


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", required=True)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    n = prep(args.models, args.work_dir, args.offset, args.limit)
    return 3 if n == 0 else 0            # rc=3 -> end of dataset (grind stop signal)


if __name__ == "__main__":
    sys.exit(main())
