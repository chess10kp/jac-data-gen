"""Reference harness for iss_TheLarkInn__aipm__1297."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TheLarkInn__aipm__1297.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
g = _mod.BuildPerformanceGraph()
for uid, secs in [
    ("aws-lc-sys", 93.5),
    ("libgit2-sys", 75.2),
    ("syn", 27.1),
    ("rustls", 23.4),
    ("jsonschema", 22.9),
    ("reqwest", 5.0),
]:
    g.add_unit(uid, secs)
g.add_dependency("jsonschema", "reqwest")
g.add_dependency("reqwest", "rustls")
g.add_dependency("rustls", "aws-lc-sys")
assert g.reachable_from("jsonschema") == ["aws-lc-sys", "jsonschema", "reqwest", "rustls"]
assert g.path_exists("jsonschema", "aws-lc-sys") is True
assert g.path_exists("syn", "aws-lc-sys") is False
top = g.critical_path_units(3)
assert top == [("aws-lc-sys", 93.5), ("libgit2-sys", 75.2), ("syn", 27.1)]
share = g.wall_clock_share(["aws-lc-sys", "libgit2-sys"])
assert share == round((93.5 + 75.2) / (93.5 + 75.2 + 27.1 + 23.4 + 22.9 + 5.0), 4)

g.add_unit("bitflags@1.3.2", 0.1)
g.add_unit("bitflags@2.11.0", 0.1)
g.add_unit("tower@0.4.13", 0.1)
g.add_unit("tower@0.5.3", 0.1)
g.add_unit("tower-lsp", 1.0)
g.add_unit("aipm", 0.0)
g.add_dependency("aipm", "tower-lsp")
g.add_dependency("tower-lsp", "bitflags@1.3.2")
g.add_dependency("tower-lsp", "bitflags@2.11.0")
g.add_dependency("tower-lsp", "tower@0.4.13")
g.add_dependency("jsonschema", "tower@0.5.3")
g.add_dependency("jsonschema", "tower@0.4.13")

dup_input = {
    "bitflags": ["bitflags@1.3.2", "bitflags@2.11.0"],
    "tower": ["tower@0.4.13", "tower@0.5.3"],
    "syn": ["syn@2.0.117"],
}
lineages = g.duplicate_lineages(dup_input)
assert lineages == {"bitflags": ["aipm"], "tower": ["jsonschema"]}

try:
    g.add_dependency("missing", "syn")
    assert False, "expected unknown unit rejection"
except _mod.BuildGraphError:
    pass

try:
    g.reachable_from("ghost")
    assert False, "expected unknown root rejection"
except _mod.BuildGraphError:
    pass

try:
    g.path_exists("jsonschema", "ghost")
    assert False, "expected unknown target rejection"
except _mod.BuildGraphError:
    pass

assert g.wall_clock_share(["aws-lc-sys", "missing", "libgit2-sys"]) == g.wall_clock_share(
    ["aws-lc-sys", "libgit2-sys"]
)

g2 = _mod.BuildPerformanceGraph()
g2.add_unit("a", 10.0)
g2.add_unit("b", 30.0)
assert g2.wall_clock_share(["a", "missing", "b"]) == 1.0
print("iss_TheLarkInn__aipm__1297 ref OK")
