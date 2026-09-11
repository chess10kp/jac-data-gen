"""Reference harness for iss_fleetdm__fleet__42933."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_fleetdm__fleet__42933.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_fleetdm__fleet__42933.py")
_spec = importlib.util.spec_from_file_location("issue42933", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

assert m.RUN_MODE_CLEAN == "clean"
assert m.RUN_MODE_INCREMENTAL == "incremental"

s0 = m.fresh_workflow_store()
assert s0 == {"stages": {}, "deps": {}, "rev": {}, "nodes": {}, "dirty": {}}
s0 = m.register_stage("nvd_sync", s0)
assert s0["stages"]["nvd_sync"] is True
assert s0["dirty"]["nvd_sync"] is False

s = m.fresh_workflow_store()
m.register_stage("nvd_sync", s)
m.register_stage("generate_cve", s)
m.register_stage("transform_vuln", s)
m.register_stage("validate_cve", s)
m.add_stage_edge("nvd_sync", "generate_cve", s)
m.add_stage_edge("nvd_sync", "transform_vuln", s)
m.add_stage_edge("generate_cve", "validate_cve", s)
m.add_stage_edge("transform_vuln", "validate_cve", s)
got = m.reachable_stages("nvd_sync", s)
assert got == ["generate_cve", "validate_cve", "transform_vuln"]
assert sum(1 for sid in got if sid == "validate_cve") == 1

s1 = m.fresh_workflow_store()
for sid in ("nvd_sync", "generate_cve", "transform_vuln", "validate_cve"):
    m.register_stage(sid, s1)
m.add_stage_edge("nvd_sync", "transform_vuln", s1)
m.add_stage_edge("transform_vuln", "validate_cve", s1)
m.add_stage_edge("nvd_sync", "generate_cve", s1)
m.add_stage_edge("generate_cve", "validate_cve", s1)
s2 = m.fresh_workflow_store()
for sid in ("nvd_sync", "generate_cve", "transform_vuln", "validate_cve"):
    m.register_stage(sid, s2)
m.add_stage_edge("nvd_sync", "generate_cve", s2)
m.add_stage_edge("generate_cve", "validate_cve", s2)
m.add_stage_edge("nvd_sync", "transform_vuln", s2)
m.add_stage_edge("transform_vuln", "validate_cve", s2)
assert m.reachable_stages("nvd_sync", s1) == m.reachable_stages("nvd_sync", s2)

s = m.fresh_workflow_store()
m.register_stage("nvd_sync", s)
try:
    m.direct_downstream("missing", s)
    raise AssertionError("expected KeyError for unknown stage")
except KeyError:
    pass
try:
    m.add_stage_edge("nvd_sync", "missing", s)
    raise AssertionError("expected KeyError for unknown edge target")
except KeyError:
    pass

s = m.fresh_workflow_store()
m.register_stage("nvd_sync", s)
m.register_stage("generate_cve", s)
m.register_stage("validate_cve", s)
m.add_stage_edge("nvd_sync", "generate_cve", s)
m.add_stage_edge("generate_cve", "validate_cve", s)
marked = m.invalidate_downstream("nvd_sync", s)
assert marked == ["generate_cve", "nvd_sync", "validate_cve"]
rep = m.rebuild_report("nvd_sync", s, force_clean=False)
assert rep["run_mode"] == m.RUN_MODE_CLEAN

s = m.fresh_workflow_store()
m.register_stage("nvd_sync", s)
m.register_stage("generate_cve", s)
m.add_stage_edge("nvd_sync", "generate_cve", s)
rep = m.rebuild_report("nvd_sync", s, force_clean=True)
assert rep == {
    "direct": ["generate_cve"],
    "reach": ["generate_cve"],
    "reach_count": 1,
    "run_mode": m.RUN_MODE_CLEAN,
    "force_clean": True,
}
print("iss_fleetdm__fleet__42933 ref OK")
