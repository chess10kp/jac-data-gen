#!/usr/bin/env python3
"""Handler-translation prep: whole-app bundles -> per-node work records that carry
the REAL FastAPI+Beanie handler code as translation context.

The richer sibling of farm_prep.py. Where farm_prep gives composer only the lifted
schema (so it authors generic CRUD), this gives composer the actual route + db-layer
code for the node, so the produced walkers preserve real behavior (partial updates,
response shaping, ownership) -- while still being gated by the same CRUD round-trip
(which conventional FARM handlers satisfy).

Input:  farm_apps.jsonl bundles (from farm_app_bundle.py):
        {repo, files:{model|route|db|auth|schema:[{path,source}]}, nodes:[...]}
Output: work records (same shape as farm_prep + a `handler_context` string) into
        --work-dir/<rid>.json -> pack -> farm_composer_batch (handler-aware prompt)
        -> farm_guard (behavioral gate).

Node<->handler matching is by name mention (conventional layered FARM layout); the
context is budget-capped so tok/record stays near the 3k target.

Usage: ./farm_handler_prep.py --bundles farm_apps.jsonl --work-dir WORK [--offset --limit]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import mongo_odm_to_jac as odm
import farm_prep

PER_FILE_CAP = 1600
TOTAL_CAP = 3200


def _slices_for_node(files: list[dict], node: str) -> list[tuple[str, str]]:
    """Files (in role order) whose source mentions the node -> (path, source)."""
    rx = re.compile(rf"\b{re.escape(node)}\b")
    return [(f["path"], f["source"]) for f in files if rx.search(f["source"])]


def handler_context(bundle: dict, node: str) -> str:
    """Concatenate route+db (then auth) code mentioning `node`, budget-capped."""
    files = bundle["files"]
    ordered = (_slices_for_node(files.get("route", []), node)
               + _slices_for_node(files.get("db", []), node)
               + _slices_for_node(files.get("auth", []), node))
    out, used = [], 0
    for path, src in ordered:
        if used >= TOTAL_CAP:
            break
        snip = src[:PER_FILE_CAP]
        out.append(f"# --- {path} ---\n{snip}")
        used += len(snip)
    return "\n\n".join(out)


def prep(bundles_path: str, work_dir: str, offset: int, limit: int) -> int:
    Path(work_dir).mkdir(parents=True, exist_ok=True)
    lines = [ln for ln in Path(bundles_path).read_text().splitlines() if ln.strip()]
    lines = lines[offset:offset + limit] if limit else lines[offset:]
    made = 0
    for ln in lines:
        bundle = json.loads(ln)
        repo = bundle.get("repo", "app")
        for mf in bundle["files"].get("model", []):
            try:
                archetype, specs = odm.analyze(mf["source"])
            except SyntaxError:
                continue
            for spec in specs:
                node = spec["node"]
                if not spec["scalar_fields"]:
                    continue
                man = farm_prep.derive_manifest(node, spec)
                if man is None:
                    continue
                ctx = handler_context(bundle, node)
                if not ctx:
                    continue                       # no real handler -> use schema-only prep instead
                rid = farm_prep._rid(f"{repo}:{mf['path']}", node)
                work = {
                    "id": rid,
                    "node": node,
                    "archetype": archetype,
                    "tag_field": spec["tag_field"],
                    "scalar_fields": spec["scalar_fields"],
                    "bool_field": spec["bool_field"],
                    "update_field": man.get("update", {}).get("update_field"),
                    "handler_context": ctx,
                    "manifest": man,
                    "source_ref": {"repo": repo, "path": mf["path"]},
                }
                Path(work_dir, f"{rid}.json").write_text(json.dumps(work))
                made += 1
    print(f"handler-prep: {len(lines)} bundles -> {made} node work-records in {work_dir}")
    return made


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundles", required=True)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--offset", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    n = prep(args.bundles, args.work_dir, args.offset, args.limit)
    return 3 if n == 0 else 0


if __name__ == "__main__":
    sys.exit(main())
