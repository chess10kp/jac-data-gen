import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_samyama-ai__samyama-graph__710",
    Path(__file__).with_name("iss_samyama-ai__samyama-graph__710.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_graph = mod.load_graph
reachable_by_path_length = mod.reachable_by_path_length
shortest_only_broken = mod.shortest_only_broken

TRI = load_graph(
    ["a", "b", "c"],
    [
        ("a", "b"), ("b", "a"),
        ("b", "c"), ("c", "b"),
        ("a", "c"), ("c", "a"),
    ],
)
assert reachable_by_path_length(TRI, "a", 1, 2) == ["b", "c"]
assert reachable_by_path_length(TRI, "a", 2, 2) == ["b", "c"]
assert shortest_only_broken(TRI, "a", 2, 2) == []

CYCLE = load_graph(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d")],
)
assert reachable_by_path_length(CYCLE, "a", 1, 3) == ["b", "c", "d"]

DIAMOND = load_graph(
    ["s", "left", "right", "t"],
    [("s", "left"), ("s", "right"), ("left", "t"), ("right", "t")],
)
assert reachable_by_path_length(DIAMOND, "s", 2, 2) == ["t"]
assert shortest_only_broken(DIAMOND, "s", 2, 2) == ["t"]

assert reachable_by_path_length(TRI, "missing", 1, 2) == []

print("ok")
