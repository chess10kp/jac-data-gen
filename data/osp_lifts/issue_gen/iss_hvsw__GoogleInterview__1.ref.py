"""Reference harness for iss_hvsw__GoogleInterview__1."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_hvsw__GoogleInterview__1.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_hvsw__GoogleInterview__1.py")
_spec = importlib.util.spec_from_file_location("issue1", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_graph_store()
assert s0 == {"nodes": {}, "deps": {}, "rev": {}}
s0 = m.register_node("s", s0)
assert "s" in s0["nodes"]
assert s0["deps"]["s"] == []
assert s0["rev"]["s"] == []

s = m.fresh_graph_store()
m.register_node("s", s)
m.register_node("a", s)
m.register_node("b", s)
m.register_node("t", s)
m.add_graph_edge("s", "a", s)
m.add_graph_edge("s", "b", s)
m.add_graph_edge("a", "t", s)
m.add_graph_edge("b", "t", s)
bfs = m.bfs_reach("s", s)
dfs = m.dfs_reach("s", s)
assert bfs == ["a", "b", "t"]
assert dfs == ["a", "b", "t"]
assert sum(1 for nid in bfs if nid == "t") == 1

s1 = m.fresh_graph_store()
for nid in ("s", "a", "b", "t"):
    m.register_node(nid, s1)
m.add_graph_edge("s", "b", s1)
m.add_graph_edge("b", "t", s1)
m.add_graph_edge("s", "a", s1)
m.add_graph_edge("a", "t", s1)
s2 = m.fresh_graph_store()
for nid in ("s", "a", "b", "t"):
    m.register_node(nid, s2)
m.add_graph_edge("s", "a", s2)
m.add_graph_edge("a", "t", s2)
m.add_graph_edge("s", "b", s2)
m.add_graph_edge("b", "t", s2)
assert m.bfs_reach("s", s1) == m.bfs_reach("s", s2)
assert m.dfs_reach("s", s1) == m.dfs_reach("s", s2)

s = m.fresh_graph_store()
m.register_node("s", s)
try:
    m.add_graph_edge("s", "missing", s)
    raise AssertionError("expected KeyError for unknown target node")
except KeyError:
    pass
try:
    m.bfs_reach("missing", s)
    raise AssertionError("expected KeyError for unknown start node")
except KeyError:
    pass

s = m.fresh_graph_store()
m.register_node("a", s)
m.register_node("b", s)
m.register_node("c", s)
m.add_graph_edge("a", "b", s)
m.add_graph_edge("b", "c", s)
m.add_graph_edge("c", "a", s)
assert m.detect_cycle(s) is True
rep = m.graph_report("a", s)
assert rep["has_cycle"] is True

s = m.fresh_graph_store()
m.register_node("s", s)
m.register_node("a", s)
m.register_node("t", s)
m.add_graph_edge("s", "a", s)
m.add_graph_edge("a", "t", s)
rep = m.graph_report("s", s)
assert rep["has_cycle"] is False
assert rep["reach_count"] == 2
assert rep["bfs_reach"] == ["a", "t"]
assert rep["dfs_reach"] == ["a", "t"]
try:
    m.graph_report("missing", s)
    raise AssertionError("expected KeyError for unknown report start")
except KeyError:
    pass
print("iss_hvsw__GoogleInterview__1 ref OK")
