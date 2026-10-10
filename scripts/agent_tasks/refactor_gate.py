#!/usr/bin/env python3
"""Idiom gate for `refactor` agent tasks.

A refactor task hands the agent working but un-idiomatic Jac and asks for an
idiomatic rewrite that preserves behaviour. Behaviour is policed by the hidden
tests; THIS gate polices the structure, using only compiler-backed views (no
regex over source, so comments / string literals / dead text can't satisfy it):

  * `jac code map`              archetype kinds + typed field lists
  * `jac tool ir ast <file>`    full typed AST dump; for a module the dump also
                                contains its `.impl.jac` annex bodies

Metrics (summed over every module file in the workspace except annexes and the
grader test module):

  arch.<kind>        count of node / edge / walker / obj / class archetypes
  enums              enum declarations
  edge_refs          edge reference expressions  [-->], [here ->:E:->], ...
  edge_filters       typed / predicate filters inside edge refs  [?:X, f == v], :E:f > 0:
  visits             visit statements
  spawns             spawn expressions (`x spawn W()`)
  connects           connect operators (++>, +>:E:+>)
  reports            report statements
  isinstance_calls   isinstance(...) calls (manual type dispatch)
  dict_fields        `has` fields whose declared type mentions dict
  glob_collections   module-level `glob` holding a dict/list
  impl_defs          impl blocks (inline + annex)
  annex_impls        impl blocks that live in a .impl.jac annex file
  modules            number of module (non-annex) .jac files
  field:<Arch>.<f>   declared type string of a field (from jac code map), "" if absent
  has_arch:<Name>    1 if an archetype with that name exists, else 0

A task lists its targets in task.json:
  "idiom_targets": [{"metric": "arch.node", "op": ">=", "value": 2, "desc": ">=2 node types"}, ...]

CLI:  refactor_gate.py <workspace> --task <task.json>   -> JSON {ok, metrics, results}
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

TEST_MODULE = "grader_tests.jac"
_LINE = re.compile(r"^\S+ - \S+\t(?P<pre>[| ]*)(?P<plus>\+-- )?(?P<kind>[A-Za-z]+)(?P<rest>.*)$")


class AstNode:
    __slots__ = ("kind", "rest", "children", "depth")

    def __init__(self, kind: str, rest: str, depth: int):
        self.kind, self.rest, self.depth, self.children = kind, rest, depth, []

    def walk(self):
        yield self
        for c in self.children:
            yield from c.walk()

    @property
    def name(self) -> str:
        return self.rest.split(" - ")[0].strip().rstrip(",").strip() if self.rest else ""


def parse_ast(text: str) -> list[AstNode]:
    """Parse `jac tool ir ast` output into trees (one root per Module)."""
    roots: list[AstNode] = []
    stack: list[AstNode] = []
    for line in text.splitlines():
        m = _LINE.match(line)
        if not m:
            continue
        depth = len(m.group("pre")) // 4 + 1 if m.group("plus") else 0
        rest = m.group("rest").strip()
        rest = rest[2:] if rest.startswith("- ") else rest
        node = AstNode(m.group("kind"), rest, depth)
        while stack and stack[-1].depth >= depth:
            stack.pop()
        if stack:
            stack[-1].children.append(node)
        else:
            roots.append(node)
        stack.append(node)
    return roots


def _run(cmd: list[str], cwd: Path, timeout: float = 180) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT"


def module_files(wd: Path) -> list[Path]:
    out = []
    for p in sorted(wd.rglob("*.jac")):
        rel = p.relative_to(wd)
        if any(part in ("__jac_gen__", ".jac", "node_modules") for part in rel.parts):
            continue
        if p.name.endswith(".impl.jac") or ".impl" in rel.parts[:-1] or p.name.endswith(".test.jac"):
            continue
        if p.name == TEST_MODULE or p.name.startswith("grader_"):
            continue
        out.append(p)
    return out


def annex_files(wd: Path) -> list[Path]:
    return [p for p in sorted(wd.rglob("*.impl.jac"))
            if "__jac_gen__" not in p.parts and ".jac" not in p.relative_to(wd).parts]


def _subtree_has(node: AstNode, kinds: set[str], names: set[str] | None = None) -> bool:
    for n in node.walk():
        if n.kind in kinds and (names is None or n.name in names):
            return True
    return False


def collect(wd: Path, jac: str = "jac") -> dict[str, Any]:
    m: dict[str, Any] = {k: 0 for k in (
        "arch.node", "arch.edge", "arch.walker", "arch.obj", "arch.class", "enums", "edge_refs",
        "edge_filters", "visits", "spawns", "connects", "reports", "isinstance_calls", "dict_fields",
        "glob_collections", "impl_defs", "annex_impls")}
    errors: list[str] = []
    mods = module_files(wd)
    m["modules"] = len(mods)
    for f in mods:
        rc, out = _run([jac, "tool", "ir", "ast", str(f.relative_to(wd))], wd)
        roots = parse_ast(out)
        if rc != 0 or not roots:
            errors.append(f"ast {f.name}: rc={rc} {out[-300:]}")
            continue
        for root in roots:
            for n in root.walk():
                k = n.kind
                if k == "Archetype":
                    tok = next((c for c in n.children if c.kind == "Token"), None)
                    kw = tok.name if tok else ""
                    if f"arch.{kw}" in m:
                        m[f"arch.{kw}"] += 1
                elif k == "Enum":
                    m["enums"] += 1
                elif k == "EdgeRefTrailer":
                    m["edge_refs"] += 1
                    m["edge_filters"] += sum(1 for d in n.walk() if d.kind == "FilterCompr")
                elif k == "VisitStmt":
                    m["visits"] += 1
                elif k == "ConnectOp":
                    m["connects"] += 1
                elif k == "ReportStmt":
                    m["reports"] += 1
                elif k == "ImplDef":
                    m["impl_defs"] += 1
                elif k == "Token" and n.name == "spawn":
                    m["spawns"] += 1
                elif k == "FuncCall":
                    callee = next((c for c in n.children if c.kind == "Name"), None)
                    if callee and callee.name == "isinstance":
                        m["isinstance_calls"] += 1
                elif k == "HasVar":
                    tag = next((c for c in n.children if c.kind == "SubTag"), None)
                    if tag and _subtree_has(tag, {"BuiltinType", "Name"}, {"dict"}):
                        m["dict_fields"] += 1
                elif k == "GlobalVars":
                    if _subtree_has(n, {"DictVal", "ListVal", "ListCompr", "DictCompr"}) or \
                            _subtree_has(n, {"BuiltinType"}, {"dict", "list"}):
                        m["glob_collections"] += 1
    for f in annex_files(wd):
        rc, out = _run([jac, "tool", "ir", "ast", str(f.relative_to(wd))], wd)
        roots = parse_ast(out)
        if rc != 0 or not roots:
            errors.append(f"ast {f.name}: rc={rc} {out[-300:]}")
            continue
        m["annex_impls"] += sum(1 for r in roots for n in r.walk() if n.kind == "ImplDef")
    # jac code map: archetype field types (resolved from cwd's module set)
    fields: dict[str, str] = {}
    archs: set[str] = set()
    rc, out = _run([jac, "code", "map"], wd)  # no target: whole module set under cwd
    try:
        data = json.loads(out[out.index("{"):])
    except Exception:
        data = {}
        errors.append(f"code map: rc={rc} {out[-300:]}")
    for a in data.get("archetypes", []):
        if Path(a.get("file", "")).name == TEST_MODULE:
            continue
        archs.add(a["name"])
        for fd in a.get("fields", []):
            nm, _, ty = fd.partition(":")
            fields[f"{a['name']}.{nm.strip()}"] = ty.strip()
    m["_fields"] = fields
    m["_archetypes"] = sorted(archs)
    m["_errors"] = errors
    return m


OPS = {
    ">=": lambda a, b: a >= b, "<=": lambda a, b: a <= b, "==": lambda a, b: a == b,
    "!=": lambda a, b: a != b, ">": lambda a, b: a > b, "<": lambda a, b: a < b,
}


def metric_value(m: dict[str, Any], name: str) -> Any:
    if name.startswith("field:"):
        return m["_fields"].get(name[len("field:"):], "")
    if name.startswith("has_arch:"):
        return int(name[len("has_arch:"):] in m["_archetypes"])
    return m.get(name, 0)


def evaluate(m: dict[str, Any], targets: list[dict]) -> tuple[bool, list[dict]]:
    res = []
    for t in targets:
        v = metric_value(m, t["metric"])
        ok = OPS[t["op"]](v, t["value"])
        res.append({"metric": t["metric"], "op": t["op"], "want": t["value"], "got": v, "ok": ok,
                    "desc": t.get("desc", "")})
    return all(r["ok"] for r in res) and not m["_errors"], res


def gate(wd: Path, targets: list[dict], jac: str = "jac") -> dict[str, Any]:
    m = collect(wd, jac)
    ok, res = evaluate(m, targets)
    return {"ok": ok, "results": res, "errors": m["_errors"],
            "metrics": {k: v for k, v in m.items() if not k.startswith("_")}}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("workspace", type=Path)
    ap.add_argument("--task", type=Path, required=True)
    ap.add_argument("--jac", default="jac")
    a = ap.parse_args()
    targets = json.loads(a.task.read_text())["idiom_targets"]
    r = gate(a.workspace.resolve(), targets, a.jac)
    print(json.dumps(r, indent=1))
    return 0 if r["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
