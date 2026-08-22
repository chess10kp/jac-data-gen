#!/usr/bin/env python3
"""Deterministic Mongo ODM model -> Jac node/edge archetypes.

The Python analog of prisma_to_jac.py, for the FARM stack's M. Because the
backend is Python, we parse with the stdlib `ast` (robust) instead of regex.

Supported ODMs (typed subset — the deterministic core):
  Beanie    class X(Document):  fields; Link[Y]/BackLink[Y]; Indexed(T)
  ODMantic  class X(Model):     fields; Reference(); EmbeddedModel
  Pydantic  class X(BaseModel):  plain fields (treated as embeddable obj/node)

Mapping (all mechanical, no guessing):
  Document/Model class      -> node
  scalar annotation         -> has field: <jac type> [= default]
  Link[Y] / list[Link[Y]]   -> typed edge  X --> Y   (endpoint-typed: no W1051)
  Reference() to Y          -> typed edge  X --> Y
  BackLink[Y]               -> DROPPED (becomes an inverse traversal at call site)
  id / _id / PydanticObjectId -> DROPPED by default (jid is identity)
  Indexed(T)                -> unwrapped to T (index is a constraint, no behavior)
  Optional[T] / T | None    -> T | None
  Settings/Config inner cls -> ignored (collection name, not data shape)

Raw PyMongo / Motor (untyped dict access) is OUT OF SCOPE here — no schema to
lift; that is the LLM/heuristic tail. This handles the typed core only.

Usage:  ./mongo_odm_to_jac.py models.py [--keep-external-id]
"""
from __future__ import annotations

import argparse
import ast
import sys

SCALAR_MAP = {
    "str": "str", "int": "int", "float": "float", "bool": "bool",
    "bytes": "bytes", "dict": "dict", "list": "list", "set": "set",
    "datetime": "str", "date": "str", "time": "str", "Decimal": "float",
    "UUID": "str", "EmailStr": "str", "HttpUrl": "str", "AnyUrl": "str",
    "PydanticObjectId": "str", "ObjectId": "str", "Any": "any",
}

# base classes that mark an archetype we lift into a `node`
NODE_BASES = {"Document", "Model", "BaseModel", "EmbeddedModel", "EmbeddedDocument"}
# annotation wrappers that mean "reference to another model" -> edge
LINK_WRAPPERS = {"Link", "BackLink", "Reference"}
DROP_WRAPPERS = {"BackLink"}          # inverse side -> traversal, not stored
ID_NAMES = {"id", "_id"}


def snake(name: str) -> str:
    import re
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def unwrap_optional(node: ast.expr) -> tuple[ast.expr, bool]:
    """Peel Optional[X] and X | None -> (X, was_optional)."""
    # Optional[X]
    if isinstance(node, ast.Subscript) and _name(node.value) == "Optional":
        inner, _ = unwrap_optional(node.slice)
        return inner, True
    # X | None  (ast.BinOp with BitOr)
    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.BitOr):
        left_is_none = _is_none(node.left)
        right_is_none = _is_none(node.right)
        if right_is_none:
            inner, _ = unwrap_optional(node.left)
            return inner, True
        if left_is_none:
            inner, _ = unwrap_optional(node.right)
            return inner, True
    return node, False


def _is_none(node: ast.expr) -> bool:
    return (isinstance(node, ast.Constant) and node.value is None) or \
        _name(node) == "None"


def _name(node) -> str | None:
    """Best-effort dotted/name for a node: Name -> id, Attribute -> attr."""
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return node.attr
    return None


def _ref_name(node) -> str | None:
    """Like _name, but also resolves a string-literal forward ref: Link["Task"]."""
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return node.value
    return _name(node)


