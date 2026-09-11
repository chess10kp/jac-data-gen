#!/usr/bin/env python3
"""Reference harness for iss_Teal-Insights__excel-grapher__353.py"""

import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "mod", HERE / "iss_Teal-Insights__excel-grapher__353.py"
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

SPECS = {
    "data": {"kind": "sheet"},
    "chart": {"kind": "chart"},
    "export": {"kind": "export"},
}
EDGES = [("chart", "data"), ("export", "chart")]

g = mod.load_workbook(SPECS, EDGES)
assert mod.serialize_node(g, "export") == (
    "node:export|kind:export|deps:["
    "node:chart|kind:chart|deps:[node:data|kind:sheet|deps:[]]]"
)
assert mod.serialize_node(g, "missing") == ""

g2 = mod.load_workbook(SPECS, EDGES)
first = mod.cached_serialize(g2, "export")
second = mod.cached_serialize(g2, "export")
assert first == second
assert "export" in g2._cache

g3 = mod.load_workbook(SPECS, EDGES)
mod.cached_serialize(g3, "export")
victims = mod.invalidate_node(g3, "data")
assert victims == ["chart", "data", "export"]
assert g3._cache == {}

DIAMOND_SPECS = {
    "hub": {"kind": "export"},
    "left": {"kind": "chart"},
    "right": {"kind": "chart"},
    "shared": {"kind": "sheet"},
}
DIAMOND_EDGES = [
    ("hub", "left"),
    ("hub", "right"),
    ("left", "shared"),
    ("right", "shared"),
]
g4 = mod.load_workbook(DIAMOND_SPECS, DIAMOND_EDGES)
assert mod.dependency_reach(g4, "shared") == ["hub", "left", "right", "shared"]
hub_blob = mod.serialize_node(g4, "hub")
assert "node:shared|kind:sheet|deps:[]" in hub_blob
assert hub_blob.count("node:shared|kind:sheet|deps:[]") == 1

assert mod.dependency_reach(g, "missing") == []
assert mod.invalidate_node(g, "missing") == []

print("ok")
