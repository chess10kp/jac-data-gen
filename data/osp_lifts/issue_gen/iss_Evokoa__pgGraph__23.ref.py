import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_pggraph_23",
    Path(__file__).with_name("iss_Evokoa__pgGraph__23.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_graph(
    ["a", "b", "c", "d"],
    [
        ("a", "b", "mentions"),
        ("b", "c", "mentions"),
        ("a", "d", "has_chunk"),
        ("d", "c", "mentions"),
    ],
)
assert mod.shortest_path(store, "a", "c", ["mentions"]) == ["a", "b", "c"]
assert mod.shortest_path(store, "a", "c") == ["a", "b", "c"]
assert mod.reachable_within(store, "a", 2, ["mentions"]) == ["a", "b", "c"]
print("ok")
