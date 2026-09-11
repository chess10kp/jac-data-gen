import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_ClickHouse__ClickHouse__107067.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_search_graph(
    ["a", "b", "c", "d"],
    [("a", "b", 1.0), ("b", "c", 2.0), ("a", "d", 5.0), ("d", "c", 1.0)],
)
assert mod.shortest_costs(g, "a") == {"a": 0.0, "b": 1.0, "c": 3.0, "d": 5.0}
assert mod.improved_nodes(g, "a") == ["a", "b", "c", "d"]

g2 = mod.load_search_graph(
    ["x", "y", "z"],
    [("x", "y", 1.0), ("y", "z", 1.0), ("z", "x", 1.0)],
)
assert mod.has_cycle(g2) is True
assert mod.shortest_costs(g2, "x")["y"] == 1.0
print("ok")