def link_target(node: ast.expr) -> tuple[str | None, bool, bool]:
    """If annotation references another model, return (Target, is_list, is_backlink).

    Handles Link[Y], BackLink[Y], list[Link[Y]], Indexed(...) unwrapping is done
    separately. Returns (None, False, False) when not a reference.
    """
    node, _ = unwrap_optional(node)
    is_list = False
    # list[...] / List[...]
    if isinstance(node, ast.Subscript) and _name(node.value) in ("list", "List"):
        node = node.slice
        is_list = True
        node, _ = unwrap_optional(node)
    if isinstance(node, ast.Subscript) and _name(node.value) in LINK_WRAPPERS:
        wrapper = _name(node.value)
        target = _ref_name(node.slice)          # resolves "ForwardRef" string literals
        return target, is_list, wrapper in DROP_WRAPPERS
    return None, is_list, False


def scalar_type(node: ast.expr) -> str:
    """Render a scalar annotation to a Jac type string."""
    node, is_opt = unwrap_optional(node)
    # Indexed(T) appears as annotation `Indexed(str, ...)` -> ast.Call; unwrap arg 0
    if isinstance(node, ast.Call) and _name(node.func) == "Indexed" and node.args:
        return scalar_type(node.args[0])
    if isinstance(node, ast.Subscript):
        base = _name(node.value)
        if base in ("list", "List"):
            inner = scalar_type(node.slice)
            t = f"list[{inner}]"
        elif base in ("dict", "Dict"):
            t = "dict"
        elif base in ("set", "Set"):
            inner = scalar_type(node.slice)
            t = f"set[{inner}]"
        else:
            t = SCALAR_MAP.get(base, "str")
        return f"{t} | None" if is_opt else t
    base = _name(node)
    t = SCALAR_MAP.get(base, "str") if base else "str"
    return f"{t} | None" if is_opt else t


def render_default(default: ast.expr | None, is_opt: bool) -> str:
    """Render ` = <val>` for a field default, or '' if none/unmappable."""
    if default is None:
        return " = None" if is_opt else ""
    # Field(default=...) / Field(...) — pull default= if literal, else drop
    if isinstance(default, ast.Call):
        fn = _name(default.func)
        if fn in ("Field",):
            for kw in default.keywords:
                if kw.arg in ("default",):
                    return render_default(kw.value, is_opt)
            # Field(default_factory=list) -> mutable default; emit empty literal
            for kw in default.keywords:
                if kw.arg == "default_factory":
                    fac = _name(kw.value)
                    if fac in ("list",):
                        return " = []"
                    if fac in ("dict",):
                        return " = {}"
        return " = None" if is_opt else ""     # runtime-generated default
    if isinstance(default, ast.Constant):
        v = default.value
        if v is None:
            return " = None"
        if isinstance(v, bool):
            return f" = {'True' if v else 'False'}"
        if isinstance(v, (int, float)):
            return f" = {v}"
        if isinstance(v, str):
            return f' = "{v}"'
    if isinstance(default, (ast.List, ast.Tuple)) and not default.elts:
        return " = []"
    if isinstance(default, ast.Dict) and not default.keys:
        return " = {}"
    return " = None" if is_opt else ""


