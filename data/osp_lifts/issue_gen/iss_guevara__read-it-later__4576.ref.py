"""Reference harness for guevara/read-it-later#4576."""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_guevara__read-it-later__4576.py")
_spec = importlib.util.spec_from_file_location("read_it_later_4576_mod", _MOD)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_graph = _mod.load_graph
reachable_from = _mod.reachable_from
cycle_nodes = _mod.cycle_nodes

g = load_graph(
    ["a", "b", "c", "d", "e"],
    [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d"), ("d", "e")],
)
assert reachable_from(g, "a") == ["a", "b", "c", "d", "e"]
assert cycle_nodes(g) == []

diamond = load_graph(
    ["s", "l", "r", "t"],
    [("s", "l"), ("s", "r"), ("l", "t"), ("r", "t")],
)
assert reachable_from(diamond, "s") == ["l", "r", "s", "t"]
assert cycle_nodes(diamond) == []

cyclic = load_graph(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert reachable_from(cyclic, "a") == ["a", "b", "c"]
assert cycle_nodes(cyclic) == ["a"]

assert reachable_from(g, "missing") == []

print("read-it-later 4576 ref OK")
