"""Reference harness for iss_cskwork__math-item-os__15."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_cskwork__math-item-os__15.py"),
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
    Path(__file__).with_name("iss_cskwork__math-item-os__15.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_prerequisite_graph = _mod.load_prerequisite_graph
get_ancestors = _mod.get_ancestors
get_descendants = _mod.get_descendants
aggregate_item_counts = _mod.aggregate_item_counts

g = load_prerequisite_graph(
    [("apex", 1), ("left", 2), ("right", 3), ("join", 4)],
    [("right", "apex"), ("join", "right"), ("left", "apex"), ("join", "left")],
)
assert get_ancestors(g, "join") == ["apex", "left", "right"]
assert get_descendants(g, "apex") == ["join", "left", "right"]
assert get_ancestors(g, "join", max_depth=1) == ["left", "right"]
assert get_descendants(g, "apex", max_depth=1) == ["left", "right"]

solo_g = load_prerequisite_graph([("only", 5)], [])
assert get_ancestors(solo_g, "missing") == []
assert get_descendants(solo_g, "missing") == []
assert get_ancestors(solo_g, "only", max_depth=0) == []
assert get_ancestors(solo_g, "only", max_depth=-3) == []
assert get_descendants(solo_g, "only", max_depth=0) == []
assert get_descendants(solo_g, "only", max_depth=-1) == []
assert aggregate_item_counts(solo_g, "missing", "ancestors") == []
assert aggregate_item_counts(solo_g, "only", "lateral") == []

cycle_g = load_prerequisite_graph(
    [("a", 1), ("b", 2), ("c", 3)],
    [("c", "a"), ("a", "b"), ("b", "c")],
)
assert get_ancestors(cycle_g, "a") == ["a", "b", "c"]
assert get_descendants(cycle_g, "c") == ["a", "b"]
assert aggregate_item_counts(cycle_g, "a", "ancestors") == [("a", 1), ("b", 2), ("c", 3)]

edge_g = load_prerequisite_graph(
    [("leaf", 4), ("root", 9)],
    [("phantom", "root"), ("leaf", "ghost"), ("leaf", "root")],
)
assert get_ancestors(edge_g, "leaf") == ["root"]
assert get_descendants(edge_g, "root") == ["leaf"]
assert get_ancestors(edge_g, "ghost") == []
assert get_descendants(edge_g, "phantom") == []
assert aggregate_item_counts(edge_g, "leaf", "ancestors") == [("root", 9)]

solo = load_prerequisite_graph([("solo", 9)], [])
assert get_ancestors(solo, "solo") == []
assert get_descendants(solo, "solo") == []
assert aggregate_item_counts(solo, "solo", "descendants") == []

fan = load_prerequisite_graph(
    [("top", 1), ("left", 2), ("mid", 3), ("right", 4), ("bot", 5)],
    [
        ("bot", "right"),
        ("mid", "top"),
        ("bot", "mid"),
        ("right", "top"),
        ("bot", "left"),
        ("left", "top"),
    ],
)
assert get_ancestors(fan, "bot") == ["left", "mid", "right", "top"]
assert get_descendants(fan, "top") == ["bot", "left", "mid", "right"]
assert aggregate_item_counts(fan, "bot", "ancestors") == [
    ("left", 2),
    ("mid", 3),
    ("right", 4),
    ("top", 1),
]
print("iss_cskwork__math-item-os__15 ref OK")
