"""Reference harness for iss_byjesper__laravel-decision-support__27."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_byjesper__laravel-decision-support__27.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_byjesper__laravel-decision-support__27.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

GuideDefinition = _mod.GuideDefinition
GuideRunner = _mod.GuideRunner
RunState = _mod.RunState

guide_diamond = GuideDefinition({
    "hub": ["right", "left"],
    "left": ["leaf"],
    "right": ["leaf"],
})
runner_diamond = GuideRunner(guide_diamond, acyclic=True)
assert runner_diamond.reachable_keys("hub") == ["hub", "right", "left", "leaf"]

guide_shortest = GuideDefinition({
    "hub": ["right", "left"],
    "left": ["goal"],
    "right": ["mid"],
    "mid": ["goal"],
})
runner_shortest = GuideRunner(guide_shortest, acyclic=True)
hit = runner_shortest.run_to("hub", "goal")
assert hit is not None
assert hit.path_keys() == ["hub", "left", "goal"]
assert hit.cursor_key() == "goal"

guide_unknown = GuideDefinition({
    "start": ["left", "right"],
    "left": [],
    "right": [],
})
runner_unknown = GuideRunner(guide_unknown, acyclic=True)
assert guide_unknown.edges_from("phantom") == []
assert runner_unknown.run_to("phantom", "start") is None
assert runner_unknown.run_to("start", "phantom") is None
assert runner_unknown.reachable_keys("phantom") == ["phantom"]
assert runner_unknown.reachable_keys("nowhere") == ["nowhere"]

state = RunState(["a", "b", "c", "d", "e"], "e")
assert state.has_visited("a") is True
assert state.has_visited("z") is False
assert state.copy().path_keys() == ["a", "b", "c", "d", "e"]
assert state.copy().cursor_key() == "e"
nxt = state.move_to("f")
assert nxt.has_visited("a") is True
assert nxt.has_visited("f") is True
assert nxt.has_visited("z") is False
assert nxt.path_keys() == ["a", "b", "c", "d", "e", "f"]

guide_guard = GuideDefinition({
    "lonely": [],
    "busy": ["a", "b"],
    "a": ["c"],
    "b": ["c"],
    "c": [],
})
runner_guard = GuideRunner(guide_guard, acyclic=True)
assert runner_guard.transition_guard_calls("lonely") == 0
assert runner_guard.transition_guard_calls("busy") == 4

guide_keys = GuideDefinition({
    "a_first": ["b"],
    "z_last": ["orphan_only"],
})
assert guide_keys.node_keys() == ["a_first", "b", "z_last", "orphan_only"]
assert guide_keys.edges_from("orphan_only") == []
print("iss_byjesper__laravel-decision-support__27 ref OK")
