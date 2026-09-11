import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_0cwa__avbcompose__14",
    Path(__file__).with_name("iss_0cwa__avbcompose__14.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

SourceGraph = mod.SourceGraph

g = SourceGraph()
g.add_project("manifest")
g.add_project("device", parent="manifest")
g.add_project("vendor", parent="manifest")
g.add_project("hal", parent="device")
g.add_project("app", parent="vendor")
assert g.active_projects() == ["app", "device", "hal", "manifest", "vendor"]
assert g.cascade_remove("device") == ["device", "hal"]
assert g.active_projects() == ["app", "manifest", "vendor"]
assert g.cascade_remove("vendor") == ["app", "vendor"]
assert g.active_projects() == ["manifest"]

deep = SourceGraph()
for i in range(5):
    deep.add_project("p%d" % i, parent=("p%d" % (i - 1)) if i else None)
assert deep.cascade_remove("p2") == ["p2", "p3", "p4"]

cyc = SourceGraph()
cyc.parent_of["a"] = "b"
cyc.parent_of["b"] = "a"
cyc.children_of["a"] = ["b"]
cyc.children_of["b"] = ["a"]
assert sorted(cyc._collect_subtree("a")) == ["a", "b"]

try:
    g.cascade_remove("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

print("ok")
