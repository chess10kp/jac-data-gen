"""Reference harness for iss_heimdalr__dag__5."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_heimdalr__dag__5.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_heimdalr__dag__5.py")
_spec = importlib.util.spec_from_file_location("issue5", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_dag_store()
assert s0 == {
    "vertices": {},
    "deps": {},
    "rev": {},
    "nodes": {},
    "ancestors_cache": {},
    "descendants_cache": {},
}
s0 = m.register_vertex("a", s0)
assert s0["vertices"]["a"] is True
assert s0["deps"]["a"] == []
assert s0["rev"]["a"] == []

s = m.fresh_dag_store()
m.register_vertex("a", s)
m.register_vertex("b", s)
m.register_vertex("c", s)
m.register_vertex("d", s)
m.add_dag_edge("a", "b", s)
m.add_dag_edge("a", "c", s)
m.add_dag_edge("b", "d", s)
m.add_dag_edge("c", "d", s)
got = m.get_descendants("a", s)
assert got == ["b", "c", "d"]
assert got == m.get_descendants("a", s)
assert sum(1 for vid in got if vid == "d") == 1
rep = m.edge_add_report("b", "d", s)
assert rep == {"descendant_count": 0, "ancestor_count": 1, "cache_keys": 1}

s1 = m.fresh_dag_store()
for vid in ("a", "b", "c", "d"):
    m.register_vertex(vid, s1)
m.add_dag_edge("a", "c", s1)
m.add_dag_edge("c", "d", s1)
m.add_dag_edge("a", "b", s1)
m.add_dag_edge("b", "d", s1)
s2 = m.fresh_dag_store()
for vid in ("a", "b", "c", "d"):
    m.register_vertex(vid, s2)
m.add_dag_edge("a", "b", s2)
m.add_dag_edge("b", "d", s2)
m.add_dag_edge("a", "c", s2)
m.add_dag_edge("c", "d", s2)
assert m.get_descendants("a", s1) == m.get_descendants("a", s2)

s = m.fresh_dag_store()
m.register_vertex("a", s)
try:
    m.add_dag_edge("a", "missing", s)
    raise AssertionError("expected KeyError for unknown target vertex")
except KeyError:
    pass
try:
    m.get_ancestors("missing", s)
    raise AssertionError("expected KeyError for unknown ancestor lookup")
except KeyError:
    pass

s = m.fresh_dag_store()
m.register_vertex("a", s)
m.register_vertex("b", s)
m.register_vertex("c", s)
m.add_dag_edge("a", "b", s)
anc = m.get_ancestors("b", s)
assert anc == ["a"]
m.add_dag_edge("b", "c", s)
assert "c" not in s["ancestors_cache"]
assert m.get_ancestors("c", s) == ["a", "b"]

s = m.fresh_dag_store()
m.register_vertex("a", s)
m.register_vertex("b", s)
m.add_dag_edge("a", "b", s)
try:
    m.add_dag_edge("a", "b", s)
    raise AssertionError("expected ValueError for duplicate edge")
except ValueError:
    pass
try:
    m.add_dag_edge("b", "a", s)
    raise AssertionError("expected ValueError for edge loop")
except ValueError:
    pass
print("iss_heimdalr__dag__5 ref OK")
