"""Reference harness for iss_N0tS0Lucky__piflow__9."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_N0tS0Lucky__piflow__9.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
from iss_N0tS0Lucky__piflow__9 import (
  DefinitionError,
  build_invoke_adjacency,
  detect_invoke_cycles,
  find_cycle_path,
  resolve_workflows,
  validate_invoke_step,
)

VALID = {
  "build-feature": {
    "steps": [
      {"id": "invoke-review", "type": "invoke", "workflow": "review-loop"},
      {
        "id": "invoke-parallel",
        "type": "parallel",
        "steps": [
          {"id": "invoke-lint", "type": "invoke", "workflow": "lint"},
          {"id": "invoke-test", "type": "invoke", "workflow": "test"},
        ],
      },
    ]
  },
  "review-loop": {"steps": [{"id": "review", "type": "shell", "command": "review"}]},
  "lint": {"steps": [{"id": "lint", "type": "shell", "command": "lint"}]},
  "test": {"steps": [{"id": "test", "type": "shell", "command": "test"}]},
}

SELF_CYCLE = {
  "solo": {"steps": [{"id": "self", "type": "invoke", "workflow": "solo"}]},
}

TWO_CYCLE = {
  "alpha": {"steps": [{"id": "a", "type": "invoke", "workflow": "beta"}]},
  "beta": {"steps": [{"id": "b", "type": "invoke", "workflow": "alpha"}]},
}

THREE_CYCLE = {
  "a": {"steps": [{"id": "a1", "type": "invoke", "workflow": "b"}]},
  "b": {"steps": [{"id": "b1", "type": "invoke", "workflow": "c"}]},
  "c": {"steps": [{"id": "c1", "type": "invoke", "workflow": "a"}]},
}

MISSING = {
  "parent": {"steps": [{"id": "missing", "type": "invoke", "workflow": "ghost"}]},
}

validate_invoke_step({"id": "ok", "type": "invoke", "workflow": "review-loop"})
try:
  validate_invoke_step({"id": "bad", "type": "invoke", "workflow": "x", "extra": 1})
  raise AssertionError("expected unknown invoke keys")
except DefinitionError as exc:
  assert "unknown invoke keys" in str(exc)
  assert "extra" in str(exc)

try:
  validate_invoke_step({"id": "bad", "type": "invoke"})
  raise AssertionError("expected missing workflow")
except DefinitionError as exc:
  assert "missing required workflow" in str(exc)

valid_adj = build_invoke_adjacency(VALID)
assert valid_adj == {
  "build-feature": ["lint", "review-loop", "test"],
  "lint": [],
  "review-loop": [],
  "test": [],
}

diamond_adj = build_invoke_adjacency({
  "root": {
    "steps": [
      {"id": "p", "type": "parallel", "steps": [
        {"id": "left", "type": "invoke", "workflow": "left-wf"},
        {"id": "right", "type": "invoke", "workflow": "right-wf"},
      ]},
      {"id": "tail", "type": "invoke", "workflow": "tail-wf"},
    ]
  },
  "left-wf": {"steps": []},
  "right-wf": {"steps": []},
  "tail-wf": {"steps": []},
})
assert diamond_adj["root"] == ["left-wf", "right-wf", "tail-wf"]

assert find_cycle_path(valid_adj, "build-feature") is None
assert find_cycle_path(build_invoke_adjacency(SELF_CYCLE), "solo") == ["solo", "solo"]
assert find_cycle_path(build_invoke_adjacency(TWO_CYCLE), "alpha") == ["alpha", "beta", "alpha"]
assert find_cycle_path(build_invoke_adjacency(THREE_CYCLE), "b") == ["b", "c", "a", "b"]

assert detect_invoke_cycles(valid_adj) is None
assert detect_invoke_cycles(build_invoke_adjacency(SELF_CYCLE)) == ["solo", "solo"]
assert detect_invoke_cycles(build_invoke_adjacency(TWO_CYCLE)) == ["alpha", "beta", "alpha"]
assert detect_invoke_cycles(build_invoke_adjacency(THREE_CYCLE)) == ["a", "b", "c", "a"]

resolved = resolve_workflows(VALID, source_file="build-feature.yaml")
assert sorted(resolved) == ["build-feature", "lint", "review-loop", "test"]
invoke_steps = [
  step
  for step in resolved["build-feature"]["steps"]
  if step.get("type") == "invoke"
]
assert len(invoke_steps) == 1
assert invoke_steps[0]["resolved_workflow"]["steps"][0]["command"] == "review"
parallel = next(
  step for step in resolved["build-feature"]["steps"] if step.get("type") == "parallel"
)
parallel_targets = sorted(
  nested["workflow"] for nested in parallel["steps"] if nested.get("type") == "invoke"
)
assert parallel_targets == ["lint", "test"]
for nested in parallel["steps"]:
  if nested.get("type") == "invoke":
    assert "resolved_workflow" in nested
    assert nested["resolved_workflow"]["steps"]

try:
  resolve_workflows(MISSING, source_file="parent.yaml")
  raise AssertionError("expected missing workflow error")
except DefinitionError as exc:
  assert "missing workflow 'ghost'" in str(exc)
  assert "step 'missing'" in str(exc)
  assert "parent.yaml" in str(exc)

for workflows, expected in (
  (SELF_CYCLE, "solo -> solo"),
  (TWO_CYCLE, "alpha -> beta -> alpha"),
  (THREE_CYCLE, "a -> b -> c -> a"),
):
  try:
    resolve_workflows(workflows, source_file="cycle.yaml")
    raise AssertionError(f"expected cycle for {sorted(workflows)}")
  except DefinitionError as exc:
    assert "invoke cycle in cycle.yaml:" in str(exc)
    assert expected in str(exc)
print("iss_N0tS0Lucky__piflow__9 ref OK")
