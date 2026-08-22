#!/usr/bin/env python3
"""Deterministic schema.prisma -> Jac node/edge archetypes.

No LLM. Prisma's schema is a regular-enough grammar that relations, scalars, and
enums lower mechanically. This produces the project-wide archetype block that the
per-record LLM call-site rewriter consumes (see PERSISTENCE_MAPPING.md).

Design decisions (all mechanical, no guessing):
  model            -> node
  scalar field     -> has field: <jac type> [= default]
  relation pair    -> ONE typed edge  Parent --> Child   (endpoint-typed: no W1051)
  FK scalar        -> DROPPED (the edge replaces it)
  back-relation    -> DROPPED (it becomes a traversal at the call site)
  @id field        -> DROPPED by default (jid is identity); --keep-external-id keeps it
  enum             -> enum
  @@unique/@@index -> ignored (constraint, no behavior at stake)

Usage:  ./prisma_to_jac.py schema.prisma [--keep-external-id]
"""
from __future__ import annotations

import argparse
import re
import sys

SCALAR_MAP = {
    "String": "str", "Int": "int", "BigInt": "int", "Float": "float",
    "Decimal": "float", "Boolean": "bool", "DateTime": "str",  # ISO string
    "Json": "dict", "Bytes": "bytes",
}


def strip_comments(text: str) -> str:
    # line comments only; prisma has no block comments
    return "\n".join(re.sub(r"//.*$", "", ln) for ln in text.splitlines())


def snake(name: str) -> str:
    s = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
    return s


def pascal(name: str) -> str:
    return name[:1].upper() + name[1:]


def parse_blocks(text: str, kind: str):
    """Yield (name, body) for every `kind Name { ... }` block."""
    for m in re.finditer(rf"\b{kind}\s+(\w+)\s*\{{(.*?)\}}", text, re.S):
        yield m.group(1), m.group(2)


def parse_field(line: str):
    """Parse one model line -> dict, or None for block-attrs/blank."""
    line = line.strip()
    if not line or line.startswith("@@"):
        return None
    m = re.match(r"(\w+)\s+([A-Za-z0-9_]+)(\[\])?(\?)?\s*(.*)$", line)
    if not m:
        return None
    name, base, is_list, is_opt, attrs = m.groups()
    rel = re.search(r"@relation\(([^)]*)\)", attrs or "")
    rel_fields, rel_refs = [], []
    if rel:
        fm = re.search(r"fields:\s*\[([^\]]*)\]", rel.group(1))
        rm = re.search(r"references:\s*\[([^\]]*)\]", rel.group(1))
        if fm:
            rel_fields = [x.strip() for x in fm.group(1).split(",") if x.strip()]
        if rm:
            rel_refs = [x.strip() for x in rm.group(1).split(",") if x.strip()]
    default = None
    dm = re.search(r"@default\(([^)]*)\)", attrs or "")
    if dm:
        default = dm.group(1).strip()
    return {
        "name": name, "base": base, "list": bool(is_list), "opt": bool(is_opt),
        "attrs": attrs or "", "is_id": "@id" in (attrs or ""),
        "rel": bool(rel), "rel_fields": rel_fields, "rel_refs": rel_refs,
        "default": default,
    }


def jac_default(f, base_jac):
    """Render `= <val>` for a scalar field, or '' if none/unmappable."""
    d = f["default"]
    if d is None:
        return " = None" if f["opt"] else ""
    if d in ("now()", "auto()", "cuid()", "uuid()", "dbgenerated()") or "(" in d:
        return " = None" if f["opt"] else ""   # runtime-generated: no static default
    if base_jac == "bool":
        return f" = {'True' if d == 'true' else 'False'}"
    if base_jac in ("int", "float"):
        return f" = {d}"
    if base_jac == "str":
        return f" = {d}" if d.startswith('"') else f' = "{d}"'
    # enum-valued field: base_jac is the enum name, d a bare member (e.g. EYE)
    if d.isidentifier():
        return f" = {base_jac}.{d}"
    return ""


def convert(text: str, keep_external_id: bool):
    text = strip_comments(text)
    enums = {name: re.findall(r"\b(\w+)\b", body)
             for name, body in parse_blocks(text, "enum")}
    models = {}
    for name, body in parse_blocks(text, "model"):
        fields = [f for f in (parse_field(ln) for ln in body.splitlines()) if f]
        models[name] = fields

    model_names = set(models)
    edges = []          # (edge_name, parent, child)
    edge_seen = set()

    # Relations: the FK-holding side carries @relation(fields:[...]). parent = field type.
    for child, fields in models.items():
        for f in fields:
            if f["rel"] and f["base"] in model_names and f["rel_fields"]:
                parent = f["base"]
                # name the edge after the parent's back-relation list field, else child
                back = next((pf["name"] for pf in models[parent]
                             if pf["base"] == child and pf["list"]), None)
                ename = pascal(back) if back else pascal(child)
                key = (ename, parent, child)
                if key not in edge_seen:
                    edge_seen.add(key)
                    edges.append(key)

    # Fields to drop per model: relations (either side) + FK scalars (+ id)
    def dropped(model):
        drop = set()
        fks = set()
        for f in models[model]:
            if f["rel"]:
                drop.add(f["name"])
                fks.update(f["rel_fields"])
            if f["base"] in model_names:      # bare relation object / list
                drop.add(f["name"])
        drop |= fks
        return drop

    out = []
    for name in enums:
        out.append(f"enum {name} {{\n    " +
                   ",\n    ".join(enums[name]) + "\n}\n")

    for model, fields in models.items():
        drop = dropped(model)
        rendered = []   # (has_default, line)
        for f in fields:
            if f["name"] in drop:
                continue
            if f["is_id"] and not keep_external_id:
                continue
            base_jac = SCALAR_MAP.get(f["base"]) or (
                f["base"] if f["base"] in enums else "str")
            t = f"list[{base_jac}]" if f["list"] else base_jac
            if f["opt"] and not f["list"]:
                t = f"{t} | None"
            fname = "ext_id" if (f["is_id"] and keep_external_id) else snake(f["name"])
            dflt = jac_default(f, base_jac)
            rendered.append((bool(dflt), f"    has {fname}: {t}{dflt};"))
        # Jac (E2004): non-default fields must precede default-bearing ones; stable within groups
        ordered = [ln for hd, ln in rendered if not hd] + \
                  [ln for hd, ln in rendered if hd]
        body = "\n".join(ordered) if ordered else "    # (no scalar fields)"
        out.append(f"node {model} {{\n{body}\n}}\n")

    for ename, parent, child in edges:
        out.append(f"edge {ename}: {parent} --> {child} {{}}\n")

    # Traversal digest: what the call-site rewriter feeds the LLM
    digest = ["# relation -> traversal (for the call-site rewriter):"]
    for ename, parent, child in edges:
        digest.append(
            f"#   {parent}.{snake(ename)}  ==  [{snake(parent)[0]} ->:{ename}:->]"
            f"   ({child}.<-  ==  [ <-:{ename}:<- ])")
    return "\n".join(out), "\n".join(digest)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("schema")
    ap.add_argument("--keep-external-id", action="store_true")
    args = ap.parse_args()
    with open(args.schema, encoding="utf-8") as fh:
        archetypes, digest = convert(fh.read(), args.keep_external_id)
    print(archetypes)
    print(digest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
