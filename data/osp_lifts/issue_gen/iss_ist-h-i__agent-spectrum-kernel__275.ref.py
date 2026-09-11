"""Reference harness for iss_ist-h-i__agent-spectrum-kernel__275."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_ist-h-i__agent-spectrum-kernel__275.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_ist-h-i__agent-spectrum-kernel__275.py")
_spec = importlib.util.spec_from_file_location("issue275", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_epic_store()
assert s0 == {"packages": {}, "tokens": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []}
s0 = m.register_package("epic", 100, s0)
assert s0["packages"]["epic"] is True
assert s0["tokens"]["epic"] == 100
assert s0["roots"] == ["epic"]

s = m.fresh_epic_store()
m.register_package("epic", 100, s)
m.register_package("slice_a", 50, s)
m.register_package("slice_b", 50, s)
m.register_package("integrate", 25, s)
m.add_pkg_dep("epic", "slice_a", s)
m.add_pkg_dep("epic", "slice_b", s)
m.add_pkg_dep("slice_a", "integrate", s)
m.add_pkg_dep("slice_b", "integrate", s)
got = m.execution_topology("epic", s)
assert got == ["integrate", "slice_a", "slice_b"]
assert sum(1 for pid in got if pid == "integrate") == 1
assert m.direct_deps("epic", s) == ["slice_a", "slice_b"]

s1 = m.fresh_epic_store()
for pid, tok in (("epic", 10), ("slice_a", 5), ("slice_b", 5), ("integrate", 3)):
    m.register_package(pid, tok, s1)
m.add_pkg_dep("epic", "slice_b", s1)
m.add_pkg_dep("slice_b", "integrate", s1)
m.add_pkg_dep("epic", "slice_a", s1)
m.add_pkg_dep("slice_a", "integrate", s1)
s2 = m.fresh_epic_store()
for pid, tok in (("epic", 10), ("slice_a", 5), ("slice_b", 5), ("integrate", 3)):
    m.register_package(pid, tok, s2)
m.add_pkg_dep("epic", "slice_a", s2)
m.add_pkg_dep("slice_a", "integrate", s2)
m.add_pkg_dep("epic", "slice_b", s2)
m.add_pkg_dep("slice_b", "integrate", s2)
assert m.execution_topology("epic", s1) == m.execution_topology("epic", s2)

s = m.fresh_epic_store()
m.register_package("epic", 10, s)
try:
    m.add_pkg_dep("epic", "missing", s)
    raise AssertionError("expected KeyError for unknown target package")
except KeyError:
    pass
try:
    m.direct_deps("missing", s)
    raise AssertionError("expected KeyError for unknown direct dep lookup")
except KeyError:
    pass

s = m.fresh_epic_store()
m.register_package("epic", 100, s)
m.register_package("slice_a", 200, s)
m.register_package("slice_b", 150, s)
assert m.admit_epic(s, 300) == m.ADMIT_EPIC
assert m.admit_epic(s, 500) == m.ADMIT_ORDINARY
assert m.checkpoint_status(999, 1000) == m.CHECKPOINT_OK
assert m.checkpoint_status(1000, 1000) == m.CHECKPOINT_ROLLOVER

s = m.fresh_epic_store()
m.register_package("epic", 100, s)
m.register_package("slice_a", 50, s)
m.add_pkg_dep("epic", "slice_a", s)
rep = m.epic_report("epic", s, 300, 1000, 1000)
assert rep["admission"] == m.ADMIT_ORDINARY
assert rep["checkpoint"] == m.CHECKPOINT_ROLLOVER
assert rep["topology"] == ["slice_a"]
assert rep["topology_count"] == 1
assert rep["direct"] == ["slice_a"]
try:
    m.epic_report("missing", s, 300, 1000, 1000)
    raise AssertionError("expected KeyError for unknown epic report start")
except KeyError:
    pass
print("iss_ist-h-i__agent-spectrum-kernel__275 ref OK")
