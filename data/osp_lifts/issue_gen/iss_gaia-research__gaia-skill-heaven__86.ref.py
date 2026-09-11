"""Reference harness for iss_gaia-research__gaia-skill-heaven__86."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_gaia-research__gaia-skill-heaven__86.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_gaia-research__gaia-skill-heaven__86.py")
_spec = importlib.util.spec_from_file_location("issue86", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

assert m.TERMUX_IO_PENALTY_MS == 8000

s0 = m.fresh_boot_store()
assert s0 == {"steps": {}, "deps": {}, "rev": {}, "nodes": {}}
s0 = m.register_boot_step("bootstrap", 100, s0)
assert s0["steps"]["bootstrap"] == 100
assert s0["nodes"]["bootstrap"].base_ms == 100

s = m.fresh_boot_store()
m.register_boot_step("bootstrap", 100, s)
m.register_boot_step("npm_unpack", 200, s)
m.register_boot_step("copy_skills", 300, s)
m.register_boot_step("launcher_ready", 400, s)
m.add_boot_dependency("bootstrap", "npm_unpack", s)
m.add_boot_dependency("bootstrap", "copy_skills", s)
m.add_boot_dependency("npm_unpack", "launcher_ready", s)
m.add_boot_dependency("copy_skills", "launcher_ready", s)
got = m.reachable_steps("bootstrap", s)
assert got == ["copy_skills", "launcher_ready", "npm_unpack"]
assert sum(1 for sid in got if sid == "launcher_ready") == 1

s1 = m.fresh_boot_store()
for sid in ("bootstrap", "npm_unpack", "copy_skills", "launcher_ready"):
    m.register_boot_step(sid, 1, s1)
m.add_boot_dependency("bootstrap", "copy_skills", s1)
m.add_boot_dependency("copy_skills", "launcher_ready", s1)
m.add_boot_dependency("bootstrap", "npm_unpack", s1)
m.add_boot_dependency("npm_unpack", "launcher_ready", s1)
s2 = m.fresh_boot_store()
for sid in ("bootstrap", "npm_unpack", "copy_skills", "launcher_ready"):
    m.register_boot_step(sid, 1, s2)
m.add_boot_dependency("bootstrap", "npm_unpack", s2)
m.add_boot_dependency("npm_unpack", "launcher_ready", s2)
m.add_boot_dependency("bootstrap", "copy_skills", s2)
m.add_boot_dependency("copy_skills", "launcher_ready", s2)
assert m.reachable_steps("bootstrap", s1) == m.reachable_steps("bootstrap", s2)

s = m.fresh_boot_store()
m.register_boot_step("bootstrap", 1, s)
try:
    m.direct_downstream("missing", s)
    raise AssertionError("expected KeyError for unknown boot step")
except KeyError:
    pass
try:
    m.add_boot_dependency("bootstrap", "missing", s)
    raise AssertionError("expected KeyError for unknown dependency")
except KeyError:
    pass

s = m.fresh_boot_store()
m.register_boot_step("bootstrap", 100, s)
m.register_boot_step("npm_unpack", 500, s)
m.add_boot_dependency("bootstrap", "npm_unpack", s)
assert m.boot_duration_ms("bootstrap", s, termux_io=False) == 600
assert m.boot_duration_ms("bootstrap", s, termux_io=True) == 600 + m.TERMUX_IO_PENALTY_MS

s = m.fresh_boot_store()
m.register_boot_step("bootstrap", 50, s)
m.register_boot_step("path_scan", 150, s)
m.add_boot_dependency("bootstrap", "path_scan", s)
rep = m.boot_report("bootstrap", s, termux_io=False)
assert rep == {
    "direct": ["path_scan"],
    "reach": ["path_scan"],
    "reach_count": 1,
    "duration_ms": 200,
    "termux_io": False,
}
print("iss_gaia-research__gaia-skill-heaven__86 ref OK")
