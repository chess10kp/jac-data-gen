"""Reference harness for iss_kmephis-ai__AI-Development-Framework__22."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_kmephis-ai__AI-Development-Framework__22.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).with_name("iss_kmephis-ai__AI-Development-Framework__22.py")
_spec = importlib.util.spec_from_file_location("_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

STATUS_COMPLETED = _mod.STATUS_COMPLETED
TRACE_REQUIREMENT = _mod.TRACE_REQUIREMENT
TRACE_DECISION = _mod.TRACE_DECISION
fresh_foundation_store = _mod.fresh_foundation_store
register_task = _mod.register_task
add_task_dependency = _mod.add_task_dependency
add_trace_ref = _mod.add_trace_ref
downstream_closure = _mod.downstream_closure
upstream_closure = _mod.upstream_closure
critical_path_order = _mod.critical_path_order
trace_refs_for_task = _mod.trace_refs_for_task
validate_foundation_dag = _mod.validate_foundation_dag

assert STATUS_COMPLETED == "COMPLETED"
assert TRACE_REQUIREMENT == "requirement"
assert TRACE_DECISION == "decision"

s0 = fresh_foundation_store()
assert isinstance(s0, _mod.FoundationStore)
assert critical_path_order(s0) == []

s = fresh_foundation_store()
register_task("ROADMAP-001", STATUS_COMPLETED, s)
register_task("AIWORK-001", STATUS_COMPLETED, s)
register_task("TRACE-001", STATUS_COMPLETED, s)
register_task("CONSUMER-001", "PENDING", s)
add_task_dependency("ROADMAP-001", "AIWORK-001", s)
add_task_dependency("ROADMAP-001", "TRACE-001", s)
add_task_dependency("AIWORK-001", "CONSUMER-001", s)
add_task_dependency("TRACE-001", "CONSUMER-001", s)
assert sorted(downstream_closure("ROADMAP-001", s)) == ["AIWORK-001", "CONSUMER-001", "TRACE-001"]

s2 = fresh_foundation_store()
register_task("FND-001", STATUS_COMPLETED, s2)
assert validate_foundation_dag(s2) == []
try:
    downstream_closure("ghost", s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    upstream_closure("ghost", s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    add_trace_ref("ghost", "req-1", TRACE_REQUIREMENT, "requires", s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

s3 = fresh_foundation_store()
register_task("FND-001", STATUS_COMPLETED, s3)
register_task("DEVENV-001", STATUS_COMPLETED, s3)
register_task("TRACE-001", STATUS_COMPLETED, s3)
add_task_dependency("FND-001", "DEVENV-001", s3)
add_task_dependency("DEVENV-001", "TRACE-001", s3)
assert critical_path_order(s3) == ["FND-001", "DEVENV-001", "TRACE-001"]
assert upstream_closure("TRACE-001", s3) == ["DEVENV-001", "FND-001"]
assert validate_foundation_dag(s3) == []

s4 = fresh_foundation_store()
register_task("TRACE-001", STATUS_COMPLETED, s4)
add_trace_ref("TRACE-001", "req-42", TRACE_REQUIREMENT, "requires", s4)
add_trace_ref("TRACE-001", "dec-7", TRACE_DECISION, "records", s4)
assert trace_refs_for_task("TRACE-001", s4) == [
    ("dec-7", "decision", "records"),
    ("req-42", "requirement", "requires"),
]
try:
    trace_refs_for_task("ghost", s4)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

s5 = fresh_foundation_store()
register_task("a", STATUS_COMPLETED, s5)
register_task("b", STATUS_COMPLETED, s5)
add_task_dependency("a", "b", s5)
try:
    add_task_dependency("b", "a", s5)
    raise AssertionError("expected ValueError")
except ValueError:
    pass
assert validate_foundation_dag(s5) == []

try:
    register_task("a", STATUS_COMPLETED, s5)
    raise AssertionError("expected ValueError")
except ValueError:
    pass
try:
    add_task_dependency("a", "ghost", s5)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    add_task_dependency("a", "a", s5)
    raise AssertionError("expected ValueError")
except ValueError:
    pass
print("iss_kmephis-ai__AI-Development-Framework__22 ref OK")
