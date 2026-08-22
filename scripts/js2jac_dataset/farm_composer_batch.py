#!/usr/bin/env python3
"""Batched composer walker-gen via cursor-agent -- FARM burndown driver.

Driven by scripts/lib/composer_harness.py (shared with js2jac_composer_batch):
MCP-strip, ask-mode, process-group teardown, durable per-call ledger, fsync'd
resumable-by-id output, transient-retry with backoff. The task here: given a
Mongo-derived Jac node archetype, AUTHOR the idiomatic CRUD walker-set for it.

Walker NAMES + entry contract are prescribed so the behavioral gate's manifest
(farm_prep.derive_manifest) matches deterministically; composer writes the actual
Jac bodies (real generation, gated by execution -- not templating).

Output contract: {"id","candidate"} JSONL -> farm_guard.py.
"""
from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "lib"))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from composer_harness import run_composer, add_common_args

_BLOCK = re.compile(r"===ID\s+(\S+?)===\s*(.*?)(?=(?:===ID\s+\S+?===)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)

SYS = (
    "You translate Mongo/Beanie data models into idiomatic Jac graph walkers. "
    "Jac uses braces and semicolons (never Python colons); nodes/edges persist on "
    "`root`; walkers carry request logic. Output valid Jac only, no prose."
)

IDIOM = """Idiom (from the shipped todo_app):
  walker:pub create_Todo {
      has title: str; has done: bool = False;
      can go with Root entry { new = here ++> Todo(title=self.title, done=self.done); report new; }
  }
  walker:pub list_Todo   { can go with Root entry { report [-->[?:Todo]]; } }
  walker:pub update_Todo { has val: bool; can go with Todo entry { here.done = self.val; report here; } }
  walker:pub delete_Todo { can go with Todo entry { del here; report "deleted"; } }
Rules: `here ++> Node(..)` creates+links to root; `[-->[?:Node]]` reads; mutate
fields in place (auto-persists, no .save()); `del here` deletes. Concrete types
only, never `any`. Do NOT redefine the given node/edge archetypes."""


def _fields_decl(scalars):
    return "; ".join(f"has {n}: {t}" for n, t, _hd in scalars)


def build_prompt(recs: list[dict]) -> str:
    parts = [SYS, "\n\n", IDIOM,
             "\n\nWrite the CRUD walker-set for EACH node below. Output EXACTLY, in order:\n"
             "===ID <id>===\n```jac\n<walkers only>\n```\n"
             "Required walkers per node X (these exact names):\n"
             "  create_X (has-params for every scalar field; `with Root entry`),\n"
             "  list_X (`with Root entry`, reports all X),\n"
             "  update_X (`has val: <type>`; `with X entry`; sets the named update field to self.val) -- only if an update field is given,\n"
             "  delete_X (`with X entry`, `del here`).\n"]
    for r in recs:
        uf = r.get("update_field")
        parts.append(
            f"\n===ID {r['id']}===  node {r['node']}"
            f"  (scalar fields: {_fields_decl(r['scalar_fields'])};"
            f" update field: {uf or 'none — omit update_' + r['node']})\n"
            f"ARCHETYPE (given, do not redefine):\n{r['archetype']}\n")
        ctx = r.get("handler_context")
        if ctx:
            parts.append(
                "REAL FastAPI+Beanie handler code for this node — translate its behavior "
                "faithfully into the walkers above (keep field-level updates, ownership, and "
                "response intent; the walkers must still satisfy the CRUD contract):\n"
                f"{ctx}\n")
    return "".join(parts)


def parse_result(text: str) -> dict[str, str]:
    out = {}
    for m in _BLOCK.finditer(text or ""):
        fm = _FENCE.search(m.group(2))
        if fm:
            out[m.group(1)] = fm.group(1).strip()
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    add_common_args(ap)
    args = ap.parse_args()
    return run_composer("farm-composer", args, build_prompt, parse_result)


if __name__ == "__main__":
    sys.exit(main())
