"""Reference harness for iss_agent-team-project__kensho-projects__17."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_agent-team-project__kensho-projects__17.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
ITEMS = [
    ("wi-a", "open", 1),
    ("wi-b", "in_progress", 2),
    ("wi-c", "done", 1),
    ("wi-d", "open", 1),
    ("wi-e", "open", 1),
    ("wi-f", "open", 1),
]
DEPS = [
    ("wi-c", "wi-a", "blocks"),
    ("wi-b", "wi-d", "blocks"),
    ("wi-f", "wi-e", "blocks"),
    ("wi-a", "wi-b", "relates"),
    ("wi-d", "wi-c", "caused-by"),
]
wp = _mod.load_workplane(ITEMS, DEPS)

assert _mod.get_state(wp, "wi-a") == "open"
assert _mod.get_state(wp, "ghost") is None
assert _mod.blocking_closure(wp, "wi-d") == ["wi-b"]
assert _mod.blocking_closure(wp, "ghost") == []
assert _mod.is_blocked(wp, "wi-a") is False
assert _mod.is_blocked(wp, "wi-d") is True
assert _mod.is_blocked(wp, "wi-e") is True
assert _mod.related_items(wp, "wi-a") == [("wi-b", "relates")]
assert _mod.related_items(wp, "wi-d") == [("wi-c", "caused-by")]
assert _mod.related_items(wp, "ghost") == []

assert _mod.transition(wp, "wi-a", "in_progress", 1) == 2
assert _mod.transition(wp, "wi-b", "in_review", 2) == 3
assert _mod.transition(wp, "wi-b", "done", 3) == 4
assert _mod.is_blocked(wp, "wi-d") is False
assert _mod.transition(wp, "wi-d", "in_progress", 1) == 2

try:
    _mod.transition(wp, "wi-e", "in_progress", 1)
    raise AssertionError("expected blocked transition")
except ValueError as err:
    assert str(err) == "blocked"

try:
    _mod.transition(wp, "wi-a", "in_review", 1)
    raise AssertionError("expected stale_version")
except ValueError as err:
    assert str(err) == "stale_version"

try:
    _mod.transition(wp, "wi-a", "done", 2)
    raise AssertionError("expected invalid_transition")
except ValueError as err:
    assert str(err) == "invalid_transition"

assert _mod.would_block_cycle(wp, "wi-d", "wi-b") is True
assert _mod.would_block_cycle(wp, "wi-a", "wi-a") is True
assert _mod.would_block_cycle(wp, "wi-c", "wi-d") is False

try:
    _mod.add_dependency(wp, "wi-d", "wi-b", "blocks")
    raise AssertionError("expected DependencyCycleError")
except _mod.DependencyCycleError as err:
    assert str(err) == "dependency_cycle"

rel_wp = _mod.load_workplane([("p", "open", 1), ("q", "open", 1)], [])
_mod.add_dependency(rel_wp, "p", "q", "relates")
_mod.add_dependency(rel_wp, "q", "p", "caused-by")
assert _mod.related_items(rel_wp, "p") == [("q", "caused-by"), ("q", "relates")]

assert _mod.remove_dependency(wp, "wi-b", "wi-d", "blocks") is True
assert _mod.blocking_closure(wp, "wi-d") == []
assert _mod.remove_dependency(wp, "wi-a", "wi-b", "blocks") is False
assert _mod.remove_dependency(wp, "nope", "wi-a", "relates") is False

try:
    _mod.add_dependency(wp, "wi-a", "wi-b", "bogus")
    raise AssertionError("expected ValueError for unknown dep type")
except ValueError as err:
    assert "unknown dependency type" in str(err)

DIAMOND = _mod.load_workplane(
    [("top", "open", 1), ("mid", "open", 1), ("a", "done", 1), ("b", "done", 1), ("leaf", "done", 1)],
    [
        ("top", "mid", "blocks"),
        ("mid", "leaf", "blocks"),
        ("b", "mid", "blocks"),
        ("a", "mid", "blocks"),
    ],
)
assert _mod.blocking_closure(DIAMOND, "leaf") == ["a", "b", "mid", "top"]

_mod.add_dependency(wp, "ghost", "wi-a", "relates")
_mod.add_dependency(wp, "wi-a", "ghost", "blocks")
assert _mod.related_items(wp, "wi-a") == [("wi-b", "relates")]

assert _mod.LIFECYCLE == frozenset({"open", "in_progress", "in_review", "done", "cancelled"})
assert _mod.DEP_TYPES == frozenset({"blocks", "relates", "caused-by"})
print("iss_agent-team-project__kensho-projects__17 ref OK")
