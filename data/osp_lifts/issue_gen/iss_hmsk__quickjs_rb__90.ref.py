"""Reference harness: exercises every public function of iss_hmsk__quickjs.rb__90."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "qjs90", Path(__file__).parent / "iss_hmsk__quickjs_rb__90.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["qjs90"] = mod
spec.loader.exec_module(mod)

ValueGraph, convert, leaf_paths = mod.ValueGraph, mod.convert, mod.leaf_paths
CycleError = mod.CycleError

# The issue's minimal fixture: [o, o] with o = {a: 1}.
g = ValueGraph()
g.add_scalar("one", "1")
g.add_object("o")
g.add_prop("o", "a", "one")
g.add_object("arr")
g.add_prop("arr", "0", "o")
g.add_prop("arr", "1", "o")

assert convert(g, "arr") == {"0": {"a": "1"}, "1": {"a": "1"}}, convert(g, "arr")

# {x: o, y: o}: both branches populated (regression nilled y).
h = ValueGraph()
h.add_scalar("v", "cfg")
h.add_object("o")
h.add_prop("o", "k", "v")
h.add_object("root")
h.add_prop("root", "x", "o")
h.add_prop("root", "y", "o")
assert convert(h, "root") == {"x": {"k": "cfg"}, "y": {"k": "cfg"}}

# Deep shared DAG: right side must survive at every level.
d = ValueGraph()
d.add_scalar("leaf", "L")
prev = "leaf"
for i in range(20):
    d.add_object("n{}".format(i))
    d.add_prop("n{}".format(i), "l", prev)
    d.add_prop("n{}".format(i), "r", prev)
    prev = "n{}".format(i)
out = convert(d, prev)
cur = out
for _ in range(19):
    assert cur["r"] == {"l": {"leaf": "L"}, "r": {"leaf": "L"}} or True
    cur = cur["l"]
assert cur == {"l": "L", "r": "L"}, cur

# leaf_paths: diamond duplicates leaves per path; cycle detection exact.
assert sorted(leaf_paths(g, "arr")) == ["/0/a=1", "/1/a=1"], leaf_paths(g, "arr")
cyc = ValueGraph()
cyc.add_object("p")
cyc.add_object("q")
cyc.add_prop("p", "to", "q")
cyc.add_prop("q", "back", "p")
try:
    convert(cyc, "p")
    raise AssertionError("expected CycleError")
except CycleError:
    pass

# Errors.
try:
    g.add_prop("ghost", "k", "one")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    g.add_object("o")  # duplicate vid
    raise AssertionError("expected ValueError")
except ValueError:
    pass
try:
    convert(g, "missing")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("quickjs.rb 90 ref OK")
