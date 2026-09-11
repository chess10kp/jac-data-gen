"""Reference harness for iss_hoodiecollin__optigon__6."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_hoodiecollin__optigon__6.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_hoodiecollin__optigon__6.py")
_spec = importlib.util.spec_from_file_location("issue6", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_path_store()
assert s0 == {"nodes": {}, "deps": {}, "weights": {}, "has_negative": False, "unweighted": True}
s0 = m.register_node("s", s0)
assert "s" in s0["nodes"]
assert s0["deps"]["s"] == []
assert m.applicable_impls(s0) == [m.IMPL_BFS, m.IMPL_DIJKSTRA]

s = m.fresh_path_store()
m.register_node("s", s)
m.register_node("a", s)
m.register_node("b", s)
m.register_node("t", s)
m.add_sp_edge("s", "a", 1, s)
m.add_sp_edge("s", "b", 1, s)
m.add_sp_edge("a", "t", 1, s)
m.add_sp_edge("b", "t", 1, s)
reach = m.reach_nodes("s", s)
assert reach == ["a", "b", "t"]
dist = m.shortest_distances("s", s, m.IMPL_BFS)
assert dist["t"] == 2

s1 = m.fresh_path_store()
for nid in ("s", "a", "b", "t"):
    m.register_node(nid, s1)
m.add_sp_edge("s", "b", 1, s1)
m.add_sp_edge("b", "t", 1, s1)
m.add_sp_edge("s", "a", 1, s1)
m.add_sp_edge("a", "t", 1, s1)
s2 = m.fresh_path_store()
for nid in ("s", "a", "b", "t"):
    m.register_node(nid, s2)
m.add_sp_edge("s", "a", 1, s2)
m.add_sp_edge("a", "t", 1, s2)
m.add_sp_edge("s", "b", 1, s2)
m.add_sp_edge("b", "t", 1, s2)
assert m.reach_nodes("s", s1) == m.reach_nodes("s", s2)
assert m.shortest_distances("s", s1, m.IMPL_BFS) == m.shortest_distances("s", s2, m.IMPL_BFS)

s = m.fresh_path_store()
m.register_node("s", s)
try:
    m.add_sp_edge("s", "missing", 1, s)
    raise AssertionError("expected KeyError for unknown target node")
except KeyError:
    pass
try:
    m.reach_nodes("missing", s)
    raise AssertionError("expected KeyError for unknown start node")
except KeyError:
    pass

s = m.fresh_path_store()
m.register_node("s", s)
m.register_node("x", s)
m.register_node("t", s)
m.add_sp_edge("s", "x", 1, s)
m.add_sp_edge("x", "t", -2, s)
m.add_sp_edge("s", "t", 4, s)
assert m.applicable_impls(s) == [m.IMPL_BELLMAN]
dist = m.shortest_distances("s", s, m.IMPL_BELLMAN)
assert dist["t"] == -1
try:
    m.shortest_distances("s", s, m.IMPL_DIJKSTRA)
    raise AssertionError("expected ValueError for inapplicable impl")
except ValueError:
    pass

s = m.fresh_path_store()
m.register_node("s", s)
m.register_node("a", s)
m.register_node("t", s)
m.add_sp_edge("s", "a", 1, s)
m.add_sp_edge("a", "t", 1, s)
rep = m.path_report("s", s)
assert rep["applicable"] == [m.IMPL_BFS, m.IMPL_DIJKSTRA]
assert rep["agree"] is True
assert rep["distances"]["t"] == 2
assert rep["reach"] == ["a", "t"]
assert rep["reach_count"] == 2
print("iss_hoodiecollin__optigon__6 ref OK")
