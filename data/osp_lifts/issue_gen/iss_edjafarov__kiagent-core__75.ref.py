"""Reference harness for iss_edjafarov__kiagent-core__75."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_edjafarov__kiagent-core__75.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_edjafarov__kiagent-core__75.py")
_spec = importlib.util.spec_from_file_location("issue75", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_query_store()
assert s0 == {"tables": {}, "refs": {}, "nodes": {}}
s0 = m.register_table("A", 1, s0)
assert s0["tables"]["A"] == 1
assert s0["nodes"]["A"].row_count == 1

s = m.fresh_query_store()
m.register_table("A", 1, s)
m.register_table("B", 1, s)
m.register_table("C", 1, s)
m.register_table("D", 1, s)
m.add_reference("A", "B", s)
m.add_reference("A", "C", s)
m.add_reference("B", "D", s)
m.add_reference("C", "D", s)
got = m.recursive_reachable("A", s, row_cap=0)
assert got == ["A", "B", "D", "C"]
assert sum(1 for tid in got if tid == "D") == 1

s1 = m.fresh_query_store()
for tid in ("A", "B", "C", "D"):
    m.register_table(tid, 1, s1)
m.add_reference("A", "C", s1)
m.add_reference("C", "D", s1)
m.add_reference("A", "B", s1)
m.add_reference("B", "D", s1)
s2 = m.fresh_query_store()
for tid in ("A", "B", "C", "D"):
    m.register_table(tid, 1, s2)
m.add_reference("A", "B", s2)
m.add_reference("B", "D", s2)
m.add_reference("A", "C", s2)
m.add_reference("C", "D", s2)
assert m.recursive_reachable("A", s1, row_cap=0) == m.recursive_reachable("A", s2, row_cap=0)

s = m.fresh_query_store()
m.register_table("A", 1, s)
try:
    m.recursive_reachable("Z", s)
    raise AssertionError("expected KeyError for unknown start")
except KeyError:
    pass
try:
    m.add_reference("A", "Z", s)
    raise AssertionError("expected KeyError for unknown reference")
except KeyError:
    pass

s = m.fresh_query_store()
m.register_table("A", 300, s)
m.register_table("B", 300, s)
m.add_reference("A", "B", s)
rep = m.bounded_reach_report("A", s, row_cap=400)
assert rep == {"tables": ["A"], "rows": 300, "truncated": True}

s = m.fresh_query_store()
m.register_table("A", 10, s)
m.register_table("B", 20, s)
m.register_table("C", 30, s)
m.add_reference("A", "B", s)
m.add_reference("B", "C", s)
assert m.query_work_units("A", s) == 60
assert m.recursive_reachable("A", s) == m.recursive_reachable("A", s, row_cap=m.DEFAULT_ROW_CAP)
print("iss_edjafarov__kiagent-core__75 ref OK")
