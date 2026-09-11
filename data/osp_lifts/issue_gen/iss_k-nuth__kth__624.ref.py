"""Reference harness for iss_k-nuth__kth__624."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_k-nuth__kth__624.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
s = _mod.fresh_workflow_store()
assert isinstance(s, _mod.WorkflowStore)
assert s.jobs == {}

s = _mod.register_job("build", _mod.PLATFORM_MACOS, 1774, 120, 0.9, _mod.CACHE_RESTORED, s)
s = _mod.register_job("lint", "linux", 90, 30, 0.8, _mod.CACHE_RESTORED, s)
s = _mod.register_job("test_mac", _mod.PLATFORM_MACOS, 60, 300, 0.7, _mod.CACHE_RESTORED, s)
s = _mod.register_job("test_lin", "linux", 55, 280, 0.6, _mod.CACHE_RESTORED, s)
assert set(s.jobs.keys()) == {"build", "lint", "test_mac", "test_lin"}

_mod.add_job_dependency("build", "lint", s)
_mod.add_job_dependency("build", "test_mac", s)
_mod.add_job_dependency("lint", "test_lin", s)
_mod.add_job_dependency("test_mac", "test_lin", s)
assert _mod.direct_downstream_jobs("build", s) == ["lint", "test_mac"]
assert _mod.direct_downstream_jobs("lint", s) == ["test_lin"]
assert sorted(_mod.downstream_closure("build", s)) == ["lint", "test_lin", "test_mac"]

s2 = _mod.fresh_workflow_store()
_mod.register_job("build", _mod.PLATFORM_MACOS, 400, 100, 0.9, _mod.CACHE_RESTORED, s2)
assert _mod.cache_diagnosis("ghost", s2) == "reject_unknown"
caught = False
try:
    _mod.downstream_closure("ghost", s2)
except KeyError:
    caught = True
assert caught

s3 = _mod.fresh_workflow_store()
_mod.register_job("compile", "linux", 600, 0, 0.5, _mod.CACHE_MISSED, s3)
_mod.register_job("link", "linux", 120, 0, 0.6, _mod.CACHE_RESTORED, s3)
_mod.register_job("test", "linux", 0, 400, 0.0, _mod.CACHE_RESTORED, s3)
_mod.add_job_dependency("compile", "link", s3)
_mod.add_job_dependency("link", "test", s3)
assert _mod.workflow_build_order(s3) == ["compile", "link", "test"]

s4 = _mod.fresh_workflow_store()
_mod.register_job("build", _mod.PLATFORM_MACOS, 1774, 120, 0.2, _mod.CACHE_MISSED, s4)
_mod.register_job("test", _mod.PLATFORM_MACOS, 0, 300, 0.1, _mod.CACHE_MISSED, s4)
_mod.add_job_dependency("build", "test", s4)
assert _mod.invalidate_downstream_on_rerun("build", s4) == ["build", "test"]
assert _mod.timing_variance_ratio(1774, 414) > 4.0
assert _mod.timing_variance_ratio(0, 0) == 0.0

s5 = _mod.fresh_workflow_store()
_mod.register_job("slow", _mod.PLATFORM_MACOS, 3125, 200, 0.1, _mod.CACHE_MISSED, s5)
_mod.register_job("fast", _mod.PLATFORM_MACOS, 414, 80, 0.95, _mod.CACHE_RESTORED, s5)
assert _mod.cache_diagnosis("slow", s5) == "cache_miss"
assert _mod.cache_diagnosis("fast", s5) == "healthy"

s6 = _mod.fresh_workflow_store()
_mod.register_job("a", "linux", 1, 1, 0.9, _mod.CACHE_RESTORED, s6)
_mod.register_job("b", "linux", 1, 1, 0.9, _mod.CACHE_RESTORED, s6)
_mod.add_job_dependency("a", "b", s6)
dup = False
try:
    _mod.register_job("a", "linux", 1, 1, 0.9, _mod.CACHE_RESTORED, s6)
except ValueError:
    dup = True
assert dup
self_dep = False
try:
    _mod.add_job_dependency("a", "a", s6)
except ValueError:
    self_dep = True
assert self_dep
cycle = False
try:
    _mod.add_job_dependency("b", "a", s6)
except ValueError:
    cycle = True
assert cycle
unknown = False
try:
    _mod.add_job_dependency("a", "missing", s6)
except KeyError:
    unknown = True
assert unknown
assert _mod.workflow_build_order(_mod.fresh_workflow_store()) == []
print("iss_k-nuth__kth__624 ref OK")
print("iss_k-nuth__kth__624 ref OK")
