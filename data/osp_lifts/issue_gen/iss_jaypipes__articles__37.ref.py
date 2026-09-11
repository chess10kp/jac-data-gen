"""Reference harness for iss_jaypipes__articles__37."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_jaypipes__articles__37.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_jaypipes__articles__37.py")
_spec = importlib.util.spec_from_file_location("issue37", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_resource_store()
assert s0 == {
    "nodes_map": {},
    "resources": {},
    "traits": {},
    "tree": {},
    "rev": {},
    "groups": {},
    "nodes": {},
    "roots": [],
}
s0 = m.register_resource("provider", 100, m.TRAIT_CPU, s0)
assert s0["nodes_map"]["provider"] is True
assert s0["resources"]["provider"] == 100
assert s0["traits"]["provider"] == m.TRAIT_CPU
assert s0["roots"] == ["provider"]

s = m.fresh_resource_store()
m.register_resource("provider", 100, m.TRAIT_CPU, s)
m.register_resource("branch_a", 50, m.TRAIT_CPU, s)
m.register_resource("branch_b", 50, m.TRAIT_CPU, s)
m.register_resource("aggregate", 25, m.TRAIT_GPU, s)
m.add_tree_edge("provider", "branch_a", s)
m.add_tree_edge("provider", "branch_b", s)
m.add_tree_edge("branch_a", "aggregate", s)
m.add_tree_edge("branch_b", "aggregate", s)
got = m.subtree_reach("provider", s)
assert got == ["aggregate", "branch_a", "branch_b"]
assert sum(1 for nid in got if nid == "aggregate") == 1
assert m.direct_children("provider", s) == ["branch_a", "branch_b"]

s1 = m.fresh_resource_store()
for nid, res, trait in (
    ("provider", 10, m.TRAIT_CPU),
    ("branch_a", 5, m.TRAIT_CPU),
    ("branch_b", 5, m.TRAIT_CPU),
    ("aggregate", 3, m.TRAIT_GPU),
):
    m.register_resource(nid, res, trait, s1)
m.add_tree_edge("provider", "branch_b", s1)
m.add_tree_edge("branch_b", "aggregate", s1)
m.add_tree_edge("provider", "branch_a", s1)
m.add_tree_edge("branch_a", "aggregate", s1)
s2 = m.fresh_resource_store()
for nid, res, trait in (
    ("provider", 10, m.TRAIT_CPU),
    ("branch_a", 5, m.TRAIT_CPU),
    ("branch_b", 5, m.TRAIT_CPU),
    ("aggregate", 3, m.TRAIT_GPU),
):
    m.register_resource(nid, res, trait, s2)
m.add_tree_edge("provider", "branch_a", s2)
m.add_tree_edge("branch_a", "aggregate", s2)
m.add_tree_edge("provider", "branch_b", s2)
m.add_tree_edge("branch_b", "aggregate", s2)
assert m.subtree_reach("provider", s1) == m.subtree_reach("provider", s2)

s = m.fresh_resource_store()
m.register_resource("provider", 10, m.TRAIT_CPU, s)
try:
    m.add_tree_edge("provider", "missing", s)
    raise AssertionError("expected KeyError for unknown tree child")
except KeyError:
    pass
try:
    m.direct_children("missing", s)
    raise AssertionError("expected KeyError for unknown direct children lookup")
except KeyError:
    pass

s = m.fresh_resource_store()
m.register_resource("provider", 100, m.TRAIT_CPU, s)
m.register_resource("leaf", 80, m.TRAIT_CPU, s)
m.register_resource("peer", 70, m.TRAIT_GPU, s)
m.add_tree_edge("provider", "leaf", s)
m.add_group_link("leaf", "peer", s)
assert m.subtree_reach("provider", s) == ["leaf"]
assert m.closure_reach("provider", s) == ["leaf", "peer"]
try:
    m.add_group_link("leaf", "missing", s)
    raise AssertionError("expected KeyError for unknown group target")
except KeyError:
    pass

s = m.fresh_resource_store()
m.register_resource("provider", 100, m.TRAIT_CPU, s)
m.register_resource("gpu_leaf", 80, m.TRAIT_GPU, s)
m.register_resource("cpu_leaf", 60, m.TRAIT_CPU, s)
m.register_resource("outside", 90, m.TRAIT_GPU, s)
m.add_tree_edge("provider", "gpu_leaf", s)
m.add_tree_edge("provider", "cpu_leaf", s)
rep = m.hierarchy_report("provider", s, 70, m.TRAIT_GPU)
assert rep["direct"] == ["cpu_leaf", "gpu_leaf"]
assert rep["flat_matches"] == ["gpu_leaf", "outside"]
assert rep["subtree_matches"] == ["gpu_leaf"]
assert rep["subtree_match_count"] == 1
assert len(rep["closure"]) == len(rep["subtree"])
try:
    m.hierarchy_report("missing", s, 70, m.TRAIT_GPU)
    raise AssertionError("expected KeyError for unknown hierarchy report start")
except KeyError:
    pass
try:
    m.subtree_reach("missing", s)
    raise AssertionError("expected KeyError for unknown subtree reach start")
except KeyError:
    pass
try:
    m.closure_reach("missing", s)
    raise AssertionError("expected KeyError for unknown closure reach start")
except KeyError:
    pass
print("iss_jaypipes__articles__37 ref OK")
