"""Reference harness for iss_tdupu__mathcity__80."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_tdupu__mathcity__80.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
g = _mod.load_workflow_store(
    {"w1": "open", "root": "inactive", "base": "closed"},
    {"w1": "wisp", "root": "issue", "base": "issue"},
    [("w1", "root", "tracks"), ("root", "base", "parent-child")],
)
assert _mod.dependency_ascent(g, "w1") == ["base", "root"]
assert _mod.workflow_issue_root_candidates(g, "w1") == ["base"]
assert _mod.workflow_issue_root_candidates(g, "root") == ["base"]
assert _mod.stale_inactive_issue_ids(g) == ["root"]
assert _mod.reaper_visit_count(g, "w1") == 3

g2 = _mod.load_workflow_store(
    {"hub": "open", "left": "inactive", "right": "inactive", "cap": "inactive"},
    {"hub": "wisp", "left": "wisp", "right": "wisp", "cap": "issue"},
    [
        ("hub", "right", "blocks"),
        ("hub", "left", "tracks"),
        ("right", "cap", "parent-child"),
        ("left", "cap", "parent-child"),
    ],
)
assert _mod.dependency_ascent(g2, "hub") == ["cap", "left", "right"]
assert _mod.workflow_issue_root_candidates(g2, "hub") == ["cap"]
assert _mod.stale_inactive_issue_ids(g2) == ["cap"]
assert _mod.reaper_visit_count(g2, "hub") == 4

g3 = _mod.load_workflow_store(
    {"a": "open", "b": "open", "c": "inactive"},
    {"a": "wisp", "b": "wisp", "c": "issue"},
    [("a", "b", "tracks"), ("b", "c", "blocks"), ("c", "a", "parent-child")],
)
assert _mod.dependency_ascent(g3, "a") == ["b", "c"]
assert _mod.workflow_issue_root_candidates(g3, "a") == ["c"]
assert _mod.reaper_visit_count(g3, "a") == 3

assert _mod.dependency_ascent(g, "missing") == []
assert _mod.workflow_issue_root_candidates(g, "missing") == []
assert _mod.stale_inactive_issue_ids(
    _mod.load_workflow_store({}, {}, [])
) == []
assert _mod.reaper_visit_count(g, "missing") == 0
print("iss_tdupu__mathcity__80 ref OK")
