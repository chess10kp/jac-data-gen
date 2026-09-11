"""Reference harness for iss_TalonT-Org__AutoSkillit__3951."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_TalonT-Org__AutoSkillit__3951.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
DIAMOND_ISSUES = [
  {"plan_id": "P1-A1-WP1", "title": "Root scaffold", "depends_on": [], "issue_number": 401},
  {"plan_id": "P2-A1-WP1", "title": "Left branch", "depends_on": ["P1-A1-WP1"], "issue_number": 402},
  {"plan_id": "P2-A2-WP1", "title": "Right branch", "depends_on": ["P1-A1-WP1"], "issue_number": 403},
  {"plan_id": "P3-A1-WP1", "title": "Merge tail", "depends_on": ["P2-A1-WP1", "P2-A2-WP1"], "issue_number": 404},
]

LINEAR_ISSUES = [
  {"plan_id": "P1-A1-WP1", "title": "Bootstrap", "depends_on": [], "issue_number": 501},
  {"plan_id": "P1-A2-WP1", "title": "Compile", "depends_on": ["P1-A1-WP1"], "issue_number": 502},
  {"plan_id": "P1-A3-WP1", "title": "Stamp", "depends_on": ["P1-A2-WP1"], "issue_number": 503},
]

PLAN_TO_ISSUE = {row["plan_id"]: row["issue_number"] for row in DIAMOND_ISSUES + LINEAR_ISSUES}
PLAN_TO_TITLE = {row["plan_id"]: row["title"] for row in DIAMOND_ISSUES + LINEAR_ISSUES}

dep_adj = _mod.build_dep_adjacency(DIAMOND_ISSUES)
assert dep_adj == {
  "P1-A1-WP1": [],
  "P2-A1-WP1": ["P1-A1-WP1"],
  "P2-A2-WP1": ["P1-A1-WP1"],
  "P3-A1-WP1": ["P2-A1-WP1", "P2-A2-WP1"],
}

succ_adj = _mod.build_successor_adjacency(dep_adj)
assert succ_adj == {
  "P1-A1-WP1": ["P2-A1-WP1", "P2-A2-WP1"],
  "P2-A1-WP1": ["P3-A1-WP1"],
  "P2-A2-WP1": ["P3-A1-WP1"],
  "P3-A1-WP1": [],
}

groups = _mod.kahn_parallel_groups(dep_adj)
assert groups == [["P1-A1-WP1"], ["P2-A1-WP1", "P2-A2-WP1"], ["P3-A1-WP1"]]

linear_dep = _mod.build_dep_adjacency(LINEAR_ISSUES)
linear_groups = _mod.kahn_parallel_groups(linear_dep)
assert linear_groups == [["P1-A1-WP1"], ["P1-A2-WP1"], ["P1-A3-WP1"]]

bem_map = {
  "groups": [["P3-A1-WP1"], ["P1-A2-WP1", "P2-A2-WP1"], ["P1-A1-WP1"]],
  "merge_order": ["P3-A1-WP1", "P1-A2-WP1", "P2-A2-WP1", "P1-A1-WP1"],
  "deferred_groups": [],
}
loaded = _mod.load_bem_groups(bem_map)
assert loaded == [["P3-A1-WP1"], ["P1-A2-WP1", "P2-A2-WP1"], ["P1-A1-WP1"]]

merge_order = _mod.flatten_merge_order(groups)
assert merge_order == ["P1-A1-WP1", "P2-A1-WP1", "P2-A2-WP1", "P3-A1-WP1"]

labels = _mod.assign_dispatch_labels(merge_order)
assert labels == {
  "P1-A1-WP1": "D-01",
  "P2-A1-WP1": "D-02",
  "P2-A2-WP1": "D-03",
  "P3-A1-WP1": "D-04",
}

assert _mod.rename_issue_title("P2-A2-WP1", "Right branch", "D-03") == "[D-03] P2-A2-WP1: Right branch"

gtypes = _mod.infer_group_types(groups)
assert gtypes == ["sequential", "parallel", "sequential"]

ctx_root = _mod.format_execution_context(
  "P1-A1-WP1",
  groups,
  merge_order,
  gtypes,
  PLAN_TO_ISSUE,
  PLAN_TO_TITLE,
  deferred=[],
)
assert "Group 1 of 3" in ctx_root
assert "Group type**: sequential" in ctx_root
assert "Position 1 of 4" in ctx_root
assert "Immediate predecessor**: None — first in group" in ctx_root
assert "#403 Right branch" in _mod.format_execution_context(
  "P2-A1-WP1",
  groups,
  merge_order,
  gtypes,
  PLAN_TO_ISSUE,
  PLAN_TO_TITLE,
)
assert "Group peers**: P2-A2-WP1" in _mod.format_execution_context(
  "P2-A1-WP1",
  groups,
  merge_order,
  gtypes,
  PLAN_TO_ISSUE,
  PLAN_TO_TITLE,
)
assert "Immediate successor**: None — last in sequence" in _mod.format_execution_context(
  "P3-A1-WP1",
  groups,
  merge_order,
  gtypes,
  PLAN_TO_ISSUE,
  PLAN_TO_TITLE,
)
assert "Gated by**: None" in ctx_root
assert "Gated by**: P9-A1-WP1" in _mod.format_execution_context(
  "P2-A2-WP1",
  groups,
  merge_order,
  gtypes,
  PLAN_TO_ISSUE,
  PLAN_TO_TITLE,
  deferred=["P9-A1-WP1"],
)
print("iss_TalonT-Org__AutoSkillit__3951 ref OK")
