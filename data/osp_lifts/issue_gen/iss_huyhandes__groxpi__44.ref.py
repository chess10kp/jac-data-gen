"""Reference harness for iss_huyhandes__groxpi__44."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_huyhandes__groxpi__44.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_huyhandes__groxpi__44.py")
_spec = importlib.util.spec_from_file_location("issue44", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_module_store()
assert s0 == {"modules": {}, "kinds": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []}
s0 = m.register_module("api", m.KIND_REQUEST, s0)
assert s0["modules"]["api"] is True
assert s0["kinds"]["api"] == m.KIND_REQUEST
assert s0["roots"] == ["api"]

s = m.fresh_module_store()
m.register_module("api", m.KIND_REQUEST, s)
m.register_module("cache", "cache", s)
m.register_module("sync", m.KIND_SYNC, s)
m.register_module("storage", "storage", s)
m.add_module_dep("api", "cache", s)
m.add_module_dep("api", "sync", s)
m.add_module_dep("cache", "storage", s)
m.add_module_dep("sync", "storage", s)
got = m.reachable_modules("api", s)
assert got == ["cache", "storage", "sync"]
assert sum(1 for mid in got if mid == "storage") == 1
assert m.direct_deps("api", s) == ["cache", "sync"]

s1 = m.fresh_module_store()
for mid, kind in (("api", m.KIND_REQUEST), ("cache", "cache"), ("sync", m.KIND_SYNC), ("storage", "storage")):
    m.register_module(mid, kind, s1)
m.add_module_dep("api", "sync", s1)
m.add_module_dep("sync", "storage", s1)
m.add_module_dep("api", "cache", s1)
m.add_module_dep("cache", "storage", s1)
s2 = m.fresh_module_store()
for mid, kind in (("api", m.KIND_REQUEST), ("cache", "cache"), ("sync", m.KIND_SYNC), ("storage", "storage")):
    m.register_module(mid, kind, s2)
m.add_module_dep("api", "cache", s2)
m.add_module_dep("cache", "storage", s2)
m.add_module_dep("api", "sync", s2)
m.add_module_dep("sync", "storage", s2)
assert m.reachable_modules("api", s1) == m.reachable_modules("api", s2)

s = m.fresh_module_store()
m.register_module("api", m.KIND_REQUEST, s)
try:
    m.add_module_dep("api", "missing", s)
    raise AssertionError("expected KeyError for unknown target module")
except KeyError:
    pass
try:
    m.direct_deps("missing", s)
    raise AssertionError("expected KeyError for unknown direct dep lookup")
except KeyError:
    pass

s = m.fresh_module_store()
m.register_module("api", m.KIND_REQUEST, s)
m.register_module("handler", m.KIND_REQUEST, s)
m.register_module("worker", m.KIND_SYNC, s)
m.add_module_dep("api", "handler", s)
m.add_module_dep("handler", "worker", s)
rep = m.pipeline_report("api", s)
assert rep["direct"] == ["handler"]
assert rep["reach"] == ["handler", "worker"]
assert rep["reach_count"] == 2
assert rep["request_modules"] == 1
assert rep["sync_modules"] == 1

s = m.fresh_module_store()
m.register_module("api", m.KIND_REQUEST, s)
m.register_module("bg", m.KIND_SYNC, s)
m.register_module("cache", "cache", s)
m.add_module_dep("api", "cache", s)
assert m.reachable_modules("bg", s) == []
rep = m.pipeline_report("api", s)
assert rep["sync_modules"] == 0
assert rep["reach"] == ["cache"]
try:
    m.pipeline_report("missing", s)
    raise AssertionError("expected KeyError for unknown pipeline start")
except KeyError:
    pass
print("iss_huyhandes__groxpi__44 ref OK")
