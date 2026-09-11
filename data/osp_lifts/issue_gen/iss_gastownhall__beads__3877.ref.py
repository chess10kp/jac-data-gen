"""Reference harness for iss_gastownhall__beads__3877."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_gastownhall__beads__3877.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_gastownhall__beads__3877.py")
_spec = importlib.util.spec_from_file_location("issue3877", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_issue_store()
assert s0 == {"issues": {}, "blocks": {}, "rev": {}, "nodes": {}}
s0 = m.register_issue("epic", s0)
assert s0["issues"]["epic"] is True
assert s0["nodes"]["epic"].iid == "epic"

s = m.fresh_issue_store()
m.register_issue("epic", s)
m.register_issue("child_a", s)
m.register_issue("child_b", s)
m.register_issue("leaf", s)
m.add_blocks_edge("epic", "child_a", s)
m.add_blocks_edge("epic", "child_b", s)
m.add_blocks_edge("child_a", "leaf", s)
m.add_blocks_edge("child_b", "leaf", s)
got = m.transitive_blocked("epic", s)
assert got == ["child_a", "leaf", "child_b"]
assert sum(1 for iid in got if iid == "leaf") == 1

s1 = m.fresh_issue_store()
for iid in ("epic", "child_a", "child_b", "leaf"):
    m.register_issue(iid, s1)
m.add_blocks_edge("epic", "child_b", s1)
m.add_blocks_edge("child_b", "leaf", s1)
m.add_blocks_edge("epic", "child_a", s1)
m.add_blocks_edge("child_a", "leaf", s1)
s2 = m.fresh_issue_store()
for iid in ("epic", "child_a", "child_b", "leaf"):
    m.register_issue(iid, s2)
m.add_blocks_edge("epic", "child_a", s2)
m.add_blocks_edge("child_a", "leaf", s2)
m.add_blocks_edge("epic", "child_b", s2)
m.add_blocks_edge("child_b", "leaf", s2)
assert m.transitive_blocked("epic", s1) == m.transitive_blocked("epic", s2)

s = m.fresh_issue_store()
m.register_issue("epic", s)
try:
    m.direct_blocked("missing", s)
    raise AssertionError("expected KeyError for unknown issue")
except KeyError:
    pass
try:
    m.add_blocks_edge("epic", "missing", s)
    raise AssertionError("expected KeyError for unknown blocks target")
except KeyError:
    pass

s = m.fresh_issue_store()
m.register_issue("epic", s)
m.register_issue("child_a", s)
m.add_blocks_edge("epic", "child_a", s)
m.add_blocks_edge("epic", "child_a", s)
assert m.direct_blocked("epic", s) == ["child_a"]
rep = m.ready_reach_report("epic", s)
assert rep["reach_count"] == 1

s = m.fresh_issue_store()
m.register_issue("epic", s)
m.register_issue("child_a", s)
m.add_blocks_edge("epic", "child_a", s)
rep = m.ready_reach_report("epic", s)
assert rep == {"direct": ["child_a"], "reach": ["child_a"], "reach_count": 1}
assert m.direct_blockers("child_a", s) == ["epic"]
print("iss_gastownhall__beads__3877 ref OK")
