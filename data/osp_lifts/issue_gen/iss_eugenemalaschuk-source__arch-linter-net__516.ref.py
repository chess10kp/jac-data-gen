"""Reference harness for iss_eugenemalaschuk-source__arch-linter-net__516."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_eugenemalaschuk-source__arch-linter-net__516.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_eugenemalaschuk-source__arch-linter-net__516.py")
_spec = importlib.util.spec_from_file_location("issue516", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_metric_store()
assert s0 == {"components": {}, "deps": {}, "rev": {}, "nodes": {}}
s0 = m.register_component("A", s0)
assert s0["components"]["A"] is True
assert s0["nodes"]["A"].cid == "A"

s = m.fresh_metric_store()
m.register_component("A", s)
m.register_component("B", s)
m.register_component("C", s)
m.register_component("D", s)
m.add_dependency("A", "B", s)
m.add_dependency("A", "C", s)
m.add_dependency("B", "D", s)
m.add_dependency("C", "D", s)
got = m.transitive_targets("A", s)
assert got == ["B", "D", "C"]
assert sum(1 for cid in got if cid == "D") == 1

s1 = m.fresh_metric_store()
for cid in ("A", "B", "C", "D"):
    m.register_component(cid, s1)
m.add_dependency("A", "C", s1)
m.add_dependency("C", "D", s1)
m.add_dependency("A", "B", s1)
m.add_dependency("B", "D", s1)
s2 = m.fresh_metric_store()
for cid in ("A", "B", "C", "D"):
    m.register_component(cid, s2)
m.add_dependency("A", "B", s2)
m.add_dependency("B", "D", s2)
m.add_dependency("A", "C", s2)
m.add_dependency("C", "D", s2)
assert m.transitive_targets("A", s1) == m.transitive_targets("A", s2)

s = m.fresh_metric_store()
m.register_component("A", s)
try:
    m.distinct_outgoing("Z", s)
    raise AssertionError("expected KeyError for unknown component")
except KeyError:
    pass
try:
    m.add_dependency("A", "Z", s)
    raise AssertionError("expected KeyError for unknown dependency")
except KeyError:
    pass

s = m.fresh_metric_store()
m.register_component("A", s)
m.register_component("B", s)
m.add_dependency("A", "B", s)
m.add_dependency("A", "B", s)
assert m.distinct_outgoing("A", s) == ["B"]
assert m.distinct_incoming("B", s) == ["A"]
rep = m.metric_report("A", s)
assert rep == {
    "out_degree": 1,
    "in_degree": 0,
    "reach_count": 1,
    "outgoing": ["B"],
    "incoming": [],
    "reach": ["B"],
}

s = m.fresh_metric_store()
m.register_component("A", s)
m.add_dependency("A", "A", s)
assert m.distinct_outgoing("A", s) == []
assert m.distinct_incoming("A", s) == []
assert m.transitive_targets("A", s) == []
print("iss_eugenemalaschuk-source__arch-linter-net__516 ref OK")
