import importlib.util
from pathlib import Path

p = Path(__file__).with_suffix(".py")
spec = importlib.util.spec_from_file_location("vt25", p)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_timeline = mod.load_timeline
delete_group = mod.delete_group
active_items = mod.active_items

BASIC = load_timeline(
    [("g1", None)],
    [("g1", "a")],
    [],
)
assert active_items(BASIC) == ["a"]
assert delete_group(BASIC, "g1") == ["a"]
assert active_items(BASIC) == []

DOWNSTREAM = load_timeline(
    [("g1", None), ("g2", None)],
    [("g1", "a"), ("g2", "x")],
    [("x", "a")],
)
assert active_items(DOWNSTREAM) == ["a", "x"]
assert delete_group(DOWNSTREAM, "g1") == ["a", "x"]
assert active_items(DOWNSTREAM) == []

NESTED = load_timeline(
    [("g1", None), ("g2", "g1")],
    [("g1", "a"), ("g2", "b")],
    [],
)
assert delete_group(NESTED, "g1") == ["a", "b"]
assert active_items(NESTED) == []

TRANSITIVE = load_timeline(
    [("g1", None), ("g2", None)],
    [("g1", "a"), ("g2", "x"), ("g2", "y")],
    [("x", "a"), ("y", "x")],
)
assert delete_group(TRANSITIVE, "g1") == ["a", "x", "y"]
assert active_items(TRANSITIVE) == []

DIAMOND = load_timeline(
    [("g1", None), ("g2", None)],
    [("g1", "a"), ("g2", "b"), ("g2", "c"), ("g2", "d")],
    [("d", "c"), ("d", "b"), ("c", "a"), ("b", "a")],
)
assert delete_group(DIAMOND, "g1") == ["a", "b", "c", "d"]
assert active_items(DIAMOND) == []

assert delete_group(BASIC, "missing") == []
