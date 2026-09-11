"""Reference harness for iss_jaxzin__indi-allsky-helm__10."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_jaxzin__indi-allsky-helm__10.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_jaxzin__indi-allsky-helm__10.py")
_spec = importlib.util.spec_from_file_location("issue10", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_release_store()
assert s0 == {"tasks": {}, "kinds": {}, "deps": {}, "rev": {}, "nodes": {}, "roots": []}
s0 = m.register_task("chart_release", m.KIND_WORKFLOW, s0)
assert s0["tasks"]["chart_release"] is True
assert s0["kinds"]["chart_release"] == m.KIND_WORKFLOW
assert s0["roots"] == ["chart_release"]

assert m.chart_gate_status(1) == m.STATUS_BLOCKED
assert m.chart_gate_status(0) == m.STATUS_READY

s = m.fresh_release_store()
m.register_task("chart_release", m.KIND_WORKFLOW, s)
m.register_task("release_yml", m.KIND_WORKFLOW, s)
m.register_task("docs_bundle", m.KIND_DOCS, s)
m.register_task("examples_bundle", m.KIND_EXAMPLE, s)
m.register_task("oci_publish", m.KIND_WORKFLOW, s)
m.add_task_dep("chart_release", "release_yml", s)
m.add_task_dep("chart_release", "docs_bundle", s)
m.add_task_dep("chart_release", "examples_bundle", s)
m.add_task_dep("release_yml", "oci_publish", s)
m.add_task_dep("docs_bundle", "oci_publish", s)
m.add_task_dep("examples_bundle", "oci_publish", s)
got = m.release_topology("chart_release", s)
assert got == ["docs_bundle", "examples_bundle", "oci_publish", "release_yml"]
assert sum(1 for tid in got if tid == "oci_publish") == 1
assert m.direct_deps("chart_release", s) == ["docs_bundle", "examples_bundle", "release_yml"]

s1 = m.fresh_release_store()
for tid, kind in (
    ("chart_release", m.KIND_WORKFLOW),
    ("docs_bundle", m.KIND_DOCS),
    ("examples_bundle", m.KIND_EXAMPLE),
    ("oci_publish", m.KIND_WORKFLOW),
):
    m.register_task(tid, kind, s1)
m.add_task_dep("chart_release", "examples_bundle", s1)
m.add_task_dep("examples_bundle", "oci_publish", s1)
m.add_task_dep("chart_release", "docs_bundle", s1)
m.add_task_dep("docs_bundle", "oci_publish", s1)
s2 = m.fresh_release_store()
for tid, kind in (
    ("chart_release", m.KIND_WORKFLOW),
    ("docs_bundle", m.KIND_DOCS),
    ("examples_bundle", m.KIND_EXAMPLE),
    ("oci_publish", m.KIND_WORKFLOW),
):
    m.register_task(tid, kind, s2)
m.add_task_dep("chart_release", "docs_bundle", s2)
m.add_task_dep("docs_bundle", "oci_publish", s2)
m.add_task_dep("chart_release", "examples_bundle", s2)
m.add_task_dep("examples_bundle", "oci_publish", s2)
assert m.release_topology("chart_release", s1) == m.release_topology("chart_release", s2)

s = m.fresh_release_store()
m.register_task("chart_release", m.KIND_WORKFLOW, s)
try:
    m.add_task_dep("chart_release", "missing", s)
    raise AssertionError("expected KeyError for unknown target task")
except KeyError:
    pass
try:
    m.direct_deps("missing", s)
    raise AssertionError("expected KeyError for unknown direct dep lookup")
except KeyError:
    pass

s = m.fresh_release_store()
m.register_task("chart_release", m.KIND_WORKFLOW, s)
m.register_task("a9_e2e", m.KIND_GATE, s)
m.register_task("release_yml", m.KIND_WORKFLOW, s)
m.register_task("readme", m.KIND_DOCS, s)
m.add_task_dep("chart_release", "a9_e2e", s)
m.add_task_dep("a9_e2e", "release_yml", s)
m.add_task_dep("release_yml", "readme", s)
rep = m.release_report("chart_release", s, 1)
assert rep["gate"] == m.STATUS_BLOCKED
assert rep["direct"] == ["a9_e2e"]
assert rep["topology"] == ["a9_e2e", "readme", "release_yml"]
assert rep["topology_count"] == 3
assert rep["workflow_tasks"] == 1
assert rep["docs_tasks"] == 1
assert rep["example_tasks"] == 0
assert rep["gate_tasks"] == 1
rep2 = m.release_report("chart_release", s, 0)
assert rep2["gate"] == m.STATUS_READY

s = m.fresh_release_store()
m.register_task("chart_release", m.KIND_WORKFLOW, s)
m.register_task("branch_rules", m.KIND_GATE, s)
m.register_task("readme", m.KIND_DOCS, s)
m.add_task_dep("chart_release", "readme", s)
assert m.release_topology("branch_rules", s) == []
rep = m.release_report("chart_release", s, 0)
assert rep["gate_tasks"] == 0
assert rep["topology"] == ["readme"]
try:
    m.release_report("missing", s, 0)
    raise AssertionError("expected KeyError for unknown release report start")
except KeyError:
    pass
print("iss_jaxzin__indi-allsky-helm__10 ref OK")
