#!/usr/bin/env python3
"""Reference harness for iss_snissn__gomap__1897.py"""

import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_snissn__gomap__1897.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_rows(
    {
        "row": {"offset": 0, "width": 16},
        "norm": {"offset": 5, "width": 4},
        "adj": {"offset": 16, "width": 8},
    },
    {"norm": "row", "adj": "row"},
    {"row": ["norm", "adj"]},
    align=8,
)
assert mod.is_aligned(g, "row")
assert not mod.is_aligned(g, "norm")
assert mod.padding_bytes(g, "norm") == 3
assert mod.lineage_closure(g, "row") == ["norm", "adj"]
assert mod.dependency_reach(g, "row") == ["adj", "norm"]

g2 = mod.load_rows(
    {
        "hub": {"offset": 0, "width": 8},
        "left": {"offset": 8, "width": 8},
        "right": {"offset": 16, "width": 8},
        "cap": {"offset": 24, "width": 8},
    },
    {},
    {"hub": ["left", "right"], "left": ["cap"], "right": ["cap"]},
)
assert mod.dependency_reach(g2, "hub") == ["cap", "left", "right"]

g3 = mod.load_rows(
    {
        "a": {"offset": 0, "width": 8},
        "b": {"offset": 8, "width": 8},
        "c": {"offset": 16, "width": 8},
    },
    {"b": "a", "c": "b"},
    {"a": ["b"], "b": ["c"], "c": ["a"]},
)
assert mod.lineage_closure(g3, "a") == ["b", "c"]
assert mod.dependency_reach(g3, "a") == ["b", "c"]

assert mod.lineage_closure(g, "missing") == []
assert mod.dependency_reach(g, "missing") == []
assert mod.padding_bytes(g, "missing") == 0

print("ok")