def convert(text: str, keep_external_id: bool):
    tree = ast.parse(text)
    classes = {}   # name -> ClassDef
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            base_names = {_name(b) for b in node.bases}
            if base_names & NODE_BASES:
                classes[node.name] = node

    model_names = set(classes)
    edges = []          # (edge_name, parent, child)
    edge_seen = set()

    def fields_of(cd: ast.ClassDef):
        for stmt in cd.body:
            if isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name):
                yield stmt.target.id, stmt.annotation, stmt.value

    # Pass 1: relations -> edges. Edge names share the archetype namespace, so
    # they must not collide with a node/enum name or another edge (E0077).
    used_names = set(model_names)      # nodes (enums not lifted here, but reserve room)
    edge_names = set()
    for cname, cd in classes.items():
        for fname, ann, _val in fields_of(cd):
            target, _is_list, is_back = link_target(ann)
            if target and target in model_names and not is_back:
                ename = pascal(fname)
                if ename in used_names or ename in edge_names:
                    ename = f"{pascal(cname)}{pascal(fname)}"   # e.g. TaskProject
                key = (ename, cname, target, fname)
                if (cname, target, fname) not in edge_seen:
                    edge_seen.add((cname, target, fname))
                    edge_names.add(ename)
                    edges.append(key)

    # Pass 2: nodes
    out = []
    for cname, cd in classes.items():
        rendered = []   # (has_default, line)
        for fname, ann, val in fields_of(cd):
            if fname in ID_NAMES and not keep_external_id:
                continue
            target, _is_list, _is_back = link_target(ann)
            if target and target in model_names:
                continue                       # relation -> edge, not a scalar has
            _, is_opt = unwrap_optional(ann)
            t = scalar_type(ann)
            out_name = "ext_id" if (fname in ID_NAMES and keep_external_id) else snake(fname)
            dflt = render_default(val, is_opt)
            rendered.append((bool(dflt), f"    has {out_name}: {t}{dflt};"))
        # Jac (E2004): non-default fields must precede default-bearing ones
        ordered = [ln for hd, ln in rendered if not hd] + \
                  [ln for hd, ln in rendered if hd]
        body = "\n".join(ordered) if ordered else "    # (no scalar fields)"
        out.append(f"node {cname} {{\n{body}\n}}\n")

    for ename, parent, child, _fname in edges:
        out.append(f"edge {ename}: {parent} --> {child} {{}}\n")

    digest = ["# relation -> traversal (for the call-site rewriter):"]
    for ename, parent, child, _fname in edges:
        digest.append(
            f"#   {parent}.{snake(ename)}  ==  [{snake(parent)[0]} ->:{ename}:->]"
            f"   ({child}.<-  ==  [ <-:{ename}:<- ])")
    return "\n".join(out), "\n".join(digest)


def pascal(name: str) -> str:
    return name[:1].upper() + name[1:]


def analyze(text: str, keep_external_id: bool = False):
    """Structured per-node view for the burndown prep + auto-manifest.

    Returns (archetypes_str, specs) where specs is a list of:
      {node, scalar_fields: [(name, jac_type, has_default)],
       tag_field: str|None,   # a required str field to identify a probe node
       bool_field: str|None}  # a bool field the update-gate can flip to True
    Relation fields (edges) are excluded from scalar_fields.
    """
    archetypes, _digest = convert(text, keep_external_id)
    tree = ast.parse(text)
    classes = {}
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            if {_name(b) for b in node.bases} & NODE_BASES:
                classes[node.name] = node
    model_names = set(classes)

    specs = []
    for cname, cd in classes.items():
        scalars, tag_field, bool_field = [], None, None
        for stmt in cd.body:
            if not (isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name)):
                continue
            fname = stmt.target.id
            if fname in ID_NAMES and not keep_external_id:
                continue
            target, _il, _ib = link_target(stmt.annotation)
            if target and target in model_names:
                continue                       # relation -> edge, not scalar
            _, is_opt = unwrap_optional(stmt.annotation)
            jt = scalar_type(stmt.annotation)
            has_def = bool(render_default(stmt.value, is_opt))
            sname = snake(fname)
            scalars.append((sname, jt, has_def))
            if jt == "str" and not has_def and tag_field is None:
                tag_field = sname
            if jt == "bool" and bool_field is None:
                bool_field = sname
        if tag_field is None:                  # fall back to first str, else first field
            tag_field = next((n for n, t, _ in scalars if t == "str"), None) \
                or (scalars[0][0] if scalars else None)
        specs.append({"node": cname, "scalar_fields": scalars,
                      "tag_field": tag_field, "bool_field": bool_field})
    return archetypes, specs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("models")
    ap.add_argument("--keep-external-id", action="store_true")
    args = ap.parse_args()
    with open(args.models, encoding="utf-8") as fh:
        archetypes, digest = convert(fh.read(), args.keep_external_id)
    print(archetypes)
    print(digest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
