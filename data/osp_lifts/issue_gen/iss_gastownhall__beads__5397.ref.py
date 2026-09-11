"""Reference harness for iss_gastownhall__beads__5397."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_gastownhall__beads__5397.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_gastownhall__beads__5397.py")
_spec = importlib.util.spec_from_file_location("issue5397", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

assert m.ENGINE_OPEN_MS == 1800
assert m.PER_NODE_MS == 250
assert m.LIGHT_PER_NODE_MS == 110

s0 = m.fresh_tree_store()
assert s0 == {"nodes_map": {}, "children": {}, "rev": {}, "nodes": {}}
s0 = m.register_node("root", s0)
assert s0["nodes_map"]["root"] is True
assert s0["nodes"]["root"].nid == "root"

s = m.fresh_tree_store()
m.register_node("root", s)
m.register_node("child_a", s)
m.register_node("child_b", s)
m.register_node("leaf", s)
m.add_parent_edge("root", "child_a", s)
m.add_parent_edge("root", "child_b", s)
m.add_parent_edge("child_a", "leaf", s)
m.add_parent_edge("child_b", "leaf", s)
got = m.reachable_descendants("root", s)
assert got == ["child_a", "leaf", "child_b"]
assert sum(1 for nid in got if nid == "leaf") == 1

s1 = m.fresh_tree_store()
for nid in ("root", "child_a", "child_b", "leaf"):
    m.register_node(nid, s1)
m.add_parent_edge("root", "child_b", s1)
m.add_parent_edge("child_b", "leaf", s1)
m.add_parent_edge("root", "child_a", s1)
m.add_parent_edge("child_a", "leaf", s1)
s2 = m.fresh_tree_store()
for nid in ("root", "child_a", "child_b", "leaf"):
    m.register_node(nid, s2)
m.add_parent_edge("root", "child_a", s2)
m.add_parent_edge("child_a", "leaf", s2)
m.add_parent_edge("root", "child_b", s2)
m.add_parent_edge("child_b", "leaf", s2)
assert m.reachable_descendants("root", s1) == m.reachable_descendants("root", s2)

s = m.fresh_tree_store()
m.register_node("root", s)
try:
    m.direct_children("missing", s)
    raise AssertionError("expected KeyError for unknown node")
except KeyError:
    pass
try:
    m.add_parent_edge("root", "missing", s)
    raise AssertionError("expected KeyError for unknown parent edge")
except KeyError:
    pass

s = m.fresh_tree_store()
m.register_node("root", s)
m.register_node("child_a", s)
m.add_parent_edge("root", "child_a", s)
assert m.list_cost_ms("root", s, journal_heavy=False) == m.ENGINE_OPEN_MS + 2 * m.LIGHT_PER_NODE_MS
assert m.list_cost_ms("root", s, journal_heavy=True) == m.ENGINE_OPEN_MS + 2 * m.PER_NODE_MS

s = m.fresh_tree_store()
m.register_node("root", s)
m.register_node("child_a", s)
m.add_parent_edge("root", "child_a", s)
rep = m.descendant_report("root", s, journal_heavy=False)
assert rep == {
    "direct": ["child_a"],
    "reach": ["child_a"],
    "reach_count": 1,
    "nodes_walked": 2,
    "cost_ms": m.ENGINE_OPEN_MS + 2 * m.LIGHT_PER_NODE_MS,
    "journal_heavy": False,
}
print("iss_gastownhall__beads__5397 ref OK")
