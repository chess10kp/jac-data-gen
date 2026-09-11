"""Reference harness for iss_fastlane__fastlane__29496."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_fastlane__fastlane__29496.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_fastlane__fastlane__29496.py")
_spec = importlib.util.spec_from_file_location("issue29496", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

assert m.SYNC_PENALTY_MS == 12000

s0 = m.fresh_build_store()
assert s0 == {"phases": {}, "deps": {}, "rev": {}, "nodes": {}}
s0 = m.register_phase("resolve", 100, s0)
assert s0["phases"]["resolve"] == 100
assert s0["nodes"]["resolve"].pid == "resolve"

s = m.fresh_build_store()
m.register_phase("resolve", 100, s)
m.register_phase("compile_ui", 200, s)
m.register_phase("launch_screen", 300, s)
m.register_phase("archive", 400, s)
m.add_phase_dependency("resolve", "compile_ui", s)
m.add_phase_dependency("resolve", "launch_screen", s)
m.add_phase_dependency("compile_ui", "archive", s)
m.add_phase_dependency("launch_screen", "archive", s)
got = m.reachable_phases("resolve", s)
assert got == ["compile_ui", "archive", "launch_screen"]
assert sum(1 for pid in got if pid == "archive") == 1

s1 = m.fresh_build_store()
for pid in ("resolve", "compile_ui", "launch_screen", "archive"):
    m.register_phase(pid, 1, s1)
m.add_phase_dependency("resolve", "launch_screen", s1)
m.add_phase_dependency("launch_screen", "archive", s1)
m.add_phase_dependency("resolve", "compile_ui", s1)
m.add_phase_dependency("compile_ui", "archive", s1)
s2 = m.fresh_build_store()
for pid in ("resolve", "compile_ui", "launch_screen", "archive"):
    m.register_phase(pid, 1, s2)
m.add_phase_dependency("resolve", "compile_ui", s2)
m.add_phase_dependency("compile_ui", "archive", s2)
m.add_phase_dependency("resolve", "launch_screen", s2)
m.add_phase_dependency("launch_screen", "archive", s2)
assert m.reachable_phases("resolve", s1) == m.reachable_phases("resolve", s2)

s = m.fresh_build_store()
m.register_phase("resolve", 1, s)
try:
    m.reachable_phases("missing", s)
    raise AssertionError("expected KeyError for unknown phase")
except KeyError:
    pass
try:
    m.add_phase_dependency("resolve", "missing", s)
    raise AssertionError("expected KeyError for unknown dependency")
except KeyError:
    pass

s = m.fresh_build_store()
m.register_phase("resolve", 100, s)
m.register_phase("launch_screen", 500, s)
m.add_phase_dependency("resolve", "launch_screen", s)
assert m.build_duration_ms("resolve", s, sync_io=False) == 600
assert m.build_duration_ms("resolve", s, sync_io=True) == 600 + m.SYNC_PENALTY_MS

s = m.fresh_build_store()
m.register_phase("resolve", 50, s)
m.register_phase("archive", 150, s)
m.add_phase_dependency("resolve", "archive", s)
rep = m.build_report("resolve", s, sync_io=False)
assert rep == {
    "direct": ["archive"],
    "reach": ["archive"],
    "reach_count": 1,
    "duration_ms": 200,
    "sync_io": False,
}
print("iss_fastlane__fastlane__29496 ref OK")
