#!/usr/bin/env python3
"""Reference harness for iss_gastownhall__gascity__2903.py"""

import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_gastownhall__gascity__2903.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_bead_graph(
    {"w1": "open", "root": "closed", "base": "closed"},
    {"w1": "wisp", "root": "issue", "base": "issue"},
    [("w1", "root", "tracks"), ("root", "base", "parent-child")],
)
assert mod.dependency_closure(g, "w1") == ["base", "root"]
assert mod.protected_from_reap(g, "root")
assert mod.protected_from_reap(g, "base")
assert not mod.protected_from_reap(g, "w1")

g2 = mod.load_bead_graph(
    {"hub": "open", "left": "closed", "right": "closed", "cap": "closed"},
    {"hub": "wisp", "left": "wisp", "right": "wisp", "cap": "issue"},
    [
        ("hub", "left", "tracks"),
        ("hub", "right", "blocks"),
        ("left", "cap", "parent-child"),
        ("right", "cap", "parent-child"),
    ],
)
assert mod.dependency_closure(g2, "hub") == ["cap", "left", "right"]

g3 = mod.load_bead_graph(
    {"w": "closed", "t": "closed"},
    {"w": "wisp", "t": "issue"},
    [("w", "t", "tracks")],
)
assert not mod.protected_from_reap(g3, "t")

g4 = mod.load_bead_graph(
    {"a": "open", "b": "open", "c": "closed"},
    {"a": "issue", "b": "wisp", "c": "wisp"},
    [],
)
assert mod.idle_open_counts(g4) == (1, 1)

g5 = mod.load_bead_graph(
    {"a": "open", "b": "open", "c": "open"},
    {"a": "wisp", "b": "wisp", "c": "wisp"},
    [("a", "b", "tracks"), ("b", "c", "blocks"), ("c", "a", "parent-child")],
)
assert mod.dependency_closure(g5, "a") == ["b", "c"]

assert mod.dependency_closure(g, "missing") == []
assert not mod.protected_from_reap(g, "missing")

print("ok")
